---
name: frontend-a11y-perf
description: WCAG 2.1 AA 접근성 + Core Web Vitals 성능 + 반응형·모바일 우선 설계 검토. UI 컴포넌트 작성·리뷰 시 수동 호출. 4축(가독성·예측가능성·응집도·결합도)과 별개로 "사용자 관점"에서 인터페이스 품질을 점검한다.
disable-model-invocation: true
---

# Frontend Accessibility & Performance

UI 컴포넌트·페이지의 **접근성·성능·반응형** 품질을 점검한다. 4축 기반 `frontend-rules` / `frontend-review`가 "변경하기 쉬운 코드"를 다룬다면, 이 스킬은 **"모든 기기·모든 사용자에게 동작하는 코드"**를 다룬다.

## 사용 시점

- 새 UI 컴포넌트 구현 전 요구사항 정리
- PR 리뷰 시 접근성·성능 관점 추가 점검
- 기존 컴포넌트의 a11y/perf 부채 진단
- 디자인 시스템 컴포넌트 품질 기준 확립

## 핵심 원칙

모든 결정에서 **사용자 우선**으로 판단한다. 접근성은 "추가 기능"이 아닌 **기본 요구사항**이다. 실제 네트워크·기기 환경에서 동작해야 하며, 모든 사용자가 모든 기기에서 사용 가능해야 한다.

---

## 1. 접근성 (WCAG 2.1 AA)

### 1-1. 시맨틱 HTML

- 의미 있는 태그 사용: `<button>`, `<nav>`, `<main>`, `<article>`, `<section>`, `<header>`, `<footer>`
- `<div onClick>` 로 버튼을 흉내내지 않는다 — 키보드·스크린리더 호환이 깨진다
- 헤딩 계층 준수: `h1 → h2 → h3` 순서. 시각적 크기 때문에 `h4` 다음 `h2` 금지

**체크리스트:**
- [ ] 클릭 가능한 요소가 모두 `<button>` 또는 `<a>` 인가 (div/span 금지)
- [ ] 페이지당 하나의 `<h1>`, 헤딩 계층이 논리적인가
- [ ] `<nav>`, `<main>`, `<aside>` 같은 랜드마크가 있는가

### 1-2. 키보드 네비게이션

- 모든 인터랙션이 키보드만으로 가능해야 한다
- `Tab` 순서가 시각적 순서와 일치해야 한다
- 포커스 트랩: 모달·다이얼로그에서 포커스가 밖으로 나가지 않게
- 포커스 표시: `:focus-visible` 스타일 제공 (제거 금지)

**체크리스트:**
- [ ] `Tab`, `Shift+Tab`으로 모든 인터랙티브 요소에 도달 가능한가
- [ ] `Enter`/`Space` 로 버튼 동작, `Escape` 로 모달 닫기가 되는가
- [ ] 포커스 링이 시각적으로 명확한가 (`outline: none` 단독 사용 금지)
- [ ] 모달 열림 시 내부로 포커스 이동, 닫힘 시 트리거 요소로 복귀하는가

### 1-3. 스크린 리더 호환

- 이미지 `alt` 속성: 의미 있는 이미지는 설명, 장식은 `alt=""`
- 폼 라벨: `<label for="...">` 또는 `aria-label`/`aria-labelledby`
- 라이브 영역: 동적 변경은 `aria-live="polite"` 또는 `role="status"`
- 숨김 처리: 시각적 숨김은 `visually-hidden` 클래스, 스크린리더 숨김은 `aria-hidden="true"`

**체크리스트:**
- [ ] 모든 `<img>`에 적절한 `alt`가 있는가
- [ ] 폼 필드가 라벨과 연결되어 있는가
- [ ] 아이콘 버튼에 `aria-label`이 있는가
- [ ] 로딩·에러·성공 상태가 라이브 영역으로 공지되는가

### 1-4. 색상 대비 & 시각

