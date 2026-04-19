# CLS (Cumulative Layout Shift)

> 페이지 수명 동안 발생한 **예상치 못한** 레이아웃 이동의 누적 점수. 사용자가 읽던 텍스트가 밀리거나, 클릭하려던 버튼이 움직이는 경험의 정량화.

## 1. 정의 & 목표

| 등급 | p75 기준 |
|---|---|
| ✅ Good | **≤ 0.1** |
| ⚠️ Needs Improvement | 0.1–0.25 |
| ❌ Poor | > 0.25 |

### Layout Shift Score 계산

```
Layout Shift Score = Impact Fraction × Distance Fraction
```

- **Impact Fraction**: 뷰포트에서 움직인 영역의 비율
- **Distance Fraction**: 가장 많이 움직인 요소의 최대 이동 거리 / 뷰포트 크기

**Session Window**: 5초 이내 연속 shift를 한 세션으로 묶고, 세션들 중 **최악 세션 점수**를 CLS로 취함 (이전에는 전체 합산이었지만 2021년 변경).

### 제외되는 이동

- **사용자 입력으로 유발된 이동** (500ms 이내): 버튼 클릭 → 메뉴 펼침 등은 CLS 계산 제외
- `transform` / `opacity` 변경: 리플로우를 일으키지 않으므로 제외
- 스크롤

---

## 2. 측정 방법

### Lab — Lighthouse / DevTools Performance

1. DevTools > Performance > 녹화
2. **Experience** 레인에 빨간색 "Layout Shift" 블록
3. 클릭하면 Summary에 **Moved from/to**, **Score** 표시
4. **Element** 탭에 어떤 DOM이 이동했는지

### Field — web-vitals.js

```js
import { onCLS } from 'web-vitals';

onCLS(({ value, entries }) => {
  const worstShift = entries
    .map(e => ({ value: e.value, sources: e.sources }))
    .sort((a, b) => b.value - a.value)[0];
  
  analytics.track('cls', {
    value,
    worstShiftValue: worstShift?.value,
    worstShiftElement: worstShift?.sources?.[0]?.node?.tagName,
  });
}, { reportAllChanges: false });
```

### DevTools "Rendering" 탭 실시간 시각화

```
DevTools > ⋮ > More tools > Rendering
→ "Layout Shift Regions" 체크
```

파란색 하이라이트가 깜빡이면 해당 영역에서 shift 발생. 페이지를 조작하면서 실시간 관찰 가능.

---

## 3. 주요 원인 (TOP 5)

### 3-1. 크기 없는 이미지·비디오·iframe

```html
<!-- ❌ Bad -->
<img src="/photo.jpg" />

<!-- ✅ Good — 크기 명시 -->
<img src="/photo.jpg" width="800" height="600" />

<!-- ✅ 또는 CSS aspect-ratio -->
<img src="/photo.jpg" style="aspect-ratio: 4/3; width: 100%;" />
```

**판단 기준**: 이미지 로딩 전 공간을 차지하지 않으면, 로딩 완료 시 그 아래 콘텐츠가 밀림.

### 3-2. 웹 폰트 교체 (FOIT/FOUT)

fallback 폰트와 웹 폰트의 **metric 차이**로 텍스트 줄바꿈이 달라지며 레이아웃 이동 발생.

**해결**:
1. `font-display: optional` — 웹 폰트가 즉시 준비 안 되면 fallback 유지 (이후 페이지 이동 시 캐시됨)
2. `size-adjust`, `ascent-override`, `descent-override`로 fallback 메트릭 웹 폰트에 맞춤

```css
@font-face {
  font-family: 'Pretendard';
  src: url('/fonts/Pretendard.woff2') format('woff2');
  font-display: swap;
}

/* fallback 메트릭을 웹 폰트에 맞춤 — Pretendard에 맞춘 예 */
@font-face {
  font-family: 'Pretendard-fallback';
  src: local('Apple SD Gothic Neo'), local('Malgun Gothic');
  size-adjust: 100%;
  ascent-override: 90%;
  descent-override: 22%;
}

body {
  font-family: 'Pretendard', 'Pretendard-fallback', sans-serif;
}
```

