# 설계 산출물 템플릿

Phase 5에서 아래 형식으로 설계 결과를 생성한다.

---

## 1. 요구사항 정리

```markdown
# [기능명] 설계 문서

## 기능 요약
- [한 줄 요약]

## 화면 상태
| 상태 | 설명 | UI |
|------|------|-----|
| 로딩 | [설명] | [스켈레톤/스피너] |
| 성공 | [설명] | [메인 콘텐츠] |
| 에러 | [설명] | [에러 메시지 + 복구 액션] |
| 빈 상태 | [설명] | [빈 상태 안내] |
| [기타] | [설명] | [UI] |

## 비즈니스 규칙
1. [규칙 1]
2. [규칙 2]
3. ...

## MVP 범위
- 포함: [항목]
- 제외 (추후 고려): [항목]
```

---

## 2. 컴포넌트 트리 + 파일 구조

```markdown
## 컴포넌트 트리

PageName
├── SectionA — [역할 한 줄] (atom/molecule/organism)
│   ├── ComponentA1 — [역할] (atom/molecule)
│   └── ComponentA2 — [역할] (atom/molecule)
└── SectionB — [역할 한 줄] (organism)
    ├── ComponentB1 — [역할] (molecule)
    └── ComponentB2 — [역할] (atom)

## 파일 구조

### 페이지 전용 코드
src/pages/{pageName}/
├── index.tsx                 — 페이지 (조립만)
├── _components/
│   ├── SectionA.tsx          — [역할]
│   └── SectionB.tsx          — [역할]
├── _hooks/
│   ├── use{Feature}.ts       — [역할] (비즈니스 로직/데이터 패칭)
│   └── use{Validation}.ts    — [역할]
├── _utils/
│   └── {util}.ts             — [역할] (페이지 전용 순수 유틸)
└── _types.ts                 — 페이지 전용 타입 + 상수 (as const)

### 공통 컴포넌트
src/components/
├── atoms/
│   └── {Component}.tsx       — [역할] (pure, 디자인시스템이 있으면 생략 가능)
├── molecules/
│   └── {Component}.tsx       — [역할] (pure)
├── organisms/
│   └── {Component}.tsx       — [역할] (비즈니스 로직/외부 의존)
├── boundaries/
│   └── {Boundary}.tsx        — [역할] (경계·가드·래퍼)
└── layouts/
    └── {Component}.tsx       — [역할] (composition only)

### 기타 공통
src/hooks/                    — 공통 훅
src/store/                    — 클라이언트 상태
src/providers/                — Provider 정의
src/utils/                    — 순수 유틸
src/apis/                     — API 함수 + DTO (endpoint path별 파일)
src/types/ or types.ts        — 공통 타입
src/constants/                — 공통 상수 (선택)
```

---

## 3. 데이터 흐름

```markdown
## API
| 엔드포인트 | 메서드 | 요청 DTO | 응답 DTO | 훅 이름 | 용도 |
|-----------|--------|---------|---------|--------|------|
| /api/... | GET | - | `ProductDTO[]` | `useGetProducts` | [설명] |
| /api/... | POST | `CreateProductDTO` | `ProductDTO` | `useCreateProduct` | [설명] |

## DTO → 도메인 타입 변환
| DTO (apis/) | 도메인 타입 (훅) | 변환 포인트 |
|------------|----------------|------------|
| `ProductDTO` | `Product` | price_in_cents → price, created_at → Date |
| `ReservationDTO` | `Reservation` | [동일 or alias] |

## 상태 분류
### 서버 상태 (TanStack Query, 훅 레이어)
- `useGetProducts()` → `{ data: Product[], isLoading, error }` — queryKey: `['products']`, staleTime: [값]
- `useCreateProduct()` → mutation — invalidate: `['products']`

### 클라이언트 상태 (로컬/Jotai/Zustand)
- [상태명]: [타입] — [용도]

### 상태 전이 (해당 시)
type {Feature}Status = 'idle' | 'processing' | 'success' | 'error';

## 이벤트 → 상태 변화
| 이벤트 | 트리거 | 상태 변화 | API 호출 |
|--------|--------|----------|---------|
| [이벤트] | [버튼 클릭 등] | [상태 A → B] | [엔드포인트] |
```

---

## 4. 핵심 결정 사항 & 트레이드오프

```markdown
## 핵심 결정
| 결정 | 선택 | 근거 | 대안 (선택하지 않은 이유) |
|------|------|------|----------------------|
| [주제] | [선택] | [근거] | [대안과 거부 이유] |

## 4축 검토 결과
| 축 | 상태 | 비고 |
|---|---|---|
| 가독성 | ✅ / ⚠️ | [설명] |
| 예측 가능성 | ✅ / ⚠️ | [설명] |
| 응집도 | ✅ / ⚠️ | [설명] |
| 결합도 | ✅ / ⚠️ | [설명] |
```

---

## 5. 구현 시 주의사항

```markdown
## 주의사항
1. [주의사항 1]
2. [주의사항 2]
3. ...

## 구현 순서 제안
1. [먼저 만들 것] — 이유: [근거]
2. [다음] — 이유: [근거]
3. ...
```
