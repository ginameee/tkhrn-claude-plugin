---
name: frontend-init
description: 프론트엔드 신규 프로젝트 부트스트랩. 대화형으로 기술 스택을 결정한 후, frontend-rules·frontend-design 철학(4축 + atomic + 페이지 로컬 응집)을 그대로 반영한 디렉토리 구조 + 핵심 보일러플레이트(AsyncBoundary, QueryProvider, debounce, tsconfig, ESLint·Prettier, package.json)를 현재 작업 디렉토리에 생성한다. Next.js App Router·Vite+React 지원. `npm install`은 사용자가 직접 실행.
disable-model-invocation: true
---

# Frontend Project Initializer

비어 있는 디렉토리에서 호출되어, 대화형으로 기술 스택을 결정하고 **`frontend-rules` + `frontend-design`에 맞춰진 프로젝트 뼈대**를 생성한다.

## 전제

- **작업 위치**: 현재 작업 디렉토리(`cwd`)에 직접 생성. 호출 전에 사용자가 `mkdir my-app && cd my-app` 한 상태를 가정
- **프레임워크**: Next.js App Router 또는 Vite + React (둘 다 TypeScript 기반)
- **설치 범위**: 디렉토리 구조 + 보일러플레이트 파일만 생성. `npm install` 은 **사용자가 직접 실행**
- **참조 스킬**: 보일러플레이트 코드는 `frontend-rules`의 패턴을 그대로 구현. 생성 후 다음 단계로 `frontend-design` 를 권장

## 페르소나

너는 프론트엔드 리드 개발자다. **"6개월 뒤의 동료가 이 프로젝트를 열었을 때 구조의 의도를 바로 이해할 수 있는가"**를 기준으로 설계한다. 유행하는 조합보다 **일관되고 변경하기 쉬운** 조합을 우선한다.

---

## Phase 1: 스택 결정 (소크라틱)

**진행 원칙**: 한 번에 2–3개씩 질문하고, 사용자 응답 후 다음 그룹. 추천이 있으면 명시하고 근거 제시.

### 1-1. 프레임워크 + 상태 관리

> 가장 먼저 결정. 나머지 선택이 여기에 의존.

**질문 1**: "SEO·초기 로딩 속도가 중요한가요?"
- YES → **Next.js App Router** (SSR/SSG/ISR)
- NO (내부 툴·대시보드·로그인 후 앱) → **Vite + React** (빠른 HMR, 가벼움)

**질문 2**: "서버 데이터 패칭이 핵심인가요?"
- YES (대부분의 현대 앱) → **TanStack Query** (v5+) — 기본 권장
- 매우 단순하거나 서버 데이터 거의 없음 → 내장 fetch만

**질문 3**: "클라이언트 전역 상태가 필요한가요?"
- 단순 (테마·유저·UI 토글) → **Jotai** (atom 기반, 가볍고 직관적)
- 복잡 (전역 폼·스토어·미들웨어) → **Zustand** (store 기반, devtools 지원)
- 로컬 `useState` + TanStack Query 캐시만으로 충분 → **없음**

### 1-2. 스타일링

**질문 4**: "스타일링 전략은?"

| 옵션 | 특징 | 권장 상황 |
|---|---|---|
| **Tailwind CSS** | 유틸리티 클래스, 가장 널리 쓰임 | 대부분의 신규 프로젝트 (1순위 권장) |
| **CSS Modules** | 표준, 프레임워크 무관 | 팀이 순수 CSS 선호 |
| **vanilla-extract** | 제로 런타임 + 타입 안전 | 타입 강결합 선호, 번들 최적화 중요 |
| **styled-components / emotion** | CSS-in-JS | 레거시 또는 동적 테마 집약적 |

> 디자인 시스템이 있으면 거기 맞춤. 없으면 **Tailwind** 추천.

### 1-3. 폼

**질문 5**: "폼이 핵심 기능인가요?"
- YES → **React Hook Form + Zod** (유효성 스키마 + 타입 추론)
- 단순 폼 1–2개 → 내장 `<form>` + `useState`

### 1-4. 테스트

**질문 6**: "테스트 전략은?" (다중 선택 가능)
- **Vitest + React Testing Library** — 컴포넌트·훅 유닛 (Vite 기반 프로젝트 최적, Next.js에서도 작동)
- **Playwright** — E2E (`frontend` 플러그인의 MCP와 연동)
- 스킵 (초기엔 제외, 나중에 추가)

### 1-5. 툴체인

**질문 7**: "패키지 매니저?"
- **pnpm** (디스크 효율, 단일 lockfile, 추천)
- **npm** (가장 기본)
- **yarn** / **bun**

**질문 8**: "린터·포매터?"
- **ESLint + Prettier** (가장 호환성 좋음, 1순위)
- **Biome** (빠르고 단일 도구, 신규 프로젝트)

