# 도깨비 지갑 — 보안 정책

## 1. 보안 원칙
1. **서버가 최종 판정한다**: 모든 접근 제어는 PostgreSQL RLS와 Storage 정책에서 한다. 앱의 `PermissionPolicy`는 버튼을 보여줄지 정하는 용도일 뿐 보안 경계가 아니다.
2. **최소 권한**: 클라이언트는 `anon` 키와 사용자 JWT만 가진다. `service_role` 키는 Edge Function 시크릿에만 둔다.
3. **역할 ≠ 열람 권한**: 소유자와 관리자도 다른 구성원의 비공개 데이터를 볼 수 없다.
4. **기본 거부**: RLS를 켠 테이블에 정책이 없으면 접근할 수 없다. 새 테이블은 RLS 활성화와 pgTAP 테스트가 있어야 머지할 수 있다.
5. **최소 수집**: 결제카드 전체 번호, 계좌 비밀번호, 주민등록번호는 수집하지 않는다.

---

## 2. 인증과 세션

| 항목 | 정책 |
|---|---|
| 로그인 수단 | Sign in with Apple, 이메일 OTP, 카카오 (P1). 비밀번호 로그인은 제공하지 않는다 (비밀번호 유출 위험 제거) |
| OTP | 6자리, 유효 10분, 재전송 60초 간격, 시간당 5회 (Supabase Auth Rate Limit 설정) |
| 토큰 | Access token 1시간, Refresh token 순환(rotation) 사용, 재사용 감지 시 전체 세션 폐기 |
| 저장 | Keychain, `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` (백업과 다른 기기로 옮겨지지 않음) |
| PKCE | OAuth 흐름에 PKCE를 사용하고, Apple 로그인에는 nonce 사용 |
| 앱 잠금 | `LAContext` 생체 인증 → 실패하면 기기 암호. 백그라운드 진입 시 앱 전환기 화면 가리기 (블러) |
| 재인증 | 계정 삭제, 그룹 삭제, 소유권 이전, 금융 연동 동의 전에는 재인증 (최근 5분 이내 로그인) |
| 로그아웃 | 서버 세션 폐기, `device_tokens` 삭제, Keychain·SwiftData·이미지 캐시 삭제, 예약된 로컬 알림 제거 |
| 다중 기기 | 허용. 설정에서 로그인한 기기 목록과 원격 로그아웃 (P1, `auth.sessions` 기반 Edge Function) |

---

## 3. 권한 모델

### 3.1 접근 판정 계층
```
① 인증: JWT 유효성 (auth.uid())
② 그룹 멤버십: private.is_member(family_group_id) — status = 'active'만
③ 역할: private.my_role() — 관리 작업
④ 데이터 공개 범위: visibility (family / private / selected) + 작성자·실사용자·참여자
⑤ 컬럼 단위: GRANT UPDATE (col) + BEFORE UPDATE 트리거
```

### 3.2 데이터 분류
| 등급 | 예 | 보호 |
|---|---|---|
| 민감 (S) | 개인 비공개 거래, 개인 예산, 금융 연동 토큰, import 원본 행, 이메일 | RLS로 본인만, 토큰은 Vault, 로그 금지 |
| 제한 (R) | 가족 공개 거래, 영수증, 지갑 카드 번호·바코드, 일정 장소 | 그룹 구성원만, 기기 저장 시 Data Protection |
| 내부 (I) | 카테고리, 공지, 할 일 | 그룹 구성원만 |
| 공개 (P) | 초대 미리보기(그룹명, 초대자 이름, 인원) | 유효한 초대 토큰이 있을 때만, rate limit |

