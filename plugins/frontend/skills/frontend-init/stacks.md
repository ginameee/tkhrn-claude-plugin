# 기술 스택 조합 레퍼런스

`frontend-init` 의 Phase 1에서 사용자와 결정할 선택지의 **근거·호환성·권장 조합** 정리.

## 추천 프리셋

사용자가 "추천대로 가줘"라고 할 때 바로 적용할 조합.

### 프리셋 A: Next.js 풀스택 (공개 웹 서비스)

| 항목 | 선택 | 근거 |
|---|---|---|
| 프레임워크 | Next.js 15 App Router | RSC + SSR/SSG/ISR, SEO 우수 |
| 언어 | TypeScript strict | `any` 금지 원칙과 일치 |
| 서버 상태 | TanStack Query v5 | 캐시·재시도·signal 자동 처리 |
| 클라 상태 | Jotai | 가볍고 atom 단위 세밀 구독 |
| 스타일링 | Tailwind CSS | RSC 호환, 가장 널리 쓰임 |
| 폼 | React Hook Form + Zod | 스키마 기반 타입 추론 |
| 에러 바운더리 | react-error-boundary | 공식 패턴, 훅 지원 |
| 테스트 | Vitest + Playwright | 유닛 + E2E |
| 린터·포매터 | ESLint + Prettier | 가장 호환성 좋음 |
| 패키지 매니저 | pnpm | 디스크 효율 + monorepo 친화 |

### 프리셋 B: Vite SPA (내부 툴 / 로그인 후 앱)

| 항목 | 선택 | 근거 |
|---|---|---|
| 프레임워크 | Vite 5 + React 18 | 빠른 HMR, SEO 불필요 |
| 라우터 | React Router v6 | 가장 표준 |
| 서버 상태 | TanStack Query v5 | 동일 |
| 클라 상태 | Jotai | 동일 |
| 스타일링 | Tailwind CSS | 동일 |
| 폼 | React Hook Form + Zod | 동일 |
| 에러 바운더리 | react-error-boundary | 동일 |
| 테스트 | Vitest + Playwright | Vite와 자연스러운 조합 |
| 린터·포매터 | ESLint + Prettier | 동일 |
| 패키지 매니저 | pnpm | 동일 |

---

## 결정 가이드

### 프레임워크: Next.js App Router vs Vite + React

| 기준 | Next.js | Vite + React |
|---|---|---|
| 초기 로딩 속도 | ⭐⭐⭐⭐⭐ (SSR/SSG) | ⭐⭐⭐ (CSR) |
| SEO | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| 개발 서버 HMR | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| 러닝 커브 | 높음 (RSC·Router 규칙) | 낮음 |
| 번들 크기 | 프레임워크 런타임 포함 | 가벼움 |
| 배포 | Vercel / Node 서버 필요 | 정적 호스팅 가능 |

**선택 기준**:
- 공개 웹 서비스·블로그·커머스·마케팅 페이지 → **Next.js**
- 로그인 후에만 접근하는 대시보드·어드민·내부 툴 → **Vite**
- 애매하면 **Next.js** (SSR 안 써도 Vite보다 제공하는 규약이 많음)

---

### 서버 상태: TanStack Query vs 내장 fetch만

| 기준 | TanStack Query | 내장 fetch + useState |
|---|---|---|
| 캐시·중복 제거 | ✅ 자동 | ❌ 수동 |
| 재시도·백오프 | ✅ 기본 | ❌ 수동 |
| `signal` 자동 abort | ✅ | ❌ |
| 무효화·낙관적 업데이트 | ✅ | ❌ |
| 번들 추가 | ~13KB | 0 |

**선택 기준**:
- 데이터 패칭이 있으면 **무조건 TanStack Query** (수동 구현은 거의 항상 버그로 이어짐)
- 서버 데이터가 거의 없는 순수 인터랙션 앱만 예외

---

### 클라이언트 상태: Jotai vs Zustand vs 없음

| 기준 | Jotai | Zustand | 없음 (useState + Context) |
|---|---|---|---|
| 모델 | atom (값 단위) | store (객체) | 컴포넌트 스코프 |
| 세밀한 구독 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| DevTools | 지원 | 지원 (Redux DevTools) | ❌ |
| 러닝 커브 | 낮음 | 낮음 | 없음 |
| 번들 | ~3KB | ~1KB | 0 |
| 미들웨어 | 일부 | 풍부 (persist, devtools, immer) | 없음 |

**선택 기준**:
- 전역 상태 대부분이 "테마·유저·사이드바 열림/닫힘" 수준 → **Jotai**
- 복잡한 도메인 스토어 (폼 마법사, 실시간 알림 큐 등) → **Zustand**
- **원칙**: 서버 데이터는 TanStack Query 캐시, UI 상태는 로컬 `useState` 를 우선. 전역 상태 없이 갈 수 있으면 가는 게 최고. 필요할 때만 추가.

---

### 스타일링

