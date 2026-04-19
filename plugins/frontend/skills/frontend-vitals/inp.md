# INP (Interaction to Next Paint)

> 사용자의 상호작용(클릭·탭·키 입력) → 다음 프레임이 페인트되기까지의 시간. 페이지 **전체 수명**에서 발생한 상호작용 중 상위 퍼센타일을 사용 (일반적으로 최악값에 가까움).

> **2024년 3월부터 FID를 공식 대체**. FID는 첫 상호작용만 측정했지만, INP는 모든 상호작용을 추적한다.

## 1. 정의 & 목표

| 등급 | p75 기준 |
|---|---|
| ✅ Good | **≤ 200ms** |
| ⚠️ Needs Improvement | 200–500ms |
| ❌ Poor | > 500ms |

### 추적되는 상호작용

- `click`, `tap`, `keypress`
- `<input>` / `<textarea>` 입력

**제외**: 스크롤, 호버, 패시브 이벤트, 자동 발생 이벤트.

### INP 분해

```
INP = Input Delay + Processing Time + Presentation Delay
```

| 구간 | 의미 | 주 원인 |
|---|---|---|
| **Input Delay** | 이벤트 발생 ~ 핸들러 시작 | 메인 스레드가 다른 태스크로 바쁨 |
| **Processing Time** | 이벤트 핸들러 실행 | 무거운 동기 로직 |
| **Presentation Delay** | 핸들러 완료 ~ 다음 페인트 | 복잡한 렌더링, 큰 DOM 변경 |

---

## 2. 측정 방법

### Lab — Lighthouse의 한계

Lighthouse는 **INP를 직접 측정 못 한다** (자동 상호작용이 없음). 대리 지표로 **TBT(Total Blocking Time)**가 Performance 섹션에 표시됨. TBT ≤ 200ms이면 INP가 Good일 가능성 높음.

### Lab — DevTools Performance

1. DevTools > Performance > 녹화 시작
2. **실제로 버튼 클릭·입력** 수행
3. 녹화 중지
4. **Interactions** 레인 확인 — 각 상호작용의 지속 시간과 구간별 분해 표시

### Field — web-vitals.js

```js
import { onINP } from 'web-vitals';

onINP(({ value, id, entries }) => {
  const worst = entries.sort((a, b) => b.duration - a.duration)[0];
  analytics.track('inp', {
    value,
    id,
    interactionType: worst.name,
    target: worst.target?.tagName,
    startTime: worst.startTime,
  });
}, { reportAllChanges: false });
```

### DevTools에서 INP 실시간 확인

```js
// 콘솔에서 실행
let worstINP = 0;
new PerformanceObserver((list) => {
  for (const entry of list.getEntries()) {
    if (entry.interactionId && entry.duration > worstINP) {
      worstINP = entry.duration;
      console.log('New worst INP:', worstINP, 'ms', entry);
    }
  }
}).observe({ type: 'event', buffered: true, durationThreshold: 0 });
```

---

## 3. 주요 원인 (TOP 5)

### 3-1. 무거운 동기 로직

- 이벤트 핸들러에서 큰 배열 필터·정렬·변환
- JSON 파싱·직렬화가 큰 데이터에 대해 실행
- 동기 암호화·해싱

**확인**: Performance > Long Tasks (> 50ms) 이벤트 핸들러 구간

### 3-2. 큰 상태 업데이트 → 과도한 리렌더

- 한 번의 `setState`가 수백 개 컴포넌트 리렌더
- 메모이제이션 누락으로 전체 트리 재렌더

**확인**: React DevTools Profiler로 상호작용 기록 → 렌더 수 확인

### 3-3. Input Delay — 다른 태스크가 메인 스레드 점유

- 서드파티 스크립트 (태그 매니저, 분석 SDK, 광고)
- 초기 하이드레이션 중 상호작용 발생
- 큰 JS 번들 파싱·실행

**확인**: Performance에서 이벤트 직전 "Task" 블록이 길게 점유

### 3-4. 동기 `ResizeObserver` / `IntersectionObserver` 콜백

- 콜백 내에서 무거운 계산 수행
- 자주 발화하며 누적

### 3-5. 레이아웃 스래싱 (Forced Synchronous Layout)

