# 테스트 작성 패턴 (Playwright)

`SKILL.md` Phase 3·4에서 참조. 안정적이고 사용자 관점에 충실한 E2E 테스트를 쓰기 위한 규칙·패턴 모음.

---

## 0. 핵심 원칙

1. **사용자 관점** — DOM 구조나 구현이 아니라 "사용자가 보고 누르는 것"을 기준으로 단언
2. **결정론적** — 같은 입력이면 항상 같은 결과. 시간·순서·이전 상태 의존 금지
3. **격리** — 각 `test()`는 단독 실행 가능. 다른 테스트가 만든 데이터 가정 금지
4. **빠른 실패** — 실패 시 어디서·왜 실패했는지 즉시 보이도록. 안개 같은 sleep 금지

---

## 1. 셀렉터 우선순위

| 순위 | 메서드 | 사용 예 |
|---|---|---|
| 1 | `getByRole` | `page.getByRole('button', { name: '로그인' })` |
| 2 | `getByLabel` | `page.getByLabel('이메일')` |
| 3 | `getByPlaceholder` | `page.getByPlaceholder('비밀번호')` |
| 4 | `getByText` | `page.getByText('환영합니다')` (정확 매치 시 `{ exact: true }`) |
| 5 | `getByTestId` | `page.getByTestId('submit-btn')` (a11y 셀렉터가 모두 부적합할 때) |
| 6 | CSS / XPath | 마지막 수단 |

### Bad / Good

```typescript
// ❌ 구현 결합·취약
await page.locator('div.login-form > form > button:nth-child(3)').click();
await page.locator('#__next > div > div > main > button').click();

// ✅ 사용자 관점·안정적
await page.getByRole('button', { name: '로그인' }).click();
```

### 다중 매칭 처리

```typescript
// 같은 role + name이 여러 개일 때
await page.getByRole('button', { name: '삭제' }).first().click();  // 좋지 않음 (의도 불명확)

// 컨텍스트로 좁히기 (권장)
const row = page.getByRole('row', { name: '항목 1' });
await row.getByRole('button', { name: '삭제' }).click();
```

---

## 2. Web-first Assertion (자동 대기 내장)

`expect(locator).toXxx()` 형태는 자동으로 폴링하며 기다린다. **`waitForTimeout`·`setTimeout` 금지**.

```typescript
// ❌ 하드 sleep — 느리고 불안정
await page.waitForTimeout(2000);
expect(await page.locator('.toast').isVisible()).toBe(true);

// ✅ web-first assertion — 자동 대기, 빠르고 안정
await expect(page.getByRole('alert')).toBeVisible();
await expect(page.getByRole('alert')).toHaveText('저장되었습니다');
```

자주 쓰는 단언:

| 의도 | 단언 |
|---|---|
| 보임 | `toBeVisible()` |
| 안 보임 / 사라짐 | `toBeHidden()` / `not.toBeVisible()` |
| 텍스트 일치 | `toHaveText('...')` (정확) / `toContainText('...')` (포함) |
| 입력값 | `toHaveValue('...')` |
| 활성/비활성 | `toBeEnabled()` / `toBeDisabled()` |
| 체크 | `toBeChecked()` |
| URL | `await expect(page).toHaveURL(/\/dashboard/)` |
| 타이틀 | `await expect(page).toHaveTitle(/.../)` |
| 개수 | `await expect(locator).toHaveCount(3)` |

### 임의 조건 폴링

```typescript
await expect.poll(async () => (await api.getOrders()).length, {
  timeout: 10_000,
  intervals: [500, 1000, 2000],
}).toBeGreaterThan(0);
```

---

## 3. 액션의 자동 대기

`click`·`fill` 등은 actionability(보임·안정·활성·hit-testable·편집 가능)를 자동 검증 후 실행한다. 명시적 대기를 줄이는 핵심 메커니즘.

```typescript
// ❌ 불필요한 대기 추가
await page.waitForSelector('button.submit');
await page.locator('button.submit').click();

// ✅ click 자체가 actionability를 기다림
await page.getByRole('button', { name: '제출' }).click();
```

예외적 대기가 필요한 곳:
- **네트워크 응답을 기다린 뒤 단언**: `page.waitForResponse(/\/api\/order/)`
- **네비게이션 동반 액션**: `Promise.all([page.waitForURL(...), btn.click()])` 또는 그냥 `expect(page).toHaveURL(...)`로 충분
- **다운로드**: `page.waitForEvent('download')`

---

## 4. 테스트 격리와 fixture

### 기본 격리

```typescript
import { test, expect } from '@playwright/test';

test.describe('로그인', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/login');
  });

  test('정상 로그인', async ({ page }) => { ... });
  test('빈 입력 시 에러', async ({ page }) => { ... });
});
```

### 인증 상태 재사용 (storageState)

로그인 케이스 자체를 검증하는 테스트가 아니라면, 매번 UI로 로그인하지 말고 **저장된 인증 상태를 재사용**한다.

