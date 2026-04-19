# 보일러플레이트 템플릿

`frontend-init` Phase 3에서 생성할 파일들의 실제 내용. 사용자 선택에 따라 조건부로 포함·제외.

> 모든 코드는 `frontend-rules` 철학을 반영한다. 규칙이 바뀌면 이 템플릿도 함께 갱신.

---

## 공통 파일

### `.gitignore`

```gitignore
# Dependencies
node_modules/

# Build output
dist/
build/
.next/
out/

# Env
.env
.env.local
.env.*.local

# Logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*

# Editor
.idea/
.vscode/
*.swp
.DS_Store

# Test
coverage/
.vitest-cache/
playwright-report/
test-results/

# Turbo / TS cache
.turbo/
*.tsbuildinfo
```

### `README.md`

```markdown
# {projectName}

{shortDescription}

## 기술 스택

- Framework: {framework}
- Language: TypeScript (strict)
- Server State: TanStack Query v5
- Client State: {clientState}
- Styling: {styling}
- Form: {form}
- Testing: {testing}
- Package Manager: {packageManager}

## 구조

이 프로젝트는 **변경하기 쉬운 코드(4축: 가독성·예측 가능성·응집도·결합도)** 원칙과 **Atomic Design + 페이지 로컬 응집** 구조를 따른다.

\`\`\`
src/
├── apis/          # API 함수 + DTO 타입 (endpoint path 파일명)
├── components/
│   ├── atoms/     # 최소 단위 UI (pure)
│   ├── molecules/ # atoms 조합 (pure)
│   ├── organisms/ # 비즈니스 로직 / 외부 의존 포함
│   ├── boundaries/# AsyncBoundary, ErrorBoundary, *Guard
│   └── layouts/   # composition only
├── hooks/         # 공통 훅 (use{HttpMethod}{Resource} 네이밍)
├── providers/     # Provider 정의
├── utils/         # 순수 유틸 (debounce 등)
├── store/         # 클라이언트 상태
└── constants/
\`\`\`

페이지 전용 코드는 `pages/{pageName}/_components`, `_hooks`, `_utils`, `_types.ts`에 둔다.

## 시작하기

\`\`\`bash
{packageManager} install
{packageManager} dev
\`\`\`

## 스크립트

- `{pm} dev` — 개발 서버
- `{pm} build` — 프로덕션 빌드
- `{pm} lint` — ESLint
- `{pm} typecheck` — TypeScript 체크
- `{pm} test` — 유닛 테스트 (설정 시)

## 개발 원칙

- 모든 `<Suspense>` 는 `<ErrorBoundary>` 와 짝 (→ `<AsyncBoundary>` 사용)
- 데이터 패칭은 비즈니스 훅 경유, 컴포넌트에서 `apis/` 직접 호출 금지
- `useSuspenseQuery` 기본, `useQuery({ suspense: true })` 금지 (v5 폐기)
- `any` 금지, strict 모드
- Props Drilling 2단계 이하
- 페이지 컴포넌트는 조립만 (비즈니스 로직 금지)
```

