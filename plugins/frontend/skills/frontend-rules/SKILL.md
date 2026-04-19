---
name: frontend-rules
description: React 프론트엔드 에러 처리(ErrorBoundary, Suspense), 로딩 상태, 디렉터리 구조, 코드 규칙. 프론트엔드 컴포넌트 작성, React 코드 작업, UI 구현, 코드 리뷰 시 자동 적용.
---

# 프론트엔드 개발 규칙

이 skill은 React 기반 프론트엔드 개발 시 적용되는 핵심 규칙을 제공한다.

## 핵심 원칙

**변경하기 쉬운 코드**를 작성한다. 이를 위해 네 가지 축을 항상 고려한다:

| 축 | 판단 기준 |
|---|---|
| **가독성** | 처음 보는 동료가 빠르게 의도를 파악할 수 있는가 |
| **예측 가능성** | 이름/파라미터/리턴만 보고 동작을 예측할 수 있는가 |
| **응집도** | 함께 변경되는 코드가 함께 모여 있는가 |
| **결합도** | 하나를 변경할 때 관련 없는 곳까지 수정해야 하는가 |

## 에러/로딩 처리 핵심 규칙

- `react-error-boundary` 사용 (커스텀 클래스 금지)
- 3단계 ErrorBoundary: App Root → Route/Page → Feature/Widget
- 모든 `<Suspense>`는 반드시 `<ErrorBoundary>`와 쌍으로
- `useSuspenseQuery` 사용 (v5 기준, `useQuery`의 `suspense: true` 폐기됨)
- `QueryErrorResetBoundary` + `ErrorBoundary` + `Suspense`를 감싼 `AsyncBoundary` 재사용 컴포넌트 필수
- 스켈레톤은 실제 콘텐츠 크기에 맞출 것 (레이아웃 시프트 방지)
- 낙관적 업데이트 시 반드시 `onError` 롤백 + `onSettled` 서버 동기화

## 데이터 패칭 핵심 규칙

- debounce/throttle은 `utils/` 하위에 순수 함수로 작성. React 훅으로 만들지 않는다
- debounce는 fetch 자체가 아닌, fetch를 발생시키는 **이벤트 핸들러**에 적용한다
- **API 호출은 반드시 훅 레이어를 경유**한다. 컴포넌트에서 `apis/` 직접 호출 금지
- 훅 이름은 `use{HttpMethod}{Resource}` 패턴 (`useGetProducts`, `useCreateProduct`)
- 훅 레이어의 책임: react-query 사용 + 캐시 전략 + DTO → 도메인 타입 파싱
- **DTO vs 도메인 타입 분리**: `apis/`는 `ProductDTO` export, 훅은 `Product` export. 동일해도 alias로 re-export 필수
- **TanStack Query 사용 시**: `queryFn`의 `signal`을 fetch에 전달만 하면 됨. AbortController 생성/abort는 자동 처리
- **직접 fetch 시**: `abortRef = useRef<AbortController | null>(null)` 패턴으로 관리. 새 요청 전 이전 요청 abort
- `AbortError`는 정상 취소이므로 에러로 처리하지 않는다

## 디렉터리 구조 핵심 규칙

- **컴포넌트 카테고리**:
  - `atoms/` — 최소 단위, pure (디자인시스템이 있으면 비워둘 수 있음)
  - `molecules/` — atoms 조합, pure
  - `organisms/` — 비즈니스 로직 / 외부 lib 의존 / 사이드이펙트 위험
  - `boundaries/` — 경계·가드·래퍼 (AsyncBoundary, ErrorBoundary, *Guard). children 제어용
  - `layouts/` — composition only
- **pure 경계**: atoms, molecules는 반드시 pure. 외부 의존이 생기면 organism으로 이동
- **페이지 로컬 우선**: 페이지 전용 코드는 `pages/{pageName}/` 아래 `_components/`, `_hooks/`, `_utils/`, `_types.ts`에 위치
- **_ prefix 목적**: 스코프 표시 + Next.js private folder + 응집도 향상
- **승격 규칙**: 2곳 이상에서 사용되면 루트 공통(`hooks/`, `components/`, `utils/`)으로 승격
- **API 구조**: `src/apis/`에 endpoint path를 파일명으로 (예: `stations.ts`). 같은 path의 GET/POST는 한 파일에
- **상수 co-location**: 페이지 전용 상수는 `_types.ts`에 `as const`로 타입과 함께 선언
- **Provider**: `src/providers/`에 별도 위치 (UI가 아닌 인프라)

## 코드 작성 핵심 규칙

- 페이지는 조립만 (로직/API 호출 금지)
- 단일 책임 원칙, God Component(300줄+) 금지
- Props Drilling 2단계 이하
- `any` 타입 금지, strict 모드 필수
- 성급한 추상화 금지 (중복이 잘못된 추상화보다 낫다)
- 서버 상태(TanStack Query) / 클라이언트 상태(Jotai/Zustand) 분리

## 상세 규칙 참조

- 에러 처리, 로딩 상태, Suspense 패턴 상세: [error-loading.md](error-loading.md)
- 프론트엔드 코드 규칙, 디렉터리 구조, 리팩토링 체크리스트: [rules.md](rules.md)
