# 프론트엔드 에러 처리 & 로딩 상태 룰셋

React 기반 프론트엔드 개발 시 에러 처리, 로딩 상태, ErrorBoundary, Suspense 패턴에 대한 코딩 에이전트 규칙.

---

## 1. ErrorBoundary 규칙

### 1.1 라이브러리 선택
- `react-error-boundary` 라이브러리(v4+)를 사용할 것. 커스텀 클래스 기반 ErrorBoundary는 사용하지 않는다.
- 라이브러리가 지원하지 못하는 매우 특수한 동작이 필요한 경우에만 클래스 기반을 허용한다.

### 1.2 바운더리 세분화 (3단계 전략)

```
App Root Boundary        -> 치명적 오류 대응 ("앱이 고장났습니다, 새로고침하세요")
  Route/Page Boundary    -> 페이지 수준 대응 ("이 페이지를 불러올 수 없습니다")
    Feature Boundary     -> 컴포넌트 수준 대응 ("이 영역을 불러오지 못했습니다, 재시도")
```

- 모든 라우트/페이지는 반드시 자체 `ErrorBoundary`를 가져야 한다.
- 독립적으로 데이터를 가져오는 위젯(차트, 피드, 사이드바)은 개별 `ErrorBoundary`로 감싸야 한다.
- 동일한 부모 데이터 소스를 공유하는 정적 표시 컴포넌트는 개별 바운더리가 필요 없다.
- 리프 컴포넌트(버튼, 인풋 등)를 ErrorBoundary로 감싸지 않는다.

### 1.3 리셋 & 복구

- 모든 `ErrorBoundary`는 반드시 `resetKeys` 또는 수동 리셋 메커니즘을 가져야 한다. 없으면 에러 상태에서 영구적으로 빠져나오지 못한다.
- 네비게이션 시 자동 리셋: `resetKeys={[location.pathname]}`
- `onReset` 콜백에서 캐시 무효화 등 정리 작업 수행: `queryClient.invalidateQueries()`

```tsx
<ErrorBoundary
  FallbackComponent={ErrorFallback}
  resetKeys={[location.pathname]}
  onReset={() => queryClient.invalidateQueries()}
>
  <MyComponent />
</ErrorBoundary>
```

### 1.4 비동기/이벤트 핸들러 에러

- ErrorBoundary는 기본적으로 렌더링 단계 에러만 잡는다.
- 비동기 작업과 이벤트 핸들러에서는 `useErrorBoundary().showBoundary(error)`를 사용하여 가장 가까운 바운더리로 전파한다.

```tsx
import { useErrorBoundary } from 'react-error-boundary';

function SaveButton() {
  const { showBoundary } = useErrorBoundary();
  const handleSave = async () => {
    try {
      await saveData();
    } catch (error) {
      showBoundary(error);
    }
  };
  return <button onClick={handleSave}>Save</button>;
}
```

- **안티패턴**: 비동기 에러를 로컬 `useState`로 잡아 즉석 에러 UI를 렌더링하는 것. 바운더리를 우회하여 에러 처리가 일관되지 않게 된다.

### 1.5 폴백 UI 요구사항

- 폴백 UI는 반드시 최소 하나의 복구 액션을 포함해야 한다: **재시도** 또는 **다른 페이지로 이동**.
- 폴백 UI는 대체하는 콘텐츠의 대략적인 크기와 일치해야 한다 (레이아웃 시프트 방지).
- 접근성을 위해 에러 폴백 컨테이너에 `role="alert"`를 사용한다.
- 프로덕션에서 스택 트레이스를 그대로 노출하지 않는다. 사용자에게 의미 있는 경우에만 `error.message`를 표시한다.

```tsx
// 위젯 수준 폴백
function WidgetErrorFallback({ error, resetErrorBoundary }) {
  return (
    <div role="alert" className="widget-error">
      <p>이 영역을 불러오지 못했습니다.</p>
      <button onClick={resetErrorBoundary}>재시도</button>
    </div>
  );
}

// 페이지 수준 폴백
function PageErrorFallback({ error, resetErrorBoundary }) {
  const navigate = useNavigate();
  return (
    <div role="alert" className="page-error">
      <h2>문제가 발생했습니다</h2>
      <p>이 페이지를 불러올 수 없습니다.</p>
      <button onClick={resetErrorBoundary}>재시도</button>
      <button onClick={() => navigate('/')}>홈으로 이동</button>
    </div>
  );
}
```