- 텍스트 대비: 일반 텍스트 4.5:1, 큰 텍스트 3:1 (WCAG AA)
- 색상만으로 정보 전달 금지 (색맹 사용자 배려) — 아이콘·텍스트 병행
- 글자 크기 확대(200%)에서도 레이아웃이 깨지지 않아야 한다

**체크리스트:**
- [ ] 대비비가 WCAG AA 기준을 충족하는가
- [ ] 에러·경고가 색상만이 아닌 아이콘·텍스트로도 표시되는가
- [ ] `prefers-reduced-motion` 감지하여 애니메이션을 줄이는가

---

## 2. 성능 (Core Web Vitals)

> **이 섹션은 요약**이다. 각 지표의 상세 해설(측정·원인 분해·개선 전략·디버깅 워크플로우)은 `frontend-vitals` 스킬을 참조한다:
> - LCP → `frontend-vitals/lcp.md`
> - INP → `frontend-vitals/inp.md`
> - CLS → `frontend-vitals/cls.md`
> - 측정 도구 비교 → `frontend-vitals/measurement.md`
>
> `frontend-a11y-perf`는 "사용자 관점 UI 품질"을, `frontend-vitals`는 "지표 중심 측정·진단 사이클"을 각각 맡는다.

### 2-1. LCP (Largest Contentful Paint) < 2.5초

- 히어로 이미지·메인 콘텐츠를 최우선 로드
- `<img fetchpriority="high">`, `<link rel="preload">` 활용
- 이미지 포맷 최적화: WebP/AVIF, 적절한 해상도
- 서버 응답 시간(TTFB) < 600ms

**체크리스트:**
- [ ] LCP 후보 이미지가 lazy-load 되지 않는가
- [ ] 이미지에 `width`·`height` 명시 (레이아웃 시프트 방지)
- [ ] 크리티컬 CSS가 인라인되거나 빠르게 로드되는가

### 2-2. INP (Interaction to Next Paint) < 200ms

- 메인 스레드 블로킹 최소화
- 긴 작업은 `requestIdleCallback` 또는 `useTransition`으로 양보
- 이벤트 핸들러에서 무거운 계산 금지 → `useMemo`, 웹 워커
- React 18+ `startTransition`으로 긴급하지 않은 업데이트 분리

**체크리스트:**
- [ ] 입력·클릭 응답에 무거운 동기 계산이 없는가
- [ ] 필터·검색 결과 업데이트에 `useTransition`을 고려했는가
- [ ] 리스트 렌더링이 가상화(`react-window` 등)되어야 하는가

### 2-3. CLS (Cumulative Layout Shift) < 0.1

- 이미지·iframe·동영상에 크기 명시
- 웹 폰트 로딩 전략: `font-display: swap` + fallback 폰트 크기 조정
- 동적 삽입 요소(배너·광고)는 공간 예약

**체크리스트:**
- [ ] 모든 미디어 요소에 `width`/`height` 또는 `aspect-ratio`가 있는가
- [ ] 스켈레톤이 실제 콘텐츠 크기와 일치하는가
- [ ] `font-display: swap` + fallback 매칭으로 CLS 방지했는가

### 2-4. 번들 크기

- 초기 번들 < 170KB (gzipped) 목표
- 코드 스플리팅: `React.lazy` + `Suspense` 로 라우트·무거운 위젯 분리
- Tree shaking 가능한 import: `import { foo } from 'lib'` (전체 import 금지)
- 큰 라이브러리 대안 검토: moment → date-fns / dayjs, lodash → lodash-es

**체크리스트:**
- [ ] 라우트별 코드 스플리팅이 되어 있는가
- [ ] 모든 페이지에 필요 없는 라이브러리가 초기 번들에 포함되지 않는가
- [ ] 번들 분석(`webpack-bundle-analyzer`, `vite-plugin-visualizer`) 했는가

### 2-5. 이미지 최적화

- 반응형 이미지: `srcset` + `sizes`
- 포맷: WebP/AVIF + fallback
- Lazy load: `loading="lazy"` (LCP 후보 제외)
- Next.js `next/image`, Vite/기타는 자체 최적화 또는 CDN 사용

---

## 3. 반응형 & 모바일 우선

