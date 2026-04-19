# Frontend Fundamentals — 안티패턴 레퍼런스

> 출처: https://frontend-fundamentals.com/code-quality/code/
> 4가지 축: 가독성, 예측 가능성, 응집도, 결합도

---

## 1. 가독성 (Readability)

### 1-1. 같이 실행되지 않는 코드 분리하기

분기별로 실행되지 않는 코드가 한 컴포넌트에 섞여 있으면 맥락 파악이 어렵다.

```tsx
// Bad — 분기 로직이 교차
function SubmitButton() {
  const isViewer = useRole() === "viewer";
  useEffect(() => {
    if (isViewer) return;
    showButtonAnimation();
  }, [isViewer]);
  return isViewer
    ? <TextButton disabled>Submit</TextButton>
    : <Button type="submit">Submit</Button>;
}

// Good — 분기별 컴포넌트 분리
function SubmitButton() {
  const isViewer = useRole() === "viewer";
  return isViewer ? <ViewerSubmitButton /> : <AdminSubmitButton />;
}
function ViewerSubmitButton() {
  return <TextButton disabled>Submit</TextButton>;
}
function AdminSubmitButton() {
  useEffect(() => { showButtonAnimation(); }, []);
  return <Button type="submit">Submit</Button>;
}
```

**판단 기준**: 한 컴포넌트 안에 조건 분기가 2개 이상이고, 각 분기의 로직(useEffect, 이벤트 핸들러 등)이 서로 독립적이면 분리 대상.

---

### 1-2. 구현 상세 추상화하기

한 컴포넌트에 인증 확인, 리다이렉트 등 구현 상세가 노출되면 동시에 고려할 맥락이 너무 많다.

```tsx
// Bad — 인증 로직이 페이지 내부에 노출
function LoginStartPage() {
  useCheckLogin({
    onChecked: (status) => {
      if (status === "LOGGED_IN") { location.href = "/home"; }
    }
  });
  return <>{/* 로그인 UI */}</>;
}

// Good — AuthGuard로 추상화
function App() {
  return <AuthGuard><LoginStartPage /></AuthGuard>;
}
function AuthGuard({ children }) {
  const status = useCheckLoginStatus();
  useEffect(() => {
    if (status === "LOGGED_IN") location.href = "/home";
  }, [status]);
  return status !== "LOGGED_IN" ? children : null;
}
```

**판단 기준**: 컴포넌트 이름의 핵심 책임과 무관한 로직(인증, 권한, 리다이렉트 등)이 내부에 있으면 추상화 대상.

또 다른 예시 — 긴 이벤트 핸들러를 별도 컴포넌트로 분리하여 버튼과 클릭 로직의 응집도를 높인다:

```tsx
// Bad — 이벤트 핸들러가 부모 컴포넌트에 길게 정의됨
function FriendInvitation() {
  const { data } = useQuery(/* ... */);
  const handleClick = async () => {
    const canInvite = await overlay.openAsync(({ isOpen, close }) => (
      <ConfirmDialog title={`${data.name}님에게 공유해요`} /* ... */ />
    ));
    if (canInvite) await sendPush();
  };
  return <Button onClick={handleClick}>초대하기</Button>;
}

// Good — 버튼 + 핸들러를 별도 컴포넌트로 분리
function FriendInvitation() {
  const { data } = useQuery(/* ... */);
  return <InviteButton name={data.name} />;
}
function InviteButton({ name }) {
  return (
    <Button onClick={async () => {
      const canInvite = await overlay.openAsync(({ isOpen, close }) => (
        <ConfirmDialog title={`${name}님에게 공유해요`} /* ... */ />
      ));
      if (canInvite) await sendPush();
    }}>
      초대하기
    </Button>
  );
}
```

---

### 1-3. 로직 종류에 따라 합쳐진 함수 쪼개기

쿼리 파라미터, 상태, API 호출 등을 하나의 Hook에 몰아넣으면 책임이 무한 증가하고, 하나의 값 변경에 전체가 리렌더링된다.

