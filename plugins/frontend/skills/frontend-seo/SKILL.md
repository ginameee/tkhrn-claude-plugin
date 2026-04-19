---
name: frontend-seo
description: 검색 엔진 가시성 관점의 프론트엔드 점검. 메타 태그, Open Graph, JSON-LD 구조화 데이터, URL·네비게이션 구조, 렌더링 전략(SSR/SSG/ISR/CSR), Next.js Metadata API, 사이트맵. 새 페이지 작성·배포 전·PR 리뷰 시 수동 호출. a11y-perf와 중복되는 Core Web Vitals는 랭킹 요소로만 참조.
disable-model-invocation: true
---

# Frontend SEO

검색 엔진 **크롤러의 관점**에서 페이지를 점검한다. `frontend-a11y-perf`가 "사용자 관점"이라면, 이 스킬은 "Googlebot·검색 결과 페이지 관점"이다.

## 사용 시점

- 새 페이지·라우트 구현 전후
- 마케팅 랜딩·블로그·커머스 상품 페이지 작업
- 배포 전 메타 데이터·구조화 데이터 점검
- 검색 트래픽이 기대치보다 낮을 때 원인 진단
- PR 리뷰 시 SEO 관점 추가 점검

## 기본 전제

- **주 프레임워크**: Next.js App Router (RSC + `generateMetadata`)
- Pages Router / 비-Next 환경은 섹션별로 fallback 가이드 제공

---

## 1. 메타 기본

모든 인덱스 대상 페이지에 있어야 한다:

| 태그 | 목적 | 길이 권장 |
|---|---|---|
| `<title>` | 검색 결과 제목 | 50–60자 (모바일 기준 이하로 잘림) |
| `<meta name="description">` | 검색 결과 설명 | 150–160자 |
| `<link rel="canonical">` | 중복 URL 정규화 | 절대 URL, 자기 참조 원칙 |
| `<meta name="robots">` | 크롤링·인덱싱 정책 | `index,follow` / `noindex,nofollow` |
| `<html lang="ko">` | 콘텐츠 언어 | ISO 언어 코드 |

### Next.js App Router 예시

```tsx
// app/products/[slug]/page.tsx
import type { Metadata } from 'next';

export async function generateMetadata({ params }): Promise<Metadata> {
  const product = await getProduct(params.slug);
  return {
    title: `${product.name} | 브랜드명`,
    description: product.summary,
    alternates: { canonical: `/products/${params.slug}` },
    robots: { index: true, follow: true },
  };
}
```

### Pages Router (fallback)

