# Schema.org JSON-LD 레퍼런스

페이지 타입별 구조화 데이터 예시. 모든 예시는 **JSON-LD** 형식이며 `<script type="application/ld+json">`으로 삽입한다.

> 공식 문서: https://schema.org/ · Google 가이드: https://developers.google.com/search/docs/appearance/structured-data

## 공통 규칙

- `@context`는 항상 `https://schema.org`
- URL·이미지는 **절대 URL**
- 날짜는 **ISO 8601** (`2025-04-19T10:30:00+09:00`)
- 가격은 숫자 (`"price": 39000`) 또는 문자열 (`"price": "39000"`) — 문자열 권장
- 통화는 ISO 4217 (`KRW`, `USD`)
- **화면에 표시되지 않는 정보를 스키마에 넣지 않는다** (Google 스팸 정책 위반)

---

## 1. Organization (루트 레이아웃)

사이트 운영 주체 정보. 전 페이지 공통.

```json
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "name": "브랜드명",
  "url": "https://example.com",
  "logo": "https://example.com/logo.png",
  "sameAs": [
    "https://www.instagram.com/브랜드",
    "https://www.youtube.com/@브랜드",
    "https://x.com/브랜드"
  ],
  "contactPoint": {
    "@type": "ContactPoint",
    "telephone": "+82-2-1234-5678",
    "contactType": "customer service",
    "availableLanguage": ["Korean", "English"]
  }
}
```

## 2. WebSite + SearchAction

사이트 검색 박스(Sitelinks Searchbox) 노출. 루트에 1회.

```json
{
  "@context": "https://schema.org",
  "@type": "WebSite",
  "url": "https://example.com",
  "name": "브랜드명",
  "potentialAction": {
    "@type": "SearchAction",
    "target": {
      "@type": "EntryPoint",
      "urlTemplate": "https://example.com/search?q={search_term_string}"
    },
    "query-input": "required name=search_term_string"
  }
}
```

## 3. BreadcrumbList

경로 표시. 홈 제외 **모든 하위 페이지**에 삽입.

```json
{
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  "itemListElement": [
    { "@type": "ListItem", "position": 1, "name": "홈", "item": "https://example.com" },
    { "@type": "ListItem", "position": 2, "name": "카테고리", "item": "https://example.com/category" },
    { "@type": "ListItem", "position": 3, "name": "서브카테고리", "item": "https://example.com/category/sub" },
    { "@type": "ListItem", "position": 4, "name": "현재 페이지" }
  ]
}
```

> 마지막 항목은 `item` 생략 가능 (현재 페이지 자기 참조).

## 4. Article / BlogPosting / NewsArticle

블로그 글·뉴스·칼럼.

```json
{
  "@context": "https://schema.org",
  "@type": "BlogPosting",
  "headline": "글 제목 (110자 이내)",
  "description": "글 요약",
  "image": ["https://example.com/articles/abc/hero-1x1.jpg", "https://example.com/articles/abc/hero-4x3.jpg", "https://example.com/articles/abc/hero-16x9.jpg"],
  "datePublished": "2025-04-10T09:00:00+09:00",
  "dateModified": "2025-04-15T14:30:00+09:00",
  "author": {
    "@type": "Person",
    "name": "작성자 이름",
    "url": "https://example.com/authors/abc"
  },
  "publisher": {
    "@type": "Organization",
    "name": "브랜드명",
    "logo": { "@type": "ImageObject", "url": "https://example.com/logo.png" }
  },
  "mainEntityOfPage": { "@type": "WebPage", "@id": "https://example.com/blog/abc" }
}
```

**체크**: `image`는 3가지 비율(1:1, 4:3, 16:9) 권장. Google 리치 결과에 유리.

## 5. Product + Offer + AggregateRating

커머스 상품.

```json
{
  "@context": "https://schema.org",
  "@type": "Product",
  "name": "상품명",
  "image": ["https://example.com/products/abc-1.jpg"],
  "description": "상품 설명",
  "sku": "ABC-001",
  "brand": { "@type": "Brand", "name": "브랜드명" },
  "offers": {
    "@type": "Offer",
    "url": "https://example.com/products/abc",
    "priceCurrency": "KRW",
    "price": "39000",
    "availability": "https://schema.org/InStock",
    "itemCondition": "https://schema.org/NewCondition",
    "priceValidUntil": "2025-12-31"
  },
  "aggregateRating": {
    "@type": "AggregateRating",
    "ratingValue": "4.7",
    "reviewCount": "128"
  }
}
```

**`availability` 값**:
- `https://schema.org/InStock`
- `https://schema.org/OutOfStock`
- `https://schema.org/PreOrder`
- `https://schema.org/Discontinued`

**주의**: `aggregateRating`은 **실제 리뷰가 페이지에 표시될 때만** 포함. 리뷰 없이 넣으면 스팸 처리.

## 6. Review (개별 리뷰)

```json
{
  "@context": "https://schema.org",
  "@type": "Review",
  "itemReviewed": {
    "@type": "Product",
    "name": "상품명"
  },
  "reviewRating": {
    "@type": "Rating",
    "ratingValue": "5",
    "bestRating": "5"
  },
  "author": { "@type": "Person", "name": "리뷰어 이름" },
  "datePublished": "2025-03-20",
  "reviewBody": "리뷰 본문"
}
```

## 7. FAQPage

FAQ·도움말 페이지. 검색 결과에 펼칠 수 있는 Q&A 노출.

```json
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "배송은 얼마나 걸리나요?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "평일 기준 1–3일 소요됩니다."
      }
    },
    {
      "@type": "Question",
      "name": "반품은 어떻게 하나요?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "주문 후 14일 이내에 마이페이지에서 반품 신청이 가능합니다."
      }
    }
  ]
}
```

