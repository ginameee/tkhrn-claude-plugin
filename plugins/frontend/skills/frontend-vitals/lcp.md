# LCP (Largest Contentful Paint)

> 뷰포트 내에서 가장 큰 콘텐츠 요소가 렌더링된 시점. 사용자가 "이 페이지 로드됐다"고 인식하는 순간.

## 1. 정의 & 목표

| 등급 | p75 기준 |
|---|---|
| ✅ Good | **≤ 2.5초** |
| ⚠️ Needs Improvement | 2.5–4.0초 |
| ❌ Poor | > 4.0초 |

### LCP 후보 요소

- `<img>`, `<image>` (SVG 내부)
- `<video>` 의 포스터 이미지
- `background-image` (CSS `url()`)
- 블록 레벨 텍스트 노드 (헤딩, 큰 문단)

**제외 요소**: `display:none`, 뷰포트 밖, opacity 0, cross-origin 이미지로 추정.

### LCP 분해

```
LCP = TTFB + Resource Load Delay + Resource Load Time + Element Render Delay
```

- **TTFB**: 서버 응답까지
- **Load Delay**: 리소스 발견 ~ 시작 (preload 누락 시 증가)
- **Load Time**: 리소스 다운로드 (이미지 크기·포맷·우선순위 영향)
- **Render Delay**: 다운로드 완료 ~ 페인트 (CSS·JS 블로킹, 폰트 대기)

**개선 시 이 4개 중 어느 구간이 큰지 확인**이 핵심.

---

## 2. 측정 방법

### Lab (Lighthouse / PageSpeed Insights)

1. Chrome DevTools > Performance > `Ctrl+Shift+E` 또는 Lighthouse 패널
2. Performance 녹화 후 **Timings** 레인에서 "LCP" 마커 확인
3. **Element** 탭에 "LCP element" 표시 — 어느 요소가 LCP인지 확인
4. **LCP by phase** 테이블로 4단계 분해 확인

### Field (web-vitals.js + RUM)

```js
import { onLCP } from 'web-vitals';

onLCP(({ value, id, entries }) => {
  // 분석 서버로 전송
  analytics.track('lcp', {
    value,
    id,
    element: entries[entries.length - 1]?.element?.tagName,
    url: entries[entries.length - 1]?.url,
  });
}, { reportAllChanges: false });
```

### DevTools에서 LCP 요소 즉시 확인

```js
// 콘솔에서 실행
new PerformanceObserver((list) => {
  const entries = list.getEntries();
  const lcp = entries[entries.length - 1];
  console.log('LCP:', lcp.startTime, lcp.element);
}).observe({ type: 'largest-contentful-paint', buffered: true });
```

---

## 3. 주요 원인 (TOP 5)

### 3-1. 느린 TTFB (서버 응답)

- 서버 로직 최적화 부재
- DB 쿼리 N+1
- CDN 미적용 또는 캐시 미스
- SSR에서 무거운 데이터 패칭 블로킹

**확인**: Lighthouse "Reduce initial server response time" 경고, TTFB > 800ms

### 3-2. LCP 이미지가 lazy load

- `loading="lazy"` 가 LCP 후보 이미지에 붙음
- Next.js `<Image priority>` 누락
- 네이티브 `loading="eager"` 명시 없음

**확인**: DevTools에서 LCP 요소가 이미지인데 Network 탭에서 초기 우선순위가 Low

### 3-3. 리소스 발견 지연

- 이미지가 JS 번들이 파싱된 후에야 DOM에 추가됨
- `<link rel="preload">` 누락
- `fetchpriority="high"` 미사용
- CSS `background-image`는 CSS 파싱 후에야 발견됨

**확인**: Performance 패널에서 이미지 요청이 HTML 도착 후 한참 뒤에 시작

### 3-4. 렌더링 블로킹 리소스

- 외부 CSS가 크고 head에 있음
- 동기 JS 스크립트가 head에 있음
- 웹 폰트 로딩으로 텍스트 LCP 지연

**확인**: Lighthouse "Eliminate render-blocking resources", FCP와 LCP 간격이 큼

### 3-5. 클라이언트 사이드 렌더링 (CSR)

- SPA에서 초기 HTML에 콘텐츠 없음 → JS 실행 → API 호출 → 렌더
- LCP가 SSR 대비 2–3배 느림

**확인**: View Source에서 `<div id="root"></div>` 외 콘텐츠 없음, LCP > 4초

---

## 4. 개선 전략 (우선순위 순)

### 4-1. LCP 이미지 즉시 로드

```tsx
// ❌ Bad
<img src="/hero.jpg" loading="lazy" />

// ✅ Good — Next.js
import Image from 'next/image';
<Image src="/hero.jpg" width={1200} height={600} priority alt="..." />

// ✅ Good — native HTML
<img src="/hero.jpg" fetchpriority="high" loading="eager" alt="..." />
```

**원칙**: LCP 후보는 `priority` / `fetchpriority="high"` + `loading="eager"`.

### 4-2. 리소스 preload

```html
<!-- head 내 -->
<link rel="preload" as="image" href="/hero.jpg" fetchpriority="high" />

<!-- 반응형 이미지 -->
<link
  rel="preload"
  as="image"
  imagesrcset="/hero-480.jpg 480w, /hero-1200.jpg 1200w"
  imagesizes="100vw"
/>
```

**주의**: preload는 **LCP 리소스 한두 개만**. 남용 시 다른 리소스 대역폭을 뺏음.

### 4-3. 이미지 포맷 + 크기 최적화

