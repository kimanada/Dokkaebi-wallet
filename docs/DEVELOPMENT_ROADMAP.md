# 도깨비 지갑 — 개발 로드맵

- 기준 인력: iOS 2명, 백엔드 1명, 디자이너 1명, QA 0.5명 (PROJECT_PLAN.md §5)
- 기간 단위: 주 (2주 스프린트). 총 약 30주 + 출시 후 확장
- 우선순위 P0/P1/P2는 REQUIREMENTS.md를 따른다.

---

## 1. 전체 일정

| 단계 | 기간 | 주요 산출물 | 마일스톤 |
|---|---|---|---|
| Phase 0. 기반 구축 | 1~2주 | 프로젝트 골격, CI, Supabase 환경, 디자인 토큰 | M0: 빈 앱이 CI에서 빌드되고 테스트가 돈다 |
| Phase 1. 인증과 가족 그룹 | 3~5주 | 로그인, 프로필, 그룹 생성·초대·전환, 역할, RLS 헬퍼 | M1: 두 사람이 같은 그룹에 들어간다 |
| Phase 2. 가계부 핵심 | 6~10주 | 거래 CRUD, 카테고리, 결제수단, 공개 범위, 영수증, 검색·필터, Realtime | M2: 가족이 거래를 함께 기록하고 실시간으로 본다 |
| Phase 3. 예산, 통계, 홈 | 11~13주 | 예산, 통계 차트, 홈 대시보드 | **M3: 내부 알파 (가계부 MVP)** |
| Phase 4. 디지털 지갑 | 14~15주 | 카드 CRUD, 스캔, 바코드 생성, 전체 화면, 오프라인 캐시 | M4: 매장에서 오프라인으로 바코드를 보여줄 수 있다 |
| Phase 5. 캘린더 | 16~18주 | 월·주·일 보기, 일정 CRUD, 참여자, 반복, 로컬 알림 | |
| Phase 6. 공지, 할 일, 알림 | 19~21주 | 공지와 읽음 상태, 할 일, 알림 센터, APNs 푸시 파이프라인 | **M5: 기능 완성 (Feature Complete), 클로즈드 베타** |
| Phase 7. 오프라인·안정화·가져오기 | 22~24주 | Outbox 확장, 충돌 처리, 반복 거래, CSV 가져오기, 자동 분류 | |
| Phase 8. 품질과 출시 | 25~30주 | 성능, 접근성, 보안 점검, 모의해킹, 앱스토어 심사 | **M6: App Store 출시 (v1.0)** |
| Phase 9. 확장 | 출시 후 | 금융 데이터 제휴 연동, 위젯, iPad, 댓글, Apple Wallet 등 | v1.x / v2.0 |

> P0 기능은 Phase 1~6에서, P1 기능은 Phase 5~8에서 완성한다. 일정이 밀리면 P1 중 **반복 거래, CSV 가져오기, 활동 피드, 카카오 로그인** 순서로 v1.1로 미룰 수 있다. 하지만 요구사항 자체는 줄이지 않고 출시 버전만 조정한다.

---

## 2. 단계별 상세

### Phase 0. 기반 구축 (1~2주)
**iOS**
- Xcode 프로젝트, 로컬 SPM 패키지 5개(DWCore, DWDomain, DWData, DWDesignSystem, DWFeatures) 구성
- xcconfig 3종, AppConfig, 의존성 주입(AppContainer), 탭 골격, Router
- SwiftLint/SwiftFormat 규칙, `os.Logger` 래퍼, AppError와 ErrorMapper 뼈대
- 디자인 토큰 (색상 세트 라이트·다크, 폰트, 간격, 반경), DWCard·DWButton·DWTextField
**백엔드**
- Supabase dev/staging/prod 프로젝트 (서울 리전), CLI 로컬 환경
- 확장 설치, ENUM, 공통 트리거, `private` 스키마, 헬퍼 함수 골격
- pgTAP 실행 환경
**공통**
- GitHub Actions: pgTAP → iOS 빌드·테스트 → 린트
- 디자인: 핵심 화면 와이어프레임(홈, 거래 입력, 지갑) 확정

**완료 기준**: CI 녹색, 시뮬레이터에서 탭 5개 이동, 다크 모드 토큰 전환 확인.

### Phase 1. 인증과 가족 그룹 (3~5주)
- 테이블: profiles, family_groups, family_members, family_invitations, private.rate_limits, private.audit_logs
- RPC: create_family_group, create_invitation, preview_invitation, accept_invitation, leave_group, remove_member, change_member_role, transfer_ownership
- iOS: Sign in with Apple, 이메일 OTP, 프로필 설정, 온보딩, 초대(공유 시트, Universal Link와 AASA 파일 호스팅), 그룹 전환기, 가족 관리 화면, 앱 잠금
- 계정 삭제 Edge Function (`delete-account`) — 심사 필수이므로 일찍 만든다
- pgTAP: T1, T8, T9, T14