```typescript
// Bad — 모든 쿼리 파라미터를 하나의 Hook에
export function usePageState() {
  const [query, setQuery] = useQueryParams({
    cardId: NumberParam,
    statementId: NumberParam,
    dateFrom: DateParam,
    dateTo: DateParam,
    statusList: ArrayParam
  });
  return useMemo(() => ({
    values: { /* 모든 값 */ },
    controls: { /* 모든 setter */ }
  }), [query, setQuery]);
}

// Good — 파라미터별 개별 Hook
export function useCardIdQueryParam() {
  const [cardId, _setCardId] = useQueryParam("cardId", NumberParam);
  const setCardId = useCallback(
    (cardId: number) => { _setCardId({ cardId }, "replaceIn"); },
    []
  );
  return [cardId ?? undefined, setCardId] as const;
}
```

**판단 기준**: Hook이 3개 이상의 독립적 상태를 관리하고, 사용처마다 그 중 일부만 쓰고 있다면 분리 대상.

---

### 1-4. 복잡한 조건에 이름 붙이기

중첩된 조건식은 의도 파악이 어렵다.

```typescript
// Bad
const result = products.filter((product) =>
  product.categories.some((category) =>
    category.id === targetCategory.id &&
    product.prices.some((price) => price >= minPrice && price <= maxPrice)
  )
);

// Good — 조건에 이름 부여
const matchedProducts = products.filter((product) => {
  return product.categories.some((category) => {
    const isSameCategory = category.id === targetCategory.id;
    const isPriceInRange = product.prices.some(
      (price) => price >= minPrice && price <= maxPrice
    );
    return isSameCategory && isPriceInRange;
  });
});
```

**판단 기준**: 조건식에 `&&`, `||`가 2개 이상 조합되어 있고, 각 부분의 의미를 즉시 파악하기 어려우면 이름 부여 대상.

---

### 1-5. 매직 넘버에 이름 붙이기

숫자의 의도가 불명확하면 가독성이 떨어진다.

```typescript
// Bad — 300이 무엇인지 알 수 없음
await delay(300);

// Good
const ANIMATION_DELAY_MS = 300;
await delay(ANIMATION_DELAY_MS);
```

**판단 기준**: 코드에 직접 들어간 숫자의 의미를 주석 없이는 파악할 수 없으면 상수 추출 대상.

---

### 1-6. 시점 이동 줄이기

변수 -> 함수 -> 상수로 3번 이동해야 맥락을 파악할 수 있으면 가독성이 나쁘다.

```tsx
// Bad — policy -> getPolicyByRole -> POLICY_SET으로 3번 시점 이동
function Page() {
  const user = useUser();
  const policy = getPolicyByRole(user.role);
  return <Button disabled={!policy.canInvite}>Invite</Button>;
}
function getPolicyByRole(role) {
  return { canInvite: POLICY_SET[role].includes("invite") };
}
const POLICY_SET = { admin: ["invite", "view"], viewer: ["view"] };

// Good — 인라인 객체로 시점 이동 제거
function Page() {
  const user = useUser();
  const policy = {
    admin: { canInvite: true, canView: true },
    viewer: { canInvite: false, canView: true }
  }[user.role];
  return <Button disabled={!policy.canInvite}>Invite</Button>;
}
```

**판단 기준**: 한 로직을 이해하기 위해 3곳 이상을 오가야 하면 시점 이동이 과도한 것. 인라인 배치 또는 가까이 모으기.

---

### 1-7. 삼항 연산자 단순하게 하기

```typescript
// Bad — 중첩 삼항
const status =
  A && B ? "BOTH" : A || B ? (A ? "A" : "B") : "NONE";

// Good — if문으로 풀기
const status = (() => {
  if (A && B) return "BOTH";
  if (A) return "A";
  if (B) return "B";
  return "NONE";
})();
```

**판단 기준**: 삼항 연산자가 2단계 이상 중첩되면 if문 또는 IIFE로 전환.

---

### 1-8. 왼쪽에서 오른쪽으로 읽히게 하기

```typescript
// Bad — 범위 조건이 직관적이지 않음
if (score >= 80 && score <= 100)

// Good — 수학 부등식처럼 왼쪽에서 오른쪽으로 읽힘
if (80 <= score && score <= 100)
```