| 포맷 | 지원 | 크기 (JPEG 대비) | 권장 |
|---|---|---|---|
| **AVIF** | 모던 브라우저 | -50% | ✅ 1순위 |
| **WebP** | 거의 모든 환경 | -30% | ✅ fallback |
| **JPEG** | 모든 환경 | 기준 | 최후 fallback |

```html
<picture>
  <source srcset="/hero.avif" type="image/avif" />
  <source srcset="/hero.webp" type="image/webp" />
  <img src="/hero.jpg" alt="..." />
</picture>
```

**반응형 + DPR 대응**:

```html
<img
  src="/hero-800.jpg"
  srcset="/hero-400.jpg 400w, /hero-800.jpg 800w, /hero-1600.jpg 1600w"
  sizes="(max-width: 768px) 100vw, 800px"
  alt="..."
/>
```

### 4-4. 서버 응답 개선 (TTFB)

- **SSG/ISR**로 전환 가능한 페이지는 우선 적용 (정적 HTML = TTFB 극소)
- **Edge 렌더링** (Vercel Edge / Cloudflare Workers) — 글로벌 지연 단축
- **DB 쿼리 최적화** — 인덱스, N+1 제거, 캐시
- **CDN** + 이미지 CDN (Cloudinary, imgix) 적용

### 4-5. 폰트 최적화

- `font-display: swap` — fallback 폰트로 즉시 표시, 로드 후 교체
- `<link rel="preload" as="font" type="font/woff2" crossorigin>` — 중요 폰트 preload
- **Variable fonts** 사용으로 파일 수 줄임
- 사용하지 않는 글리프 제거 (subset)

```css
@font-face {
  font-family: 'Pretendard';
  src: url('/fonts/Pretendard-Regular.woff2') format('woff2');
  font-display: swap;
}
```

### 4-6. 렌더 블로킹 최소화

- 크리티컬 CSS는 `<style>` 인라인, 나머지는 `<link media="print" onload>` 패턴으로 비블로킹화
- JS는 `defer` 또는 `async`
- 서드파티 스크립트 (GA·픽셀)는 `next/script` `strategy="lazyOnload"` 또는 `afterInteractive`

### 4-7. 서버 컴포넌트 / SSR 전환

```tsx
// ❌ CSR — LCP가 JS + API 후에야
'use client';
export default function ProductPage() {
  const { data } = useQuery(...);
  if (!data) return <Skeleton />;
  return <Product {...data} />;
}

// ✅ RSC (Next.js App Router) — 서버에서 HTML 완성
export default async function ProductPage() {
  const data = await getProduct();
  return <Product {...data} />;
}
```

---

## 5. 디버깅 워크플로우

### Step 1. LCP 요소 식별

```
Chrome DevTools > Performance > 녹화
→ Timings 레인 "LCP" 마커 클릭
→ Summary 하단 "Related Node" 확인
```

### Step 2. 4단계 분해

| 단계 | 측정 | 우세 시 조치 |
|---|---|---|
| TTFB | 0 ~ 응답 도착 | 서버 최적화 (§4-4) |
| Load Delay | 응답 도착 ~ 리소스 요청 시작 | preload / 우선순위 (§4-2, §4-1) |
| Load Time | 요청 ~ 수신 완료 | 포맷·크기·CDN (§4-3) |
| Render Delay | 수신 완료 ~ 페인트 | 렌더 블로킹 제거 (§4-6) |

**이상적 분배**: TTFB 10%, Load Delay 10%, Load Time 40%, Render Delay 40% 내외.  
특정 단계가 지배적이면 거기부터 공략.

### Step 3. 개선 검증

- Lighthouse는 매 실행마다 ±10% 변동 → **3회 평균**
- Production 배포 후 **Search Console > Core Web Vitals** 28일 추이 확인
- 회귀 방지: CI에 Lighthouse budget 설정

```yaml
# lighthouse-budget.json
[
  {
    "resourceSizes": [
      { "resourceType": "image", "budget": 500 },
      { "resourceType": "script", "budget": 250 }
    ],
    "timings": [
      { "metric": "largest-contentful-paint", "budget": 2500 }
    ]
  }
]
```

---

## 6. 체크리스트

- [ ] LCP 요소가 `priority` / `fetchpriority="high"` 를 가지는가
- [ ] LCP 이미지가 `loading="lazy"` 가 아닌가
- [ ] 이미지가 AVIF 또는 WebP로 제공되는가
- [ ] 반응형 `srcset` + `sizes`로 기기별 적절한 크기 전송하는가
- [ ] `width`/`height` 또는 `aspect-ratio`가 명시되어 있는가 (CLS 동시 해결)
- [ ] 크리티컬 리소스(LCP 이미지·히어로 폰트)에 preload 적용
- [ ] TTFB가 800ms 이하인가 — 아니면 SSG/ISR/Edge 고려
- [ ] 렌더 블로킹 CSS/JS 제거 또는 defer/async
- [ ] `font-display: swap` + fallback 폰트 설정
- [ ] CSR 페이지라면 SSR/SSG 전환 가능한지 재검토
- [ ] Lighthouse budget CI 설정으로 회귀 방지

## 자주 하는 실수

1. **"내 Mac에서 빠른데 왜 Poor?"** — CrUX는 모바일 4G + 저사양 CPU 기준. 실 사용자 환경에서 측정.
2. **모든 이미지에 preload** — 오히려 LCP가 느려질 수 있음. 정확히 LCP 요소 1–2개만.
3. **`priority` 남발** — 페이지당 1–2개. 전부 high면 아무것도 high가 아님.
4. **`next/image` 없이 최적화 기대** — 수동으로 srcset·preload 설정하지 않으면 개선 미미.
5. **Lab 수치만 보고 배포** — field 데이터로 실제 개선 확인 필수.