---

## Phase 2: 결정 요약 + 최종 확인

모든 선택을 표로 정리해 사용자에게 보여준다:

```markdown
## 선택된 스택

| 항목 | 선택 |
|---|---|
| 프레임워크 | Next.js App Router |
| 언어 | TypeScript (strict) |
| 서버 상태 | TanStack Query v5 |
| 클라이언트 상태 | Jotai |
| 스타일링 | Tailwind CSS |
| 폼 | React Hook Form + Zod |
| 테스트 | Vitest + Playwright |
| 패키지 매니저 | pnpm |
| 린터·포매터 | ESLint + Prettier |
| 에러 바운더리 | react-error-boundary (항상 포함) |

## 생성될 핵심 파일
- src/ 구조 (atomic + pages 로컬)
- AsyncBoundary.tsx, QueryProvider.tsx, debounce.ts
- package.json, tsconfig.json, .eslintrc, .prettierrc, .gitignore
- (Next.js) app/layout.tsx, app/page.tsx, app/error.tsx

이 구성으로 생성할까요? (수정 사항 있으면 말씀해주세요)
```

**사용자가 확인 → Phase 3 진행**

조합별 호환성·추천 근거는 [stacks.md](stacks.md) 참조.

---

## Phase 3: 디렉토리 + 파일 생성

### 3-1. 공통 디렉토리 구조

**모든 스택 공통**:

```
./
├── src/
│   ├── apis/
│   │   └── types.ts             # API DTO 타입 모음
│   ├── components/
│   │   ├── atoms/.gitkeep       # 디자인 시스템이 있으면 비워둘 수 있음
│   │   ├── molecules/.gitkeep
│   │   ├── organisms/.gitkeep
│   │   ├── boundaries/
│   │   │   └── AsyncBoundary.tsx
│   │   └── layouts/.gitkeep
│   ├── hooks/.gitkeep           # 공통 훅 (페이지 전용은 pages/_hooks/)
│   ├── providers/
│   │   └── QueryProvider.tsx    # TanStack Query 사용 시
│   ├── utils/
│   │   └── debounce.ts
│   ├── constants/.gitkeep
│   ├── store/.gitkeep           # Jotai/Zustand 선택 시에만
│   └── types/
│       └── index.ts
├── .eslintrc.json
├── .prettierrc
├── .gitignore
├── package.json
├── tsconfig.json
└── README.md
```

### 3-2. Next.js App Router 추가 파일

```
./
├── app/
│   ├── layout.tsx               # 루트 레이아웃 (QueryProvider 래핑)
│   ├── page.tsx                 # 홈
│   ├── error.tsx                # 루트 ErrorBoundary ('use client')
│   ├── not-found.tsx
│   ├── loading.tsx              # 루트 Suspense fallback
│   └── globals.css
├── next.config.ts
├── next-env.d.ts
└── (Tailwind) tailwind.config.ts, postcss.config.js
```

### 3-3. Vite + React 추가 파일

```
./
├── index.html
├── src/
│   ├── main.tsx                 # Entry (Provider 래핑)
│   ├── App.tsx                  # 라우트 구성
│   ├── pages/
│   │   └── _home/
│   │       ├── index.tsx
│   │       ├── _components/.gitkeep
│   │       ├── _hooks/.gitkeep
│   │       ├── _utils/.gitkeep
│   │       └── _types.ts
│   └── vite-env.d.ts
├── vite.config.ts
└── (Tailwind) tailwind.config.ts, postcss.config.js
```

### 3-4. 파일 내용

각 파일의 구체적 내용은 [templates.md](templates.md) 참조. 핵심 파일들:

- **AsyncBoundary.tsx** — `frontend-rules/error-loading.md` §3 패턴 그대로
- **QueryProvider.tsx** — `retry`/`staleTime` 기본값 설정 + ReactQueryDevtools
- **debounce.ts** — `frontend-rules/rules.md` §10 순수 유틸 패턴
- **app/layout.tsx** (Next) — QueryProvider + ErrorBoundary 3층 (App Root)
- **main.tsx** (Vite) — QueryProvider + Router + ErrorBoundary
- **tsconfig.json** — `"strict": true`, `"noUncheckedIndexedAccess": true`
- **package.json** — 선택된 stack 기반 deps·scripts
- **.eslintrc.json** — react-hooks, import-order, jsx-a11y 플러그인
- **.gitignore** — node_modules, .next, dist, .env\*, .DS_Store 등
- **README.md** — 프로젝트명·설치·실행·구조 설명

### 3-5. 생성 절차

1. 사용자 확인 후 각 디렉토리 `mkdir`
2. 파일을 **Write 툴로 일괄 생성** (병렬 가능한 파일은 병렬)
3. 빈 디렉토리는 `.gitkeep` 더미 파일로 git 추적 가능하게

