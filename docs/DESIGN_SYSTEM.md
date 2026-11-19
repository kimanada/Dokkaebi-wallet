# 도깨비 지갑 — 디자인 시스템

## 1. 브랜드 콘셉트

**"도깨비 방망이의 풍요와 행운, 현대의 지갑으로"**

- 도깨비는 캐릭터가 아니라 **상징**으로만 쓴다. 방망이의 돌기를 단순하게 만든 점 패턴, 금빛 하이라이트, "뚝딱" 하고 무언가가 완성되는 순간의 작은 모션으로 표현한다.
- 키워드: 따뜻함, 신뢰, 절제된 고급스러움, 가족의 온기
- 하지 말 것: 민속 캐릭터 일러스트를 크게 쓰기, 원색 오방색을 강하게 쓰기, 화려한 그라데이션, 금색을 남용하기

### 1.1 브랜드 요소
| 요소 | 사용 |
|---|---|
| 로고 심볼 | 둥근 사각형 안에 방망이 실루엣을 기하학적으로 만든 형태 (딥그린 바탕, 골드 선). 앱 아이콘과 시작 화면에만 사용 |
| 워드마크 | "도깨비 지갑" — 시스템 서체 Bold, 자간 -2% |
| 행운 점 패턴 | 3×3 점 배열, 투명도 8%. 빈 상태 화면과 지갑 카드 배경에만 은은하게 |
| "뚝딱" 모션 | 거래 저장, 할 일 완료, 예산 안에서 한 달을 마쳤을 때 금빛 반짝임 (0.6초, 한 번만) |

---

## 2. 색상

### 2.1 핵심 팔레트
| 토큰 | 라이트 | 다크 | 용도 |
|---|---|---|---|
| `bg.canvas` | `#FAF7F0` 아이보리 | `#121412` | 화면 배경 |
| `bg.surface` | `#FFFFFF` | `#1C1F1C` | 카드, 시트 |
| `bg.surfaceElevated` | `#FFFFFF` | `#242824` | 시트 안 카드, 팝오버 |
| `bg.subtle` | `#F2EDE3` | `#2A2E2A` | 입력 필드, 칩 배경 |
| `brand.primary` | `#1F4D3A` 딥그린 | `#6FB08F` | 주요 버튼, 선택 상태, 탭 아이콘 |
| `brand.primaryPressed` | `#163A2B` | `#5A9A7A` | |
| `brand.onPrimary` | `#FFFFFF` | `#0E1F17` | primary 위 텍스트 |
| `brand.primarySoft` | `#E3EDE7` | `#1E3329` | 선택된 칩, 강조 배경 |
| `accent.gold` | `#B8913A` | `#D4B266` | 장식, 즐겨찾기 별, 프리미엄 하이라이트 (**텍스트용 아님**) |
| `accent.goldSoft` | `#F4EBD6` | `#3A3222` | 고정 공지 배경 |
| `accent.beige` | `#E8DCC8` | `#3B352B` | 구분선 강조, 보조 카드 |
| `accent.brown` | `#7A5C43` | `#C4A386` | 보조 텍스트 강조, 아이콘 |
| `text.primary` | `#1E1E1C` | `#F2F0EA` | 본문 |
| `text.secondary` | `#5F5A52` | `#B5B0A6` | 보조 |
| `text.tertiary` | `#8F897E` | `#7F7A71` | 플레이스홀더, 비활성 (본문에는 쓰지 않음) |
| `border.default` | `#E6E0D4` | `#33372F` | 카드 테두리 (0.5pt) |
| `border.strong` | `#CFC6B5` | `#4A4F46` | 입력 포커스 전 상태 |

### 2.2 의미 색상
| 토큰 | 라이트 | 다크 | 용도 |
|---|---|---|---|
| `semantic.income` | `#2E7D5B` | `#7CC4A0` | 수입 금액 |
| `semantic.expense` | `#1E1E1C` (text.primary) | `#F2F0EA` | 지출 금액. 빨간색을 쓰지 않아 불안감을 줄인다 |
| `semantic.transfer` | `#5F5A52` | `#B5B0A6` | 이체 |
| `semantic.success` | `#2E7D5B` | `#7CC4A0` | |
| `semantic.warning` | `#95600F` | `#E3B45C` | 예산 80% |
| `semantic.danger` | `#B3412E` | `#EE8A76` | 예산 초과, 삭제, 오류 |
| `semantic.info` | `#3A6A8C` | `#8DB7D6` | 안내 |