`e2e/fixtures/auth.fixture.ts`:

```typescript
import { test as base, expect } from '@playwright/test';

type AuthFixtures = {
  authenticatedPage: import('@playwright/test').Page;
};

export const test = base.extend<AuthFixtures>({
  authenticatedPage: async ({ browser }, use) => {
    const context = await browser.newContext({
      storageState: 'e2e/.auth/user.json',
    });
    const page = await context.newPage();
    await use(page);
    await context.close();
  },
});

export { expect };
```

전역 셋업으로 `user.json`을 한 번만 만든다. `playwright.config.ts`에 `globalSetup` 추가:

```typescript
// e2e/global-setup.ts
import { chromium, FullConfig } from '@playwright/test';

export default async function globalSetup(config: FullConfig) {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.goto(`${config.projects[0].use.baseURL}/login`);
  await page.getByLabel('이메일').fill(process.env.E2E_USER_EMAIL!);
  await page.getByLabel('비밀번호').fill(process.env.E2E_USER_PASSWORD!);
  await page.getByRole('button', { name: '로그인' }).click();
  await page.waitForURL('**/dashboard');
  await page.context().storageState({ path: 'e2e/.auth/user.json' });
  await browser.close();
}
```

`.gitignore`에 `e2e/.auth/` 추가.

> 단, **로그인 자체를 테스트하는 케이스**는 storageState 없이 fresh context로 실행해야 한다.

---

## 5. Page Object Model (POM)

같은 페이지를 **3개 이상의 테스트**에서 다루면 도입. 미만이면 인라인이 더 단순.

`e2e/pages/login.page.ts`:

```typescript
import { Page, Locator } from '@playwright/test';

export class LoginPage {
  readonly page: Page;
  readonly emailInput: Locator;
  readonly passwordInput: Locator;
  readonly submitButton: Locator;
  readonly errorAlert: Locator;

  constructor(page: Page) {
    this.page = page;
    this.emailInput = page.getByLabel('이메일');
    this.passwordInput = page.getByLabel('비밀번호');
    this.submitButton = page.getByRole('button', { name: '로그인' });
    this.errorAlert = page.getByRole('alert');
  }

  async goto() {
    await this.page.goto('/login');
  }

  async login(email: string, password: string) {
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);
    await this.submitButton.click();
  }
}
```

사용:

```typescript
test('잘못된 비밀번호 시 에러', async ({ page }) => {
  const login = new LoginPage(page);
  await login.goto();
  await login.login('user@test.com', 'wrong');
  await expect(login.errorAlert).toContainText('비밀번호가 올바르지 않습니다');
});
```

### POM 원칙

- **DOM 셀렉터는 POM 안에만** — 테스트 파일에서 `getByRole(...)` 직접 호출 금지
- **단언은 테스트 파일에** — POM은 동작 제공, 단언은 호출자가
- **너무 많은 헬퍼 금지** — `clickButtonAndWaitForToast()` 같은 한 번 쓰는 헬퍼는 인라인이 낫다

---

## 6. 네트워크 제어

### 응답 대기

```typescript
test('상품 추가 후 목록 갱신', async ({ page }) => {
  await page.goto('/products');
  const responsePromise = page.waitForResponse(/\/api\/products$/);
  await page.getByRole('button', { name: '상품 추가' }).click();
  await responsePromise;
  await expect(page.getByRole('row')).toHaveCount(11);
});
```

### 모킹

```typescript
test('서버 에러 시 토스트 표시', async ({ page }) => {
  await page.route('**/api/orders', (route) => {
    route.fulfill({ status: 500, body: JSON.stringify({ error: 'server' }) });
  });
  await page.goto('/orders');
  await expect(page.getByRole('alert')).toContainText('일시적인 오류');
});
```

> 모킹은 **부정 시나리오·외부 의존 격리**가 목적. 정상 플로우까지 모킹하면 E2E의 가치(통합 검증)가 사라진다.

---

## 7. 테스트 데이터

### 동적 생성 (권장)

```typescript
test('새 글 작성', async ({ page }) => {
  const title = `테스트 글 ${Date.now()}`;
  await page.goto('/posts/new');
  await page.getByLabel('제목').fill(title);
  await page.getByRole('button', { name: '게시' }).click();
  await expect(page.getByRole('heading', { name: title })).toBeVisible();
});
```

### Fixture로 정리

매 테스트가 자기 데이터를 만들면, **자기 데이터를 정리**해야 한다. `afterEach` 또는 fixture의 cleanup 단계에서 API로 삭제.

```typescript
const test = base.extend<{ post: { id: string; title: string } }>({
  post: async ({ request }, use) => {
    const created = await request.post('/api/posts', {
      data: { title: `테스트 ${Date.now()}` },
    });
    const post = await created.json();
    await use(post);
    await request.delete(`/api/posts/${post.id}`);
  },
});
```

---

## 8. 디버깅·관찰성

