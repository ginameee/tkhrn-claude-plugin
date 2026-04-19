# tkhrn-claude-plugin

ginameee 의 Claude Code 플러그인 마켓플레이스.

## 포함된 플러그인

| 플러그인 | 설명 |
|---|---|
| [`frontend`](plugins/frontend) | React/FE 4축 기반 개발 규칙·설계 인터랙션·코드 리뷰·접근성/성능 + Playwright MCP |

## 설치

### 원격 마켓플레이스로 설치

```
/plugin marketplace add ginameee/tkhrn-claude-plugin
/plugin install frontend@tkhrn-plugins
```

### 로컬 개발 중 설치

```
/plugin marketplace add /path/to/tkhrn-claude-plugin
/plugin install frontend@tkhrn-plugins
```

## 업데이트

```
/plugin marketplace update tkhrn-plugins
/plugin update frontend@tkhrn-plugins
```

## 구조

```
tkhrn-claude-plugin/
├── .claude-plugin/
│   └── marketplace.json     # 마켓플레이스 카탈로그
└── plugins/
    └── frontend/            # frontend 플러그인
        ├── .claude-plugin/plugin.json
        ├── .mcp.json        # Playwright
        └── skills/
            ├── frontend-rules/        # 자동 적용 규칙
            ├── frontend-design/       # 대화형 설계
            ├── frontend-review/       # 코드 리뷰
            └── frontend-a11y-perf/    # 접근성·성능
```
