# devlog plugin

Claude Code 대화를 Astro 블로그([vibe-devlog](https://github.com/jangchunlee/vibe-devlog))로 정리·발행하는 플러그인.

## 아키텍처

```
Claude Code 대화
    ↓  (/devlog-post 또는 "블로그에 올려줘")
devlog-post 스킬
    ↓  범위 선정 → 초안 작성 → 🚨 민감정보 스크러빙 → 메타데이터 제안 → 사용자 확인
MCP tool: process_blog_content
    ↓
@ginameee/tkhrn-devlog-mcp (로컬 npx)
    ↓  (credentials from OS keychain)
AWS Lambda (blog-lambda)
    ↓
GitHub API (PR 생성)
    ↓
GitHub Actions → S3 배포
```

## 구성

| 항목 | 내용 |
|---|---|
| **Skill** | `devlog-post` — 수동 호출 (`/devlog-post`) + 대화형 ("블로그에 올려줘") |
| **MCP** | `devlog` — `@ginameee/tkhrn-devlog-mcp` npx 실행 |
| **Credentials** | OS keychain (setup 1회), env var fallback 지원 |

## 설치 (사용자 관점)

### 1. 마켓플레이스 추가
```
/plugin marketplace add ginameee/tkhrn-claude-plugin
```

### 2. devlog 플러그인 설치
```
/plugin install devlog@tkhrn-plugins
```

### 3. MCP credentials 설정 (최초 1회)
```bash
npx @ginameee/tkhrn-devlog-mcp setup
```

대화형으로 두 값 입력:
- `BLOG_LAMBDA_URL` — AWS Lambda Function URL
- `LAMBDA_API_KEY` — Lambda 측 auth 에 사용할 API key

입력값은 **OS keychain에 암호화 저장**되고, 이후 `.mcp.json` 이나 shell env 에 평문 저장할 필요 없음.

### 4. Claude Code 재시작
MCP가 활성화되고 `process_blog_content` tool 사용 가능.

## 사용법

### 수동 호출
```
/devlog-post "Claude Code 플러그인 마켓플레이스 만들기"
```

### 대화형
```
지금까지 대화한 React Suspense 부분만 블로그에 정리해서 올려줘
```

### 스킬이 하는 일
1. 포스팅 범위 확인
2. 블로그 포스트로 재구성 (대화체 → 서술체, 섹션 분할)
3. 🚨 민감정보 스크러빙 — API 키·토큰·절대 경로·이메일·내부 URL 자동 제거
4. 메타데이터 제안 (제목·요약·태그)
5. 프리뷰 + 사용자 확인
6. `process_blog_content` 호출 → PR URL 반환
7. GitHub에서 수동 리뷰·머지 → Actions 자동 배포

자세한 워크플로우는 [skills/devlog-post/SKILL.md](skills/devlog-post/SKILL.md).

## 민감정보 관리

### 원칙
- **`.mcp.json`에 credential 없음** — keychain에서 해석
- **레포에 credential 평문 저장 금지**
- **대화 내용을 포스팅하기 전 자동 스크러빙**

### Credential 해석 우선순위
1. OS keychain (setup 완료 후)
2. `BLOG_LAMBDA_URL` / `LAMBDA_API_KEY` 환경변수 (fallback, CI·일회성)
3. 없으면 명확한 에러 + setup 안내

### 회전·리셋
```bash
# 키 변경 / 다른 Lambda 전환
npx @ginameee/tkhrn-devlog-mcp setup --reset
```

## 문제 해결

| 증상 | 원인 | 조치 |
|---|---|---|
| `credential not found` | setup 미실행 | `npx @ginameee/tkhrn-devlog-mcp setup` |
| `401 / 403` | API key 불일치 | `setup --reset` 후 재입력 |
| `Lambda timeout` | 콜드 스타트 또는 장애 | 재시도, CloudWatch 확인 |
| `PR already exists` | 브랜치명 충돌 (드뭄) | 잠시 후 재시도 또는 기존 PR 정리 |
| tool 호출 실패 | Claude Code 재시작 필요 | 재시작 후 `/plugin list` 로 확인 |

## 연관 스킬

- `frontend-seo` — 공개 포스트의 메타·OG 이미지 설계
- `frontend-review` — 포스트 내 코드 스니펫 품질 점검
- `frontend-vitals` — 블로그 자체 성능 진단

## 개발·배포 상태

- **MCP 패키지**: `@ginameee/tkhrn-devlog-mcp` — 별도 레포 `tkhrn-devlog-mcp` 에서 관리·publish
- **Lambda**: `vibe-devlog` 레포의 `lambda/` 디렉토리
- **블로그**: [jangchunlee/vibe-devlog](https://github.com/jangchunlee/vibe-devlog) (Astro, S3 정적 호스팅)

## 보안 주의

이 플러그인의 MCP는 사용자의 Lambda endpoint를 호출합니다. **Lambda 측 인증이 견고해야** (API key 검증·rate limiting·IAM) 무단 포스팅을 방지할 수 있습니다. Lambda URL이 노출되더라도 API key 없이는 호출 불가능해야 안전합니다.
