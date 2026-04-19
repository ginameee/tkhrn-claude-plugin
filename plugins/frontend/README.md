# frontend plugin

React/FE 개발을 위한 통합 플러그인. **변경하기 쉬운 코드**를 위한 4축(가독성·예측 가능성·응집도·결합도)을 중심으로 한다.

## 포함된 스킬

| 스킬 | 트리거 | 용도 |
|---|---|---|
| `frontend-init` | 수동 | 신규 프로젝트 부트스트랩 — 대화형 스택 결정 + 구조·보일러플레이트 생성 (Next.js App Router / Vite+React) |
| `frontend-rules` | 자동 (React 컴포넌트 작성·리뷰 시) | 에러/로딩/데이터패칭/디렉터리 핵심 규칙 |
| `frontend-design` | 수동 (`/frontend-design`) | 5-phase 대화형 설계 (요구사항 → 컴포넌트 트리 → 데이터 흐름 → 4축 검토 → 산출물) |
| `frontend-review` | 수동 (`/frontend-review`) | 4축 + 구조 + 에러/로딩 + 데이터패칭 종합 코드 리뷰 |
| `frontend-a11y-perf` | 수동 | WCAG 2.1 AA 접근성 + 성능 요약 + 반응형 검토 |
| `frontend-vitals` | 수동 | Core Web Vitals 심화 — LCP/INP/CLS 각 지표별 측정·원인·개선·디버깅 워크플로우 (파일 단위 분리) |
| `frontend-seo` | 수동 | 메타·OG·JSON-LD·URL 구조·네비게이션(`<a>` vs `router.push`)·렌더링 전략·사이트맵 (Next.js App Router 중심) |

## 포함된 MCP

| MCP | 용도 |
|---|---|
| `playwright` | 브라우저 자동화 (E2E, 스크린샷, 폼 입력, 접근성 검증) |

## 설치

```
/plugin marketplace add ginameee/tkhrn-claude-plugin
/plugin install frontend@tkhrn-plugins
```

## 철학

좋은 프론트엔드 코드는 **변경하기 쉬운 코드**다. 이를 위해 네 축을 항상 동시에 고려한다:

| 축 | 판단 기준 |
|---|---|
| **가독성** | 처음 보는 동료가 빠르게 의도를 파악할 수 있는가 |
| **예측 가능성** | 이름·파라미터·리턴만 보고 동작을 예측할 수 있는가 |
| **응집도** | 함께 변경되는 코드가 함께 모여 있는가 |
| **결합도** | 하나를 변경할 때 관련 없는 곳까지 수정해야 하는가 |