```js
// ❌ 매 iteration마다 재레이아웃 강제
items.forEach(item => {
  const width = container.offsetWidth;  // 읽기 → 스타일 계산 강제
  item.style.width = `${width / 2}px`;  // 쓰기 → 재레이아웃 예약
});

// ✅ 읽기와 쓰기 분리
const width = container.offsetWidth;  // 한 번만 읽기
items.forEach(item => {
  item.style.width = `${width / 2}px`;
});
```

---

## 4. 개선 전략 (우선순위 순)

### 4-1. 긴 작업을 **쪼개기** (Yield to Main Thread)

50ms 이상 동기 실행은 무조건 쪼갠다.

```js
// ✅ scheduler.yield() (가장 최신 API, 지원 제한적)
async function processItems(items) {
  for (const item of items) {
    processItem(item);
    if (navigator.scheduling?.isInputPending?.()) {
      await scheduler.yield();
    }
  }
}

// ✅ setTimeout(0) — 호환성 좋음
function processInChunks(items, chunkSize = 100) {
  let i = 0;
  function run() {
    const end = Math.min(i + chunkSize, items.length);
    for (; i < end; i++) processItem(items[i]);
    if (i < items.length) setTimeout(run, 0);
  }
  run();
}
```

### 4-2. React `useTransition` / `useDeferredValue`

긴급하지 않은 업데이트를 백그라운드로.

```tsx
// ❌ 입력과 필터링이 한 프레임에 — 큰 리스트일수록 INP 악화
function Search({ items }) {
  const [query, setQuery] = useState('');
  const filtered = items.filter(i => i.name.includes(query));
  return (
    <>
      <input value={query} onChange={e => setQuery(e.target.value)} />
      <List items={filtered} />
    </>
  );
}

// ✅ useTransition — 입력은 즉시 반영, 필터링은 양보 가능
function Search({ items }) {
  const [query, setQuery] = useState('');
  const [displayQuery, setDisplayQuery] = useState('');
  const [isPending, startTransition] = useTransition();

  return (
    <>
      <input
        value={query}
        onChange={e => {
          setQuery(e.target.value);  // 즉시 반영
          startTransition(() => setDisplayQuery(e.target.value));  // 양보 가능
        }}
      />
      <List items={items.filter(i => i.name.includes(displayQuery))} />
    </>
  );
}

// ✅ useDeferredValue — 더 간결
function Search({ items }) {
  const [query, setQuery] = useState('');
  const deferred = useDeferredValue(query);
  const filtered = useMemo(() => items.filter(i => i.name.includes(deferred)), [deferred, items]);
  return (
    <>
      <input value={query} onChange={e => setQuery(e.target.value)} />
      <List items={filtered} />
    </>
  );
}
```

### 4-3. 리스트 가상화

화면 밖 아이템을 렌더하지 않음. 100개 이상 리스트는 가상화 적용.

```tsx
import { useVirtualizer } from '@tanstack/react-virtual';

function BigList({ items }) {
  const parentRef = useRef(null);
  const v = useVirtualizer({
    count: items.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 50,
  });
  return (
    <div ref={parentRef} style={{ height: 500, overflow: 'auto' }}>
      <div style={{ height: v.getTotalSize(), position: 'relative' }}>
        {v.getVirtualItems().map(row => (
          <div
            key={row.key}
            style={{ position: 'absolute', top: row.start, height: row.size, width: '100%' }}
          >
            {items[row.index].name}
          </div>
        ))}
      </div>
    </div>
  );
}
```

### 4-4. 메모이제이션

- `React.memo`로 하위 컴포넌트 불필요 렌더 차단
- `useMemo`로 비싼 계산 캐시
- `useCallback`으로 props에 전달되는 함수 안정화

**주의**: 전부 붙이지 않는다 — 측정 후 병목 지점만. 메모 자체도 오버헤드.

### 4-5. 웹 워커로 오프로드

메인 스레드 밖에서 실행:

```ts
// worker.ts
self.onmessage = (e) => {
  const result = heavyComputation(e.data);
  self.postMessage(result);
};

// main.ts
const worker = new Worker(new URL('./worker.ts', import.meta.url));
worker.postMessage(data);
worker.onmessage = (e) => setState(e.data);
```