### `tsconfig.json` (Next.js)

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": false,
    "skipLibCheck": true,
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "forceConsistentCasingInFileNames": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": { "@/*": ["./src/*"] }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
```

### `tsconfig.json` (Vite + React)

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "jsx": "react-jsx",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "forceConsistentCasingInFileNames": true,
    "esModuleInterop": true,
    "isolatedModules": true,
    "resolveJsonModule": true,
    "skipLibCheck": true,
    "noEmit": true,
    "allowImportingTsExtensions": true,
    "paths": { "@/*": ["./src/*"] },
    "useDefineForClassFields": true,
    "types": ["vite/client"]
  },
  "include": ["src"]
}
```

### `.prettierrc`

```json
{
  "semi": true,
  "singleQuote": true,
  "trailingComma": "all",
  "printWidth": 100,
  "tabWidth": 2,
  "arrowParens": "always",
  "endOfLine": "lf"
}
```

### `.eslintrc.json` (Next.js + TypeScript)

```json
{
  "extends": [
    "next/core-web-vitals",
    "plugin:@typescript-eslint/recommended",
    "plugin:jsx-a11y/recommended",
    "prettier"
  ],
  "plugins": ["@typescript-eslint", "jsx-a11y"],
  "rules": {
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/no-unused-vars": ["error", { "argsIgnorePattern": "^_" }],
    "react/jsx-curly-brace-presence": ["error", "never"],
    "no-console": ["warn", { "allow": ["warn", "error"] }]
  }
}
```

### `.eslintrc.json` (Vite + React)

```json
{
  "root": true,
  "env": { "browser": true, "es2022": true },
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:react-hooks/recommended",
    "plugin:jsx-a11y/recommended",
    "prettier"
  ],
  "plugins": ["react-refresh"],
  "rules": {
    "react-refresh/only-export-components": ["warn", { "allowConstantExport": true }],
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/no-unused-vars": ["error", { "argsIgnorePattern": "^_" }],
    "no-console": ["warn", { "allow": ["warn", "error"] }]
  }
}
```

---

## `src/` 공통 보일러플레이트

### `src/components/boundaries/AsyncBoundary.tsx`

> `frontend-rules/error-loading.md` §3 재사용 컴포넌트. 모든 비동기 영역은 이걸로 감싼다.

```tsx
import { QueryErrorResetBoundary } from '@tanstack/react-query';
import { ErrorBoundary, type FallbackProps } from 'react-error-boundary';
import { Suspense, type ReactNode } from 'react';

interface AsyncBoundaryProps {
  children: ReactNode;
  errorFallback?: (props: FallbackProps) => ReactNode;
  loadingFallback?: ReactNode;
  resetKeys?: unknown[];
}

function DefaultErrorFallback({ error, resetErrorBoundary }: FallbackProps) {
  return (
    <div role="alert" className="p-4 border border-red-300 rounded">
      <p>문제가 발생했습니다.</p>
      {process.env.NODE_ENV !== 'production' && <pre className="text-xs mt-2">{error.message}</pre>}
      <button onClick={resetErrorBoundary} className="mt-2 px-3 py-1 border rounded">
        재시도
      </button>
    </div>
  );
}

function DefaultLoadingFallback() {
  return <div aria-busy="true" aria-label="로딩 중" className="p-4">로딩 중…</div>;
}

export function AsyncBoundary({
  children,
  errorFallback,
  loadingFallback = <DefaultLoadingFallback />,
  resetKeys = [],
}: AsyncBoundaryProps) {
  return (
    <QueryErrorResetBoundary>
      {({ reset }) => (
        <ErrorBoundary
          onReset={reset}
          FallbackComponent={errorFallback ? (props) => <>{errorFallback(props)}</> : DefaultErrorFallback}
          resetKeys={resetKeys}
        >
          <Suspense fallback={loadingFallback}>{children}</Suspense>
        </ErrorBoundary>
      )}
    </QueryErrorResetBoundary>
  );
}
```

### `src/providers/QueryProvider.tsx` (TanStack Query)

```tsx
'use client';

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';
import { useState, type ReactNode } from 'react';

export function QueryProvider({ children }: { children: ReactNode }) {
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 60 * 1000, // 1분 기본
            retry: 3,
            retryDelay: (attempt) => Math.min(1000 * 2 ** attempt, 30000),
            refetchOnWindowFocus: false,
          },
          mutations: {
            retry: 0,
          },
        },
      }),
  );

  return (
    <QueryClientProvider client={queryClient}>
      {children}
      {process.env.NODE_ENV === 'development' && <ReactQueryDevtools initialIsOpen={false} />}
    </QueryClientProvider>
  );
}
```

> Vite 버전은 맨 위 `'use client';` 제거.

### `src/utils/debounce.ts`

> `frontend-rules/rules.md` §10 순수 유틸 패턴. 이벤트 핸들러에 적용용.

```ts
export function debounce<T extends (...args: unknown[]) => unknown>(
  fn: T,
  delay: number,
): (...args: Parameters<T>) => void {
  let timer: ReturnType<typeof setTimeout> | null = null;
  return (...args: Parameters<T>) => {
    if (timer) clearTimeout(timer);
    timer = setTimeout(() => fn(...args), delay);
  };
}

export function throttle<T extends (...args: unknown[]) => unknown>(
  fn: T,
  delay: number,
): (...args: Parameters<T>) => void {
  let lastCall = 0;
  let timer: ReturnType<typeof setTimeout> | null = null;
  return (...args: Parameters<T>) => {
    const now = Date.now();
    const elapsed = now - lastCall;
    if (elapsed >= delay) {
      lastCall = now;
      fn(...args);
    } else if (!timer) {
      timer = setTimeout(() => {
        lastCall = Date.now();
        timer = null;
        fn(...args);
      }, delay - elapsed);
    }
  };
}
```

### `src/apis/types.ts`

```ts
/**
 * API DTO 타입 모음 — 서버 스펙 그대로.
 *
 * 훅 레이어 (hooks/) 에서 도메인 타입으로 변환하거나 alias로 re-export한다.
 * 컴포넌트에서 이 파일을 직접 import 하지 않는다.
 */