**판단 기준**: 범위 비교에서 변수가 양쪽에 반복 등장하면, 수직선 순서(작은 값 <= 변수 <= 큰 값)로 재배치.

---

## 2. 예측 가능성 (Predictability)

### 2-1. 이름 겹치지 않게 관리하기

라이브러리와 동일한 이름으로 래퍼를 만들면, 호출자가 추가 로직(인증 등)을 예측할 수 없다.

```typescript
// Bad — 라이브러리와 같은 이름으로 래퍼 생성
import { http as httpLibrary } from "@some-library/http";
export const http = {
  async get(url: string) {
    const token = await fetchToken();
    return httpLibrary.get(url, {
      headers: { Authorization: `Bearer ${token}` }
    });
  }
};

// Good — 래퍼임을 명시하는 이름
export const httpService = {
  async getWithAuth(url: string) {
    const token = await fetchToken();
    return httpLibrary.get(url, {
      headers: { Authorization: `Bearer ${token}` }
    });
  }
};
```

**판단 기준**: 외부 라이브러리/API와 동일한 이름의 래퍼가 있고, 동작이 다르면 이름 변경 대상.

---

### 2-2. 같은 종류의 함수는 반환 타입 통일하기

같은 목적의 함수들이 서로 다른 반환 타입을 가지면 사용할 때마다 타입을 확인해야 한다.

```typescript
// Bad — 반환 타입 불일치
function useUser() { return useQuery({ ... }); }         // Query 객체 반환
function useServerTime() { return useQuery({ ... }).data; } // data만 반환

// Good — Query 객체로 통일
function useUser() { return useQuery({ ... }); }
function useServerTime() { return useQuery({ ... }); }
```

검증 함수도 마찬가지:

```typescript
// Bad
function checkIsNameValid(name: string): boolean { ... }
function checkIsAgeValid(age: number): { ok: boolean; reason?: string } { ... }

// Good — 모두 객체로 통일
function checkIsNameValid(name: string): { ok: boolean; reason?: string } { ... }
function checkIsAgeValid(age: number): { ok: boolean; reason?: string } { ... }
```

**판단 기준**: 같은 패턴의 함수(useXxx, checkXxx 등)인데 반환 타입이 다르면 통일 대상.

---

### 2-3. 숨은 로직 드러내기

함수 이름과 시그니처에서 예측할 수 없는 부수효과가 숨어 있으면 안 된다.

```typescript
// Bad — fetchBalance 안에 logging이 숨어 있음
async function fetchBalance(): Promise<number> {
  const balance = await http.get<number>("...");
  logging.log("balance_fetched");  // 숨은 부수효과
  return balance;
}

// Good — 부수효과를 호출부에서 명시
async function fetchBalance(): Promise<number> {
  const balance = await http.get<number>("...");
  return balance;
}
// 호출부
const balance = await fetchBalance();
logging.log("balance_fetched");  // 명시적
```

**판단 기준**: 함수 이름/파라미터/반환타입으로 예측할 수 없는 부수효과(로깅, 분석, 전역 상태 변경 등)가 내부에 있으면 분리 대상.

---

## 3. 응집도 (Cohesion)

### 3-1. 함께 수정되는 파일을 같은 디렉토리에 두기

```
// Bad — 종류별 분류 (함께 수정되는 파일이 흩어짐)
src/components/  src/hooks/  src/utils/  src/constants/

// Good — 도메인별 분류 (함께 수정되는 파일이 모여 있음)
src/domains/
  Domain1/  (components/, hooks/, utils/)
  Domain2/  (components/, hooks/, utils/)
```

**판단 기준**: 하나의 기능 수정 시 3개 이상의 서로 다른 최상위 디렉토리를 건드려야 하면 도메인별 구조 고려.

---

### 3-2. 매직 넘버 없애기 (응집도 관점)

1-5와 같은 예시지만 관점이 다르다: 애니메이션 시간이 300ms에서 500ms로 변경되면, 상수 없이 흩어진 `300`을 모든 곳에서 수동으로 찾아 수정해야 하는 **응집도** 문제.

**판단 기준**: 같은 의미의 숫자가 2곳 이상에서 사용되는데 상수로 묶이지 않았으면 응집도 위반.

