# 도깨비 지갑 — 앱 구조 설계

## 1. 아키텍처 개요

```
┌──────────────────────────── Presentation ────────────────────────────┐
│  SwiftUI View  ──(사용자 동작)──▶  ViewModel (@Observable, @MainActor) │
│      ▲                                   │                            │
│      └──────(상태: ViewState<T>)─────────┘                            │
└──────────────────────────────────┬───────────────────────────────────┘
                                   │ 프로토콜 호출 (async/await)
┌──────────────────────────── Domain ─────────────────────────────────┐
│  Entities (struct, Sendable)   Repository 프로토콜   UseCase(필요 시)  │
│  PermissionPolicy, RecurrenceExpander, MoneyFormatter 등 순수 로직     │
└──────────────────────────────────┬───────────────────────────────────┘
                                   │
┌──────────────────────────── Data ───────────────────────────────────┐
│  Repository 구현 (캐시 우선 + 원격)                                    │
│   ├─ RemoteDataSource (supabase-swift: PostgREST, RPC, Storage)       │
│   ├─ LocalDataSource (SwiftData 캐시)                                 │
│   ├─ SyncEngine (Outbox 대기열, 증분 동기화, Realtime 적용)            │
│   └─ DTO ↔ Entity 매퍼                                               │
└──────────────────────────────────────────────────────────────────────┘
```

### 1.1 계층별 책임
| 계층 | 책임 | 하지 않는 일 |
|---|---|---|
| View | 레이아웃, 사용자 입력 전달, 상태 표시, 접근성 레이블 | 비즈니스 로직, 네트워크, 포맷 계산 |
| ViewModel | 화면 상태(`ViewState`), 입력 검증, Repository 호출 조합, 오류를 화면용 메시지로 변환, 내비게이션 요청 | Supabase SDK 직접 호출, SwiftData 직접 접근 |
| UseCase (선택) | 여러 Repository를 묶는 도메인 작업 (예: `CreateTransactionWithReceiptsUseCase`) | UI 상태 |
| Repository | 데이터 출처 추상화, 캐시 정책, 오프라인 쓰기 대기열 등록, DTO 변환 | UI 문구, 화면 상태 |
| DataSource | 순수 입출력 (SDK 호출, SwiftData CRUD) | 비즈니스 판단 |
| SyncEngine | 대기열 전송, 재시도, 충돌 처리, Realtime 이벤트 반영 | 화면 의존 |