export type ApiError = {
  message: string;
  code?: string;
  status?: number;
};

// 도메인별 DTO 는 apis/{resource}.ts 각 파일에 co-locate 하거나 여기에 추가
```

### `src/types/index.ts`

```ts
/**
 * 프로젝트 전역에서 쓰이는 공통 도메인 타입 (API DTO 아님).
 */

export type Nullable<T> = T | null;
export type Maybe<T> = T | undefined;
```

---

## Next.js App Router 파일

### `app/layout.tsx`

```tsx
import type { Metadata } from 'next';
import './globals.css';
import { QueryProvider } from '@/providers/QueryProvider';
import { ErrorBoundary } from 'react-error-boundary';

export const metadata: Metadata = {
  title: {
    default: '{projectName}',
    template: '%s | {projectName}',
  },
  description: '{shortDescription}',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ko">
      <body>
        <QueryProvider>{children}</QueryProvider>
      </body>
    </html>
  );
}
```

### `app/page.tsx`

```tsx
export default function HomePage() {
  return (
    <main className="p-8">
      <h1 className="text-2xl font-bold">{projectName}</h1>
      <p className="mt-2 text-gray-600">프로젝트가 생성되었습니다.</p>
    </main>
  );
}
```

### `app/error.tsx`

```tsx
'use client';

import { useEffect } from 'react';

export default function RootError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    // TODO: 에러 로깅 (Sentry 등)
    console.error(error);
  }, [error]);

  return (
    <main role="alert" className="p-8">
      <h2 className="text-xl font-semibold">문제가 발생했습니다</h2>
      <p className="mt-2">페이지를 불러오지 못했습니다.</p>
      <button onClick={reset} className="mt-4 px-4 py-2 border rounded">
        재시도
      </button>
    </main>
  );
}
```

### `app/not-found.tsx`

```tsx
import Link from 'next/link';

export default function NotFound() {
  return (
    <main className="p-8">
      <h2 className="text-xl font-semibold">페이지를 찾을 수 없습니다</h2>
      <Link href="/" className="mt-4 inline-block underline">
        홈으로
      </Link>
    </main>
  );
}
```

### `app/loading.tsx`

```tsx
export default function Loading() {
  return (
    <div aria-busy="true" aria-label="페이지 로딩 중" className="p-8">
      로딩 중…
    </div>
  );
}
```

### `app/globals.css` (Tailwind 사용 시)

```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

### `next.config.ts`

```ts
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  reactStrictMode: true,
  images: {
    // remotePatterns 등 필요 시 추가
  },
};

export default nextConfig;
```

### `tailwind.config.ts` (Next.js)

```ts
import type { Config } from 'tailwindcss';

export default {
  content: ['./app/**/*.{ts,tsx}', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {},
  },
  plugins: [],
} satisfies Config;
```

### `postcss.config.js`

```js
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
```

---

## Vite + React 파일

### `index.html`

```html
<!doctype html>
<html lang="ko">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>{projectName}</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```

### `src/main.tsx`

```tsx
import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import { ErrorBoundary } from 'react-error-boundary';
import { QueryProvider } from './providers/QueryProvider';
import App from './App';
import './index.css';

function RootErrorFallback({ error }: { error: Error }) {
  return (
    <div role="alert" style={{ padding: 24 }}>
      <h1>앱을 시작할 수 없습니다</h1>
      <p>페이지를 새로고침해 주세요.</p>
      {import.meta.env.DEV && <pre>{error.message}</pre>}
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <ErrorBoundary FallbackComponent={RootErrorFallback}>
      <QueryProvider>
        <BrowserRouter>
          <App />
        </BrowserRouter>
      </QueryProvider>
    </ErrorBoundary>
  </React.StrictMode>,
);
```

### `src/App.tsx`

```tsx
import { Routes, Route } from 'react-router-dom';
import { AsyncBoundary } from '@/components/boundaries/AsyncBoundary';
import HomePage from '@/pages/_home';

export default function App() {
  return (
    <AsyncBoundary>
      <Routes>
        <Route path="/" element={<HomePage />} />
      </Routes>
    </AsyncBoundary>
  );
}
```

### `src/pages/_home/index.tsx`