---

### 3-3. 폼의 응집도 생각하기

| 접근 방식 | 적합한 상황 |
|-----------|-----------|
| **필드 레벨 응집도** (개별 validation) | 필드가 독립적, 재사용 필요, 비동기 검증 |
| **폼 레벨 응집도** (Zod 스키마 등) | 필드 간 의존성, 멀티스텝 위저드, 통합 비즈니스 로직 |

```tsx
// 필드 레벨 — react-hook-form register에 개별 validate
{...register("email", {
  validate: (value) => {
    if (!value) return "이메일을 입력해주세요.";
    if (!/^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i.test(value))
      return "유효한 이메일 주소를 입력해주세요.";
    return "";
  }
})}

// 폼 레벨 — Zod 스키마로 중앙 관리
const schema = z.object({
  email: z.string().min(1, "이메일을 입력해주세요.").email("유효한 이메일 주소를 입력해주세요.")
});
```

**판단 기준**: 필드 간 교차 검증(비밀번호 확인, 합계 제한 등)이 있으면 폼 레벨. 필드가 완전히 독립적이면 필드 레벨.

---

## 4. 결합도 (Coupling)

### 4-1. 책임을 하나씩 관리하기

1-3과 동일한 `usePageState` 예시의 결합도 관점: 하나의 Hook이 5개 파라미터를 관리하면 어떤 값이 바뀌어도 모든 사용처에 영향을 미친다.

**판단 기준**: Hook/함수를 사용하는 곳에서 전체 반환값의 일부만 사용하고 있다면, 나머지 값의 변경에도 불필요하게 영향받는 결합 문제.

---

### 4-2. 중복 코드 허용하기

유사한 코드를 무리하게 하나의 Hook/컴포넌트로 공유하면, 페이지별 요구사항이 달라질 때 수정이 어렵다.

```typescript
// Bad — 무리하게 공유한 Hook (모든 페이지가 같은 로깅, 닫기 동작 강제)
export const useOpenMaintenanceBottomSheet = () => {
  const maintenanceBottomSheet = useMaintenanceBottomSheet();
  const logger = useLogger();
  return async (info: TelecomMaintenanceInfo) => {
    logger.log("점검 바텀시트 열림");
    const result = await maintenanceBottomSheet.open(info);
    if (result) { logger.log("점검 바텀시트 알림받기 클릭"); }
    closeView();
  };
};

// Good — 페이지별로 중복을 허용하되 각자의 요구사항을 자유롭게 반영
// PageA에서는 로깅 값이 다르고, PageB에서는 닫기 동작이 없는 등 각각 구현
```

**판단 기준**: 공유 코드를 수정할 때 "이 페이지에서는 이렇게, 저 페이지에서는 저렇게" 분기가 필요해지면, 공유를 풀고 중복을 허용하는 것이 낫다.

---

### 4-3. Props Drilling 제거하기

부모 -> 중간 -> 자식으로 prop이 전달되면, prop 변경 시 모든 중간 컴포넌트를 수정해야 한다.

```tsx
// Bad — ItemEditModal -> ItemEditBody -> ItemEditList로 props 전달
// 중간 컴포넌트가 사용하지 않는 props까지 전달

// Good A — Composition 패턴 (children 활용)
function ItemEditBody({ children, keyword, onKeywordChange, onClose }) {
  return (
    <>
      <Input value={keyword} onChange={(e) => onKeywordChange(e.target.value)} />
      <Button onClick={onClose}>닫기</Button>
      {children}
    </>
  );
}

// Good B — Context API (깊은 트리에서)
function ItemEditList({ keyword, onConfirm }) {
  const { items, recommendedItems } = useItemEditModalContext();
  // ...
}
```

**판단 기준**: props가 3단계 이상 전달되고, 중간 컴포넌트가 해당 prop을 사용하지 않으면 Composition 또는 Context로 전환.

---

## 5. 디렉터리 구조

### 5-1. Atomic Design 레벨 위반

atoms/molecules는 반드시 **pure**(외부 상태/도메인/사이드이펙트 없음)여야 한다. 외부 의존이 생기면 organism으로 이동한다.