### 2.3 카테고리 팔레트 (16색, 라이트·다크 쌍)
차트와 카테고리 아이콘 배경에 쓴다. 채도를 낮춘 자연색 계열로 브랜드 톤을 유지한다.

| # | 이름 | 라이트 | 다크 |
|---|---|---|---|
| 1 | 솔잎 | `#3F7A5E` | `#74B394` |
| 2 | 이끼 | `#7C8B4A` | `#AEBE7A` |
| 3 | 황토 | `#B8793A` | `#DDA66C` |
| 4 | 단풍 | `#B5523B` | `#E08A73` |
| 5 | 석류 | `#9C3D54` | `#D27A90` |
| 6 | 자두 | `#6E4A7E` | `#A78BB7` |
| 7 | 쪽빛 | `#3D5A8A` | `#86A2CF` |
| 8 | 하늘 | `#4D8AA8` | `#8CC0D8` |
| 9 | 청자 | `#4F9A8F` | `#8ACBC1` |
| 10 | 금 | `#B8913A` | `#D4B266` |
| 11 | 밤 | `#7A5C43` | `#C4A386` |
| 12 | 먹 | `#4A4A48` | `#A8A8A4` |
| 13 | 살구 | `#D08A5E` | `#EDB38E` |
| 14 | 진달래 | `#C0678E` | `#E5A0BE` |
| 15 | 쑥 | `#6F9A6A` | `#A6CDA1` |
| 16 | 모래 | `#A89A7C` | `#CFC3A8` |

- 카테고리 아이콘: 둥근 사각형(반경 10pt, 36×36pt)에 카테고리 색 15% 투명 배경과 카테고리 색 아이콘.
- 차트에서는 상위 6개 카테고리만 색을 쓰고 나머지는 "기타"(`#CFC6B5`)로 묶는다.
- 구성원 색은 1, 7, 3, 5, 9, 6번 순서로 배정한다.

### 2.4 대비 기준
- 본문 텍스트는 4.5:1 이상, 큰 텍스트(17pt Bold / 24pt 이상)는 3:1 이상.
- 계산으로 확인한 조합 (WCAG 상대 휘도 공식): `text.primary`/`bg.canvas` 15.6:1, `brand.primary`/`bg.canvas` 9.0:1, `text.secondary`/`bg.surface` 6.8:1, `brand.onPrimary`/`brand.primary` 9.6:1, `accent.brown`/`bg.canvas` 5.7:1, `semantic.income`/`bg.surface` 5.0:1, `semantic.danger`/`bg.surface` 5.7:1, `semantic.warning`/`bg.canvas` 5.0:1. 다크: `text.primary`/`bg.canvas` 16.2:1, `brand.primary`/`bg.canvas` 7.3:1, `text.secondary`/`bg.surface` 7.7:1.
- `text.tertiary`/`bg.surface`는 3.5:1이므로 플레이스홀더와 큰 텍스트에만 쓴다.
- `accent.gold`/`bg.canvas`는 2.75:1 → **텍스트에 쓰지 않는다**. 아이콘이나 장식에 쓸 때는 다른 단서(형태, 레이블)를 함께 둔다.
- "대비 증가" 접근성 설정이 켜지면 `border.default`를 `border.strong`으로, `text.tertiary`를 `text.secondary`로 바꾼다.

### 2.5 구현
- `Assets.xcassets`에 Color Set으로 등록한다 (Any / Dark, High Contrast 변형 포함).
- 코드에서는 `DWColor.Background.canvas`처럼 토큰으로만 접근하고, 16진수 값을 코드에 직접 쓰지 않는다.

---

## 3. 타이포그래피

- 서체: 시스템 서체(SF Pro). 한글은 시스템이 자동으로 Apple SD Gothic Neo로 대체한다. 별도 폰트를 넣지 않아 용량을 줄이고 Dynamic Type을 그대로 지원한다.
- 금액 숫자: `.monospacedDigit()` (자릿수 정렬), 큰 금액은 SF Pro Rounded로 부드러운 인상을 준다.
- 모든 스타일은 Dynamic Type에 맞춰 크기가 바뀐다 (`Font.TextStyle` 기반).