### 1.2 기술 선택
| 항목 | 선택 | 이유 |
|---|---|---|
| 상태 관리 | Observation (`@Observable`) | iOS 17 기준, 불필요한 다시 그리기 감소 |
| 동시성 | Swift Concurrency (async/await, actor), Swift 6 Strict Concurrency 대비 | |
| 백엔드 SDK | `supabase-swift` v2 (SPM) | Auth, PostgREST, Realtime V2, Storage, Functions |
| 로컬 DB | SwiftData | iOS 17 기본 제공, SwiftUI와 연동이 쉬움 |
| 보안 저장 | Keychain (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`) | 세션, 앱 잠금 설정 |
| 이미지 | 직접 만든 `ImageCache` (메모리 NSCache + 디스크) | 서드파티 의존 최소화 |
| 바코드 | Core Image (QR, Code128, PDF417, Aztec) + 직접 구현한 1D 인코더 (EAN/UPC/Code39/ITF), VisionKit/Vision 스캔 | |
| 차트 | Swift Charts | |
| 로그 | `os.Logger` (카테고리별), 개인정보는 `privacy: .private` | |
| 크래시·분석 | Firebase Crashlytics 또는 Sentry (P1에서 결정, 개인정보 마스킹 필수) | |
| 의존성 관리 | Swift Package Manager | |

외부 라이브러리는 `supabase-swift` 하나를 기본으로 하고, 다른 라이브러리는 꼭 필요한지 검토한 뒤에 넣는다.

---

## 2. 폴더 및 파일 구조

> **2단계(프로젝트 초기 구축) 적용 현황**: 초기에는 단일 앱 타깃 안에서 폴더로 계층을 나눈다.
> `App / Core / DesignSystem / Models / Services / Repositories / ViewModels / Features / Resources`.
> 기능별 폴더(`Features/<기능>/Views, ViewModels, Models`)와 아래 모듈의 책임 구분은 같다. 코드가 커지면 아래 구조대로 로컬 Swift Package로 분리한다.
> 의존 방향 규칙(§2.1)은 폴더 단위로 지킨다. ViewModel·Model·Repository·Core는 SwiftUI를 import하지 않는다. 그래서 Linux Swift 툴체인에서도 컴파일과 테스트를 할 수 있다.
> Xcode 프로젝트는 `scripts/generate_project.rb`로 만든다. 색상과 앱 아이콘은 `scripts/generate_assets.py`로 만든다.

최종 목표 구조: Xcode 프로젝트 1개와 로컬 Swift Package로 모듈을 나눈다. 모듈 경계 덕분에 빌드 시간이 줄고 의존 방향을 강제할 수 있다.

```
DokkaebiWallet/
├── DokkaebiWallet.xcodeproj
├── App/                                  # 앱 타깃 (얇게 유지)
│   ├── DokkaebiWalletApp.swift           # @main, AppContainer 주입
│   ├── AppDelegate.swift                 # APNs 등록, 알림 델리게이트
│   ├── RootView.swift                    # 인증 상태에 따른 루트 분기
│   ├── MainTabView.swift                 # 5개 탭
│   ├── Config/
│   │   ├── Debug.xcconfig / Staging.xcconfig / Release.xcconfig
│   │   └── AppConfig.swift               # Info.plist 값 읽기 (SUPABASE_URL, ANON_KEY)
│   ├── Resources/
│   │   ├── Assets.xcassets               # 색상 세트 (라이트/다크), 앱 아이콘
│   │   ├── Localizable.xcstrings
│   │   ├── DefaultMerchantDictionary.json
│   │   └── KoreanHolidays.json
│   ├── DokkaebiWallet.entitlements       # Push, Associated Domains, Keychain Sharing(위젯)
│   └── PrivacyInfo.xcprivacy             # 개인정보 매니페스트
│
├── Packages/
│   ├── DWCore/                           # 의존성 없음
│   │   ├── Foundation/                   # Money, DateRange, Period, Clock, UUIDProvider
│   │   ├── Errors/                       # AppError, ErrorMapper
│   │   ├── Logging/                      # Log.swift
│   │   ├── Recurrence/                   # RRule 파서, RecurrenceExpander
│   │   ├── Formatting/                   # MoneyFormatter, DateFormatter(그룹 시간대)
│   │   └── Utilities/                    # Debouncer, Throttler, Hashing(SHA256)
│   │
│   ├── DWDomain/                         # 의존: DWCore
│   │   ├── Entities/
│   │   │   ├── UserProfile.swift, FamilyGroup.swift, FamilyMember.swift, Invitation.swift
│   │   │   ├── Transaction.swift, Category.swift, PaymentMethod.swift
│   │   │   ├── RecurringTransaction.swift, Budget.swift, BudgetStatus.swift
│   │   │   ├── StatisticsModels.swift
│   │   │   ├── WalletCard.swift, BarcodeType.swift
│   │   │   ├── CalendarEvent.swift, EventOccurrence.swift
│   │   │   ├── Notice.swift, TaskItem.swift, AppNotification.swift, ActivityItem.swift
│   │   │   └── ImportBatch.swift, CategoryRule.swift
│   │   ├── Repositories/                 # 프로토콜만
│   │   │   ├── AuthRepository.swift, ProfileRepository.swift, FamilyRepository.swift
│   │   │   ├── TransactionRepository.swift, CategoryRepository.swift
│   │   │   ├── PaymentMethodRepository.swift, BudgetRepository.swift, StatisticsRepository.swift
│   │   │   ├── WalletRepository.swift, CalendarRepository.swift
│   │   │   ├── NoticeRepository.swift, TaskRepository.swift
│   │   │   ├── NotificationRepository.swift, ActivityRepository.swift
│   │   │   ├── ImportRepository.swift, AttachmentRepository.swift
│   │   ├── Policies/
│   │   │   └── PermissionPolicy.swift    # UI 버튼 노출 판단 (서버 RLS가 최종 판정)
│   │   └── UseCases/
│   │       ├── SaveTransactionUseCase.swift
│   │       ├── CSVImportUseCase.swift
│   │       ├── AutoCategorizer.swift
│   │       └── DuplicateDetector.swift
│   │
│   ├── DWData/                           # 의존: DWDomain, supabase-swift
│   │   ├── Remote/
│   │   │   ├── SupabaseClientProvider.swift
│   │   │   ├── DTOs/                     # Codable, snake_case 매핑
│   │   │   ├── RemoteDataSources/        # TransactionRemoteDataSource 등
│   │   │   └── RealtimeService.swift     # 그룹 채널 관리
│   │   ├── Local/
│   │   │   ├── Models/                   # @Model 클래스 (CachedTransaction 등)
│   │   │   ├── LocalStore.swift          # ModelContainer, ModelActor
│   │   │   ├── FileStore.swift           # 이미지, 바코드 이미지 (Data Protection)
│   │   │   └── KeychainStore.swift
│   │   ├── Sync/
│   │   │   ├── SyncEngine.swift          # actor
│   │   │   ├── OutboxItem.swift          # @Model
│   │   │   ├── SyncCursorStore.swift
│   │   │   └── ConflictResolver.swift
│   │   ├── Repositories/                 # 프로토콜 구현
│   │   └── Mappers/
│   │
│   ├── DWDesignSystem/                   # 의존: DWCore
│   │   ├── Tokens/                       # DWColor, DWFont, DWSpacing, DWRadius, DWShadow, DWMotion
│   │   ├── Components/
│   │   │   ├── DWCard.swift, DWButton.swift, DWTextField.swift, DWAmountField.swift
│   │   │   ├── DWSegmentedControl.swift, DWChip.swift, DWAvatar.swift, DWAvatarStack.swift
│   │   │   ├── DWProgressBar.swift, DWBadge.swift, DWEmptyState.swift, DWErrorView.swift
│   │   │   ├── DWSkeleton.swift, DWToast.swift, DWSectionHeader.swift, DWListRow.swift
│   │   │   ├── CategoryIcon.swift, VisibilityBadge.swift, SyncStatusIndicator.swift
│   │   │   └── BarcodeView.swift
│   │   └── Modifiers/                    # .dwCardStyle(), .dwScreenBackground()
│   │
│   ├── DWFeatures/                       # 의존: DWDomain, DWDesignSystem (DWData에는 의존하지 않음)
│   │   ├── Auth/            (SignInView, OTPVerifyView, ProfileSetupView, AuthViewModel)
│   │   ├── Onboarding/      (WelcomeView, CreateOrJoinGroupView, JoinByCodeView)
│   │   ├── Home/            (HomeView, HomeViewModel, Cards/…)
│   │   ├── Ledger/
│   │   │   ├── List/        (LedgerView, LedgerViewModel, TransactionRow, FilterSheet)
│   │   │   ├── Editor/      (TransactionEditorView, TransactionEditorViewModel, VisibilityPicker, MemberPicker)
│   │   │   ├── Detail/      (TransactionDetailView, ReceiptViewer)
│   │   │   ├── Recurring/   (RecurringListView, RecurrenceRuleEditor)
│   │   │   ├── Budget/      (BudgetView, BudgetEditorView, BudgetViewModel)
│   │   │   ├── Statistics/  (StatisticsView, StatisticsViewModel, Charts/…)
│   │   │   ├── Categories/  (CategoryManageView, CategoryEditorView, CategoryViewModel)
│   │   │   ├── PaymentMethods/
│   │   │   └── Import/      (CSVImportView, ColumnMappingView, ImportPreviewView, ImportViewModel)
│   │   ├── Wallet/          (WalletView, WalletCardEditorView, BarcodeScannerView, FullScreenBarcodeView, WalletViewModel)
│   │   ├── Calendar/        (CalendarView, MonthView, WeekView, DayView, EventEditorView, EventDetailView, CalendarViewModel)
│   │   ├── More/            (MoreMenuView)
│   │   ├── Notices/         (NoticeListView, NoticeDetailView, NoticeEditorView, ReadStatusView, NoticeViewModel)
│   │   ├── Tasks/           (TaskListView, TaskBoardView, TaskEditorView, TaskViewModel)
│   │   ├── NotificationCenter/ (NotificationListView, NotificationViewModel)
│   │   ├── Family/          (FamilyManageView, MemberDetailView, InviteView, GroupSettingsView, GroupSwitcher)
│   │   └── Settings/        (SettingsView, NotificationSettingsView, SecuritySettingsView, AccountView, DataExportView)
│   │
│   └── DWTestSupport/                    # Mock Repository, Fixture, FakeClock
│
├── DokkaebiWalletTests/                  # 단위 테스트 (Swift Testing)
├── DokkaebiWalletUITests/                # XCUITest
├── DokkaebiWidgets/                      # WidgetKit 확장 (P2)
├── NotificationServiceExtension/         # 리치 푸시 (P2: 이미지 첨부 공지)
└── supabase/
    ├── config.toml
    ├── migrations/
    ├── functions/                        # Edge Functions (Deno/TypeScript)
    │   ├── send-push/
    │   ├── delete-account/
    │   ├── storage-cleanup/
    │   └── financial-sync/  (P2)
    ├── tests/                            # pgTAP
    └── seed.sql
```

### 2.1 의존 방향 규칙
`App → DWFeatures → DWDomain → DWCore`, `App → DWData → DWDomain`. `DWFeatures`는 `DWData`를 import하지 않는다. 의존성은 App의 `AppContainer`가 조립해 주입한다.

---

## 3. 의존성 주입

```swift
@MainActor @Observable
final class AppContainer {
    let session: SessionStore               // 로그인 사용자, 현재 그룹, 내 역할
    let transactions: TransactionRepository
    let categories: CategoryRepository
    // … 모든 Repository
    let syncEngine: SyncEngine
    let realtime: RealtimeService
    let router: AppRouter
}
// 주입: .environment(container)  →  각 화면 진입 시 ViewModel 생성
// 예) LedgerView(viewModel: LedgerViewModel(repo: container.transactions, session: container.session))
```
- 미리보기(Preview)와 테스트에서는 `AppContainer.preview` / `.mock`으로 Mock Repository를 주입한다.
- `SessionStore`는 `currentGroupID`가 바뀌면 Realtime 채널을 바꾸고, 캐시 범위를 바꾸고, 각 ViewModel에 새로고침 이벤트를 보낸다.

---

## 4. ViewModel 규칙

```swift
enum ViewState<Value> {
    case idle, loading
    case loaded(Value)
    case empty
    case failed(AppError)
}

@MainActor @Observable
final class LedgerViewModel {
    private(set) var state: ViewState<[TransactionSection]> = .idle
    var filter = TransactionFilter.currentMonth
    private(set) var isSyncPending = false

    private let repo: TransactionRepository
    private let session: SessionStore
    private var observeTask: Task<Void, Never>?

    func onAppear() { observeTask = Task { for await list in repo.observe(groupID: session.groupID, filter: filter) { … } } }
    func onDisappear() { observeTask?.cancel() }
    func delete(_ id: Transaction.ID) async { … 낙관적 제거 → 실패 시 복구 + 토스트 }
}
```
- Repository는 `AsyncStream`으로 로컬 캐시 변경을 내보낸다. ViewModel은 이 스트림을 구독하기만 하면 된다. 원격 동기화나 Realtime 이벤트가 캐시를 갱신하면 화면이 자동으로 바뀐다 (단일 진실 공급원 = 로컬 캐시).
- 입력 폼 ViewModel(`TransactionEditorViewModel`)은 `draft` 구조체와 `validationErrors`를 가진다. 저장할 때 `SaveTransactionUseCase`를 부른다.
- ViewModel은 문자열을 직접 만들지 않고 `LocalizedStringResource`를 쓴다.

---

## 5. 내비게이션 구조

### 5.1 탭
| 탭 | 루트 화면 | SF Symbol |
|---|---|---|
| 홈 | HomeView | `house` |
| 가계부 | LedgerView (상단 세그먼트: 내역 / 통계 / 예산) | `list.bullet.rectangle` |
| 지갑 | WalletView | `wallet.pass` |
| 캘린더 | CalendarView | `calendar` |
| 전체 | MoreMenuView (공지사항, 할 일, 알림 센터, 가족 관리, 설정) | `square.grid.2x2` |

알림 센터는 전체 메뉴에 두고, 모든 탭 루트 상단 오른쪽에도 종 아이콘(읽지 않은 수 배지)을 둔다. 그룹 전환기는 홈과 가계부 상단 왼쪽에 둔다.

### 5.2 Router
```swift
@Observable final class AppRouter {
    var selectedTab: Tab = .home
    var homePath = NavigationPath()        // 탭별 NavigationStack 경로
    var ledgerPath = NavigationPath()
    var walletPath = NavigationPath()
    var calendarPath = NavigationPath()
    var morePath = NavigationPath()
    var sheet: SheetRoute?                 // 모달
    var fullScreen: FullScreenRoute?       // 바코드 전체 화면, 잠금 화면

    func handle(deepLink: DeepLink)         // 푸시, Universal Link, 위젯
}
enum LedgerRoute: Hashable { case detail(Transaction.ID), recurringList, categories, paymentMethods, importCSV, statistics(DateRange) }
enum SheetRoute: Identifiable { case transactionEditor(TransactionEditorMode), eventEditor(...), taskEditor(...), noticeEditor(...), invite, groupSwitcher }
```
- 딥링크 형식: `dokkaebi://group/{gid}/{entity}/{id}`, Universal Link `https://dokkaebiwallet.app/invite/{token}`
- 딥링크를 처리할 때 `gid`가 현재 그룹과 다르면 그룹을 먼저 바꾼 뒤 이동한다. 사용자가 구성원이 아니면 "접근할 수 없음" 화면을 보여준다.

### 5.3 화면 이동 맵 (요약)
```
RootView
 ├─ (미인증) SignIn → OTPVerify → ProfileSetup → Onboarding(CreateOrJoin)
 ├─ (잠금) AppLockView
 └─ MainTabView
     ├─ 홈 → 거래 상세 / 일정 상세 / 할 일 상세 / 공지 상세 / 예산 / 알림 센터
     ├─ 가계부 → [내역] 거래 상세 → 수정(sheet) / [통계] 카테고리 → 필터된 내역 / [예산] 예산 편집
     │          ⋯ 메뉴 → 카테고리 관리, 결제수단 관리, 반복 거래, CSV 가져오기, 내보내기
     ├─ 지갑 → 카드 상세 → 전체 화면 바코드(fullScreenCover) / 카드 추가(sheet: 스캔·사진·직접 입력)
     ├─ 캘린더 → 일정 상세 → 수정(sheet)
     └─ 전체 → 공지사항 / 할 일 / 알림 센터 / 가족 관리(구성원·초대·그룹 설정) / 설정
```
자세한 흐름은 USER_FLOW.md를 참고한다.

---

## 6. Supabase 연동

### 6.1 Auth
- `SupabaseClient(supabaseURL:, supabaseKey: anonKey, options: .init(auth: .init(storage: KeychainLocalStorage(), flowType: .pkce)))`
- Sign in with Apple: `ASAuthorizationController`로 identity token을 받아 `auth.signInWithIdToken(credentials: .init(provider: .apple, idToken:, nonce:))`를 호출한다. nonce는 SHA-256으로 처리한다.
- 이메일 OTP: `signInWithOTP(email:)` → `verifyOTP(email:, token:, type: .email)`
- 카카오: `signInWithOAuth(provider: .kakao, redirectTo: dokkaebi://auth-callback)` + `ASWebAuthenticationSession`
- `authStateChanges`를 구독해 `SessionStore`를 갱신한다. `signedOut`이 오면 로컬 데이터를 지우고 루트로 돌아간다.

### 6.2 데이터 접근
- 단순 CRUD는 PostgREST(`client.from("…")`)를 쓰고, 여러 테이블을 원자적으로 바꾸거나 권한이 복잡한 작업은 RPC(`client.rpc("upsert_transaction", params:)`)를 쓴다.
- DTO는 `Codable`이며 `JSONDecoder.keyDecodingStrategy = .convertFromSnakeCase`, 날짜는 ISO8601(소수 초 포함)로 디코딩한다.
- 모든 쿼리에 `family_group_id`를 명시한다. RLS가 막아 주더라도 쿼리 계획 효율과 실수 방지를 위해서다.

### 6.3 Storage
- 업로드 전처리: `ImageProcessor`가 리사이즈(긴 변 2048px)하고, 썸네일(400px)을 만들고, EXIF를 제거한 뒤 JPEG 품질 0.8로 저장한다.
- 업로드는 `BackgroundUploadQueue`(Outbox의 한 종류)로 처리하고, 실패하면 재시도한다.
- 다운로드: Signed URL을 받아 `ImageCache`에 넣는다. 캐시 키는 storage_path다 (경로가 바뀌지 않으므로 영구적으로 쓸 수 있다).

### 6.4 Realtime
```swift
actor RealtimeService {
    func subscribe(groupID: UUID, userID: UUID) async   // 채널 group:{gid}
    func unsubscribe() async
}
```
- 포그라운드에 들어오면 구독하고, 백그라운드로 가면 30초 뒤 해제한다.
- 이벤트를 받으면 `SyncEngine.apply(remoteChange:)`로 캐시에 반영한다 (`version`이 로컬보다 클 때만).
- 다시 연결되면 `sync_changes(since: cursor)`로 놓친 변경분을 메운다.

### 6.5 Push Notification
- 앱을 처음 실행할 때 바로 권한을 요청하지 않는다. 그룹에 가입한 뒤 맥락에 맞는 화면("가족의 새 지출과 공지를 알려드릴게요")에서 요청한다.
- `registerForRemoteNotifications` → 토큰을 받으면 `device_tokens`에 upsert한다 (environment는 빌드 구성에 따라 결정).
- 알림을 누르면 `userInfo.deep_link`로 `AppRouter.handle(deepLink:)`를 부른다.
- 포그라운드에서는 배너 대신 앱 안 토스트로 보여주고 알림 센터 배지를 갱신한다.
- 로컬 알림: `LocalReminderScheduler`가 일정과 할 일의 알림을 예약한다. iOS는 대기 중인 로컬 알림을 64개까지만 허용하므로, 가까운 순서로 60개만 예약하고 앱이 활성화될 때마다 다시 계산한다.

---

## 7. 로컬 캐싱

### 7.1 캐시 범위와 정책
| 데이터 | 범위 | 정책 |
|---|---|---|
| 프로필, 그룹, 구성원 | 참여 중인 모든 그룹 | 앱을 시작할 때 갱신 |
| 카테고리, 결제수단 | 현재 그룹 | 전체 캐시 + Realtime |
| 거래 | 현재 그룹, 최근 13개월 | 증분 동기화 + Realtime. 더 오래된 기간은 온라인에서 조회만 한다 (캐시하지 않음) |
| 예산 | 현재 그룹 이번 달 + 지난달 | |
| 통계 | 서버 RPC 결과를 기간 키로 메모리에 캐시 (5분) | 오프라인이면 로컬 거래로 근사 계산하고 "오프라인 기준" 표시 |
| 지갑 카드 | 개인 카드 + 참여 중인 모든 그룹의 공유 카드 | **완전 캐시**. 바코드 이미지를 미리 렌더링해 파일로 저장한다 |
| 일정 | 현재 그룹, 앞뒤 6개월 | |
| 할 일 | 현재 그룹, 미완료 전체 + 최근 30일 완료 | |
| 공지 | 현재 그룹 최근 100건 | |
| 알림 | 최근 90일 | |
| 이미지 | LRU 디스크 캐시 200MB | 지갑 이미지는 LRU에서 빼서 항상 보관 |

### 7.2 SwiftData 모델 원칙
- 캐시 모델(`@Model final class CachedTransaction`)은 도메인 엔티티와 분리하고, Repository에서 매핑한다.
- `@Attribute(.unique) var id: UUID`, `version`, `updatedAt`, `deletedAt`, `syncState` (synced / pendingCreate / pendingUpdate / pendingDelete / conflict)
- 사용자별 저장소: `ModelConfiguration(url: …/\(userID).store)`. 로그아웃하면 파일을 통째로 지운다.
- 파일 보호: 저장소 디렉터리에 `FileProtectionType.completeUntilFirstUserAuthentication`을 쓴다 (백그라운드 동기화를 위해). 지갑 바코드 이미지는 `.complete`.
- 쓰기는 `@ModelActor`(백그라운드)로 처리하고, 읽기는 메인 컨텍스트의 `FetchDescriptor`로 한다.

---

## 8. 오프라인 대응과 동기화

### 8.1 쓰기 흐름 (Outbox 패턴)
```
사용자 저장
  → 로컬 캐시에 즉시 반영 (syncState = pending*)        ← UI 즉시 갱신
  → OutboxItem 추가 {id, entity, operation, payload, expectedVersion, attempt, createdAt}
  → SyncEngine.kick()
       온라인: 순서대로 RPC 전송 (같은 엔티티는 직렬, 다른 엔티티는 동시 3개까지)
         성공 → 서버 응답(version 포함)으로 캐시 갱신, syncState = synced, Outbox에서 제거
         409 충돌 → ConflictResolver
         네트워크 오류 → 지수 백오프 (2s, 4s, 8s … 최대 5분), 연결 복구(NWPathMonitor) 시 즉시 재시도
         4xx 검증·권한 오류 → 재시도하지 않음. syncState = failed, 사용자에게 알림 (수정 또는 폐기)
```
- 클라이언트가 UUID를 만들기 때문에 같은 생성 요청을 다시 보내도 `ON CONFLICT (id) DO NOTHING`(멱등)이 된다.
- 첨부 이미지 업로드는 거래 생성 Outbox가 성공한 뒤에 실행되는 하위 작업이다.

### 8.2 충돌 처리
| 상황 | 처리 |
|---|---|
| 같은 거래를 두 사람이 수정 (version 불일치) | 기본은 **서버 우선**이다. 로컬에서 바꾼 필드가 서버에서 바뀐 필드와 겹치지 않으면 자동으로 병합해 다시 보낸다. 겹치면 "다른 구성원이 먼저 수정했어요" 시트에서 [서버 버전 유지] / [내 변경 다시 적용]을 고른다. |
| 수정하려는데 서버에서 이미 삭제됨 | 로컬에서도 삭제하고 알린다. "복구" 버튼은 권한이 있을 때만 보여준다. |
| 오프라인 중에 카테고리가 삭제됨 | 서버가 거래 저장을 거부한다 (FK·비활성). 사용자에게 카테고리를 다시 고르게 한다. |
| 오프라인 중에 그룹에서 추방됨 | 동기화할 때 403 → 해당 그룹 캐시와 Outbox를 버리고 안내한다. |

### 8.3 읽기 동기화
1. 앱을 시작하거나 포그라운드로 돌아오면 `sync_changes(group, since: cursor)`를 호출한다. 테이블별 변경 행(삭제 표시 포함)과 `revoked_ids`(공개 범위가 바뀌어 더 이상 볼 수 없게 된 ID)를 받는다.
   - `revoked_ids` 계산: 서버의 DEFINER 하위 함수가 `transaction_history`(visibility 변경)와 공개 대상 변경 기록에서 "since 이후 공개 범위가 바뀌었고, 지금 호출자는 볼 수 없는 ID"만 골라 **ID만** 돌려준다 (내용은 돌려주지 않는다). 클라이언트는 그 ID를 로컬 캐시에서 지운다. 같은 방식을 일정(`visibility` 변경, 참여자 제외)에도 적용한다.
2. Realtime 이벤트로 실시간 반영
3. 가끔(하루 1회) 전체 ID 대조로 정합성을 점검한다 (드리프트 보정).

### 8.4 기능별 오프라인 지원
| 기능 | 오프라인 읽기 | 오프라인 쓰기 |
|---|---|---|
| 지갑 | ✅ | ✅ (카드 추가·수정. 이미지는 나중에 업로드) |
| 가계부 | ✅ (캐시 범위 안) | ✅ |
| 할 일 | ✅ | ✅ |
| 캘린더 | ✅ | ✅ (일정 CRUD) |
| 공지 | ✅ | ❌ (읽음 표시만 대기열에 넣음) |
| 통계 | ⚠️ 로컬 근사치 | — |
| 카테고리 관리, 가족 관리, 초대 | ✅ 읽기 | ❌ (권한·일관성 문제로 온라인 전용) |
| CSV 가져오기 | — | ❌ |

화면 상단에 오프라인 배너("오프라인 상태예요. 연결되면 자동으로 저장돼요")를 띄우고, 대기 중인 항목에는 시계 아이콘을 표시한다.

---

## 9. 오류 및 예외 처리

### 9.1 오류 모델
```swift
enum AppError: Error, Equatable {
    case network(NetworkReason)          // offline, timeout, serverUnreachable
    case unauthorized                    // 세션 만료 → 재로그인
    case forbidden                       // RLS 거부 (42501), 그룹 추방
    case notFound
    case conflict(serverVersion: Int)    // 낙관적 잠금 실패
    case validation([FieldError])        // 23514 CHECK, 23505 UNIQUE 등
    case rateLimited(retryAfter: TimeInterval?)
    case storage(StorageReason)          // 용량 초과, 형식 오류
    case server(code: String?)           // 5xx
    case unknown(underlying: String)
}
```
- `ErrorMapper`: `PostgrestError.code`(SQLSTATE) / HTTP 상태 / `URLError`를 `AppError`로 바꾼다.
  - `23505 uq_category_name` → validation(이름 중복), `23514 shared_must_be_family` → validation(공동 지출은 가족 공개만 가능), `42501` → forbidden, `40001` → conflict, `P0001`(RAISE EXCEPTION, 사용자 정의 코드 `DW###` 메시지 접두어) → 대응하는 도메인 오류.
- 화면 표시 규칙:
  | 오류 | UI |
  |---|---|
  | network | 오프라인 배너, 쓰기는 대기열에 넣음 |
  | validation | 필드 아래 인라인 메시지 |
  | conflict | 충돌 해결 시트 |
  | forbidden | 토스트 "권한이 없어요" + 화면 새로고침. 그룹에서 추방됐으면 그룹 선택 화면으로 |
  | unauthorized | 세션 갱신을 한 번 시도하고, 실패하면 로그인 화면 |
  | server/unknown | 오류 화면과 [다시 시도], 오류 ID 표시 (지원 문의용) |
- 크래시를 막기 위해 `fatalError`와 강제 언래핑은 금지한다 (린트 규칙). 예외는 `Result`/`throws`로 전파한다.
- 모든 오류는 `Log.error`로 기록한다. 금액, 메모, 바코드 값 같은 개인정보는 로그에 남기지 않는다.

### 9.2 엣지 케이스 체크리스트
- 월 시작일이 25일인 그룹에서 "이번 달" 기간 계산, 2월과 말일 처리
- 그룹 시간대와 기기 시간대가 다를 때 날짜 표시 (그룹 시간대를 기준으로 한다)
- 여름시간(DST)이 있는 시간대로 확장할 때 반복 일정 계산 (`Calendar`와 `TimeZone` 사용)
- 999,999,999,999원을 넘는 입력 방지, 천 단위 구분 기호 입력 처리
- 그룹을 전환하는 중에 늦게 도착한 응답 무시 (요청에 groupID 태그를 붙여 비교)
- 같은 거래 저장 버튼을 여러 번 누르는 경우 (버튼 비활성화와 UUID 멱등성)
- 로컬 알림 64개 한도

---

## 10. 테스트 전략

| 레벨 | 도구 | 대상 | 기준 |
|---|---|---|---|
| 단위 | Swift Testing (`@Test`) | DWCore (RRule, 기간 계산, 금액 포맷, 해시), DWDomain (권한 정책, 중복 판정, 자동 분류), ViewModel (Mock Repository) | 커버리지 70% 이상, 기간·반복 계산은 경계값 테스트 100% |
| 매퍼·DTO | Swift Testing + JSON Fixture | 서버 응답 디코딩, snake_case 매핑 | 모든 DTO |
| 동기화 | Swift Testing + 인메모리 SwiftData + FakeRemote | Outbox 재시도, 충돌, 오프라인 → 온라인 전환, 멱등성 | 시나리오 20개 이상 |
| DB / RLS | pgTAP (`supabase test db`) | 모든 테이블 정책, RPC 권한, 트리거, 제약 | 정책별 허용·거부 케이스 각 1개 이상 |
| 통합 | XCTest + 로컬 Supabase (CI에서 `supabase start`) | Repository 구현이 실제 DB에서 동작하는지 | 핵심 플로우 |
| UI | XCUITest (Mock 서버 모드 실행 인자 `-UITestMock`) | 로그인, 거래 등록, 바코드 표시, 할 일 완료, 초대 수락 | 스모크 10개 |
| 스냅샷 | swift-snapshot-testing (dev 의존성) | 디자인 시스템 컴포넌트 라이트·다크·AX 글자 크기 | 컴포넌트 전체 |
| 접근성 | Xcode Accessibility Inspector, `performAccessibilityAudit()` (XCUITest) | 주요 화면 | 매 릴리스 |
| 성능 | XCTest `measure`, Instruments | 거래 1만 건 목록 스크롤, 콜드 스타트 | NFR-01 |
| 수동 QA | 테스트 케이스 문서 | 다중 기기 실시간 동기화, 푸시, 오프라인 | 릴리스마다 |

### CI (GitHub Actions)
1. `supabase start` → 마이그레이션 → `supabase test db` (pgTAP)
2. `xcodebuild test` (iPhone 시뮬레이터, macOS 러너)
3. SwiftLint, SwiftFormat 검사
4. main에 머지하면 staging 마이그레이션 → TestFlight 배포 (fastlane)