| 방식 | RSC 호환 | 번들 | 러닝 커브 | 비고 |
|---|---|---|---|---|
| **Tailwind CSS** | ✅ | 작음 (purge) | 중 (유틸리티 암기) | 1순위 권장 |
| **CSS Modules** | ✅ | 작음 | 낮음 | 표준, 프레임워크 무관 |
| **vanilla-extract** | ✅ | 매우 작음 | 중 (빌드 설정) | 타입 안전 선호 시 |
| **styled-components** | ⚠️ | 중 | 낮음 | RSC에서 제약 (클라이언트 컴포넌트만) |
| **emotion** | ⚠️ | 중 | 낮음 | 동일 제약 |
| **PandaCSS** | ✅ | 작음 | 중 | 신생, 확장 중 |

**RSC 제약 주의**: Next.js App Router + CSS-in-JS 런타임(styled-components·emotion)은 서버 컴포넌트에서 직접 못 씀. 반드시 `'use client'` 분리.

**기본 추천**: **Tailwind** — 생태계·학습 자료·성능 모두 균형.

---

### 폼: RHF + Zod vs 기본

| 규모 | 추천 |
|---|---|
| 로그인·검색 폼 1–2개 | 기본 `<form>` + `useState` + 인라인 validate |
| 회원가입·상품 등록 등 3+ 필드 | **React Hook Form + Zod** |
| 멀티스텝 위저드 | **RHF + Zod** 필수 |

**Zod의 가치**:
- 스키마 하나로 런타임 검증 + TypeScript 타입 추론 (`z.infer`)
- 서버 응답 검증 재활용 가능
- DTO → 도메인 타입 변환에도 활용 가능 (`frontend-rules/rules.md`)

---

### 테스트

| 도구 | 용도 | 속도 |
|---|---|---|
| **Vitest + React Testing Library** | 컴포넌트·훅·유틸 유닛 | 빠름 |
| **Playwright** | E2E·시각 회귀 | 중 |
| Jest + RTL | Vitest 호환, Next 공식 가이드 | 중 (Vitest보다 느림) |

**권장**:
- Vite 기반 프로젝트 → **Vitest** (빌드 환경 공유)
- Next.js → **Vitest** (공식 가이드 있음) 또는 Jest — Vitest가 더 빠름
- E2E 필요 시 → **Playwright** 추가 (`frontend` 플러그인의 MCP가 바로 연동됨)

**초기엔 E2E 스킵 가능** — 핵심 플로우가 정착되고 나서 도입.

---

### 린터·포매터: ESLint + Prettier vs Biome

| 항목 | ESLint + Prettier | Biome |
|---|---|---|
| 속도 | 보통 | 10–100배 빠름 (Rust) |
| 생태계 | 압도적 (플러그인 수천 개) | 아직 제한적 |
| 프레임워크 지원 | 모두 대응 (eslint-plugin-next, jsx-a11y 등) | Next 제한 있음 |
| 설정 복잡도 | 높음 | 낮음 |
| IDE 지원 | 성숙 | 성숙 |

**권장**:
- 처음 시작 + 확장성 중시 → **ESLint + Prettier** (1순위)
- 팀이 성능·단순성 우선 + Biome 생태계 수용 가능 → **Biome**

---

### 패키지 매니저

| 매니저 | 특징 |
|---|---|
| **pnpm** | 심볼릭 링크로 디스크 절약, 단일 lockfile, 빠름 (1순위) |
| **npm** | 기본, 가장 호환성 좋음 |
| **yarn** (Classic) | npm 대안, 레거시 프로젝트 많음 |
| **yarn berry** (PnP) | 빠르지만 도구 호환성 낮음 (주의) |
| **bun** | 초고속, 새 프로젝트에 적합 (성숙 중) |

**권장**: **pnpm** (대부분의 신규 프로젝트). npm도 무난.

---

## 호환성 주의점

### Next.js App Router + CSS-in-JS 런타임

- styled-components·emotion은 서버 컴포넌트에서 **직접 사용 불가**
- 해결: 스타일 사용처를 `'use client'` 로 분리, 또는 Tailwind·CSS Modules 선택

### TanStack Query + RSC

- 서버 컴포넌트에서 직접 쓰지 않음. 클라이언트 컴포넌트에서만.
- 서버에서 초기 데이터 prefetch → 클라이언트에서 Hydration 패턴 권장 (공식 가이드)

### React 18+ Suspense + ErrorBoundary

- Suspense는 `react-error-boundary` 와 **반드시 짝**. 단독 사용 금지 (`frontend-rules/error-loading.md` §2.1)

### Strict Mode

- `tsconfig.json` 의 `"strict": true` 는 **기본**으로 켠다
- `"noUncheckedIndexedAccess": true` 도 추가 권장 (배열/객체 접근 시 undefined 체크 강제)

---

## 선택 영향도 매트릭스

| 선택 | 영향받는 파일 |
|---|---|
| 프레임워크 | `package.json`, 엔트리 구조 (`app/` vs `main.tsx`), `next.config.ts` vs `vite.config.ts` |
| TanStack Query | `QueryProvider.tsx`, `package.json`, 루트 레이아웃 |
| 클라 상태 라이브러리 | `src/store/`, `package.json` |
| Tailwind | `tailwind.config.ts`, `postcss.config.js`, `globals.css` |
| RHF + Zod | `package.json` (type 추가) |
| 테스트 | `vitest.config.ts` / `playwright.config.ts`, `package.json` scripts |
| ESLint vs Biome | `.eslintrc.json` vs `biome.json`, `package.json` scripts |