| 토큰 | 기반 스타일 | 기본 크기/굵기 | 행간 | 용도 |
|---|---|---|---|---|
| `display` | largeTitle | 34 / Bold, Rounded | 41 | 홈 이번 달 지출 총액 |
| `title1` | title | 28 / Bold | 34 | 화면 제목 |
| `title2` | title2 | 22 / Semibold | 28 | 섹션 큰 제목, 전체 화면 바코드 번호 |
| `title3` | title3 | 20 / Semibold | 25 | 카드 제목 |
| `headline` | headline | 17 / Semibold | 22 | 리스트 제목, 버튼 |
| `body` | body | 17 / Regular | 24 (+2 행간 추가, 한글 가독성) | 본문 |
| `callout` | callout | 16 / Regular | 21 | 보조 본문 |
| `subheadline` | subheadline | 15 / Regular | 20 | 리스트 보조 정보 |
| `footnote` | footnote | 13 / Regular | 18 | 메타 정보 (작성자, 날짜) |
| `caption` | caption | 12 / Medium | 16 | 배지, 차트 레이블 |
| `amountLarge` | title | 28 / Bold, Rounded, monospacedDigit | | 거래 입력 금액 |
| `amountRow` | body | 17 / Semibold, monospacedDigit | | 목록 금액 |

- 금액 표기: `32,000원`. 큰 금액 요약은 `1,250만 원` 형식을 선택할 수 있다 (통계 축). 수입은 `+32,000원`, 지출은 부호 없이 쓴다.
- 날짜 표기: `11월 19일 (수)`, 연도가 다르면 `2025년 11월 19일`. 시간은 `오후 3:20`.
- 줄 길이: 본문은 한 줄에 약 35자 이내 (iPhone 기본 여백 기준).

---

## 4. 간격, 레이아웃, 모양

### 4.1 간격 (4pt 그리드)
| 토큰 | 값 | 용도 |
|---|---|---|
| `space.xxs` | 2 | 아이콘과 배지 |
| `space.xs` | 4 | |
| `space.sm` | 8 | 요소 안 간격 |
| `space.md` | 12 | 리스트 행 안 간격 |
| `space.lg` | 16 | 카드 안쪽 여백, 화면 좌우 여백 |
| `space.xl` | 20 | 카드와 카드 사이 |
| `space.xxl` | 24 | 섹션 사이 |
| `space.xxxl` | 32 | 화면 상단 큰 여백 |

- 화면 좌우 여백 20pt (충분한 여백 원칙), 카드 안쪽 여백 20pt, 카드 사이 16pt.
- 터치 영역은 최소 44×44pt.

### 4.2 모서리 반경 (`RoundedRectangle(cornerRadius:, style: .continuous)`)
| 토큰 | 값 | 용도 |
|---|---|---|
| `radius.sm` | 8 | 칩, 작은 배지 |
| `radius.md` | 12 | 입력 필드, 버튼 |
| `radius.lg` | 20 | 카드 |
| `radius.xl` | 28 | 시트 상단, 지갑 카드 |
| `radius.full` | 9999 | 아바타, 알약 모양 버튼 |

### 4.3 그림자와 깊이
| 토큰 | 라이트 | 다크 |
|---|---|---|
| `elevation.card` | `color #1E1E1C @ 4%, y 2, blur 12` + 0.5pt `border.default` | 그림자 없음, `bg.surface` 명도 차이와 0.5pt 테두리 |
| `elevation.floating` | `@ 10%, y 8, blur 24` | `@ 40% 검정, y 8, blur 24` |

다크 모드에서는 그림자보다 표면 명도 단계(canvas < surface < surfaceElevated)로 깊이를 표현한다.

### 4.4 아이콘
- SF Symbols만 쓴다. 굵기는 텍스트와 맞추고(기본 `.regular`, 강조할 때 `.semibold`), 렌더링 모드는 `.hierarchical`.
- 카테고리 아이콘 큐레이션 목록 (예): `fork.knife`, `cup.and.saucer`, `cart`, `basket`, `house`, `bolt`, `phone`, `bus`, `car`, `cross.case`, `book`, `figure.and.child.holdinghands`, `theatermasks`, `airplane`, `tshirt`, `gift`, `pawprint`, `shield`, `building.columns`, `banknote`, `wonsign.circle`, `ellipsis.circle` 등 약 80개.

---

## 5. 컴포넌트

