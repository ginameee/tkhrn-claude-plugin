# tkhrn-claude-plugin

ginameee 의 Claude Code 플러그인 마켓플레이스.

## 포함된 플러그인

| 플러그인 | 설명 |
|---|---|
| [`frontend`](plugins/frontend) | React/FE 4축 기반 개발 규칙·설계 인터랙션·코드 리뷰·접근성/성능 + SEO + Core Web Vitals + Playwright E2E + MCP |
| [`devlog`](plugins/devlog) | Claude Code 대화를 Astro 블로그(vibe-devlog)로 정리·발행 — 내부 MCP + Lambda + GitHub PR 파이프라인 (사전 setup 필요) |

## 설치

### 원격 마켓플레이스로 설치

```
/plugin marketplace add ginameee/tkhrn-claude-plugin
/plugin install frontend@tkhrn-plugins
/plugin install devlog@tkhrn-plugins    # 필요 시
```

### 로컬 개발 중 설치

```
/plugin marketplace add /path/to/tkhrn-claude-plugin
/plugin install frontend@tkhrn-plugins
```

### devlog 플러그인 추가 설정 (1회)

```bash
npx tkhrn-devlog-mcp setup
```

OS keychain 에 `BLOG_LAMBDA_URL` / `LAMBDA_API_KEY` 를 암호화 저장. 자세한 내용은 [plugins/devlog/README.md](plugins/devlog/README.md).

## 업데이트

```
/plugin marketplace update tkhrn-plugins
/plugin update frontend@tkhrn-plugins
```

## 구조

```
tkhrn-claude-plugin/
├── .claude-plugin/
│   └── marketplace.json          # 마켓플레이스 카탈로그
└── plugins/
    ├── frontend/                  # frontend 플러그인
    │   ├── .claude-plugin/plugin.json
    │   ├── .mcp.json              # Playwright
    │   └── skills/
    │       ├── frontend-init/
    │       ├── frontend-rules/
    │       ├── frontend-design/
    │       ├── frontend-review/
    │       ├── frontend-a11y-perf/
    │       ├── frontend-seo/
    │       ├── frontend-vitals/
    │       └── frontend-e2e/
    └── devlog/                    # devlog 플러그인
        ├── .claude-plugin/plugin.json
        ├── .mcp.json              # tkhrn-devlog-mcp
        └── skills/
            └── devlog-post/
```