### 1.6 ErrorBoundary 범위 규칙

- ErrorBoundary를 예상 가능한 에러(폼 유효성 검사, 404, 비즈니스 로직)에 사용하지 않는다. 이런 에러는 조건부 렌더링으로 처리한다.
- 앱 전체를 하나의 ErrorBoundary로 감싸지 않는다. 단일 에러가 전체 앱을 죽인다.

---

## 2. Suspense 규칙

### 2.1 핵심 페어링 규칙

- 모든 `<Suspense>`는 반드시 형제 또는 부모 `<ErrorBoundary>`와 짝을 이뤄야 한다.
- ErrorBoundary 없는 Suspense는 거부된 Promise가 잡히지 않는다.

### 2.2 TanStack Query (React Query v5) 통합

- `useSuspenseQuery`를 사용한다. `useQuery`의 `suspense: true` 옵션은 v5에서 폐기되었다.
- 하나의 컴포넌트 내에서 병렬 데이터 패칭이 필요하면 `useSuspenseQueries`를 사용하여 요청 워터폴을 방지한다.

```tsx
import { useSuspenseQuery } from '@tanstack/react-query';

function UserProfile({ userId }) {
  const { data } = useSuspenseQuery({
    queryKey: ['user', userId],
    queryFn: () => fetchUser(userId),
  });
  // data는 undefined가 아닌 것이 보장됨 - 로딩/에러 체크 불필요
  return <div>{data.name}</div>;
}
```

### 2.3 바운더리 배치 전략

- Suspense 바운더리는 **시각적 "로딩 단위"** 수준에 배치한다 - 독립적으로 로딩 상태를 보여줄 수 있는 가장 작은 UI 영역.
- Suspense는 비동기 작업을 시작하는 컴포넌트와 가까이 위치시킨다.

```tsx
// 나쁜 예: 페이지 전체에 하나의 Suspense (모든 것이 가장 느린 쿼리를 기다림)
<Suspense fallback={<FullPageSpinner />}>
  <Header />      {/* 빠름 */}
  <MainContent /> {/* 느림 */}
  <Sidebar />     {/* 중간 */}
</Suspense>

// 좋은 예: 독립 영역별 분리된 바운더리
<Header />
<Suspense fallback={<ContentSkeleton />}>
  <MainContent />
</Suspense>
<Suspense fallback={<SidebarSkeleton />}>
  <Sidebar />
</Suspense>
```

### 2.4 중첩 Suspense를 활용한 점진적 로딩

- Suspense 바운더리를 **빠른 것부터 느린 것 순서로** 중첩하여 점진적으로 콘텐츠를 표시한다.
- 바깥쪽 바운더리는 빠른 데이터를, 안쪽 바운더리는 점차 느린 데이터를 감싼다.

```tsx
<Suspense fallback={<PageShell />}>
  <Header user={userId} />           {/* 빠름 */}
  <Suspense fallback={<FeedSkeleton />}>
    <Feed userId={userId} />          {/* 중간 */}
    <Suspense fallback={<CommentsSkeleton />}>
      <Comments postId={activePostId} /> {/* 느림 */}
    </Suspense>
  </Suspense>
</Suspense>
```

### 2.5 Suspense 안티패턴

- Suspense 내부에서 매 렌더마다 새로운 Promise를 생성하지 않는다. 무한 서스펜드 루프가 발생한다. 캐싱 레이어(TanStack Query, Jotai async atoms 등)를 사용한다.
- 자주 리렌더링되는 컴포넌트 내부에 Suspense 바운더리를 두지 않는다. 리렌더링마다 Promise identity가 변경되면 폴백이 다시 트리거된다.
- `SuspenseList`는 React에서 안정화될 때까지 프로덕션 코드에서 의존하지 않는다.

---

## 3. 재사용 가능한 AsyncBoundary 패턴