```tsx
import Head from 'next/head';

export default function Page({ product }) {
  return (
    <>
      <Head>
        <title>{product.name} | 브랜드명</title>
        <meta name="description" content={product.summary} />
        <link rel="canonical" href={`https://example.com/products/${product.slug}`} />
      </Head>
      {/* ... */}
    </>
  );
}
```

### 체크리스트
- [ ] 페이지별 **고유한** title·description (템플릿 그대로 복붙 금지)
- [ ] 루트 레이아웃에 **사이트 기본값** `metadata` export로 fallback 제공
- [ ] canonical은 **절대 URL**, 동일 콘텐츠 중복 URL 병합
- [ ] 테스트·프리뷰·관리자 페이지는 `noindex,nofollow`
- [ ] 동적 경로(`[slug]`)는 `generateMetadata`로 페이지별 메타 생성

---

## 2. Open Graph / Twitter Cards

소셜 공유 미리보기에 영향. Google 검색 결과에도 일부 영향(특히 이미지).

| 태그 | 필수 | 비고 |
|---|---|---|
| `og:title` | ✅ | title과 달라도 됨 (더 매력적으로) |
| `og:description` | ✅ | meta description과 달라도 됨 |
| `og:image` | ✅ | 1200×630 권장, 절대 URL, 공개 접근 |
| `og:url` | ✅ | canonical과 동일 원칙 |
| `og:type` | ✅ | `website` / `article` / `product` |
| `og:site_name` | ⚪ | 사이트 전체 공통 |
| `twitter:card` | ✅ | `summary_large_image` 기본 |
| `twitter:site` | ⚪ | 공식 X 계정 |

### Next.js App Router 예시

```tsx
export const metadata: Metadata = {
  openGraph: {
    title: '상품명',
    description: '상품 요약',
    url: 'https://example.com/products/abc',
    images: [{ url: '/og/products/abc.png', width: 1200, height: 630 }],
    type: 'website',
    siteName: '브랜드명',
  },
  twitter: {
    card: 'summary_large_image',
    title: '상품명',
    description: '상품 요약',
    images: ['/og/products/abc.png'],
  },
};
```

### 체크리스트
- [ ] `og:image`가 **절대 URL**이고 인증 없이 접근 가능
- [ ] 동적 페이지는 `opengraph-image.tsx` / `generateMetadata`로 페이지별 OG 이미지
- [ ] `og:type`이 콘텐츠 성격과 일치 (블로그 글 = `article`)
- [ ] 이미지 비율 1.91:1 (1200×630), 파일 크기 < 5MB
- [ ] [opengraph.xyz](https://www.opengraph.xyz/) 또는 Facebook Sharing Debugger로 검증

---

## 3. 구조화 데이터 (JSON-LD)

검색 결과 리치 스니펫(별점, 가격, FAQ 펼침 등) 생성 근거. 페이지 타입별 스키마는 [schema-org.md](schema-org.md) 참조.

### 원칙

- **JSON-LD 우선**: Microdata·RDFa보다 JSON-LD 권장 (Google 공식 권장)
- **페이지 콘텐츠와 일치**: 화면에 없는 정보를 스키마에 넣지 않는다 (스팸 간주)
- **검증 필수**: 배포 전 [Rich Results Test](https://search.google.com/test/rich-results) 또는 [Schema.org Validator](https://validator.schema.org/)

### 자주 쓰는 타입

| 타입 | 용도 | 리치 결과 |
|---|---|---|
| `Organization` / `LocalBusiness` | 홈·About | 사이트 박스, 로고 |
| `WebSite` + `SearchAction` | 홈 | 사이트링크 검색 박스 |
| `BreadcrumbList` | 모든 하위 페이지 | 경로 표시 |
| `Article` / `BlogPosting` | 블로그·뉴스 | 헤드라인 카드 |
| `Product` + `Offer` + `AggregateRating` | 커머스 상품 | 가격·별점 |
| `FAQPage` | FAQ·도움말 | 펼침 질문 |
| `Recipe` | 레시피 | 조리 시간·이미지 |
| `Event` | 이벤트 | 날짜·장소 |

### Next.js App Router 삽입

```tsx
export default function ProductPage({ product }) {
  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'Product',
    name: product.name,
    image: [product.image],
    offers: {
      '@type': 'Offer',
      price: product.price,
      priceCurrency: 'KRW',
      availability: 'https://schema.org/InStock',
    },
  };
  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      {/* 페이지 내용 */}
    </>
  );
}
```

> `dangerouslySetInnerHTML`은 이 케이스에서 공식 권장 패턴 (React가 `<script>` 자식 텍스트를 렌더링하지 않기 때문).

### 체크리스트
- [ ] JSON-LD가 실제 페이지 콘텐츠와 일치
- [ ] 모든 하위 페이지에 `BreadcrumbList`
- [ ] 상품/리뷰 페이지에 `Product` + `Offer` + `AggregateRating` (리뷰가 있을 때만)
- [ ] 루트 레이아웃에 `Organization` + `WebSite`
- [ ] Rich Results Test 통과
- [ ] 화면에 없는 정보를 스키마에 넣지 않음 (ex. 존재하지 않는 별점)

---

## 4. URL 구조 & 네비게이션

### 4-1. URL 구조 원칙

| 원칙 | 설명 |
|---|---|
| **사람이 읽을 수 있게** | `/products/wireless-headphones` ✅ / `/p?id=12345` ⚠️ |
| **소문자 + kebab-case** | `/blog/how-to-x` ✅ / `/Blog/HowToX` ❌ |
| **계층을 반영** | `/category/sub-category/item` |
| **확장자·쿼리 최소화** | 정적 자원 외에는 `.html` 금지, 정렬/필터는 쿼리 OK |
| **트레일링 슬래시 일관성** | 전체 사이트에서 통일 (Next.js `trailingSlash` 설정) |
| **불변 URL** | 변경 시 **301 리다이렉트** 필수 |

---

### 4-2. 네비게이션 — `<a>` / `<Link>` 필수, `onClick + router.push` 금지

검색 크롤러는 `href` 속성만 따라간다. `onClick` 핸들러에서 `router.push()`를 호출하는 방식은 **크롤러가 링크를 발견하지 못하므로 인덱싱 대상에서 누락**된다. 사용자 측면에서도:

- 🚫 Cmd/Ctrl + 클릭으로 새 탭 열기 불가
- 🚫 우클릭 → "새 창으로 열기" 불가
- 🚫 링크 호버 시 브라우저 상태바에 URL 미표시
- 🚫 북마크·공유 기능 깨짐
- 🚫 스크린 리더가 "링크"가 아닌 "버튼"으로 읽음 (문맥 오류)

#### Next.js

```tsx
// ❌ Bad — 크롤러가 못 따라감
import { useRouter } from 'next/navigation';
function ProductCard({ id }) {
  const router = useRouter();
  return (
    <div onClick={() => router.push(`/products/${id}`)} style={{ cursor: 'pointer' }}>
      {/* ... */}
    </div>
  );
}