```tsx
// Bad — molecules/SearchBar.tsx가 API 훅을 직접 사용
function SearchBar() {
  const { data } = useProductSearch();  // 외부 의존 → molecule 자격 상실
  return <Input value={data?.query} />;
}

// Good — molecule은 props만으로 동작
function SearchBar({ value, onChange }) {
  return <Input value={value} onChange={onChange} />;
}
// 외부 의존은 organism이 가짐
function ProductSearchBar() {
  const { query, onQueryChange } = useProductSearch();
  return <SearchBar value={query} onChange={onQueryChange} />;
}
```

**판단 기준**: atoms/molecules 안에 `useContext`, `useStore`, API 훅, 브라우저 API 등 외부 의존이 있으면 위반.

---

### 5-2. 페이지 전용 코드가 공통에 있음

한 페이지에서만 쓰는 컴포넌트/훅이 `src/components/`, `src/hooks/` 루트에 있으면 응집도가 낮다.

**판단 기준**:
- 한 페이지에서만 쓰이는데 `src/components/` 루트에 있음 → `pages/{name}/_components/`로 이동
- 2곳 이상에서 쓰이는데 `pages/A/_hooks/`에만 있음 → `src/hooks/`로 승격

---

### 5-3. Provider가 components에 섞여 있음

Provider는 UI 컴포넌트가 아닌 인프라다. `src/providers/`에 두어야 한다. layout 컴포넌트도 composition만 담당해야 한다.

**판단 기준**: Provider 정의가 `components/` 하위에 있거나, layout이 데이터를 패칭·비즈니스 로직을 포함하면 위반.

---

## 6. 에러/로딩 패턴

### 6-1. ErrorBoundary 배치 오류

```tsx
// Bad — 앱 전체를 하나의 ErrorBoundary로 (단일 에러가 전체 앱 죽임)
<ErrorBoundary><App /></ErrorBoundary>

// Bad — 리프 컴포넌트(버튼)를 감싼 ErrorBoundary (과도)
<ErrorBoundary><Button /></ErrorBoundary>

// Good — 3단계 계층: App Root / Route·Page / Feature·Widget
<AppRootBoundary>
  <RouteBoundary>
    <FeatureBoundary><Widget /></FeatureBoundary>
  </RouteBoundary>
</AppRootBoundary>
```

**판단 기준**: ErrorBoundary가 없는 라우트/위젯이 있거나, 리프 컴포넌트를 불필요하게 감싸거나, `resetKeys`가 없으면 위반.

---

### 6-2. Suspense / ErrorBoundary 페어링 누락

모든 `<Suspense>`는 형제 또는 상위에 `<ErrorBoundary>`가 있어야 한다. 없으면 거부된 Promise가 잡히지 않는다.

**판단 기준**: Suspense 상위 트리에 ErrorBoundary가 없으면 위반.

---

### 6-3. `useQuery`의 `suspense: true` 사용 (폐기됨)

TanStack Query v5 에서 `useQuery({ suspense: true })`는 폐기되었다. `useSuspenseQuery`를 사용해야 한다.

```tsx
// Bad
const { data } = useQuery({ queryKey: [...], queryFn: ..., suspense: true });

// Good
const { data } = useSuspenseQuery({ queryKey: [...], queryFn: ... });
```

---

### 6-4. AsyncBoundary 패턴 미활용

`QueryErrorResetBoundary + ErrorBoundary + Suspense` 3중 중첩을 매 사용처마다 반복하면 응집도가 떨어진다. `AsyncBoundary` 재사용 컴포넌트로 감싸야 한다.

**판단 기준**: 동일한 3중 중첩이 2곳 이상 반복되면 AsyncBoundary로 추출 대상.

---

### 6-5. 스켈레톤이 실제 콘텐츠 크기와 불일치

스켈레톤이 실제 콘텐츠와 크기가 다르면 레이아웃 시프트(CLS) 발생. 크기를 맞춰야 한다.

**판단 기준**: `height`, `aspect-ratio`가 실제 콘텐츠와 다르거나, 스켈레톤 없이 스피너만 쓰면 위반.

---