### 3.3 주요 위협과 대응
| 위협 | 대응 |
|---|---|
| 다른 그룹 데이터 접근 (IDOR) | 모든 정책에 그룹 멤버십 확인. UUID는 추측할 수 없지만 그것에 의존하지 않는다 |
| 관리자가 다른 사람의 비공개 거래 조회 | `can_view_transaction`에 역할 조건이 없다. pgTAP로 검증한다 |
| 공개 범위를 우회하는 집계 | 통계 RPC는 모두 SECURITY INVOKER로 RLS를 그대로 적용한다. DEFINER 집계(예산 알림)는 결과를 공동 지출 또는 본인 데이터로만 제한한다 |
| 알림과 활동 피드를 통한 유출 | 수신자별 권한을 확인한 뒤 알림을 만든다. private 데이터는 활동 기록을 만들지 않는다. 푸시 본문에서 금액 숨기기 옵션 |
| Realtime 이전 값(old record) 유출 | `REPLICA IDENTITY FULL`을 쓰지 않는다. 물리 DELETE 대신 소프트 삭제 |
| `created_by` 위조 | INSERT 트리거로 `auth.uid()` 강제 |
| 그룹 간 참조 주입 (다른 그룹의 category_id 등) | 검증 트리거가 같은 그룹인지 확인 |
| 탈퇴하거나 추방된 구성원의 남은 접근 | 멤버십 status가 바뀌는 즉시 RLS로 차단. 클라이언트는 다음 요청에서 403을 받고 캐시를 지운다. 이미 기기에 있는 캐시는 기술적으로 회수할 수 없으므로 앱이 다음에 실행될 때 지운다 (한계로 명시) |
| 초대 코드 무차별 대입 | 6자리 영숫자 (32^6 ≈ 10억) + 사용자당 10분에 10회 제한 + 만료 |
| 초대 링크 유출 | 토큰은 해시로 저장하고, 사용 횟수 제한과 관리자 회수(revoke) 기능을 둔다 |
| 영수증 URL 공유로 유출 | 비공개 버킷, Signed URL 1시간 |
| SECURITY DEFINER 함수 악용 | `SET search_path = ''`, 함수 첫 줄에서 권한 확인, `private` 스키마에 두고 `public` API로 노출하지 않으며, 필요한 함수만 `GRANT EXECUTE` |
| SQL 주입 | PostgREST 파라미터 바인딩만 쓴다. RPC 안에서 동적 SQL을 금지하며, 꼭 필요하면 `format('%I', …)`을 쓴다 |
| 남용 (대량 요청) | Supabase API rate limit, RPC별 `private.rate_limits`, Edge Function에서 JWT 검증 |
| 탈옥 기기, 디버거 | 완전한 방어는 불가능하다. 민감 화면 스크린샷 감지 안내(P2), 서버 검증으로 피해 범위 제한 |

---

## 4. 데이터 보호

### 4.1 전송
- 모든 통신은 HTTPS (TLS 1.2 이상), ATS 예외 없음.
- 인증서 고정(pinning)은 Supabase 인증서 교체 위험 때문에 기본으로 쓰지 않는다. 금융 연동을 도입할 때 공개키 고정 여부를 검토한다.

### 4.2 서버 저장
- Supabase 기본 디스크 암호화(AES-256)와 서울 리전.
- 금융 연동 토큰과 APNs 키는 Supabase Vault와 Edge Function 시크릿에 둔다.
- 백업: Supabase PITR (Pro 플랜 이상), 보관 7일. 복구 절차는 분기마다 점검한다.
- 지갑 카드 번호를 컬럼 단위로 암호화(pgsodium)하는 것은 검토했지만, 그룹 공유 카드를 복호화하려면 키를 그룹 단위로 관리해야 해서 복잡도가 높다. 그래서 RLS + 디스크 암호화로 시작하고 P2에서 다시 검토한다. 결제카드 번호는 입력 단계에서 경고한다 (Luhn 검사).

### 4.3 기기 저장
| 데이터 | 위치 | 보호 |
|---|---|---|
| 세션 토큰 | Keychain | ThisDeviceOnly |
| SwiftData 캐시 | App Support/사용자ID/ | `completeUntilFirstUserAuthentication`, iCloud 백업 제외 (`isExcludedFromBackup`) |
| 지갑 바코드 이미지 | App Support/wallet/ | `complete` (잠금 상태에서는 접근 불가) |
| 이미지 캐시 | Caches/ | `completeUntilFirstUserAuthentication` |
| 위젯 공유 데이터 (P2) | App Group 컨테이너 | 요약 수치만 (거래 상세 저장 금지) |

### 4.4 로깅
- `os.Logger`에서 금액, 메모, 사용처, 바코드 값, 이메일은 `privacy: .private`으로 처리한다.
- 크래시 리포트 도구에는 사용자 ID 해시만 보내고, 화면 텍스트와 네트워크 본문은 보내지 않는다.
- 서버: Edge Function 로그에 요청 본문을 남기지 않는다. `private.audit_logs`에 보안 이벤트(역할 변경, 추방, 소유권 이전, 그룹·계정 삭제, 초대 생성·수락, 금융 연동 동의·철회)를 기록하고 1년 보관한다.

### 4.5 이미지
- 업로드 전에 EXIF(GPS 포함)를 지운다.
- 허용 MIME과 크기를 버킷 설정과 클라이언트 양쪽에서 검증한다.

---

## 5. 개인정보 처리 (개인정보보호법)