// ✅ Good — 실제 <a href>로 렌더링됨
import Link from 'next/link';
function ProductCard({ id }) {
  return (
    <Link href={`/products/${id}`}>
      {/* ... */}
    </Link>
  );
}

// ✅ Good — 카드 전체를 링크로 감싸고 내부에 버튼/링크가 있으면 nested 방지
function ProductCard({ id, onFavorite }) {
  return (
    <article className="card">
      <Link href={`/products/${id}`} className="card-link" aria-label="상품 상세">
        {/* 이미지·제목 */}
      </Link>
      <button onClick={onFavorite}>찜</button>  {/* 카드 밖 또는 position:relative로 overlay 분리 */}
    </article>
  );
}
```

#### React Router

```tsx
// ❌ Bad
const navigate = useNavigate();
<div onClick={() => navigate('/about')}>About</div>

// ✅ Good
import { Link } from 'react-router-dom';
<Link to="/about">About</Link>
```

#### 예외 — 프로그램 이동이 정당한 경우

**`router.push` / `navigate()`는 "클릭 가능한 요소"가 아닌 플로우 제어에만** 사용한다:

```tsx
// ✅ 폼 제출 후 리다이렉트 (클릭 요소 아님)
async function onSubmit(data) {
  await submitForm(data);
  router.push('/thank-you');
}

// ✅ 로그인 성공 후 이동
useEffect(() => {
  if (isAuthenticated) router.push('/dashboard');
}, [isAuthenticated]);

// ✅ 프로그래매틱 가드 (권한 없으면 이동)
if (!hasAccess) router.push('/403');
```

**판단 기준**:
- 사용자가 **클릭해서 이동하는 요소** → 반드시 `<Link>` / `<a href>`
- 폼 제출·타이머·조건 충족 등 **자동 이동** → `router.push` OK

---

### 4-3. 내부 링크 전략

- 중요 페이지는 **여러 내부 링크**로 도달 가능해야 한다 (orphan page 방지)
- 앵커 텍스트는 **목적지 콘텐츠를 드러냄** — "여기를 클릭" ❌ / "상품 상세 보기" ✅
- 같은 페이지로 가는 링크가 여러 개면 **가장 중요한 앵커 텍스트 하나를 기준**으로 통일 (Google의 first-link-counts)

### 4-4. 외부 링크

```tsx
<a href="https://..." target="_blank" rel="noopener noreferrer">외부 사이트</a>
```

- `rel="noopener"`: 보안 (탭 탈취 방지)
- `rel="noreferrer"`: 프라이버시
- 스폰서/광고 링크: `rel="sponsored"` 또는 `rel="nofollow"`

### 체크리스트
- [ ] 클릭 가능한 네비게이션 요소가 모두 `<Link>` / `<a href>` 기반
- [ ] `onClick + router.push` 패턴이 없는가 (이동 버튼·카드·메뉴 전수 확인)
- [ ] URL이 kebab-case + 계층 반영
- [ ] 트레일링 슬래시 정책 통일
- [ ] 변경된 URL에 301 리다이렉트 설정
- [ ] 외부 링크에 `rel="noopener noreferrer"`

---

## 5. 렌더링 전략 선택

콘텐츠 성격별로 렌더링 방식을 선택한다. **크롤러가 JS 실행 없이도 HTML을 볼 수 있는가**가 SEO 관점의 핵심.

| 전략 | SEO 친화도 | 적합한 페이지 |
|---|---|---|
| **SSG (Static)** | ⭐⭐⭐⭐⭐ | 블로그·마케팅·문서 (변경 드묾) |
| **ISR (Incremental)** | ⭐⭐⭐⭐⭐ | 커머스 상품·뉴스 (주기적 갱신) |
| **SSR (Server)** | ⭐⭐⭐⭐ | 개인화 콘텐츠·실시간 가격 |
| **CSR (Client)** | ⭐⭐ | 로그인 필요 대시보드·앱 내부 |

### Next.js App Router 결정 트리

```
페이지가 인덱싱 대상인가?
├─ 아니오 (대시보드·마이페이지·관리자) → CSR 또는 noindex
└─ 예
   ├─ 콘텐츠가 자주 바뀌는가?
   │  ├─ 거의 안 바뀜 → SSG (기본값, `generateStaticParams`)
   │  ├─ 주기적 (수 분~수 시간) → ISR (`export const revalidate = 3600`)
   │  └─ 요청마다 다름 (개인화/실시간) → SSR (`export const dynamic = 'force-dynamic'`)
   └─ RSC 기본값(Static) 사용