### UI 모드 (가장 강력)

```bash
pnpm test:e2e:ui
```

타임라인·DOM 스냅샷·네트워크·콘솔을 한 화면에서.

### Trace

`playwright.config.ts`에서 `trace: 'on-first-retry'` 권장. 실패 시 `playwright-report/`에서 trace 뷰어로 단계별 재생.

### Debug 모드

```bash
pnpm test:e2e:debug --grep "로그인"
```

Playwright Inspector로 단계별 실행.

### 콘솔·네트워크 캡처

```typescript
test.beforeEach(async ({ page }) => {
  page.on('console', (msg) => {
    if (msg.type() === 'error') console.error('Browser error:', msg.text());
  });
  page.on('pageerror', (err) => console.error('Page error:', err));
});
```

---

## 9. 안티패턴

### ❌ Hard sleep
```typescript
await page.waitForTimeout(3000);  // 느리고 불안정
```
→ `await expect(...).toBeVisible()` 또는 `waitForResponse`

### ❌ 구현 디테일 셀렉터
```typescript
await page.locator('div.MuiBox-root.css-1abcdef').click();
```
→ `getByRole`·`getByLabel`로 교체

### ❌ 테스트 간 순서 의존
```typescript
test('1. 회원가입', ...);
test('2. 로그인 (위 가입 계정으로)', ...);  // 1번이 실패하면 2번도 실패
```
→ 각 테스트가 자체적으로 fixture·API로 사전 데이터 마련

### ❌ Page reload로 상태 초기화
```typescript
await page.reload();
await page.waitForTimeout(1000);  // 복합 안티패턴
```
→ `goto`로 새 진입, 또는 fixture로 fresh context

### ❌ Conditional 테스트
```typescript
if (await page.getByText('로그인').isVisible()) {
  await page.getByText('로그인').click();
}
```
→ 분기 자체가 시나리오면 별도 `test()`로 분리. 같은 테스트 안에서 if는 의도 불명.

### ❌ DOM 구조 단언
```typescript
const html = await page.locator('main').innerHTML();
expect(html).toContain('<button class="primary">');
```
→ `await expect(page.getByRole('button', { name: '...' })).toBeVisible()`

### ❌ console.log로 디버깅 흔적 남기기
→ 작업 끝나면 제거. 임시 디버그는 `test.only` + UI 모드.

---

## 10. 실패 시 점검 순서 (Phase 4 분류 A 보조)

테스트가 실패할 때 다음 순서로 의심:

1. **셀렉터** — 같은 role+name이 여러 개? 동적으로 변하는 텍스트?
2. **타이밍** — actionability가 안 잡히는 비표준 컴포넌트? (예: `pointer-events: none` 잔존)
3. **상태** — 이전 테스트의 잔여 데이터? localStorage·쿠키·서버 데이터?
4. **환경** — `baseURL` 일치? dev 서버 빌드 캐시? 시간대(`process.env.TZ`)?
5. **명세 가정** — Phase 2 탐색에서 본 것과 실제가 다른가? → **분류 B로 이동, 사용자 확인**

`trace.zip` + 스크린샷·비디오를 먼저 본다. 그 다음 코드 의심.

---

## 11. CI 고려 (참고용, 별도 작업)

이 스킬 범위 밖이지만 작성 시 염두:

- `forbidOnly: !!process.env.CI` — `test.only` 누락 방지
- `retries: 2` — flaky 케이스 임시 완충 (근본 해결 후 제거)
- `workers: 1` (CI) — 자원 한정 + 안정성. 로컬은 병렬
- `reporter: 'github'` (GitHub Actions) — PR에 직접 표시
- artifact: `test-results/`, `playwright-report/`, `trace.zip` 업로드

---

## 12. 빠른 참조: 좋은 테스트의 형태

```typescript
import { test, expect } from '@playwright/test';
import { LoginPage } from '../pages/login.page';

test.describe('로그인 플로우', () => {
  test('유효한 자격 증명으로 대시보드 진입', async ({ page }) => {
    const login = new LoginPage(page);
    await login.goto();
    await login.login('user@test.com', 'correct-password');

    await expect(page).toHaveURL(/\/dashboard/);
    await expect(page.getByRole('heading', { name: '환영합니다' })).toBeVisible();
  });

  test('빈 이메일 제출 시 검증 에러', async ({ page }) => {
    const login = new LoginPage(page);
    await login.goto();
    await login.submitButton.click();

    await expect(login.errorAlert).toContainText('이메일을 입력해주세요');
  });
});
```

특징:
- ✅ `getByRole`·`getByLabel` 기반 셀렉터 (POM 안에 캡슐화)
- ✅ Web-first assertion (`toHaveURL`·`toBeVisible`·`toContainText`)
- ✅ 사용자 관점 단언 (URL·문구·요소 표시)
- ✅ 각 테스트가 독립 (login.goto부터 시작)
- ✅ `waitForTimeout` 없음