`QueryErrorResetBoundary` + `ErrorBoundary` + `Suspense`를 감싸는 하나의 재사용 컴포넌트를 만든다. 이 세 컴포넌트 중첩을 매번 반복하지 않는다.

```tsx
import { QueryErrorResetBoundary } from '@tanstack/react-query';
import { ErrorBoundary } from 'react-error-boundary';
import { Suspense } from 'react';

function AsyncBoundary({
  children,
  errorFallback: ErrorFallbackComponent = DefaultErrorFallback,
  loadingFallback = <DefaultSkeleton />,
  resetKeys = [],
}) {
  return (
    <QueryErrorResetBoundary>
      {({ reset }) => (
        <ErrorBoundary
          onReset={reset}
          FallbackComponent={ErrorFallbackComponent}
          resetKeys={resetKeys}
        >
          <Suspense fallback={loadingFallback}>
            {children}
          </Suspense>
        </ErrorBoundary>
      )}
    </QueryErrorResetBoundary>
  );
}
```

사용법:
```tsx
<AsyncBoundary
  loadingFallback={<ProfileSkeleton />}
  errorFallback={WidgetErrorFallback}
>
  <UserProfile userId={id} />
</AsyncBoundary>
```

---

## 4. 로딩 상태 UX 규칙

### 4.1 스켈레톤 vs 스피너 판단 기준

| 상황 | 사용할 것 |
|------|-----------|
| 페이지/섹션 초기 로딩 | 콘텐츠 레이아웃에 맞는 스켈레톤 |
| 리스트/피드 로딩 | 3-5개 플레이스홀더 아이템의 스켈레톤 |
| 이미지 로딩 | aspect-ratio 플레이스홀더가 있는 스켈레톤 |
| 버튼 액션 (저장, 제출) | 버튼 내 인라인 스피너 |
| 파일 업로드/처리 | 프로그레스 바 또는 스피너 |
| 라우트 간 이동 | 기존 콘텐츠 유지 (`useTransition`) |
| 부가 콘텐츠 | `fallback={null}` (표시 안 함) |

### 4.2 스켈레톤 요구사항

- 스켈레톤은 실제 콘텐츠의 대략적인 크기와 레이아웃에 맞춰야 한다 (레이아웃 시프트 방지).
- 스크린 리더 접근성을 위해 스켈레톤 컨테이너에 `aria-busy="true"`를 사용한다.
- 빠른 응답 시 로딩 상태가 깜빡이는 것을 방지하기 위해 CSS `animation-delay: 200ms`를 적용한다.

```tsx
function CardSkeleton() {
  return (
    <div className="card" aria-busy="true" aria-label="콘텐츠 로딩 중">
      <div className="skeleton skeleton-image" style={{ aspectRatio: '16/9' }} />
      <div className="skeleton skeleton-title" style={{ width: '70%', height: '1.5rem' }} />
      <div className="skeleton skeleton-text" style={{ width: '100%', height: '1rem' }} />
    </div>
  );
}
```

```css
.skeleton {
  animation: pulse 1.5s ease-in-out infinite;
  animation-delay: 200ms;
  animation-fill-mode: backwards;
}
```

### 4.3 트랜지션 처리

- 라우트 전환 시 스피너 대신 `useTransition`을 사용하여 기존 콘텐츠를 유지한다.
- `useTransition`의 `isPending`을 사용하여 기존 콘텐츠를 흐리게 표시한다 (예: `opacity: 0.7`).

---

## 5. 낙관적 업데이트 규칙

- 성공 확률이 높고 위험이 낮은 변형(좋아요, 토글, 순서 변경)에 낙관적 업데이트를 사용한다.
- `onError`에서 반드시 롤백을 구현한다.
- `onSettled`에서 반드시 `invalidateQueries`로 서버와 동기화한다.
- 파괴적 작업(삭제, 영구 변경)에는 사용자 확인 없이 낙관적 업데이트를 사용하지 않는다.

