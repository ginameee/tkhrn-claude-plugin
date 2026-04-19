---
name: devlog-post
description: Claude Code 대화(또는 그 일부)를 Astro 블로그(vibe-devlog) 포스트로 정리해 게시. 사용자가 지정한 범위만 대상으로 초안 작성 → 민감정보 스크러빙 → 메타데이터(제목·요약·태그) 제안 → 사용자 확인 → `process_blog_content` MCP 호출로 GitHub PR 생성. 수동 슬래시(`/devlog-post`) 호출과 대화형 호출("블로그에 올려줘") 모두 지원.
---

# DevLog Post

Claude Code에서 나눈 대화를 블로그 포스트로 정제해 `@ginameee/tkhrn-devlog-mcp` MCP를 통해 게시한다. **수동 호출 전용** — 자동 트리거 없음.

## 전제 조건

**첫 실행 전 반드시 1회 수행** (그렇지 않으면 MCP tool 호출이 credential 에러로 실패):

```bash
npx @ginameee/tkhrn-devlog-mcp setup
```

- 대화형으로 `BLOG_LAMBDA_URL` / `LAMBDA_API_KEY` 입력
- OS keychain에 저장 (macOS Keychain / Windows Credential Manager / Linux libsecret)
- 이후 Claude Code가 MCP를 spawn 할 때마다 자동 해석

설정 변경: `npx @ginameee/tkhrn-devlog-mcp setup --reset`

## 사용 시점

- **수동 호출**: `/devlog-post [범위 또는 주제]`
- **대화형**: "지금까지 대화를 블로그에 정리해서 올려줘", "이 세션의 React 관련 부분만 포스팅해줘"

자동 포스팅은 하지 않는다. 사용자가 명시적으로 요청할 때만.

---

## Phase 1: 범위 확인

**원칙**: 사용자가 지정한 범위만 대상. 범위가 명확하지 않으면 **먼저 질문**.

### 1-1. `$ARGUMENTS` / 대화 힌트 파싱

| 사용자 표현 | 해석 |
|---|---|
| "지금까지 대화" / "이 세션" | 현재 세션 전체 |
| "방금 다룬 X" / "X 부분만" | 특정 주제 필터링 |
| "최근 N개 메시지" | 메시지 개수 지정 |
| "도입부터 Y까지" | 범위 지정 |
| 주제 키워드만 제공 | 해당 주제 관련 부분 추려내기 |

### 1-2. 범위 불명확 시 질문

```markdown
어떤 범위를 포스트로 올릴까요?
1. 이 세션 전체 요약
2. 특정 주제 — 어떤 주제인지 알려주세요
3. 특정 메시지 범위 — 시작~끝 지점 지정
4. 이미 작성한 내용(초안·메모)을 넘겨줄게요
```

### 1-3. 블로그 성격 판단

사용자 블로그(`jangchunlee/vibe-devlog`)는 **기술·개발 관련 devlog**. 범위가 기술 콘텐츠와 거리가 멀면(예: 단순 잡담, 일정 조율) 확인:

> "이 내용은 기술 블로그와 결이 조금 달라 보입니다. 그대로 진행할까요, 아니면 기술적 관점으로 재해석할까요?"

---

## Phase 2: 초안 작성 + 🚨 보안 스크러빙

### 2-1. 구조화

대화 원문을 그대로 올리지 않는다. **블로그 포스트로 재구성**:

| 블로그 섹션 | 대화에서 뽑을 것 |
|---|---|
| **도입** (문제·배경) | 초기 질문·동기 |
| **본문 — 접근·시도** | 논의된 접근법, 대안, 트레이드오프 |
| **결론 — 해결·결과** | 채택된 방식, 동작 확인 |
| **배운 점·Takeaways** (선택) | 의사결정 근거, 예상 밖 발견 |
| **참고** (선택) | 대화에 등장한 링크·자료 |

- 코드 블록·인용·단계별 설명은 보존
- 대화체(~해주세요, ~할까요)는 **서술체/객관체**로 전환
- 중복·사담·맥락 없는 메시지 제거
- 제목·헤딩 3~5개로 정리 (H1 자동 생성, 본문엔 H2/H3만)

### 2-2. 🚨 민감정보 자동 스크러빙 체크리스트

**포스팅 전 반드시 수행**. 발견 즉시 제거·마스킹·사용자 확인:

| 카테고리 | 패턴·예시 | 조치 |
|---|---|---|
| **API 키·토큰** | `ghp_*`, `sk-*`, AWS access key (`AKIA*`), JWT, 32+ 길이 hex/base64 | **즉시 제거** + 사용자에게 "발견된 비밀이 있어 제거했습니다" 안내 |
| **비밀번호·시크릿** | `password=`, `secret=`, `.env` 값 | 제거 |
| **절대 경로** | `/Users/chun/...`, `C:\Users\...` | `~/`, `<project>/` 로 치환 |
| **Lambda URL** | `*.lambda-url.*.amazonaws.com`, 서명된 URL | 제거 또는 `<lambda-url>` placeholder |
| **개인 식별 정보** | 이메일, 전화번호, 주민번호, 신용카드 | 제거 또는 가명 |
| **내부 엔드포인트** | 사설 도메인, 내부 IP (10.*, 192.168.*) | 제거 |
| **Git 원격 주소(private)** | private repo URL | 확인 후 제거 결정 |
| **SSH 키·인증서** | `-----BEGIN`, `ssh-rsa` 로 시작하는 블록 | 즉시 제거 |
| **데이터베이스 DSN** | `postgresql://user:pass@...` | 제거 |

**원칙**: 의심되면 **제거가 디폴트**. 사용자가 "이건 남겨도 돼"라고 할 때만 복원.

스크러빙 수행 후 사용자에게 보고:
```markdown
## 스크러빙 결과
- API 키 패턴 2건 발견 → 제거
- 절대 경로 3건 → `~/` 로 치환
- 이메일 1건 → 제거
```

### 2-3. 길이·품질 기준

