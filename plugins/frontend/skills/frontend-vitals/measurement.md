# 측정 도구 비교 & 워크플로우

Core Web Vitals를 측정하는 방법은 여러 가지이며, **같은 페이지라도 도구에 따라 수치가 크게 다르다**. 도구별 특성과 언제 쓰는지 정리.

## 도구 분류

```
┌────────────────────────────────────────────────────────────┐
│                  Lab (시뮬레이션)                            │
│  - 단일 측정, 일관된 조건                                    │
│  - 원인 진단 · 회귀 테스트                                   │
│                                                             │
│  • Chrome DevTools (Performance / Lighthouse)              │
│  • PageSpeed Insights (Lighthouse 부분)                    │
│  • WebPageTest                                             │
└────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│                  Field (RUM, 실제 사용자)                    │
│  - 28일 p75 통계                                             │
│  - 랭킹 판단 · 우선순위 결정                                  │
│                                                             │
│  • CrUX (Chrome UX Report)                                 │
│  • Google Search Console                                   │
│  • PageSpeed Insights (Field Data 섹션)                    │
│  • web-vitals.js → GA4 / 자체 RUM                          │
└────────────────────────────────────────────────────────────┘
```

---

## 1. Chrome DevTools — Performance 패널

**언제**: 특정 상호작용·렌더링 단계의 구체적 원인 파악할 때.

### 기본 사용
1. DevTools > Performance 탭
2. ⚙️ > **CPU 4x slowdown**, **Fast 3G** 등 throttling
3. 녹화 시작 → 페이지 로드 또는 상호작용 → 중지

### 주요 레인
- **Timings**: FCP, LCP, DCL, Load 마커
- **Interactions**: 각 상호작용 구간(Input Delay / Processing / Presentation) 분해
- **Experience**: Layout Shift 블록
- **Network**: 리소스 요청 타임라인
- **Main**: 메인 스레드 점유 (Long Task > 50ms 빨강)

### 체크 포인트
- LCP 요소가 누구인지 (Timings 마커 Related Node)
- 상호작용 구간별 병목 (Interactions → Summary의 3-phase)
- Long Task 존재 여부 및 호출 스택

---

## 2. Lighthouse — DevTools 탭 / PageSpeed Insights

**언제**: 전체 지표 요약·자동 진단·회귀 테스트.

### 특징
- 단일 실행은 **±10% 변동**이 일반적 → 3회 평균
- 모바일 / 데스크톱 분리 측정
- "Performance" 점수(0–100)는 가중 평균
- **INP는 측정 못 함** (상호작용 없음) — TBT가 대리 지표

### 해석 주의
- 로컬 Lighthouse 점수 > PSI 점수일 가능성 높음 (로컬 머신이 더 빠름)
- 배포 판단은 PSI + Field 데이터 기준

### CI 통합

```yaml
# .github/workflows/lighthouse.yml
- uses: treosh/lighthouse-ci-action@v10
  with:
    urls: |
      https://example.com
      https://example.com/products/sample
    budgetPath: ./lighthouse-budget.json
```

```json
// lighthouse-budget.json
[{
  "timings": [
    { "metric": "largest-contentful-paint", "budget": 2500 },
    { "metric": "total-blocking-time", "budget": 200 },
    { "metric": "cumulative-layout-shift", "budget": 100 }
  ],
  "resourceSizes": [
    { "resourceType": "script", "budget": 250 },
    { "resourceType": "image", "budget": 500 }
  ]
}]
```

---

## 3. PageSpeed Insights (PSI)

**언제**: 특정 URL의 현재 상태를 빠르게 확인.

URL: https://pagespeed.web.dev/

### 두 섹션
1. **Core Web Vitals Assessment** (상단)
   - Field 데이터 (CrUX, 28일 p75)
   - **실제 검색 랭킹 판단은 이 데이터**
2. **Performance** (하단)
   - Lab 데이터 (Lighthouse)
   - 개선 기회·진단 항목 자동 제안

### Field 데이터가 "Not available"이면
- 해당 URL의 CrUX 트래픽이 부족 (소규모 사이트)
- 이럴 때는 **origin-level** (도메인 전체) 데이터만 참고

---

## 4. CrUX (Chrome UX Report)

**언제**: 사이트 전체·경쟁사·카테고리 비교 등 집계 분석.

### 접근 방법
1. **BigQuery** 공개 데이터셋 (월별 집계)
2. **CrUX API** — 특정 URL/origin의 현재 28일 p75
3. **CrUX Dashboard (Looker Studio)** — 도메인별 트렌드 시각화

### CrUX API 예시

```bash
curl -X POST \
  "https://chromeuxreport.googleapis.com/v1/records:queryRecord?key=API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://example.com",
    "metrics": ["largest_contentful_paint", "interaction_to_next_paint", "cumulative_layout_shift"]
  }'
```

---

## 5. Google Search Console — Core Web Vitals Report

**언제**: Google 관점에서 **실제 랭킹에 영향을 주는** URL 그룹 파악.