| 항목 | 정책 |
|---|---|
| 수집 항목 | 필수: 이메일 또는 Apple/카카오 식별자, 표시 이름. 선택: 프로필 사진. 서비스 이용 중 생성: 거래, 일정 등 |
| 수집 목적 | 가족 공유 가계부와 생활 관리 서비스 제공 |
| 보관 | 회원 탈퇴 시 지체 없이 파기. 공동 기록은 작성자 식별 정보를 지우고(`SET NULL`) 그룹에 남긴다. 이 내용을 처리방침과 탈퇴 화면에서 알린다 |
| 소프트 삭제 데이터 | 30일 뒤 영구 삭제 |
| 국외 이전 | 서울 리전을 써서 데이터 저장소는 국내에 둔다. APNs(Apple) 전송은 국외 이전에 해당하므로 처리방침에 적는다. 크래시 분석 도구도 같다 |
| 위탁 | Supabase(인프라), Apple(푸시), 크래시 분석 도구 → 처리방침에 수탁자 목록 |
| 아동 | 만 14세 미만은 법정대리인 동의가 필요하다. 가입할 때 나이를 확인하고, 미만이면 보호자(그룹 소유자) 동의 절차를 거친다 (P1, 법률 검토 후 확정) |
| 정보주체 권리 | 열람(데이터 내보내기 CSV/JSON), 정정, 삭제(계정 삭제), 처리 정지(알림 끄기) |
| App Store | Privacy Nutrition Label, `PrivacyInfo.xcprivacy` (Required Reason API: UserDefaults, 파일 타임스탬프 등 신고), 앱 안 계정 삭제 |
| 금융 데이터 (P2) | 신용정보법을 검토한다. 제휴 업체의 허가 범위 안에서만, 별도 동의(목적, 항목, 기간)와 철회 기능을 둔다 |

---

## 6. 보안 검증

### 6.1 필수 pgTAP 테스트 (CI를 통과해야 머지)
| # | 시나리오 | 기대 결과 |
|---|---|---|
| T1 | 그룹 B 사용자가 그룹 A의 모든 테이블을 SELECT | 0행 |
| T2 | 그룹 B 사용자가 그룹 A로 거래 INSERT | 42501 |
| T3 | 구성원 X의 private 거래를 소유자가 SELECT / 통계 RPC 호출 | 0행 / 합계에서 제외 |
| T4 | selected 거래를 지정되지 않은 구성원이 조회 | 0행 |
| T5 | 공동 지출을 private로 INSERT 또는 UPDATE | 23514 |
| T6 | 관리자가 다른 사람의 personal 거래를 UPDATE | 0행 갱신 |
| T7 | 관리자가 다른 사람의 공동 지출을 personal 또는 private로 바꿈 | 거부 |
| T8 | member가 역할 컬럼을 UPDATE | 거부 |
| T9 | 추방된 사용자가 즉시 SELECT | 0행 |
| T10 | 클라이언트가 notifications에 INSERT | 거부 |
| T11 | 다른 사람의 영수증 Storage 객체 다운로드 (private 거래) | 거부 |
| T12 | 개인 지갑 카드를 같은 그룹의 다른 구성원이 조회 | 0행 |
| T13 | 다른 그룹의 category_id로 거래 생성 | 검증 트리거 오류 |
| T14 | 만료되거나 회수된 초대 코드로 수락 | 오류 |
| T15 | 담당자가 할 일 제목을 UPDATE | 거부 (상태만 바꿀 수 있음) |
| T16 | activity_logs에 private 거래 흔적이 남는지 | 없음 |
| T17 | 공개 범위를 private로 바꾼 뒤 다른 구성원의 sync_changes 응답 | revoked_ids에 포함되고 내용은 없음 |

### 6.2 정기 점검
- 마이그레이션 PR마다 보안 체크리스트: RLS 활성화, 정책 4종(SELECT/INSERT/UPDATE/DELETE) 검토, DEFINER 함수 search_path, 인덱스.
- Supabase Security Advisor(Database Linter)를 배포 전에 실행한다.
- 출시 전 외부 모의해킹 1회, 이후 연 1회.
- 의존성 취약점 점검 (GitHub Dependabot, SPM).

---

## 7. 사고 대응

1. 탐지: 비정상 트래픽 경보 (Supabase 로그 드레인 → 모니터링), 사용자 신고
2. 차단: 문제 정책을 핫픽스 마이그레이션으로 고치거나, 해당 RPC의 `REVOKE EXECUTE`, 필요하면 세션 일괄 폐기
3. 조사: audit_logs와 API 로그 분석, 영향 범위 산정
4. 통지: 개인정보 유출이 확인되면 72시간 안에 정보주체에게 통지하고 개인정보보호위원회에 신고 (법정 기준 확인)
5. 재발 방지: 해당 시나리오를 pgTAP 테스트로 추가

---

## 8. 개발 보안 규칙
- 시크릿을 저장소에 커밋하지 않는다. `.xcconfig`의 anon key는 공개되어도 되는 값이지만 환경별로 분리하고, service_role 키는 절대 포함하지 않는다.
- `print()`를 금지하고 `Log`를 쓴다 (SwiftLint 커스텀 규칙).
- 강제 언래핑과 `try!`를 금지한다 (테스트 코드 제외).
- 붙여넣기 보드: 바코드 번호를 복사하면 `UIPasteboard`의 `localOnly`와 `expirationDate`(60초)를 설정한다.
- 화면 녹화 중이거나 앱 전환기에서는 지갑 전체 화면을 가린다 (`sceneWillResignActive` 블러).