> 도구: https://screenspan.net/fallback, https://meowni.ca/font-style-matcher/

### 3-3. 동적으로 삽입되는 콘텐츠

- 배너·공지·쿠키 동의 (페이지 로드 후 상단에 삽입 → 기존 콘텐츠 밀림)
- 광고 슬롯 (크기 미지정)
- 임베드 위젯 (YouTube, Twitter, Instagram)

**해결**: 공간 **예약**.

```html
<!-- ❌ 광고 로드 시 높이 확장 -->
<div id="ad-slot"></div>

<!-- ✅ 미리 높이 예약 -->
<div id="ad-slot" style="min-height: 250px;"></div>
```

### 3-4. 스켈레톤과 실 콘텐츠 크기 불일치

```tsx
// ❌ 스켈레톤이 실제 콘텐츠보다 작음 → 교체 시 아래가 밀림
<Skeleton height={40} />
{data && <Article />}  // 실제 높이 800px

// ✅ 예상 높이 맞춤
<div style={{ minHeight: 800 }}>
  {loading ? <ArticleSkeleton /> : <Article />}
</div>
```

`frontend-rules`의 로딩 규칙과 상호참조.

### 3-5. CSS 애니메이션이 레이아웃 속성 변경

```css
/* ❌ width / height / top / left / margin 변경 — 리플로우 유발 */
@keyframes slide {
  from { margin-left: -100px; }
  to { margin-left: 0; }
}

/* ✅ transform — 리플로우 없음 (compositor 레이어) */
@keyframes slide {
  from { transform: translateX(-100px); }
  to { transform: translateX(0); }
}
```

---

## 4. 개선 전략 (우선순위 순)

### 4-1. 모든 미디어에 크기 명시

- `<img>`, `<video>`, `<iframe>`: `width` + `height` 속성
- 반응형: CSS `aspect-ratio: W / H; width: 100%;`

```html
<!-- 반응형 이미지 — 비율 유지하며 크기 예약 -->
<img
  src="/photo.jpg"
  width="1600"
  height="900"
  style="width: 100%; height: auto;"
  alt="..."
/>
```

브라우저는 `width/height` 속성에서 비율을 계산해 공간을 예약한다.

### 4-2. 폰트 매칭

- `font-display: optional` 또는 `swap` + fallback 메트릭 매칭 (§3-2)
- 중요 폰트는 `<link rel="preload" as="font">`
- 시스템 폰트만 사용할 수 있다면 그것이 가장 안전

### 4-3. 동적 콘텐츠 공간 예약

- 광고·배너·공지: 최소 크기 지정
- 쿠키 배너: 페이지 상단이 아닌 **하단 고정**(position: fixed)으로 레이아웃 분리
- 임베드: 플랫폼 권장 비율로 placeholder

```css
/* 16:9 유튜브 임베드 */
.video-wrapper {
  aspect-ratio: 16 / 9;
  width: 100%;
}
.video-wrapper iframe {
  width: 100%;
  height: 100%;
}
```

### 4-4. 스켈레톤 크기 일치

- 스켈레톤이 실제 콘텐츠 레이아웃과 동일한 높이·간격
- 리스트는 아이템 개수·높이까지 시뮬레이션

```tsx
function ArticleListSkeleton({ count = 5 }) {
  return (
    <ul>
      {Array.from({ length: count }).map((_, i) => (
        <li key={i} style={{ minHeight: 120, marginBottom: 16 }}>
          <div style={{ height: 24, width: '70%', background: '#eee' }} />
          <div style={{ height: 80, marginTop: 8, background: '#f3f3f3' }} />
        </li>
      ))}
    </ul>
  );
}
```

### 4-5. 변형은 transform / opacity로

레이아웃에 영향 없는 속성만 애니메이션.