```tsx
const mutation = useMutation({
  mutationFn: (id) => likePost(id),
  onMutate: async (id) => {
    await queryClient.cancelQueries({ queryKey: ['posts'] });
    const previous = queryClient.getQueryData(['posts']);
    queryClient.setQueryData(['posts'], (old) =>
      old.map(p => p.id === id ? { ...p, liked: true } : p)
    );
    return { previous };
  },
  onError: (_err, _id, context) => {
    queryClient.setQueryData(['posts'], context.previous); // 롤백
  },
  onSettled: () => {
    queryClient.invalidateQueries({ queryKey: ['posts'] }); // 서버 동기화
  },
});
```

---

## 6. 에러 재시도 & 복구

- TanStack Query 기본 재시도(3회, 지수 백오프)를 유지한다. 이유 없이 비활성화하지 않는다.
- 쿼리 클라이언트 기본값에 일관된 재시도 동작을 설정한다:

```tsx
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 3,
      retryDelay: (attempt) => Math.min(1000 * 2 ** attempt, 30000),
    },
  },
});
```

- 모든 에러 상태는 최소 하나의 복구 경로를 제공해야 한다: 재시도, 다른 페이지로 이동, 또는 우아한 성능 저하(부분 콘텐츠 표시).

---

## 7. Next.js App Router 규칙

Next.js App Router(v13.4+) 사용 시:

- 각 라우트 세그먼트에 `error.tsx`를 배치하여 에러를 격리한다. 반드시 클라이언트 컴포넌트(`'use client'`)여야 한다.
- `loading.tsx`로 `page.tsx` 주변에 자동 Suspense 바운더리를 생성한다.
- 더 세밀한 로딩이 필요하면 페이지 컴포넌트 내부에 `<Suspense>` 바운더리를 추가한다.
- Server Action에서 예상 가능한 에러는 throw 대신 에러 상태 객체를 반환한다.

```
app/
  dashboard/
    page.tsx        -> 페이지 컴포넌트
    loading.tsx     -> 자동 Suspense 바운더리
    error.tsx       -> 자동 ErrorBoundary ('use client' 필수)
    not-found.tsx   -> notFound() 호출 처리
```

```tsx
// Server Action: throw 대신 에러 객체 반환
'use server';
export async function createUser(formData: FormData) {
  const result = await db.users.create(/* ... */);
  if (!result.success) {
    return { error: '사용자 생성에 실패했습니다' };
  }
  revalidatePath('/users');
  return { success: true };
}
```

---

## 8. 상태 관리 분리 원칙

- **서버 상태** (API 데이터 패칭, 캐싱, 동기화): TanStack Query를 사용한다.
- **클라이언트 상태** (UI 상태, 폼 상태, 로컬 설정): Jotai/Zustand를 사용한다.
- Jotai async atoms를 서버 상태 라이브러리 대체로 사용하지 않는다. 캐싱, 중복 제거, 백그라운드 리패칭, 재시도 로직이 없다.

---

## 9. 점진적 로딩을 위한 콘텐츠 우선순위

1. **네비게이션/크롬** - 즉시 (캐시 또는 정적)
2. **주요 콘텐츠 구조** - 스켈레톤 즉시, 실제 콘텐츠 최대한 빨리
3. **부차 콘텐츠** - 주요 콘텐츠 이후 로드, 독립적인 Suspense 바운더리
4. **부가 콘텐츠** - 지연 로딩(`React.lazy`), 지연, 또는 인터랙션 시 로드; `fallback={null}` 사용

```tsx
function ProductPage({ productId }) {
  return (
    <>
      <NavBar />  {/* 1. 정적 - 즉시 */}
      <Suspense fallback={<ProductDetailSkeleton />}>
        <ProductDetail id={productId} />  {/* 2. 주요 */}
      </Suspense>
      <Suspense fallback={<ReviewsSkeleton />}>
        <Reviews productId={productId} />  {/* 3. 부차 */}
      </Suspense>
      <Suspense fallback={null}>
        <LazyRecommendations productId={productId} />  {/* 4. 부가 */}
      </Suspense>
    </>
  );
}
```

---

## 10. 데이터 패칭 최적화 규칙

### 10.1 Debounce / Throttle 적용 기준

기능에 따라 적절한 호출 제어 전략을 선택한다.