**완료 기준**: 기기 2대에서 초대 → 수락 → 같은 그룹 확인. 추방하면 즉시 접근 차단.

### Phase 2. 가계부 핵심 (6~10주)
- 테이블: categories(+기본 시드), payment_methods, transactions, transaction_visible_members, transaction_attachments, transaction_history
- RPC: upsert_transaction, soft_delete/restore, delete_category, search_transactions, sync_changes
- Storage: receipts 버킷과 정책
- iOS:
  - 거래 입력 시트 (금액 키패드, 유형, 카테고리 그리드, 공동·개인, 실사용자, 공개 범위, 영수증 첨부·문서 스캔)
  - 월별 목록, 상세, 수정, 삭제·실행 취소, 검색, 필터
  - 카테고리 관리 (추가, 편집, 정렬, 사용 중지, 대체 후 삭제), 결제수단 관리
  - SwiftData 캐시, 증분 동기화, RealtimeService, **기본 Outbox (거래 한정)**
- pgTAP: T2~T7, T11, T13, T17

**완료 기준**: 한 명이 등록한 거래가 2초 안에 다른 기기에 보인다. private 거래는 보이지 않는다. 비행기 모드에서 등록한 거래가 연결 후 동기화된다.

### Phase 3. 예산, 통계, 홈 (11~13주)
- 테이블: budgets, budget_categories, activity_logs
- RPC: get_budget_status, get_monthly_summary, get_category_breakdown, get_member_breakdown, get_dashboard
- 예산 임계치 판단 트리거 (알림 행은 Phase 6 파이프라인에 연결. 그 전까지는 앱 안 표시만)
- iOS: 예산 화면·편집, 통계 차트 4종과 전월 대비, 홈 대시보드 (일정·할 일·공지 카드는 빈 상태 자리만)
- 성능: 거래 1만 건 시드로 목록과 통계 응답 측정

**M3 내부 알파**: 팀 가족을 대상으로 2주 동안 실제로 써 본다 (TestFlight 내부).

### Phase 4. 디지털 지갑 (14~15주)
- 테이블: wallet_cards, wallet_card_user_prefs / Storage: wallet-images
- iOS: 카드 목록(개인·가족 필터, 즐겨찾기, 검색), 편집, VisionKit 실시간 스캔, 사진에서 인식, Core Image 생성기와 1D 인코더(EAN-13/8, UPC-A, Code39, ITF), 전체 화면(밝기, 자동 잠금 방지, 가로), 오프라인 완전 캐시, 지갑 잠금
- 테스트: 인코더 체크섬 단위 테스트, 실제 매장 POS 스캐너로 인식 검증 (주요 멤버십 10종)
- pgTAP: T12

**완료 기준**: 비행기 모드 + 앱 재시작 후에도 모든 카드를 전체 화면으로 표시할 수 있다.

### Phase 5. 캘린더 (16~18주)
- 테이블: calendar_events, event_participants, event_exceptions, event_reminders
- RPC: get_events
- iOS: RRULE 파서·전개기 (DWCore, 경계값 테스트), 월·주·일 뷰 (직접 만든 그리드, 스크롤 성능), 일정 편집, 반복 수정 범위 3종, 참여자 응답, LocalReminderScheduler (64개 한도 관리), 공휴일 데이터
- 홈 일정 카드 연결

### Phase 6. 공지, 할 일, 알림 (19~21주)
- 테이블: notices, notice_attachments, notice_reads, tasks, task_assignees, notifications, notification_preferences, device_tokens, private.push_queue
- 알림 생성 트리거 (거래, 공지, 일정, 할 일, 예산, 구성원), Database Webhook → Edge Function `send-push` (APNs .p8), pg_cron (마감 알림, 정리 작업)
- iOS: 공지 목록·상세·작성(이미지)·고정·읽음 현황, 할 일 목록·보드·편집·완료 체크, 알림 센터, 알림 설정, 딥링크 처리, 앱 아이콘 배지
- 홈 할 일·공지·활동 카드 연결
- pgTAP: T10, T15, T16

**M5 기능 완성 / 클로즈드 베타**: 외부 베타 가족 20~30팀 (TestFlight 외부), 피드백 수집 채널 운영.