### 3-1. Mobile-First CSS

- 기본 스타일은 모바일 기준, `min-width` 미디어 쿼리로 확장
- 브레이크포인트: 일반적으로 640 / 768 / 1024 / 1280 / 1536 (Tailwind 기준) 또는 디자인 시스템 기준

```css
/* Mobile first */
.container { padding: 1rem; }

@media (min-width: 768px) {
  .container { padding: 2rem; }
}
```

### 3-2. 터치 타겟

- 최소 터치 타겟 크기: 44×44px (WCAG 2.5.5)
- 인접 타겟 간격 8px 이상
- hover 의존 금지 — 터치 기기에서는 hover가 없음

### 3-3. 뷰포트 & 안전 영역

- `<meta name="viewport" content="width=device-width, initial-scale=1">`
- iOS 노치: `env(safe-area-inset-*)` 활용
- 가로 스크롤 방지: `overflow-x: hidden` 남용 금지, 원인(고정 너비 요소) 제거

### 3-4. 인풋 최적화

- `inputmode` 속성: 숫자는 `inputmode="numeric"`, 이메일은 `inputmode="email"` — 적절한 모바일 키보드 표시
- `autocomplete` 속성: 브라우저 자동 완성 지원
- `<input type="...">`: 날짜·시간·색상 등 시맨틱 타입 사용

---

## 4. 컴포넌트 아키텍처

### 4-1. 재사용 가능한 디자인 시스템

- 디자인 토큰(색상·간격·타이포) 중앙 관리
- 컴파운드 컴포넌트 패턴: `<Select><Select.Option /></Select>`
- Headless UI + 프로젝트 스타일링 분리 (Radix UI, Headless UI 등)

### 4-2. 현대 프레임워크 베스트 프랙티스

- **React**: Suspense + use, Server Components (RSC), Transitions
- **Next.js App Router**: 서버 컴포넌트 우선, 클라이언트 컴포넌트는 필요 시에만
- **Vue 3**: Composition API, `<script setup>`
- **Angular**: Signals (v17+), standalone components

### 4-3. 상태 관리 계층화

- 서버 상태 (TanStack Query) / 클라이언트 전역 상태 (Jotai/Zustand) / 로컬 상태 (`useState`) 분리
- URL 상태 (`?query=...`) 활용하여 새로고침·공유 가능하게

---

## 검토 프로세스

UI 컴포넌트·페이지를 리뷰할 때:

1. **접근성 우선 점검**
   - 시맨틱 HTML·키보드·스크린리더·대비
   - 자동화 도구(axe-core, Lighthouse a11y)로 기본 스캔 권장

2. **성능 지표 점검**
   - Core Web Vitals (LCP / INP / CLS)
   - 번들 크기 / 초기 로드 / 이미지 최적화

3. **반응형 검증**
   - 모바일·태블릿·데스크톱 뷰포트 확인
   - 터치 타겟 크기, hover 의존 체크

4. **컴포넌트 아키텍처**
   - 재사용성, 프레임워크 패턴 준수

## 출력 형식

```markdown
## a11y / perf 리뷰 결과

### 접근성 (WCAG 2.1 AA)
- ✅ / ⚠️ [항목] — [설명]

### 성능 (Core Web Vitals)
- ✅ / ⚠️ LCP: [평가]
- ✅ / ⚠️ INP: [평가]
- ✅ / ⚠️ CLS: [평가]

### 반응형
- ✅ / ⚠️ [항목]

### 개선 우선순위
1. [높음] [항목] — [근거]
2. [중간] [항목] — [근거]
3. [낮음] [항목] — [근거]
```

## 원칙

- **접근성은 타협 불가** — 기능 완료 = a11y 완료
- **측정 기반 판단** — Lighthouse, Chrome DevTools Performance, 실제 기기 테스트
- **트레이드오프 명시** — "JS 번들을 줄이면 X 기능이 제한된다" 같은 선택의 근거 제시
- **프로덕션 환경 가정** — 느린 3G·저사양 기기에서도 동작해야 한다