### 6-6. 낙관적 업데이트에 롤백 없음

```tsx
// Bad — 에러 시 UI가 거짓 상태로 남음
const mutation = useMutation({
  onMutate: (id) => queryClient.setQueryData(['posts'], optimistic),
  // onError, onSettled 없음
});

// Good
const mutation = useMutation({
  onMutate: async (id) => {
    await queryClient.cancelQueries({ queryKey: ['posts'] });
    const previous = queryClient.getQueryData(['posts']);
    queryClient.setQueryData(['posts'], optimistic);
    return { previous };
  },
  onError: (_err, _id, context) => {
    queryClient.setQueryData(['posts'], context.previous);  // 롤백
  },
  onSettled: () => {
    queryClient.invalidateQueries({ queryKey: ['posts'] });  // 서버 동기화
  },
});
```

---

### 6-7. 비동기 에러를 로컬 `useState`로 처리

```tsx
// Bad — 에러 바운더리 우회, 일관성 없는 처리
function SaveButton() {
  const [error, setError] = useState<Error | null>(null);
  const handleSave = async () => {
    try { await saveData(); }
    catch (e) { setError(e); }  // 바운더리 우회
  };
  if (error) return <InlineError />;
  return <button onClick={handleSave}>Save</button>;
}

// Good — showBoundary로 바운더리에 전파
import { useErrorBoundary } from 'react-error-boundary';
function SaveButton() {
  const { showBoundary } = useErrorBoundary();
  const handleSave = async () => {
    try { await saveData(); }
    catch (e) { showBoundary(e); }
  };
  return <button onClick={handleSave}>Save</button>;
}
```

---

## 7. 데이터 패칭

### 7-1. debounce가 잘못된 위치에 있음

```tsx
// Bad — fetch 자체를 debounce (의도 불명확, 관심사 혼합)
const debouncedFetch = debounce(fetchSearch, 300);

// Bad — debounce를 React 훅으로 구현 (React에 불필요한 결합)
function useDebounce(value: string, delay: number) { /* ... */ }

// Good — 순수 유틸, 이벤트 핸들러를 debounce
// utils/debounce.ts
export function debounce<T>(fn: T, delay: number) { /* ... */ }

// 컴포넌트: fetch를 트리거하는 핸들러를 감쌈
const handleSearch = useMemo(
  () => debounce((q: string) => searchAPI(q).then(setResults), SEARCH_DEBOUNCE_MS),
  [],
);
```

**판단 기준**:
- `debounce`/`throttle`이 React 훅으로 작성됨 → `utils/`로 이동
- fetch/API 함수 자체를 debounce → 이벤트 핸들러를 debounce로 변경
- API 호출이 있는 입력에 debounce/throttle이 없음 → 필수 적용

---

### 7-2. TanStack Query `signal` 무시

`queryFn`이 받는 `signal`을 fetch에 전달하지 않으면 자동 abort가 동작하지 않는다. 쿼리 무효화/언마운트 시 네트워크 요청이 계속되어 메모리 누수·경쟁 조건 유발.

```tsx
// Bad — signal 무시
queryFn: () => fetch('/api/products').then(r => r.json())

// Good
queryFn: ({ signal }) => fetch('/api/products', { signal }).then(r => r.json())
```

---

### 7-3. 직접 fetch 시 AbortController 관리 실패

useEffect 내에서 매번 `new AbortController()`를 만들면 외부 이벤트 핸들러에서 abort 불가. `useRef<AbortController | null>(null)` 패턴으로 관리해야 한다.

```tsx
// Bad — ref 없이 effect 내부에서만 생성
useEffect(() => {
  const controller = new AbortController();
  fetch(url, { signal: controller.signal });
  return () => controller.abort();
}, [url]);
// → 이벤트 핸들러에서 수동 abort 불가, race condition 위험

// Good — abortRef 패턴
const abortRef = useRef<AbortController | null>(null);
const fetchData = useCallback(async () => {
  abortRef.current?.abort();
  abortRef.current = new AbortController();
  try {
    await fetch(url, { signal: abortRef.current.signal });
  } catch (e) {
    if (e instanceof Error && e.name !== 'AbortError') throw e;
  }
}, [url]);
```