| 컴포넌트 | 사양 |
|---|---|
| **DWCard** | `bg.surface`, `radius.lg`, 안쪽 여백 20, `elevation.card`. 헤더(제목 `title3` + 오른쪽 "더보기" `footnote` `brand.primary`) 선택 사항 |
| **DWButton** | 종류: primary(딥그린 채움, 흰 글씨), secondary(`brand.primarySoft` 배경, 딥그린 글씨), tertiary(텍스트), destructive(`semantic.danger`). 높이 52(large) / 44(medium) / 32(small), `radius.md`. 누르면 0.97배 축소, 로딩 중에는 ProgressView |
| **DWTextField** | `bg.subtle`, 높이 52, `radius.md`, 포커스 시 1.5pt `brand.primary` 테두리, 오류 시 `semantic.danger` 테두리와 아래 메시지 (`footnote`) |
| **DWAmountField** | 가운데 정렬 `amountLarge`, 단위 "원", 입력하면 천 단위 구분 기호 표시, 빠른 버튼 [+1만] [+5천] [+1천] [지우기] |
| **DWSegmentedControl** | 알약 모양 컨테이너 `bg.subtle`, 선택 항목은 `bg.surface`와 그림자 (iOS 기본보다 부드러운 톤). 선택이 바뀔 때 matchedGeometryEffect |
| **DWChip** | 높이 32, `radius.full`. 선택하면 `brand.primarySoft` 배경과 `brand.primary` 글씨·테두리 |
| **TransactionRow** | 왼쪽 카테고리 아이콘(36) / 가운데 사용처(`headline`)와 카테고리·결제수단·실사용자 아바타(`footnote`) / 오른쪽 금액(`amountRow`)과 공개 범위 아이콘(🔒 나만, 👥 선택). 높이 최소 64. 동기화 대기 중이면 시계 아이콘 |
| **VisibilityBadge** | family: 아이콘 없음 (기본값이라 생략), private: `lock.fill`, selected: `person.2.fill` + 인원 수. VoiceOver 레이블 "나만 보기" 등 |
| **ScopeTag** | 공동: `brand.primarySoft` 배경에 "공동", 개인: `bg.subtle` 배경에 "개인" (`caption`) |
| **DWProgressBar (예산)** | 높이 8, `radius.full`, 트랙 `bg.subtle`, 채움 0~79% `brand.primary`, 80~99% `semantic.warning`, 100% 이상 `semantic.danger` (넘친 부분은 줄무늬) |
| **DWAvatar / DWAvatarStack** | 크기 24/32/44/64, 이미지가 없으면 구성원 색 배경에 이름 첫 글자. 스택은 -8pt 겹침, 4명이 넘으면 "+N" |
| **DWBadge** | 읽지 않은 수: `semantic.danger` 배경, 흰 글씨 `caption`, 99+ |
| **DWEmptyState** | 행운 점 패턴 일러스트(64pt, `accent.beige`) + 제목 `headline` + 설명 `subheadline` + 버튼 |
| **DWSkeleton** | `bg.subtle` 블록과 은은한 shimmer (동작 줄이기가 켜지면 정지) |
| **DWToast** | 하단 플로팅, `text.primary` 배경(다크에서는 반전), `radius.md`, 실행 취소 액션 지원, 3~5초 |
| **WalletCardView** | 신용카드 비율(1.586:1), `radius.xl`, 카드 대표 색 배경과 밝기에 따른 텍스트 색 자동 선택, 오른쪽 아래에 행운 점 패턴 8%, 브랜드 로고, 즐겨찾기 별(`accent.gold`) |
| **FullScreenBarcode** | 흰 배경 고정(다크 모드에서도 흰색, 인식률 때문), 바코드 좌우 여백 24, 아래에 번호 `title2` monospaced, 위에 브랜드명. 1D 바코드는 가로 회전 권장 안내 |
| **NoticeRow** | 고정 공지는 `accent.goldSoft` 배경과 `pin.fill`(`accent.gold`), 안 읽은 공지는 제목 Bold와 왼쪽 점 |
| **TaskRow** | 원형 체크박스(24), 중요도 표시(긴급 `semantic.danger` 막대 3pt), 마감 D-day 칩, 담당자 아바타 스택 |
| **CalendarDayCell** | 오늘은 딥그린 원 배경, 선택한 날은 `brand.primarySoft`, 일정 점 최대 3개, 일요일·공휴일 날짜는 `semantic.danger` |
| **SyncStatusIndicator** | 내비게이션 바: 오프라인 `wifi.slash`, 대기 N건 `arrow.triangle.2.circlepath` |

---

## 6. 차트 (Swift Charts)

| 차트 | 마크 | 스타일 |
|---|---|---|
| 월별 수입·지출 | `BarMark` 그룹 | 수입 `semantic.income`, 지출 `brand.primary` 70%. 막대 모서리 4, 선택한 달 강조 (나머지는 40%) |
| 카테고리 비율 | `SectorMark(innerRadius: .ratio(0.62), angularInset: 1.5)` | 카테고리 팔레트, 가운데에 총액 `title2` |
| 구성원별 | 가로 `BarMark` | 구성원 색, 오른쪽 끝에 금액 주석 |
| 공동 vs 개인 | 누적 `BarMark` | 공동 `brand.primary`, 개인 `accent.brown` |
| 예산 페이스 | `LineMark` 누적 지출 + `RuleMark` 예산선 (점선 `semantic.warning`) | `AreaMark` 그라데이션 10% |