| 상황 | 전략 | 지연 시간 | 이유 |
|------|------|-----------|------|
| 검색 입력 (자동완성) | **Debounce** | 300-500ms | 타이핑 완료 후 한 번만 요청 |
| 폼 필드 실시간 유효성 검사 | **Debounce** | 300ms | 입력 중에는 검증 불필요 |
| 무한 스크롤 | **Throttle** | 200-300ms | 스크롤 중 일정 간격으로 감지 |
| 윈도우 리사이즈 | **Throttle** | 100-200ms | 연속 이벤트를 일정 간격으로 제한 |
| 버튼 클릭 (API 호출) | **Debounce (leading)** | 500ms-1s | 더블 클릭 방지, 첫 클릭만 실행 |
| 실시간 필터링 | **Debounce** | 200-300ms | 필터 조건 변경 완료 후 요청 |
| 지도 드래그/줌 | **Throttle** | 300ms | 이동 중 적당한 빈도로 데이터 요청 |

**판단 기준:**
- **Debounce**: "마지막 입력 후 N ms 동안 추가 입력이 없을 때" 실행. 사용자 입력 완료를 기다리는 경우.
- **Throttle**: "N ms마다 최대 한 번" 실행. 연속 이벤트에서 일정 빈도를 보장하는 경우.
- **Leading debounce**: 첫 호출은 즉시 실행, 이후 일정 시간 동안 추가 호출 무시. 버튼 클릭에 적합.

**debounce는 순수 유틸 함수로 작성한다.** React 훅(`useDebounce`)이 아닌 `utils/debounce.ts`에 순수 함수로 정의하고, fetch를 발생시키는 이벤트 핸들러를 감싼다. fetch 자체를 debounce하지 않는다.

```ts
// utils/debounce.ts - 순수 유틸 함수
export function debounce<T extends (...args: any[]) => any>(
  fn: T,
  delay: number,
): (...args: Parameters<T>) => void {
  let timer: ReturnType<typeof setTimeout>;
  return (...args: Parameters<T>) => {
    clearTimeout(timer);
    timer = setTimeout(() => fn(...args), delay);
  };
}
```

```tsx
// 사용 예: 이벤트 핸들러를 debounce로 감싼다
import { debounce } from '@/utils/debounce';

const SEARCH_DEBOUNCE_MS = 300;

function SearchInput() {
  const [results, setResults] = useState([]);

  // fetch를 debounce하는 게 아니라, fetch를 트리거하는 핸들러를 debounce
  const handleSearch = useMemo(
    () => debounce(async (query: string) => {
      const data = await searchAPI(query);
      setResults(data);
    }, SEARCH_DEBOUNCE_MS),
    [],
  );

  return (
    <input onChange={(e) => handleSearch(e.target.value)} />
  );
}
```

**규칙:**
- API 호출이 포함된 사용자 입력에는 반드시 debounce 또는 throttle을 적용한다.
- debounce/throttle은 `utils/` 하위에 순수 함수로 작성한다. React 훅으로 만들지 않는다.
- debounce는 fetch 자체가 아닌, fetch를 발생시키는 **이벤트 핸들러**에 적용한다.
- debounce/throttle 지연 시간은 상수로 정의한다 (매직 넘버 금지).

### 10.2 요청 취소: TanStack Query vs 직접 fetch

요청 취소 전략은 TanStack Query 사용 여부에 따라 달라진다.

**경로 A: TanStack Query 사용 시 — signal만 전달하면 된다**

TanStack Query가 내부적으로 AbortController를 생성하고, `queryFn`에 `signal`을 파라미터로 넘겨준다. 쿼리가 취소되면(컴포넌트 언마운트, queryKey 변경, 쿼리 무효화 등) 자동으로 `abort()`를 호출한다. 우리가 할 일은 `signal`을 `fetch`/`axios`에 전달하는 것뿐이다.

```tsx
// TanStack Query: AbortController 생성/abort 모두 자동
// 우리는 signal을 fetch에 전달만 하면 된다
function useProducts(categoryId: string) {
  return useSuspenseQuery({
    queryKey: ['products', categoryId],
    queryFn: ({ signal }) => {
      return fetch(`/api/products?category=${categoryId}`, { signal })
        .then(res => res.json());
    },
  });
}
```