---

### 7-4. `AbortError`를 에러로 처리

AbortError는 정상적인 취소다. 에러 상태로 표시하면 UX가 깨진다.

```tsx
// Bad — 모든 에러를 그대로 setError
.catch(setError)

// Good — AbortError 제외
.catch(e => {
  if (e instanceof Error && e.name !== 'AbortError') setError(e);
})
```

---

### 7-5. 컴포넌트에서 직접 fetch 호출

컴포넌트가 `apis/`를 직접 호출하거나 `fetch`를 인라인으로 쓰면 재사용 불가, 관심사 혼합.

```tsx
// Bad — 컴포넌트가 apis 직접 호출
function ProductList() {
  const [products, setProducts] = useState([]);
  useEffect(() => { productAPI.getAll().then(setProducts); }, []);
}

// Good — 훅 레이어를 경유
function ProductList() {
  const { data: products } = useGetProducts();
}
```

**판단 기준**: 컴포넌트에서 `apis/` import 또는 `fetch`/`axios` 직접 호출 → 훅으로 캡슐화.

---

### 7-6. 훅 네이밍이 HTTP 메서드를 드러내지 않음

```
Bad: useProducts       (GET? POST? 모호)
Good: useGetProducts, useCreateProduct, useUpdateProduct, useDeleteProduct
```

---

### 7-7. DTO를 컴포넌트에서 직접 사용

`apis/`의 DTO 타입을 컴포넌트가 직접 import하면 apis 레이어에 결합된다. 훅에서 도메인 타입으로 변환하거나 alias로 re-export 해야 한다.

```tsx
// Bad — 컴포넌트가 DTO import
import type { ProductDTO } from 'apis/products';
function ProductCard({ product }: { product: ProductDTO }) { /* ... */ }

// Good — 훅에서 도메인 타입 export
// hooks/useGetProducts.ts
export type Product = { /* 프론트 친화 형태 */ };
// 컴포넌트
import type { Product } from 'hooks/useGetProducts';
```

---

## 8. 금지 패턴

### 8-1. God Component (300줄+)

단일 컴포넌트가 300줄을 넘으면 응집도·가독성 모두 위반. 역할을 분리해 쪼갠다.

**판단 기준**: 컴포넌트 파일이 300줄 이상이거나, 한 문장으로 역할 설명이 불가능하면 분리.

---

### 8-2. 페이지 컴포넌트에 비즈니스 로직

페이지는 조립만 담당한다. 로직은 훅·유틸로 이동.

```tsx
// Bad — 페이지가 계산/검증/API 호출
function CheckoutPage() {
  const [items, setItems] = useState([]);
  useEffect(() => { cartAPI.get().then(setItems); }, []);
  const total = items.reduce((s, i) => s + i.price * i.quantity, 0);
  const discount = total > 100000 ? total * 0.1 : 0;
  // ...
}

// Good — 페이지는 조립만
function CheckoutPage() {
  return (
    <AsyncBoundary>
      <CartSummary />
      <PaymentForm />
    </AsyncBoundary>
  );
}
```

---

### 8-3. `any` 타입 사용

TypeScript strict 모드 필수. `any` 대신 `unknown` + 타입 가드를 사용한다.

---

### 8-4. 매 렌더마다 새 Promise 생성 (Suspense 내부)

```tsx
// Bad — 매 렌더마다 새 Promise → 무한 서스펜드 루프
<Suspense fallback={<Skeleton />}>
  <Component data={fetchData()} />  {/* 렌더마다 새 호출 */}
</Suspense>

// Good — 캐싱 레이어 사용
<Suspense fallback={<Skeleton />}>
  <Component />  {/* 내부에서 useSuspenseQuery 사용 */}
</Suspense>
```

---

### 8-5. 프로덕션에 스택 트레이스 노출

`error.stack`을 그대로 렌더링하면 보안·UX 모두 위반. 사용자 친화적 메시지로 변환하고, 스택은 로깅으로만 남긴다.

---

## 빠른 체크리스트 요약