**후보**: 이미지 처리, 큰 JSON 파싱, 암호화, 검색 인덱싱.

### 4-6. 서드파티 스크립트 제어

```tsx
// Next.js
import Script from 'next/script';

<Script src="https://example.com/analytics.js" strategy="afterInteractive" />
<Script src="https://example.com/chat.js" strategy="lazyOnload" />
```

- `afterInteractive`: 하이드레이션 직후
- `lazyOnload`: 유휴 시간 로드 (가장 덜 방해)

### 4-7. 이벤트 위임 최소화

수천 개 요소에 개별 리스너 대신 부모 1개 위임 — 단, 핸들러 내부 매칭 로직이 무거우면 역효과. 균형점 측정.

### 4-8. 디바운스 / 스로틀

입력 기반 API/필터는 debounce, 스크롤/리사이즈는 throttle (관련 규칙은 `frontend-rules` 참조).

---

## 5. 디버깅 워크플로우

### Step 1. 어느 상호작용이 문제인가

Field 데이터(web-vitals.js)로 **worst interaction의 target 셀렉터·이벤트 타입** 수집. 몇 % 사용자가 어느 요소에서 겪는지 파악.

### Step 2. 재현 + Performance 녹화

해당 상호작용을 DevTools Performance에서 녹화:
1. **Interactions** 레인에서 해당 상호작용 클릭
2. **Summary** 하단의 3-phase breakdown (Input Delay / Processing / Presentation) 확인

### Step 3. 지배적 구간에 따라 조치

| 지배 구간 | 의심 | 1차 조치 |
|---|---|---|
| **Input Delay** (> 50ms) | 메인 스레드 점유 | 서드파티 스크립트 지연 (§4-6), 긴 작업 분할 (§4-1) |
| **Processing** (> 100ms) | 무거운 핸들러 | 로직 쪼개기 / useTransition / 메모 / 워커 (§4-1, §4-2, §4-5) |
| **Presentation** (> 50ms) | 큰 리렌더 / 레이아웃 | 가상화·메모 / 레이아웃 스래싱 제거 (§4-3, §4-4) |

### Step 4. React 관점 점검

- **React DevTools Profiler**로 해당 상호작용 기록 → 렌더링된 컴포넌트 수·시간 확인
- "Why did this render?" 확인 (props 변경 없이 렌더되면 메모 대상)
- 가장 큰 commit duration 컴포넌트 집중

### Step 5. 검증

- 수정 후 동일 상호작용 재측정
- 실제 field 데이터로 p75 개선 확인 (28일)

---

## 6. 체크리스트

- [ ] 모든 이벤트 핸들러가 50ms 이내에 완료되는가
- [ ] 큰 리스트(100+) 가상화 적용
- [ ] 긴급하지 않은 업데이트에 `useTransition` / `useDeferredValue` 사용
- [ ] 입력 기반 검색·필터에 debounce (300ms 내외)
- [ ] 리렌더 핫스팟 메모이제이션 (Profiler 근거)
- [ ] 서드파티 스크립트가 `afterInteractive` / `lazyOnload`
- [ ] 레이아웃 스래싱(읽기·쓰기 교차) 없는가
- [ ] 무거운 순수 계산은 웹 워커 고려
- [ ] 이벤트 핸들러 내부에 무조건 `setState` 체인이 3개 이상이면 `unstable_batchedUpdates` 또는 `flushSync` 검토 (React 17 이하)

## 자주 하는 실수

1. **`useCallback` / `useMemo` 남발** — 대부분 도움 안 됨. 측정 후 병목만.
2. **Lighthouse TBT만 보고 안심** — TBT는 **로드 시점**만 본다. INP는 **세션 전체**.
3. **입력에 `useTransition` 잘못 적용** — 입력 자체를 transition으로 감싸면 **입력이 늦어짐**. 입력은 urgent, 파생 계산만 transition.
4. **가상화 없이 큰 리스트** — 1000개 리스트는 가상화 없이는 항상 INP Poor.
5. **전역 Context 값 변경** — Context 값이 바뀌면 모든 consumer 렌더. provider를 분할하거나 selector 패턴 사용.