- AbortController를 직접 생성할 필요 없다.
- `abortRef`를 만들 필요 없다.
- `queryFn`의 `signal` 파라미터를 **무시하지 않고 반드시 전달**한다.
- axios 사용 시에도 동일: `axios.get(url, { signal })`

**경로 B: 직접 fetch 시 — abortRef 패턴으로 관리한다**

TanStack Query 없이 비즈니스 훅에서 직접 fetch할 때는 `useRef`로 AbortController를 관리한다. useEffect 내에서 매번 `new AbortController()`를 만드는 대신, ref로 두면 이벤트 핸들러에서도, cleanup에서도, 어디서든 abort가 가능하다.

```tsx
function useProducts(categoryId: string) {
  const [products, setProducts] = useState<Product[]>([]);
  const [error, setError] = useState<Error | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const abortRef = useRef<AbortController | null>(null);

  const fetchProducts = useCallback(async (catId: string) => {
    // 이전 요청 취소
    abortRef.current?.abort();
    abortRef.current = new AbortController();

    setIsLoading(true);
    setError(null);

    try {
      const res = await fetch(`/api/products?category=${catId}`, {
        signal: abortRef.current.signal,
      });
      const data = await res.json();
      setProducts(data);
    } catch (err) {
      if (err instanceof Error && err.name !== 'AbortError') {
        setError(err);
      }
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchProducts(categoryId);
    return () => abortRef.current?.abort();
  }, [categoryId, fetchProducts]);

  return { products, error, isLoading, refetch: () => fetchProducts(categoryId) };
}
```

**규칙:**
- TanStack Query 사용 시: `queryFn`의 `signal`을 fetch에 전달하기만 하면 된다. AbortController를 직접 관리하지 않는다.
- 직접 fetch 시: `useRef<AbortController | null>(null)`로 abortRef를 관리한다. useEffect 내에서 매번 new AbortController 생성하지 않는다.
- 새 요청 시작 전에 `abortRef.current?.abort()`로 이전 요청을 취소한다.
- `AbortError`는 정상적인 취소이므로 에러로 처리하지 않는다 (`err.name !== 'AbortError'` 체크).

### 10.3 비즈니스 훅 패턴

데이터 패칭 로직은 도메인별 비즈니스 훅에 캡슐화한다. 컴포넌트에서 fetch를 직접 호출하지 않는다.

```tsx
// domains/products/hooks/useProducts.ts
// TanStack Query 사용 시
function useProducts(categoryId: string) {
  return useSuspenseQuery({
    queryKey: ['products', categoryId],
    queryFn: ({ signal }) => productAPI.getByCategory(categoryId, { signal }),
  });
}

// domains/products/hooks/useProductSearch.ts
// debounce가 필요한 경우: 이벤트 핸들러에 debounce를 적용
function useProductSearch() {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<Product[]>([]);
  const abortRef = useRef<AbortController | null>(null);

  const search = useMemo(
    () => debounce(async (q: string) => {
      if (!q) { setResults([]); return; }

      abortRef.current?.abort();
      abortRef.current = new AbortController();

      try {
        const data = await productAPI.search(q, { signal: abortRef.current.signal });
        setResults(data);
      } catch (err) {
        if (err instanceof Error && err.name !== 'AbortError') throw err;
      }
    }, SEARCH_DEBOUNCE_MS),
    [],
  );

  useEffect(() => () => abortRef.current?.abort(), []);

  return {
    query,
    results,
    onQueryChange: (q: string) => { setQuery(q); search(q); },
  };
}
```

**규칙:**
- 데이터 패칭은 `domains/{도메인}/hooks/` 하위에 비즈니스 훅으로 캡슐화한다.
- 훅 이름은 도메인을 반영한다: `useProducts`, `useOrders`, `useUserProfile` 등.
- 훅은 `{ data, isLoading, error }` 또는 도메인에 맞는 명확한 인터페이스를 반환한다.
- debounce + abort가 필요한 경우 하나의 비즈니스 훅 안에서 함께 관리한다.
- 컴포넌트는 비즈니스 훅만 사용하고, fetch/abort/debounce 상세를 알 필요가 없다.