```tsx
export default function HomePage() {
  return (
    <main style={{ padding: 32 }}>
      <h1>{projectName}</h1>
      <p>프로젝트가 생성되었습니다.</p>
    </main>
  );
}
```

### `src/pages/_home/_types.ts`

```ts
// 홈 페이지 전용 타입 + 관련 상수 (as const)
```

### `src/index.css` (Tailwind 사용 시)

```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

### `vite.config.ts`

```ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'node:path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: { '@': path.resolve(__dirname, './src') },
  },
  server: {
    port: 5173,
  },
});
```

### `tailwind.config.ts` (Vite)

```ts
import type { Config } from 'tailwindcss';

export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: { extend: {} },
  plugins: [],
} satisfies Config;
```

---

## `package.json` 조립 가이드

선택 조합에 따라 조립. 예시는 **Next.js + Tailwind + TanStack Query + Jotai + RHF+Zod + Vitest + ESLint/Prettier + pnpm** 기준.

```json
{
  "name": "{projectName}",
  "version": "0.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "eslint . --ext .ts,.tsx",
    "typecheck": "tsc --noEmit",
    "format": "prettier --write .",
    "test": "vitest"
  },
  "dependencies": {
    "next": "^15.0.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "@tanstack/react-query": "^5.59.0",
    "@tanstack/react-query-devtools": "^5.59.0",
    "react-error-boundary": "^4.1.0",
    "jotai": "^2.10.0",
    "react-hook-form": "^7.53.0",
    "@hookform/resolvers": "^3.9.0",
    "zod": "^3.23.0"
  },
  "devDependencies": {
    "typescript": "^5.6.0",
    "@types/node": "^22.0.0",
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0",
    "eslint": "^9.0.0",
    "eslint-config-next": "^15.0.0",
    "eslint-config-prettier": "^9.1.0",
    "eslint-plugin-jsx-a11y": "^6.10.0",
    "@typescript-eslint/eslint-plugin": "^8.0.0",
    "@typescript-eslint/parser": "^8.0.0",
    "prettier": "^3.3.0",
    "tailwindcss": "^3.4.0",
    "postcss": "^8.4.0",
    "autoprefixer": "^10.4.0",
    "vitest": "^2.0.0",
    "@testing-library/react": "^16.0.0",
    "@testing-library/jest-dom": "^6.5.0",
    "jsdom": "^25.0.0"
  }
}
```

### Vite 기반 `scripts` 차이

```json
"scripts": {
  "dev": "vite",
  "build": "tsc && vite build",
  "preview": "vite preview",
  "lint": "eslint . --ext .ts,.tsx",
  "typecheck": "tsc --noEmit",
  "format": "prettier --write .",
  "test": "vitest"
}
```

### Vite 기반 `dependencies` 차이

```json
"dependencies": {
  "react": "^18.3.0",
  "react-dom": "^18.3.0",
  "react-router-dom": "^6.27.0",
  "@tanstack/react-query": "^5.59.0",
  "@tanstack/react-query-devtools": "^5.59.0",
  "react-error-boundary": "^4.1.0",
  // ... 나머지 동일
},
"devDependencies": {
  "vite": "^5.4.0",
  "@vitejs/plugin-react": "^4.3.0",
  "typescript": "^5.6.0",
  // ... ESLint·Prettier·Tailwind 동일
  "eslint-plugin-react-hooks": "^5.0.0",
  "eslint-plugin-react-refresh": "^0.4.0"
}
```

> 버전은 템플릿 작성 시점 기준. 생성 시 `latest` 태그로 받아도 되고, 구체 버전 고정도 가능.

### 조건부 포함 규칙

| 선택 | 추가 deps |
|---|---|
| 클라 상태 = Jotai | `jotai` |
| 클라 상태 = Zustand | `zustand` |
| 스타일 = styled-components | `styled-components` + `@types/styled-components` |
| 스타일 = emotion | `@emotion/react` `@emotion/styled` |
| 스타일 = vanilla-extract | `@vanilla-extract/css` `@vanilla-extract/vite-plugin` (or next plugin) |
| 폼 | `react-hook-form` `@hookform/resolvers` `zod` |
| 테스트 = Vitest | `vitest` `@testing-library/react` `@testing-library/jest-dom` `jsdom` |
| 테스트 = Playwright | `@playwright/test` + `playwright.config.ts` |
| 린터 = Biome | `@biomejs/biome` (ESLint·Prettier 제거) |
| 패키지 매니저 = pnpm | `packageManager: "pnpm@9.x"` 필드 추가 |