- 최소 300자, 권장 800~2500자
- 너무 짧으면 "이 범위로는 포스트 분량이 부족합니다. 범위를 넓히거나 특정 관점으로 확장할까요?" 제안
- 단락 2~6문장, 코드 블록엔 언어 태그 (``` ts 등)

---

## Phase 3: 메타데이터 제안

MCP tool `process_blog_content` 에 넘길 값을 제안. MCP가 내부에서 frontmatter/파일명/브랜치를 생성하므로 Claude는 **핵심 3개만** 결정:

### 3-1. `title` (string, 필수)

- **SEO 친화 + 구체적** — "React 이야기" ❌ / "React Suspense + ErrorBoundary 중첩 시 주의할 점" ✅
- 40~70자 권장
- 한/영 혼용은 자연스럽게 (영문 용어는 원문 유지)
- 클릭베이트·과장 금지 ("충격적", "반드시 알아야 할" 등 사용 안 함)

### 3-2. `excerpt` (string, 필수)

- 1~2문장, 120~160자
- **무엇을 다루는지 + 누가 읽으면 좋은지** 드러나게
- 본문 첫 단락 복붙 금지 — 별도 요약

### 3-3. `tags` (string[], 선택)

- 3~5개
- 소문자·kebab-case 또는 간단한 한글 (`react`, `typescript`, `성능최적화`)
- 너무 일반(`coding`, `development`)하거나 너무 세부(`react-18.3.1-specific`)는 피함
- 기존 블로그 태그와 일관성 유지 (이미 쓰던 태그면 재사용)

---

## Phase 4: 프리뷰 + 사용자 확인

**포스팅 전 반드시 확인 받기**. 자동 진행 금지.

출력 형식:

```markdown
## 📝 블로그 포스트 프리뷰

### 메타데이터
- **제목**: {title}
- **요약**: {excerpt}
- **태그**: {tags.join(', ')}

### 스크러빙 결과
{스크러빙 리포트}

### 본문 (마크다운)
\`\`\`markdown
{content}
\`\`\`

---

### 다음 중 선택
1. ✅ **이대로 게시** — MCP 호출해서 PR 생성
2. ✏️ **제목/요약/태그 수정** — 수정할 부분 알려주세요
3. ✏️ **본문 수정** — 특정 섹션 고치기
4. ❌ **취소**
```

수정 요청이 있으면 해당 부분만 반영하고 다시 프리뷰. 루프.

---

## Phase 5: 게시 (MCP 호출)

사용자 승인 후 `process_blog_content` tool 호출:

```ts
// 의사코드
await mcp.call('process_blog_content', {
  title,         // string
  excerpt,       // string
  content,       // string (마크다운 본문)
  tags,          // string[] | undefined
});
```

### 실패 처리

| 에러 | 원인 추정 | 사용자 안내 |
|---|---|---|
| `credential not found` | setup 미실행 | "`npx @ginameee/tkhrn-devlog-mcp setup` 먼저 실행해주세요" |
| `401 / 403 from Lambda` | API key 불일치·만료 | "keychain 의 API 키가 Lambda와 일치하는지 확인. 필요하면 `setup --reset`" |
| 네트워크 에러 | Lambda URL 오타·장애 | "URL 재확인 또는 AWS 콘솔에서 Lambda 상태 확인" |
| `PR already exists` | 같은 브랜치명 충돌 (드뭄) | "잠시 후 재시도 또는 기존 PR 먼저 정리" |

---

## Phase 6: 사후 안내

성공 응답 예시:
```json
{
  "status": "success",
  "prUrl": "https://github.com/jangchunlee/vibe-devlog/pull/123",
  "branchName": "blog-post/1700000000000",
  "filename": "2025-04-19-my-post.md",
  "message": "PR created successfully!"
}
```

사용자에게:
```markdown
## ✅ 게시 완료

- **PR**: {prUrl}
- **브랜치**: {branchName}
- **파일명**: {filename}

### 다음 단계
1. GitHub에서 PR 리뷰·머지
2. GitHub Actions가 자동 빌드·배포
3. 몇 분 내 블로그에 반영

관련 스킬:
- `frontend-seo` — 게시 전 메타/OG 이미지 추가하려면
- `frontend-review` — 포스트 내 코드 스니펫 품질 점검
```

---

## 원칙

1. **사용자 명시적 승인 없이 게시 금지** — Phase 4 통과 필수
2. **민감정보는 제거가 디폴트** — Phase 2-2 스크러빙 철저히
3. **대화 원문 그대로 옮기지 않는다** — 블로그 포스트로 재구성
4. **범위 임의 확대 금지** — 사용자가 지정한 범위만
5. **메타데이터는 제안, 최종 결정은 사용자** — 자동 게시 금지
6. **내부 프로젝트·상품·전략 관련 내용** 발견 시 사용자에게 공개 여부 확인
7. **실패 시 재시도보다 진단** — 같은 에러 반복 금지
8. **MCP tool 시그니처 준수** — 추가 파라미터 임의 주입 금지

---

## MCP Tool 스펙 (참조)

### `process_blog_content`

| 파라미터 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `title` | string | ✅ | 포스트 제목 |
| `excerpt` | string | ✅ | 요약 1~2문장 |
| `content` | string | ✅ | 마크다운 본문 (frontmatter 제외, MCP가 생성) |
| `tags` | string[] | ❌ | 태그 배열 |

### 응답

```ts
{
  status: 'success' | 'error',
  prUrl?: string,        // 성공 시
  branchName?: string,
  filename?: string,
  message?: string,
  error?: string,        // 실패 시
}
```

실제 아키텍처: MCP → AWS Lambda → GitHub API (PR 생성) → GitHub Actions → S3 배포.  
**blog 레포**: `jangchunlee/vibe-devlog` (Astro). 포스트 저장 경로 `src/content/posts/YYYY-MM-DD-slug.md`.

---

## 예시 호출 시나리오

### 시나리오 A: 세션 전체 요약

```
User: /devlog-post

Claude: 이 세션 전체를 포스트로 올리겠습니다. 주제는 "Claude Code 플러그인 마켓플레이스 구축" 으로 정리할까요?
  - 포함될 핵심 섹션: 마켓플레이스 구조, MCP 번들링, 민감정보 관리
  - 제외 후보: 초기 탐색 잡담, 오타 수정
  
User: 좋아

Claude: [Phase 2~4 진행, 프리뷰 제공]

User: 제목 "Claude Code 플러그인 마켓플레이스 처음부터 만들기" 로 바꿔줘

Claude: [수정 후 재프리뷰]

User: 게시해줘

Claude: [MCP 호출] → PR URL 반환
```

### 시나리오 B: 특정 주제만

```
User: 오늘 논의한 Core Web Vitals 부분만 블로그에 올려줘

Claude: [CWV 관련 메시지만 추출 → Phase 2~ 진행]
```

### 시나리오 C: 초안 제공

```
User: 내가 쓴 초안이야. 이걸 포스트로 다듬어서 올려줘.
[초안 붙여넣기]

Claude: [스크러빙 + 메타데이터 제안 + 프리뷰]
```