### 10.4 Race Condition 방지

여러 비동기 요청이 순서 보장 없이 응답할 때 발생하는 문제를 방지한다.

```tsx
// 나쁜 예: race condition 가능
useEffect(() => {
  fetchData(id).then(setData); // 이전 요청 응답이 나중에 도착하면 덮어씀
}, [id]);
```

**해결 방법:**
- **TanStack Query**: queryKey 기반으로 자동 처리. 추가 작업 불필요.
- **직접 fetch**: abortRef 패턴 사용. 새 요청 전에 이전 요청을 abort하면 이전 응답의 콜백이 실행되지 않는다.

```tsx
// abortRef로 race condition 방지
const abortRef = useRef<AbortController | null>(null);

useEffect(() => {
  abortRef.current?.abort(); // 이전 요청 취소
  abortRef.current = new AbortController();

  fetchData(id, { signal: abortRef.current.signal })
    .then(setData)
    .catch(err => {
      if (err instanceof Error && err.name !== 'AbortError') setError(err);
    });

  return () => abortRef.current?.abort();
}, [id]);
```

**규칙:**
- TanStack Query를 사용하면 race condition이 자동으로 처리된다.
- 직접 fetch 시 abortRef 패턴으로 이전 요청을 취소한다.
- `cancelled` 플래그는 불필요하다. abort 시 AbortError가 발생하므로 콜백이 실행되지 않는다.

---

## 안티패턴 빠른 참조 체크리스트

| 안티패턴 | 왜 나쁜가 | 대신 할 것 |
|----------|-----------|------------|
| 커스텀 클래스 ErrorBoundary | resetKeys, hooks 지원 부재 | `react-error-boundary` 사용 |
| 앱 전체를 하나의 ErrorBoundary로 | 단일 에러가 전체 앱 종료 | 라우트/위젯별 계층적 바운더리 |
| resetKeys 없는 ErrorBoundary | 에러 상태에 영구히 갇힘 | `resetKeys` 또는 리셋 메커니즘 추가 |
| ErrorBoundary 없는 Suspense | 거부된 Promise 미포착 | 항상 Suspense + ErrorBoundary 쌍으로 |
| `useQuery`의 `suspense: true` | TanStack Query v5에서 폐기됨 | `useSuspenseQuery` 사용 |
| 매 렌더마다 새 Promise 생성 | 무한 서스펜드 루프 | 캐싱 레이어 사용 (TanStack Query) |
| 비동기 에러의 로컬 `useState` | 일관성 없는 에러 처리 | `showBoundary()` 훅 사용 |
| 알려진 형태의 콘텐츠에 스피너 | 나쁜 UX, 레이아웃 시프트 | 콘텐츠 레이아웃 맞춤 스켈레톤 |
| 로딩 딜레이 없음 | 로딩 상태 깜빡임 | CSS `animation-delay: 200ms` |
| 롤백 없는 낙관적 업데이트 | 에러 시 불일치 상태 | `onError` 롤백 구현 |
| 프로덕션에서 스택 트레이스 노출 | 보안 위험, 나쁜 UX | 사용자 친화적 에러 메시지 |
| debounce를 React 훅으로 구현 | React에 불필요한 결합 | `utils/debounce.ts` 순수 함수로 작성 |
| fetch 자체를 debounce | 의도 불명확, 관심사 혼합 | fetch를 발생시키는 이벤트 핸들러를 debounce |
| API 호출에 debounce/throttle 없음 | 불필요한 요청 폭주, 서버 부하 | 입력 기반 API에 debounce, 스크롤에 throttle |
| TanStack Query에서 signal 무시 | 자동 abort 미작동, 메모리 누수 | `queryFn`의 `signal`을 fetch에 반드시 전달 |
| useEffect 내 매번 new AbortController | ref 없이 외부에서 abort 불가 | `abortRef = useRef<AbortController>` 패턴 |
| AbortError를 에러로 처리 | 정상 취소를 에러로 표시 | `err.name !== 'AbortError'` 체크 |
| 컴포넌트에서 직접 fetch | 관심사 혼합, 재사용 불가 | 도메인별 비즈니스 훅으로 캡슐화 |
