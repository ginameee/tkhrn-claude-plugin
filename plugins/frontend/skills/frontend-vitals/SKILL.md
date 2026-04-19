---
name: frontend-vitals
description: Core Web Vitals(LCP/INP/CLS) 전용 심화 스킬. 각 지표별 정의·목표값·측정 방법·원인 진단·개선 전략·디버깅 워크플로우를 파일 단위로 제공. 성능 이슈 진단·PageSpeed 점수 개선·배포 전 체크·Lighthouse 리포트 분석 시 수동 호출.
disable-model-invocation: true
---

# Frontend Core Web Vitals

Google 검색 랭킹 요소이자 실사용자 체감 품질을 결정하는 **3대 Core Web Vitals** 지표를 진단·개선한다.

| 지표 | 의미 | Good | Needs Improvement | Poor | 상세 |
|---|---|---|---|---|---|
| **LCP** (Largest Contentful Paint) | 주요 콘텐츠 표시 시점 | ≤ 2.5초 | 2.5–4.0초 | > 4.0초 | [lcp.md](lcp.md) |
| **INP** (Interaction to Next Paint) | 상호작용 → 화면 반영 | ≤ 200ms | 200–500ms | > 500ms | [inp.md](inp.md) |
| **CLS** (Cumulative Layout Shift) | 누적 레이아웃 이동 | ≤ 0.1 | 0.1–0.25 | > 0.25 | [cls.md](cls.md) |

> 목표값은 **75th percentile of page loads** 기준 (상위 25%가 Poor 이하 허용). 2024년 3월부터 FID는 INP로 공식 대체됨.

## 보조 지표

일차적이진 않지만 CWV를 진단할 때 함께 봐야 한다.

| 지표 | 의미 | 목표 | 역할 |
|---|---|---|---|
| **TTFB** (Time to First Byte) | 서버 첫 바이트 도착 | ≤ 800ms | LCP의 하한선 결정 |
| **FCP** (First Contentful Paint) | 첫 콘텐츠 표시 | ≤ 1.8초 | LCP의 선행 지표 |
| **TBT** (Total Blocking Time) | 메인 스레드 블로킹 합 | ≤ 200ms | INP의 lab 대리 지표 |

## Lab vs Field

Core Web Vitals는 **두 가지 측정 방식**이 있고, 결과가 크게 다를 수 있다.

| 구분 | Lab 데이터 | Field 데이터 (RUM) |
|---|---|---|
| **예** | Lighthouse, PageSpeed Insights "Performance" 섹션 | CrUX, Google Search Console, web-vitals.js + GA/RUM |
| **환경** | 시뮬레이션 (4G / 저사양 CPU) | 실제 사용자 기기·네트워크 |
| **통계** | 단일 실행 | 28일 이동 평균 (CrUX) |
| **INP** | ❌ 측정 불가 (상호작용 없음) | ✅ 주 측정 방식 |
| **권장 용도** | 원인 진단, 회귀 테스트 | 랭킹 판단, 우선순위 결정 |

**원칙**: 실제 개선 판단은 **field 데이터(CrUX)** 기준. lab 데이터는 디버깅용.

측정 도구 상세는 [measurement.md](measurement.md) 참조.

---

## 사용 시점

- PageSpeed Insights / Search Console에서 CWV 경고 발생 시
- 주요 페이지 배포 전 성능 회귀 점검
- 특정 지표 수치가 Poor/Needs Improvement로 떨어졌을 때 원인 진단
- Lighthouse 점수를 높여야 하는 마케팅·랜딩 페이지
- 새 라이브러리·이미지 포맷·폰트 도입 전후 영향도 평가

## 진단 프로세스

대상 페이지가 주어지면 다음 순서로 진행한다:

1. **현재 상태 수집**
   - PageSpeed Insights 실행 → lab + field 수치 확인
   - Chrome DevTools Performance 녹화
   - Search Console > Core Web Vitals 보고서
2. **어느 지표가 문제인가 식별**
   - 지표별 상세 파일([lcp.md](lcp.md) / [inp.md](inp.md) / [cls.md](cls.md)) 확인
3. **원인 가설 수립**
   - 상세 파일의 "주요 원인" 체크리스트 점검
4. **개선 적용**
   - 우선순위 순으로 변경
5. **재측정 + 회귀 방지**
   - 동일 조건에서 before/after 비교
   - 배포 후 field 데이터 28일 관찰

## 출력 형식

```markdown
## Core Web Vitals 진단 결과

### 대상
- URL: [페이지]
- 측정 환경: Lab (Lighthouse 모바일) / Field (CrUX 28일)

### 현재 지표
| 지표 | Lab | Field (p75) | 상태 |
|---|---|---|---|
| LCP | 3.2s | 2.8s | ⚠️ Needs Improvement |
| INP | - | 180ms | ✅ Good |
| CLS | 0.05 | 0.12 | ⚠️ Needs Improvement |
| TTFB | 620ms | 580ms | ✅ Good |

### 원인 분석
- **LCP**: [구체적 원인 + 위치]
- **CLS**: [구체적 원인 + 위치]

### 개선 우선순위
1. [높음] [항목] — 예상 개선폭: [수치]
2. [중간] ...
3. [낮음] ...

### 검증 방법
[재측정 시점·도구·기준]
```

## 원칙

- **측정 → 진단 → 개선 → 재측정 순환** — 추측 기반 최적화 금지
- **Field > Lab** — 최종 판단은 실제 사용자 데이터 기준
- **상위 1–2개 병목 집중** — 동시에 10개 고치려 하지 않는다
- **회귀 방지** — 개선 후 동일 경로 재진입 시 수치 유지 확인
- **트레이드오프 명시** — 번들 분할 = 추가 요청, preload = 다른 리소스와 대역폭 경쟁
- **p75 기준 사고** — "내 Mac에서 빠름"이 아닌 "75%의 실제 사용자가 Good" 목표

## 연결된 스킬

- `frontend-a11y-perf`: 번들 크기, 이미지 포맷, 코드 스플리팅 같은 **엔지니어링 관점**의 성능
- `frontend-seo`: CWV를 **검색 랭킹 요소**로서 참조
- `frontend-review`: 4축 관점에서 발견한 성능 안티패턴

이 스킬은 **지표 중심의 측정·진단·개선 사이클**에 특화한다.