```

### 체크리스트
- [ ] 인덱싱 대상 페이지는 **서버에서 HTML을 반환**한다 (View Page Source로 콘텐츠 확인)
- [ ] CSR-only 페이지는 `noindex` 처리
- [ ] `use client` 남용으로 서버 렌더링이 깨지지 않았는가
- [ ] ISR `revalidate` 주기가 콘텐츠 신선도에 맞는가

---

## 6. 사이트맵 & robots.txt

### sitemap.xml

Next.js App Router:

```tsx
// app/sitemap.ts
import type { MetadataRoute } from 'next';

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const products = await getAllProducts();
  return [
    { url: 'https://example.com', lastModified: new Date(), changeFrequency: 'daily', priority: 1 },
    { url: 'https://example.com/blog', changeFrequency: 'weekly', priority: 0.8 },
    ...products.map(p => ({
      url: `https://example.com/products/${p.slug}`,
      lastModified: p.updatedAt,
      changeFrequency: 'weekly' as const,
      priority: 0.7,
    })),
  ];
}
```

### robots.txt

```tsx
// app/robots.ts
import type { MetadataRoute } from 'next';

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      { userAgent: '*', allow: '/', disallow: ['/admin', '/api', '/preview'] },
    ],
    sitemap: 'https://example.com/sitemap.xml',
  };
}
```

### 체크리스트
- [ ] 인덱싱 대상 URL이 사이트맵에 모두 포함
- [ ] `noindex` 페이지는 사이트맵에서 **제외**
- [ ] 5만 URL / 50MB 초과 시 사이트맵 인덱스로 분할
- [ ] `robots.txt`에 사이트맵 URL 명시
- [ ] Google Search Console에 사이트맵 제출

---

## 7. 기타 랭킹 요소 (상호 참조)

이 스킬에선 체크리스트만 나열하고, 상세는 다른 스킬을 참조한다.

- **Core Web Vitals (LCP / INP / CLS)** → `frontend-a11y-perf`
- **접근성 (키보드·대비·시맨틱 HTML)** → `frontend-a11y-perf`
- **모바일 친화성 (반응형·터치 타겟)** → `frontend-a11y-perf`
- **HTTPS / 혼합 콘텐츠** → 인프라 영역
- **페이지 경험 신호** → 위 4개 항목 종합

---

## 검토 프로세스

SEO 리뷰 대상이 주어지면:

1. **크롤러 시뮬레이션**
   - View Page Source로 콘텐츠가 HTML에 있는지 확인
   - 메타 태그·canonical·robots 확인
2. **구조화 데이터 검증**
   - Rich Results Test 실행
3. **네비게이션 감사**
   - 모든 이동 요소가 `<a>` / `<Link>` 기반인지 grep (`router.push`, `navigate(` 의 onClick 용법)
4. **URL 구조 감사**
   - 리다이렉트 체인, 소문자 일관성, 트레일링 슬래시
5. **사이트맵·robots 검증**

## 출력 형식

```markdown
## SEO 리뷰 결과

### 메타 기본
- ✅ / ⚠️ [항목] — [근거]

### Open Graph
- ✅ / ⚠️ [항목]

### 구조화 데이터
- ✅ / ⚠️ [타입/위치] — [Rich Results Test 결과]

### URL & 네비게이션
- ✅ / ⚠️ [항목] — [파일:라인]

### 렌더링 전략
- ✅ / ⚠️ [페이지] — [현재 전략 vs 권장]

### 사이트맵 / robots
- ✅ / ⚠️ [항목]

### 개선 우선순위
1. [높음] [항목] — [근거]
2. [중간] ...
```

## 원칙

- **검증 없이는 단정하지 않는다** — Rich Results Test, View Page Source 같은 실제 도구로 확인
- **크롤러 관점 > 개발자 관점** — "저는 봤으니까 괜찮다"는 CSR에서는 틀릴 수 있다
- **과장·스팸 금지** — 키워드 스터핑, 보이지 않는 텍스트, 스키마와 콘텐츠 불일치는 역효과
- **측정 후 개선** — Google Search Console의 실제 인덱싱·쿼리 데이터를 우선 신뢰