### 특징
- URL을 **Good / Needs Improvement / Poor** 그룹으로 자동 분류
- 문제 URL **샘플** 제공 (전체 아님)
- 모바일·데스크톱 분리
- 개선 후 "수정 확인" 요청 기능

### 워크플로우
1. 보고서에서 **Poor URL 그룹** 확인
2. 대표 샘플 URL을 PSI로 진단
3. 원인 수정 → 배포
4. "수정 확인" 클릭 → Google이 재평가

---

## 6. web-vitals.js (Field RUM 수집)

**언제**: 자체 사이트의 상세 field 데이터를 커스텀 분석 시스템으로 모으고 싶을 때.

### 전체 설정

```ts
// lib/vitals.ts
import { onCLS, onFCP, onINP, onLCP, onTTFB } from 'web-vitals';

function sendToAnalytics(metric) {
  const body = JSON.stringify({
    name: metric.name,
    value: metric.value,
    id: metric.id,
    navigationType: metric.navigationType,
    rating: metric.rating,
    page: window.location.pathname,
    // 디버깅용 추가 필드
    attribution: metric.attribution,
  });

  // beacon은 페이지 언로드 시에도 안정적
  if (navigator.sendBeacon) {
    navigator.sendBeacon('/api/vitals', body);
  } else {
    fetch('/api/vitals', { body, method: 'POST', keepalive: true });
  }
}

onCLS(sendToAnalytics);
onFCP(sendToAnalytics);
onINP(sendToAnalytics);
onLCP(sendToAnalytics);
onTTFB(sendToAnalytics);
```

### Next.js App Router 통합

```tsx
// app/layout.tsx — RSC
import { VitalsReporter } from '@/components/VitalsReporter';

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        <VitalsReporter />
        {children}
      </body>
    </html>
  );
}

// components/VitalsReporter.tsx
'use client';
import { useEffect } from 'react';

export function VitalsReporter() {
  useEffect(() => {
    import('web-vitals').then(({ onCLS, onFCP, onINP, onLCP, onTTFB }) => {
      [onCLS, onFCP, onINP, onLCP, onTTFB].forEach(fn => fn(sendToAnalytics));
    });
  }, []);
  return null;
}
```

### Next.js `useReportWebVitals` (간편)

```tsx
// app/vitals-provider.tsx
'use client';
import { useReportWebVitals } from 'next/web-vitals';

export function VitalsProvider() {
  useReportWebVitals((metric) => {
    // metric.name: 'LCP' | 'INP' | 'CLS' | 'FCP' | 'TTFB' | 'Next.js-*'
    navigator.sendBeacon('/api/vitals', JSON.stringify(metric));
  });
  return null;
}
```

### Attribution (원인 디버깅 정보 포함)

`web-vitals/attribution` import로 상세 정보 함께 수집:

```ts
import { onLCP } from 'web-vitals/attribution';

onLCP(({ value, attribution }) => {
  console.log({
    lcp: value,
    element: attribution.element,            // LCP 요소 selector
    url: attribution.url,                    // LCP 리소스 URL
    timeToFirstByte: attribution.timeToFirstByte,
    resourceLoadDelay: attribution.resourceLoadDelay,
    resourceLoadTime: attribution.resourceLoadTime,
    elementRenderDelay: attribution.elementRenderDelay,
  });
});
```

---

## 7. WebPageTest

**언제**: 다양한 지역·네트워크 조건에서의 상세 측정이 필요할 때.

### 특징
- 글로벌 테스트 서버 (서울·도쿄·북미·유럽)
- 네트워크 프로파일 세밀 제어
- 영상 녹화 + **Filmstrip** 시각화
- 비교 기능 (before/after, 경쟁사)

URL: https://www.webpagetest.org/

---

## 도구 선택 가이드

| 상황 | 추천 도구 |
|---|---|
| "이 페이지 느린 원인이 뭐지?" | Chrome DevTools Performance |
| "전반적 성능 점수" | Lighthouse / PSI |
| "실제 사용자 경험" | PSI Field + GSC + CrUX |
| "회귀 방지 CI" | Lighthouse CI + budget |
| "상세 RUM 분석" | web-vitals.js → GA4 / 자체 백엔드 |
| "지역별 영향" | WebPageTest |
| "상호작용 INP 디버깅" | DevTools Performance Interactions 레인 |
| "경쟁사 비교" | CrUX via PSI / BigQuery |

---

## 측정 원칙

1. **같은 조건으로 비교** — 네트워크·디바이스·throttling 동일하게
2. **3회 이상 평균** — lab 측정은 변동 큼
3. **Lab → Field 순서** — 원인 진단 lab, 최종 판단 field
4. **배포 후 28일** — field 데이터는 28일 이동 평균이므로 즉시 반영 안 됨
5. **p75 중심** — 평균값은 의미 없음. "상위 25% 사용자가 어떤지"가 기준
6. **Production URL 측정** — 로컬·스테이징은 네트워크·서버 환경이 달라 의미 제한
7. **캐시 고려** — 첫 방문(cold) vs 재방문(warm) 분리 측정