### Phase 7. 오프라인·안정화·가져오기 (22~24주)
- Outbox를 할 일과 일정으로 확장하고 지갑 이미지 업로드 대기열 추가, 충돌 해결 UI, 하루 1회 정합성 점검
- 반복 거래 (recurring_transactions, pg_cron 생성, 확인 대기 흐름), 반복 할 일
- CSV 가져오기: 인코딩 감지, 열 매핑과 프리셋, 미리보기, 중복 판정, 되돌리기, category_rules와 기본 가맹점 사전, 가져오기 기록
- 데이터 내보내기 (CSV/JSON), 카카오 로그인
- 베타 피드백 반영

### Phase 8. 품질과 출시 (25~30주)
| 주 | 작업 |
|---|---|
| 25 | 성능 최적화 (콜드 스타트, 목록, 이미지), 메모리 누수 점검 (Instruments) |
| 26 | 접근성 감사 (Dynamic Type AX5, VoiceOver 전 화면, 대비), 스냅샷 테스트 보강 |
| 27 | 보안: Security Advisor, RLS 전수 리뷰, 외부 모의해킹 |
| 28 | 모의해킹 결과 반영, 개인정보 처리방침·이용약관 법률 검토, 앱 내 고지 |
| 29 | App Store 자료 (스크린샷, 설명, 개인정보 라벨, PrivacyInfo), 심사 제출 |
| 30 | 심사 대응, 단계적 출시 (Phased Release 7일), 운영 모니터링 대시보드 |

**출시 기준 (Exit Criteria)**
- P0 요구사항 100% 완료, P1은 90% 이상 (미완료 항목은 v1.1 계획에 포함)
- pgTAP T1~T17 전부 통과, 크리티컬·높음 등급 보안 이슈 0건
- 베타 크래시 없는 세션 99.5% 이상
- NFR-01~04 성능 기준 충족

### Phase 9. 출시 후 확장
| 버전 | 내용 |
|---|---|
| v1.1 | 미룬 P1 항목, 홈 위젯(WidgetKit), 홈 카드 편집, 영수증 OCR |
| v1.2 | iPad `NavigationSplitView` 레이아웃, 공지 댓글, 할 일 체크리스트, EventKit 내보내기 |
| v1.3 | 예산 이월, 쿠폰 만료 알림, Apple Wallet(.pkpass) 내보내기 검토, XLSX 가져오기 |
| v2.0 | **금융 데이터 제휴 연동**: 업체 선정 (공식 API 또는 허가 기반 업체만) → 계약·보안 심사 → `financial_connections`, Edge Function `financial-sync`, 동의 관리 UI. 법률 검토 (신용정보법) 포함 3~4개월 |
| 이후 | 다국어(en), 다중 통화, 가족 목표 저축, 정기 리포트 푸시, 지갑 카드 컬럼 암호화 재검토 |

---

## 3. 단계별 의존 관계

```
Phase 0 ─▶ Phase 1 ─▶ Phase 2 ─▶ Phase 3 ─┬─▶ Phase 7 ─▶ Phase 8
                     │                    │
                     ├─▶ Phase 4 (지갑은 그룹만 있으면 병렬 가능)
                     └─▶ Phase 5 ─▶ Phase 6 (알림 파이프라인은 일정·할 일 필요)
```
- iOS 개발자 2명은 Phase 4(지갑)를 Phase 3와 병렬로 진행해 2주를 앞당길 수 있다.
- 백엔드는 알림 파이프라인(`send-push`)을 Phase 3부터 미리 만들어 Phase 6의 위험을 줄인다.

---

## 4. 주요 위험과 일정 완충

| 위험 | 완충 |
|---|---|
| 동기화 엔진 복잡도 | Phase 2에서는 거래만으로 범위를 제한하고, Phase 7에 3주를 배정 |
| 캘린더 반복 일정 버그 | RRULE 지원 범위를 문서로 고정하고 (D8), 경계값 테스트를 먼저 작성 |
| App Store 심사 거절 | Phase 1에 계정 삭제, Sign in with Apple, 개인정보 매니페스트를 먼저 구현 |
| 바코드 인식 실패 (매장) | Phase 4에 실제 매장 테스트를 포함하고, 원본 이미지 표시를 대체 수단으로 둠 |
| 금융 제휴 지연 | v2.0으로 분리해 v1 출시와 무관하게 진행 |

---

## 5. 스프린트 운영 규칙
- 2주 스프린트: 계획 → 개발 → 데모 (실기기 2대로 실시간 동기화 시연) → 회고
- 완료 정의(DoD): 코드 리뷰 승인, 단위 테스트, 관련 pgTAP 테스트, 라이트·다크·큰 글자 스크린샷 확인, 문서(이 디렉터리) 갱신
- 설계 문서를 바꿀 때는 PROJECT_PLAN.md §3 핵심 결정과 충돌하는지 먼저 확인하고, 관련 문서를 같은 PR에서 함께 수정한다.