| ✅ 리플로우 없음 | ❌ 리플로우 유발 |
|---|---|
| `transform` | `top` / `left` / `right` / `bottom` |
| `opacity` | `width` / `height` / `margin` / `padding` |
| `filter` | `border` / `display` |

### 4-6. 프리렌더링 / SSR 활용

CSR에서 상태 변화로 전체 레이아웃이 재구성되면 CLS 누적. SSR/SSG로 **최종 형태의 HTML**을 서버에서 보내면 shift 발생 여지 자체가 줄어든다.

### 4-7. 사용자 상호작용 500ms 윈도우 활용

- 사용자 클릭 이후 500ms 이내의 shift는 CLS 제외 (의도된 변경으로 간주)
- "더보기" 클릭 → 콘텐츠 확장 같은 의도된 shift는 문제없음
- 단, 입력 직후 async 응답이 500ms를 넘으면 다시 CLS 대상 — 응답 전 공간 예약 필요

---

## 5. 디버깅 워크플로우

### Step 1. 실시간 시각화

```
DevTools > Rendering > "Layout Shift Regions" ON
```

페이지 로드부터 스크롤·상호작용까지 수행하며 **파란색 깜빡임** 관찰.

### Step 2. Performance 녹화로 shift 특정

- **Experience** 레인의 빨간 "Layout Shift" 블록 클릭
- Summary의 Score·Moved from·Moved to로 원인 요소 파악
- Console에서 요소를 `$0`으로 선택 가능

### Step 3. 원인 분류

| 증상 | 원인 | 조치 |
|---|---|---|
| 이미지 로드 후 텍스트 하강 | 이미지 크기 미지정 | width/height 또는 aspect-ratio (§4-1) |
| 스크롤 직후 상단 shift | 지연 로드된 콘텐츠가 공간 점유 | 공간 예약 (§4-3) |
| 텍스트 한 번 재조판 | 폰트 교체 (FOUT) | font-display + metric 매칭 (§4-2) |
| 페이지 로드 2–3초 후 | 배너·광고·공지 삽입 | 슬롯 크기 예약 (§4-3) |
| 데이터 로드 후 리스트 밀림 | 스켈레톤 크기 불일치 | 스켈레톤 높이 맞춤 (§4-4) |

### Step 4. 개선 검증

- `Layout Shift Regions` ON 상태로 재현 시 깜빡임 사라졌는지 확인
- Lighthouse 3회 실행 평균
- Field 데이터는 28일 뒤 확인

---

## 6. 체크리스트

- [ ] 모든 `<img>` / `<video>` / `<iframe>`에 `width`/`height` 또는 `aspect-ratio`
- [ ] 웹 폰트에 `font-display: optional` 또는 메트릭 매칭된 `swap`
- [ ] 동적 배너·광고·임베드가 공간을 예약
- [ ] 스켈레톤이 실제 콘텐츠 크기와 일치
- [ ] 애니메이션이 `transform` / `opacity` 기반 (레이아웃 속성 변경 금지)
- [ ] `min-height` / `aspect-ratio`로 async 콘텐츠 영역 예약
- [ ] DevTools Rendering "Layout Shift Regions"로 페이지 훑어 깜빡임 없음 확인
- [ ] CrUX에서 p75 CLS ≤ 0.1

## 자주 하는 실수

1. **`height: auto` 만으로 예약된다고 착각** — 비율 힌트가 없으면 브라우저가 공간 못 예약. `aspect-ratio` 필요.
2. **`transition: all`** — 레이아웃 속성까지 전환 대상에 포함되어 예기치 않은 shift.
3. **쿠키 배너를 페이지 최상단에 동적 삽입** — 아래 모든 콘텐츠 밀어냄. 하단 fixed 또는 최상단 자리 예약.
4. **스켈레톤을 한 덩어리로** — 실제 콘텐츠가 여러 섹션인데 스켈레톤은 하나의 큰 박스면 교체 시 재배치. 섹션별 스켈레톤으로.
5. **`font-display: block`** — FOIT 길어져 LCP 악화. `swap` 또는 `optional` 선호.