| # | 축 | 체크 항목 | 핵심 질문 |
|---|---|----------|----------|
| 1 | 가독성 | 분기별 코드 분리 | 한 컴포넌트에 독립적 분기가 2개 이상? |
| 2 | 가독성 | 구현 상세 추상화 | 컴포넌트 핵심 책임과 무관한 로직이 내부에? |
| 3 | 가독성 | 합쳐진 함수 쪼개기 | Hook이 3개 이상 독립 상태를 관리? |
| 4 | 가독성 | 조건에 이름 붙이기 | &&/\|\| 2개 이상 조합된 이름 없는 조건식? |
| 5 | 가독성 | 매직 넘버 이름 | 의미 불명확한 숫자 리터럴? |
| 6 | 가독성 | 시점 이동 줄이기 | 로직 파악에 3곳 이상 이동 필요? |
| 7 | 가독성 | 삼항 연산자 | 2단계 이상 중첩? |
| 8 | 가독성 | 비교 순서 | 범위 비교가 왼->오 순서가 아닌? |
| 9 | 예측 가능성 | 이름 충돌 | 래퍼가 원본과 같은 이름? |
| 10 | 예측 가능성 | 반환 타입 통일 | 같은 패턴 함수의 반환 타입 불일치? |
| 11 | 예측 가능성 | 숨은 부수효과 | 이름으로 예측 불가한 side effect? |
| 12 | 응집도 | 디렉토리 구조 | 기능 수정 시 3+ 디렉토리를 건드림? |
| 13 | 응집도 | 매직 넘버 (응집도) | 같은 의미 숫자가 2곳 이상 흩어져? |
| 14 | 응집도 | 폼 응집도 | 필드 간 의존성에 맞는 접근 방식? |
| 15 | 결합도 | 단일 책임 | 반환값의 일부만 사용하는 곳이 많은? |
| 16 | 결합도 | 중복 허용 | 공유 코드에 페이지별 분기가 늘어남? |
| 17 | 결합도 | Props Drilling | props 3단계 이상 전달, 중간이 미사용? |
| 18 | 구조 | Atomic Design | atoms/molecules에 외부 의존 있음? |
| 19 | 구조 | 페이지 로컬 | 페이지 전용 코드가 공통에 있음? |
| 20 | 구조 | Provider 위치 | Provider가 components/ 에 섞임? |
| 21 | 에러로딩 | ErrorBoundary 계층 | 계층적 바운더리 없이 단일/과도? |
| 22 | 에러로딩 | Suspense 페어링 | ErrorBoundary 없는 Suspense? |
| 23 | 에러로딩 | useSuspenseQuery | v5인데 `suspense: true` 쓰는지? |
| 24 | 에러로딩 | AsyncBoundary | 3중 중첩이 반복됨? |
| 25 | 에러로딩 | 스켈레톤 크기 | 실제 콘텐츠와 크기 불일치? |
| 26 | 에러로딩 | 낙관적 롤백 | onError/onSettled 누락? |
| 27 | 에러로딩 | 비동기 에러 | 로컬 useState로 처리? |
| 28 | 데이터패칭 | debounce 위치 | React 훅 또는 fetch 자체에 적용? |
| 29 | 데이터패칭 | signal 전달 | queryFn의 signal을 fetch에 전달? |
| 30 | 데이터패칭 | abortRef | 직접 fetch 시 ref 없이 매번 생성? |
| 31 | 데이터패칭 | AbortError | 에러로 처리? |
| 32 | 데이터패칭 | 직접 fetch | 컴포넌트에서 apis/fetch 직접 호출? |
| 33 | 데이터패칭 | 훅 네이밍 | HTTP 메서드가 이름에 드러나는가? |
| 34 | 데이터패칭 | DTO 사용 | 컴포넌트가 DTO 타입 직접 import? |
| 35 | 금지 | God Component | 300줄+ 단일 컴포넌트? |
| 36 | 금지 | 페이지 로직 | 페이지에 비즈니스 로직 직접 배치? |
| 37 | 금지 | any 타입 | any 사용? |
| 38 | 금지 | 매 렌더 Promise | Suspense 내부에서 새 Promise? |
| 39 | 금지 | 스택 트레이스 | 프로덕션에 노출? |