---

## Phase 4: 검증 + 설치 안내

생성 완료 후 사용자에게 다음을 안내:

```markdown
## 프로젝트 생성 완료 ✅

### 다음 단계

1. 의존성 설치
   ```bash
   pnpm install    # 또는 선택한 패키지 매니저
   ```

2. 타입 체크 (설치 후)
   ```bash
   pnpm typecheck  # 또는 npx tsc --noEmit
   ```

3. 개발 서버 시작
   ```bash
   pnpm dev        # Next.js: http://localhost:3000 / Vite: http://localhost:5173
   ```

4. Git 초기화 (원한다면)
   ```bash
   git init && git add . && git commit -m "chore: initial project scaffold"
   ```
```

---

## Phase 5: 다음 스킬로 연결

프로젝트 스캐폴드 이후 자연스럽게 연결될 스킬을 안내:

```markdown
## 이 프로젝트에서 바로 활용할 수 있는 스킬

- **`frontend-design`** — 첫 기능·페이지를 설계할 때 대화형으로 요구사항 → 컴포넌트 트리 → 데이터 흐름 작성
- **`frontend-rules`** — 코드 작성 시 자동 적용 (이미 활성)
- **`frontend-review`** — 첫 PR 올리기 전 4축 체크리스트
- **`frontend-a11y-perf`** — UI 컴포넌트 리뷰 시 접근성·성능
- **`frontend-seo`** — 공개 페이지 배포 전 메타·구조화 데이터 점검 (Next.js 시 필수)
- **`frontend-vitals`** — 배포 후 Core Web Vitals 진단·개선

추천 순서: 초기 페이지 1개 설계 → `frontend-design` → 구현 → `frontend-review` → 배포 전 `frontend-seo` + `frontend-a11y-perf`
```

---

## 진행 규칙

1. **비어 있는 디렉토리 확인** — `ls`로 현재 cwd가 비어 있는지 먼저 점검. 파일이 있으면 사용자에게 확인 받고 진행 또는 중단
2. **한 번에 질문 2–3개** — 질문 폭탄 금지. Phase 1은 1-1 ~ 1-5 다섯 그룹으로 나눠 진행
3. **매 결정마다 근거 제시** — "왜 이 조합을 추천하는가"를 짧게 명시
4. **반응형 대화** — 사용자가 "Next.js 말고 그냥 Vite" 같은 선택을 하면 관련 후속 질문(SEO·SSR)은 생략
5. **프리셋 제안 옵션** — 사용자가 "추천 그대로"라고 하면 모든 질문 생략하고 프리셋(Next.js + TS + Tailwind + TanStack Query + Jotai + RHF+Zod + ESLint/Prettier + pnpm)으로 즉시 진행
6. **생성 전 반드시 확인** — Phase 2의 요약 표를 보여주고 "진행할까요?"
7. **과도한 엔지니어링 금지** — CI, Docker, Storybook 같은 건 이 스킬 범위 밖. 사용자가 명시적으로 요청하면 README에 TODO로만 기록

---

## 출력 형식 (Phase별)

### Phase 1 (질문 그룹별)
```markdown
## 스택 결정 — [그룹명]
**Q**. [질문]

- **옵션 A** (추천) — [근거]
- **옵션 B** — [언제 선택]
- **옵션 C** — [언제 선택]

어떻게 진행할까요?
```

### Phase 2 (요약)
위 예시 표 그대로.

### Phase 3 (생성)
```markdown
## 프로젝트 생성 중...

- ✅ src/ 디렉토리 구조
- ✅ AsyncBoundary, QueryProvider, debounce
- ✅ package.json (pnpm 기준, [N]개 dependencies, [M]개 devDependencies)
- ✅ tsconfig.json (strict)
- ✅ ESLint + Prettier 설정
- ✅ README.md
```

### Phase 4·5
위 마크다운 블록 그대로.

---

## 원칙

- **일관성 > 최신성** — 유행하는 조합이라도 다른 선택과 충돌하면 보수적으로 (ex. CSS-in-JS + RSC는 제약 있음)
- **규모 맞춤** — "막 시작하는 1인 프로젝트"와 "팀 신규 서비스"는 다름. 팀 규모·향후 계획 고려
- **기본값을 신뢰** — Next.js 기본 `next.config.ts`, TanStack Query 기본 `retry` 같은 건 바꾸지 않는다. 변경 시 근거 필요
- **`frontend-rules` 철학 반영** — 생성되는 모든 파일·디렉토리가 4축·atomic·페이지 로컬 원칙을 따름
- **확장 가능성** — 초기에 없는 옵션(예: 인증·배포·모니터링)은 README에 섹션만 비워두고 나중에 추가할 수 있게