**주의**: 2023년 이후 FAQ 리치 결과 표시 범위가 축소됨. 정부·의료·공식 사이트에서만 표시될 수 있음. 구조화 데이터 자체는 유효.

## 8. HowTo

단계별 가이드.

```json
{
  "@context": "https://schema.org",
  "@type": "HowTo",
  "name": "방법 제목",
  "description": "전체 요약",
  "totalTime": "PT15M",
  "step": [
    { "@type": "HowToStep", "position": 1, "name": "1단계", "text": "1단계 설명", "image": "https://example.com/step-1.jpg" },
    { "@type": "HowToStep", "position": 2, "name": "2단계", "text": "2단계 설명" }
  ]
}
```

**주의**: FAQ와 마찬가지로 2023년 이후 리치 결과 범위 축소.

## 9. Event

이벤트·공연·세미나.

```json
{
  "@context": "https://schema.org",
  "@type": "Event",
  "name": "이벤트명",
  "startDate": "2025-05-10T14:00:00+09:00",
  "endDate": "2025-05-10T18:00:00+09:00",
  "eventStatus": "https://schema.org/EventScheduled",
  "eventAttendanceMode": "https://schema.org/OfflineEventAttendanceMode",
  "location": {
    "@type": "Place",
    "name": "장소명",
    "address": {
      "@type": "PostalAddress",
      "streetAddress": "...",
      "addressLocality": "서울",
      "postalCode": "04524",
      "addressCountry": "KR"
    }
  },
  "image": ["https://example.com/events/abc.jpg"],
  "description": "이벤트 설명",
  "offers": {
    "@type": "Offer",
    "url": "https://example.com/events/abc",
    "price": "0",
    "priceCurrency": "KRW",
    "availability": "https://schema.org/InStock",
    "validFrom": "2025-04-01T00:00:00+09:00"
  }
}
```

## 10. Recipe

레시피.

```json
{
  "@context": "https://schema.org",
  "@type": "Recipe",
  "name": "김치찌개",
  "image": ["https://example.com/recipes/kimchi-stew.jpg"],
  "author": { "@type": "Person", "name": "작성자" },
  "datePublished": "2025-04-10",
  "description": "간단 레시피 설명",
  "prepTime": "PT10M",
  "cookTime": "PT20M",
  "totalTime": "PT30M",
  "recipeYield": "2인분",
  "recipeCategory": "메인",
  "recipeCuisine": "한식",
  "nutrition": { "@type": "NutritionInformation", "calories": "450 kcal" },
  "recipeIngredient": ["김치 200g", "두부 1모", "돼지고기 100g"],
  "recipeInstructions": [
    { "@type": "HowToStep", "name": "재료 손질", "text": "...", "image": "..." },
    { "@type": "HowToStep", "name": "끓이기", "text": "..." }
  ]
}
```

## 11. LocalBusiness

지역 기반 사업체 (음식점·매장 등).

```json
{
  "@context": "https://schema.org",
  "@type": "Restaurant",
  "name": "식당명",
  "image": ["https://example.com/store/hero.jpg"],
  "url": "https://example.com",
  "telephone": "+82-2-1234-5678",
  "priceRange": "₩₩",
  "address": {
    "@type": "PostalAddress",
    "streetAddress": "...",
    "addressLocality": "서울",
    "postalCode": "04524",
    "addressCountry": "KR"
  },
  "geo": { "@type": "GeoCoordinates", "latitude": 37.5665, "longitude": 126.9780 },
  "openingHoursSpecification": [
    {
      "@type": "OpeningHoursSpecification",
      "dayOfWeek": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"],
      "opens": "11:00",
      "closes": "22:00"
    }
  ],
  "servesCuisine": "한식",
  "menu": "https://example.com/menu"
}
```

`@type`은 `Restaurant` 외에 `Store`, `Dentist`, `Hotel` 등 [LocalBusiness 서브타입](https://schema.org/LocalBusiness) 사용.

## 12. VideoObject

페이지에 임베드된 동영상.

```json
{
  "@context": "https://schema.org",
  "@type": "VideoObject",
  "name": "동영상 제목",
  "description": "동영상 설명",
  "thumbnailUrl": ["https://example.com/thumb-16x9.jpg"],
  "uploadDate": "2025-04-10T09:00:00+09:00",
  "duration": "PT3M45S",
  "contentUrl": "https://example.com/videos/abc.mp4",
  "embedUrl": "https://www.youtube.com/embed/abc"
}
```

---

## 검증 체크리스트

- [ ] [Rich Results Test](https://search.google.com/test/rich-results) 통과
- [ ] [Schema.org Validator](https://validator.schema.org/) 오류 0
- [ ] 페이지 화면에 표시되는 정보와 스키마 내용 일치
- [ ] 이미지·URL이 절대 경로
- [ ] 동일 타입이 여러 개면 Graph 사용 (`"@graph": [...]`)
- [ ] JSON 유효성 (trailing comma, 따옴표)

## 여러 스키마 동시 삽입 (Graph)

한 페이지에 Organization + WebPage + BreadcrumbList + Product를 함께 넣을 때:

```json
{
  "@context": "https://schema.org",
  "@graph": [
    { "@type": "Organization", "@id": "https://example.com/#org", "name": "...", "url": "..." },
    { "@type": "WebSite", "@id": "https://example.com/#website", "url": "...", "publisher": { "@id": "https://example.com/#org" } },
    { "@type": "BreadcrumbList", "itemListElement": [...] },
    { "@type": "Product", "name": "...", "offers": {...} }
  ]
}
```

`@id`로 객체 간 참조를 하면 중복 선언이 줄고 관계가 명시적이 된다.