- 축 레이블은 `caption`, `text.tertiary`. 격자선은 `border.default` 0.5pt, 가로 격자만 쓴다.
- 금액 축은 `만` 단위로 줄여서 쓴다 (예: 50만).
- `chartXSelection`으로 값을 고르면 툴팁 카드(`DWCard` 축소판)를 띄운다.
- 접근성: `.accessibilityChartDescriptor`를 쓰고, [표로 보기] 토글을 둔다.

---

## 7. 모션과 햅틱

| 토큰 | 값 | 용도 |
|---|---|---|
| `motion.quick` | `.snappy(duration: 0.2)` | 토글, 칩 선택 |
| `motion.standard` | `.smooth(duration: 0.3)` | 화면 요소 전환 |
| `motion.emphasis` | `.bouncy(duration: 0.45, extraBounce: 0.1)` | 완료 체크, 카드 추가 |
| `motion.ttukttak` | 금빛 반짝임 파티클 0.6초 + `.sensoryFeedback(.success)` | 저장 완료 순간 (하루 몇 번만 노출되도록 빈도 제한) |

- 햅틱: 저장 성공 `.success`, 삭제 `.warning`, 세그먼트·칩 선택 `.selection`, 바코드 인식 `.impact(weight: .medium)`.
- "동작 줄이기"가 켜지면 파티클과 바운스 대신 페이드만 쓴다.

---

## 8. 화면 레이아웃 원칙

- 배경은 항상 `bg.canvas` 아이보리, 내용은 흰 카드로 묶는다 (`List` 대신 `ScrollView` + `LazyVStack` 카드 구성을 기본으로, 설정 화면은 `List(.insetGrouped)`에 배경 색만 바꿔서 쓴다).
- 내비게이션 바: 큰 제목(`.large`), 배경은 투명에서 스크롤하면 `.ultraThinMaterial`.
- 탭바: 기본 `TabView`, 선택 색 `brand.primary`, 비선택 색 `text.tertiary`.
- 시트: `.presentationCornerRadius(28)`, `.presentationBackground(bg.surface)`, 짧은 입력은 `.medium` detent.
- 홈 화면 구성 (위에서 아래로):
  1. 그룹 전환기 + 알림 종
  2. 이번 달 요약 카드 (지출 총액 `display`, 수입, 예산 진행률)
  3. 공동 / 개인 지출 2열 카드
  4. 오늘·이번 주 일정 카드
  5. 미완료 할 일 카드
  6. 최근 거래 카드
  7. 최근 공지 카드
  8. 가족 활동 피드
- iPad와 가로 모드는 P2: `NavigationSplitView` 2열.

---

## 9. 접근성

- Dynamic Type: AX5까지 레이아웃이 깨지지 않아야 한다. 큰 글자에서는 가로 배치(HStack)를 세로 배치로 바꾼다 (`ViewThatFits`, `dynamicTypeSize` 분기).
- VoiceOver: 금액은 "삼만 이천 원 지출, 식비, 11월 19일, 나만 보기"처럼 한 문장으로 읽히도록 `accessibilityElement(children: .combine)`과 커스텀 레이블을 쓴다.
- 색만으로 정보를 전달하지 않는다: 예산 상태에는 문구("82% 사용")를 함께 쓰고, 수입은 "+" 부호를 붙인다.
- 바코드 전체 화면: VoiceOver로 "바코드, 번호 1234…"를 읽어 준다.
- 최소 터치 영역 44pt, 스와이프 동작에는 같은 기능을 하는 버튼(컨텍스트 메뉴)을 함께 둔다.

---

## 10. 문구 톤

- 존댓말 해요체, 짧고 따뜻하게. 예: "저장했어요", "이번 달 예산의 80%를 썼어요".
- 비난하는 표현을 쓰지 않는다: "과소비" 대신 "지난달보다 12% 더 썼어요".
- 오류는 원인과 해결책을 함께 쓴다: "인터넷 연결을 확인해 주세요. 연결되면 자동으로 저장돼요."
- 서비스명은 항상 "도깨비 지갑"(띄어쓰기 포함)으로 쓴다.
