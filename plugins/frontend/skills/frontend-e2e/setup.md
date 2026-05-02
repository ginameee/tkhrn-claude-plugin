# Playwright 환경 세팅

`SKILL.md` Phase 1에서 호출. 환경이 없거나 부분적으로만 있는 프로젝트에 Playwright E2E 인프라를 구성한다.

---

## 1. 사전 점검

| 항목 | 확인 방법 | 누락 시 |
|---|---|---|
| 패키지 매니저 | `pnpm-lock.yaml` / `package-lock.json` / `yarn.lock` | 사용자 확인 |
| Node 버전 | `node -v` (≥ 18) | 사용자에게 안내 (절차 중단 X) |
| 개발 서버 명령 | `package.json` `scripts.dev` | 사용자에게 어떤 명령으로 띄우는지 질의 |
| baseURL | `dev` 실행 시 호스트·포트 (예: `http://localhost:3000`) | 사용자 입력 |

---

## 2. 의존성 설치

> 명령은 사용자에게 **안내만** 하고 실행은 사용자에게 맡긴다 (frontend-init과 동일 원칙). 단, 사용자가 "설치까지 해달라" 명시하면 실행.

```bash
# pnpm
pnpm add -D @playwright/test

# npm
npm i -D @playwright/test

# yarn
yarn add -D @playwright/test
```

브라우저 바이너리:

```bash
npx playwright install --with-deps chromium
# 모든 브라우저가 필요하면: npx playwright install --with-deps
```

> 처음에는 **chromium만** 설치를 권장. CI나 크로스 브라우저 요구가 명확해지면 그때 firefox·webkit 추가.

---

## 3. `playwright.config.ts` 생성

프로젝트 루트에 다음 파일을 생성. 주석 없는 깔끔한 버전:

```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: process.env.CI ? 'github' : 'html',
  use: {
    baseURL: process.env.E2E_BASE_URL ?? 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
  webServer: {
    command: 'pnpm dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
  },
});
```

### 사용자 환경에 맞춰 조정할 항목

| 항목 | 결정 기준 |
|---|---|
| `baseURL` | 사용자가 알려준 dev 서버 주소 (Vite는 보통 `http://localhost:5173`) |
| `webServer.command` | 사용자 패키지 매니저·dev 스크립트 (`pnpm dev` / `npm run dev` / `yarn dev`) |
| `webServer.url` | `baseURL`과 동일하게 |
| `projects` | 초기엔 chromium만. 모바일 뷰포트 테스트가 필요하면 `Mobile Chrome` 추가 |
| `testDir` | 기존 디렉토리 컨벤션이 있으면 거기 (`tests/e2e` 등) |

> ⚠️ **개발 서버를 항상 켜둔 채로 작업하는 팀**이면 `webServer` 블록을 빼고 사용자가 직접 띄우게 두는 것도 가능. 사용자에게 한 번 물어보는 게 안전.

---

## 4. 디렉토리 구조 생성

```
e2e/
├── auth/                   # 도메인별 그룹
│   └── .gitkeep
├── fixtures/               # 공통 fixture (인증·테스트 데이터)
│   └── .gitkeep
├── pages/                  # POM 클래스 (필요 시)
│   └── .gitkeep
├── utils/                  # 헬퍼·셀렉터 상수
│   └── .gitkeep
└── smoke.spec.ts           # 첫 동작 확인용 (Phase 1 종료 후 삭제 또는 유지)
```

> 기존에 `tests/e2e/`가 있으면 그쪽으로. 새로 시작이면 루트의 `e2e/`가 단순.

---

## 5. `.gitignore` 갱신

다음 항목이 없으면 추가:

```
# Playwright
/test-results/
/playwright-report/
/playwright/.cache/
/blob-report/
```

---

## 6. `package.json` 스크립트 추가

```json
{
  "scripts": {
    "test:e2e": "playwright test",
    "test:e2e:ui": "playwright test --ui",
    "test:e2e:debug": "playwright test --debug",
    "test:e2e:report": "playwright show-report"
  }
}
```

---

## 7. Smoke 테스트 (환경 동작 확인)

`e2e/smoke.spec.ts`:

```typescript
import { test, expect } from '@playwright/test';

test('홈페이지 로드', async ({ page }) => {
  await page.goto('/');
  await expect(page).toHaveURL(/.*/);  // baseURL 기준 어떤 페이지든 응답
});
```

실행:

```bash
pnpm test:e2e --grep "홈페이지 로드"
```

✅ pass면 환경 OK → Phase 2로 진행.
❌ fail이면 `webServer.command` / `baseURL` / 포트 충돌 점검.

---

## 8. 사용자 확인용 출력

세팅 완료 후 사용자에게 다음 형식으로 보고:

```markdown
## Playwright 환경 세팅 완료 ✅

### 생성된 파일
- `playwright.config.ts` (baseURL: http://localhost:3000)
- `e2e/` 디렉토리 (auth/ fixtures/ pages/ utils/)
- `e2e/smoke.spec.ts` (환경 동작 확인용 — 유지/삭제 선택)
- `.gitignore` 갱신
- `package.json` scripts 추가

### 다음 단계
1. 의존성 설치 (아직 안 했다면)
   \`\`\`bash
   pnpm add -D @playwright/test
   npx playwright install --with-deps chromium
   \`\`\`
2. Smoke 테스트로 환경 확인
   \`\`\`bash
   pnpm test:e2e
   \`\`\`
3. 통과하면 Phase 2 (시나리오 탐색)로 진행

테스트할 시나리오는 무엇인가요? (또는 `$ARGUMENTS`로 전달된 시나리오로 진행)
```

---

## 흔한 함정

- **`webServer` 시작 실패** — 사용자 dev 명령이 다른 디렉토리에서 실행되어야 하면 `cwd` 옵션 추가
- **포트 충돌** — `reuseExistingServer: true`인 상태에서 다른 프로세스가 같은 포트 점유 → 한 번 죽이고 재시도
- **Next.js dev의 느린 첫 컴파일** — `webServer.timeout`을 180_000 정도로 늘려둘 것
- **Vite의 비표준 포트** — `vite.config.ts`의 `server.port` 확인 후 `baseURL` 동기화
- **모노레포** — `webServer.command`를 `pnpm --filter web dev` 식으로

---

## 범위 밖 (이 스킬에서 다루지 않음)

- CI 파이프라인 통합 (GitHub Actions 등) — 별도 요청 시 진행
- 비주얼 회귀 테스트 (`toMatchSnapshot`) — 옵션. 사용자 명시 시
- API 레벨 모킹 라이브러리(MSW) 통합 — `page.route`로 충분, 필요 시 별도 검토
- 인증 토큰 관리 (1Password CLI 등) — 환경 변수 또는 storageState로 단순화
