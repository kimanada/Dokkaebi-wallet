# 도깨비 지갑 — 데이터베이스 설계

- DBMS: Supabase PostgreSQL 15+
- 스키마: `public` (앱 데이터), `private` (보안 함수와 내부 테이블, API로 노출하지 않음), `auth`/`storage` (Supabase 관리)
- 확장: `pgcrypto`, `pg_trgm`, `pg_cron`, `pg_net`, `supabase_vault`, `pgtap` (테스트 전용)
- 공통 규칙은 PROJECT_PLAN.md §3의 D1~D12를 따른다.

---

## 1. 공통 규칙

| 항목 | 규칙 |
|---|---|
| PK | `id uuid PRIMARY KEY DEFAULT gen_random_uuid()`. 클라이언트에서 UUID를 만들어 보낼 수 있다 (D9). |
| 감사 컬럼 | `created_at timestamptz NOT NULL DEFAULT now()`, `updated_at timestamptz NOT NULL DEFAULT now()` (트리거로 갱신) |
| 동시성 | 동기화 대상 테이블은 `version integer NOT NULL DEFAULT 1`. 수정할 때마다 트리거가 1씩 올린다. 클라이언트는 `WHERE version = :expected` 조건으로 수정한다. |
| 소프트 삭제 | `deleted_at timestamptz NULL` (D10). **RLS SELECT 정책은 `deleted_at`으로 거르지 않는다.** 거르면 (1) 동기화 RPC가 삭제 표시(tombstone)를 돌려줄 수 없고, (2) `deleted_at`을 채우는 UPDATE가 RLS 검사(새 행이 SELECT 정책을 통과해야 함)에서 실패한다. 대신 일반 조회용 뷰와 RPC, 클라이언트 쿼리에서 `deleted_at IS NULL`을 명시하고, 부분 인덱스로 성능을 확보한다. |
| 그룹 분리 | 그룹에 속한 데이터는 `family_group_id uuid NOT NULL REFERENCES family_groups(id) ON DELETE CASCADE` |
| 사용자 참조 | `REFERENCES public.profiles(id)`. 탈퇴한 사용자를 참조할 때는 `ON DELETE SET NULL`로 두어 공동 기록을 보존한다. |
| 금액 | `bigint NOT NULL CHECK (amount > 0)`, `currency char(3) NOT NULL DEFAULT 'KRW'` (D4) |
| 열거형 | PostgreSQL `ENUM` 타입 (아래 §2) |
| 명명 | snake_case, 복수형 테이블명, FK는 `<단수>_id` |

### 1.1 공통 트리거 함수
```sql
-- updated_at 갱신과 version 증가
CREATE FUNCTION private.touch_row() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  IF TG_OP = 'UPDATE' THEN NEW.version := OLD.version + 1; END IF;
  RETURN NEW;
END $$;
```
`version` 컬럼이 있는 모든 테이블에 `BEFORE UPDATE` 트리거로 붙인다. 없는 테이블에는 `updated_at`만 갱신하는 `private.touch_updated_at()`을 쓴다.

---

## 2. 열거형 (ENUM)

| 타입 | 값 |
|---|---|
| `member_role` | `owner`, `admin`, `member` |
| `member_status` | `active`, `left`, `removed` |
| `invitation_status` | `pending`, `accepted`, `revoked`, `expired` |
| `transaction_type` | `income`, `expense`, `transfer` |
| `expense_scope` | `shared`, `personal` |
| `visibility` | `family`, `private`, `selected` |
| `transaction_status` | `confirmed`, `pending_review` |
| `transaction_source` | `manual`, `recurring`, `csv_import`, `provider_sync` |
| `category_kind` | `income`, `expense` |
| `payment_method_type` | `bank_account`, `savings`, `credit_card`, `debit_card`, `cash`, `easy_pay`, `other` |
| `budget_scope` | `family`, `personal` |
| `wallet_scope` | `personal`, `family` |
| `barcode_type` | `qr`, `code128`, `ean13`, `ean8`, `upca`, `code39`, `itf`, `pdf417`, `aztec`, `data_matrix`, `image_only` |
| `event_response` | `pending`, `accepted`, `declined`, `tentative` |
| `task_status` | `todo`, `in_progress`, `done` |
| `task_priority` | `low`, `normal`, `high`, `urgent` |
| `notification_type` | `transaction_created`, `notice_created`, `event_created`, `event_updated`, `event_deleted`, `task_assigned`, `task_due_soon`, `task_overdue`, `budget_warning`, `budget_exceeded`, `member_joined`, `member_left`, `invitation_accepted` |
| `import_status` | `parsing`, `previewing`, `completed`, `failed`, `reverted` |
| `import_row_status` | `new`, `duplicate`, `suspected_duplicate`, `error`, `imported`, `skipped` |
| `device_platform` | `ios` |

---

## 3. ERD 개요

```
auth.users 1─1 profiles
profiles 1─N family_members N─1 family_groups
family_groups 1─N family_invitations
family_groups 1─N categories (self-ref parent_id)
family_groups 1─N payment_methods ─N:1 profiles(owner)
family_groups 1─N transactions ─N:1 categories / payment_methods / profiles(created_by, spent_by)
transactions 1─N transaction_visible_members N─1 profiles
transactions 1─N transaction_attachments
transactions 1─N transaction_history
family_groups 1─N recurring_transactions 1─N transactions
family_groups 1─N budgets 1─N budget_categories N─1 categories
profiles 1─N wallet_cards(personal) / family_groups 1─N wallet_cards(family)
family_groups 1─N calendar_events 1─N event_participants / event_exceptions / event_reminders
family_groups 1─N notices 1─N notice_attachments / notice_reads
family_groups 1─N tasks 1─N task_assignees
profiles 1─N notifications, device_tokens, notification_preferences
family_groups 1─N activity_logs
family_groups 1─N category_rules, import_batches 1─N import_rows
profiles 1─N financial_connections (P2)
```

---

## 4. 테이블 상세

### 4.1 사용자와 그룹

#### `profiles`
`auth.users`와 1:1 관계다. 가입하면 트리거(`on_auth_user_created`)가 자동으로 만든다.

| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | uuid | PK, FK → auth.users(id) ON DELETE CASCADE | |
| display_name | text | NOT NULL, CHECK (char_length BETWEEN 1 AND 30) | 표시 이름 |
| avatar_path | text | NULL | Storage `avatars` 경로 |
| locale | text | NOT NULL DEFAULT 'ko-KR' | |
| time_zone | text | NOT NULL DEFAULT 'Asia/Seoul' | |
| last_active_group_id | uuid | NULL, FK → family_groups(id) ON DELETE SET NULL | 마지막으로 선택한 그룹 |
| default_expense_scope | expense_scope | NOT NULL DEFAULT 'shared' | 거래 입력 기본값 |
| default_visibility | visibility | NOT NULL DEFAULT 'family' | |
| created_at, updated_at | timestamptz | | |

> 이메일은 `auth.users`에만 둔다. 다른 구성원에게 이메일을 노출하지 않는다.

#### `family_groups`
| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | uuid | PK | |
| name | text | NOT NULL, CHECK (char_length BETWEEN 1 AND 30) | |
| image_path | text | NULL | Storage `group-images` |
| owner_id | uuid | NOT NULL, FK → profiles(id) | 비정규화 캐시. 실제 기준은 `family_members.role` (트리거로 일치시킴) |
| currency | char(3) | NOT NULL DEFAULT 'KRW' | |
| time_zone | text | NOT NULL DEFAULT 'Asia/Seoul' | |
| month_start_day | smallint | NOT NULL DEFAULT 1, CHECK (BETWEEN 1 AND 28) | |
| members_can_manage_categories | boolean | NOT NULL DEFAULT true | |
| members_can_invite | boolean | NOT NULL DEFAULT false | |
| max_members | smallint | NOT NULL DEFAULT 20 | |
| created_at, updated_at | timestamptz | | |
| deleted_at | timestamptz | NULL | 삭제 예약 (30일 후 영구 삭제) |

#### `family_members`
| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | uuid | PK | |
| family_group_id | uuid | NOT NULL, FK → family_groups ON DELETE CASCADE | |
| user_id | uuid | NULL, FK → profiles ON DELETE SET NULL | 계정을 삭제하면 NULL ("탈퇴한 구성원") |
| role | member_role | NOT NULL DEFAULT 'member' | |
| status | member_status | NOT NULL DEFAULT 'active' | |
| nickname | text | NULL, CHECK (char_length <= 20) | 그룹 안 별칭 |
| color | text | NOT NULL DEFAULT '#1F4D3A' | 차트에서 구성원을 구분하는 색 |
| joined_at | timestamptz | NOT NULL DEFAULT now() | |
| left_at | timestamptz | NULL | |
| created_at, updated_at | timestamptz | | |

- 유니크: `UNIQUE (family_group_id, user_id)` (다시 가입하면 status를 active로 되살린다)
- 부분 유니크: `CREATE UNIQUE INDEX one_owner_per_group ON family_members(family_group_id) WHERE role = 'owner' AND status = 'active';`
- 인덱스: `(user_id, status)` — "내 그룹 목록"과 RLS 헬퍼 함수에서 자주 쓴다.

> 거래 등 다른 테이블은 사용자를 `profiles(id)`로 참조한다. 탈퇴한 사람의 이름은 `family_members.nickname`과 표시용 스냅샷으로 보여준다.

#### `family_invitations`
| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | uuid | PK | |
| family_group_id | uuid | NOT NULL, FK | |
| invited_by | uuid | NOT NULL, FK → profiles | |
| code | text | NOT NULL, UNIQUE | 6자리 영숫자 (혼동하기 쉬운 0/O/1/I 제외) |
| token_hash | text | NOT NULL, UNIQUE | 초대 링크 토큰의 SHA-256. 원문 토큰은 저장하지 않는다. |
| role | member_role | NOT NULL DEFAULT 'member', CHECK (role <> 'owner') | |
| max_uses | smallint | NOT NULL DEFAULT 1 | |
| use_count | smallint | NOT NULL DEFAULT 0 | |
| status | invitation_status | NOT NULL DEFAULT 'pending' | |
| expires_at | timestamptz | NOT NULL DEFAULT now() + interval '7 days' | |
| created_at | timestamptz | | |

- 인덱스: `(family_group_id, status)`
- 초대 수락은 RPC `accept_invitation(p_code text)`(SECURITY DEFINER)로만 처리한다. 만료, 사용 횟수, 인원 제한을 확인하고 원자적으로 처리한다. 무차별 대입을 막기 위해 사용자당 시도 횟수를 제한한다 (`private.rate_limits`).

### 4.2 카테고리와 결제수단

#### `categories`
| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | uuid | PK | |
| family_group_id | uuid | NOT NULL, FK | 그룹 단위 (D12) |
| parent_id | uuid | NULL, FK → categories(id) ON DELETE RESTRICT | 1단계 하위 카테고리 (트리거로 깊이 1 강제) |
| kind | category_kind | NOT NULL | |
| name | text | NOT NULL, CHECK (char_length BETWEEN 1 AND 20) | |
| icon | text | NOT NULL | SF Symbol 이름 (허용 목록은 클라이언트에서 검증) |
| color | text | NOT NULL, CHECK (color ~ '^#[0-9A-Fa-f]{6}$') | |
| sort_order | integer | NOT NULL DEFAULT 0 | |
| is_default | boolean | NOT NULL DEFAULT false | 기본 제공 여부 |
| is_system | boolean | NOT NULL DEFAULT false | "기타"처럼 삭제할 수 없는 항목 |
| is_active | boolean | NOT NULL DEFAULT true | 사용 중지 = false |
| created_by | uuid | NULL, FK → profiles ON DELETE SET NULL | |
| version, created_at, updated_at, deleted_at | | | |

- 유니크: `CREATE UNIQUE INDEX uq_category_name ON categories(family_group_id, kind, coalesce(parent_id,'00000000-0000-0000-0000-000000000000'), lower(name)) WHERE deleted_at IS NULL;`
- 인덱스: `(family_group_id, kind, sort_order) WHERE deleted_at IS NULL`
- 삭제는 RPC `delete_category(p_id uuid, p_replacement_id uuid)`로만 한다. 거래, 예산, 규칙을 대체 카테고리로 옮긴 뒤 소프트 삭제한다. `is_system`이면 거부한다.
- 그룹을 만들면 `private.seed_default_categories(group_id)`가 기본 카테고리를 넣는다.

#### `payment_methods` (계좌·카드·결제수단)
| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | uuid | PK | |
| family_group_id | uuid | NOT NULL, FK | |
| owner_id | uuid | NULL, FK → profiles ON DELETE SET NULL | 명의자 |
| type | payment_method_type | NOT NULL | |
| institution_name | text | NULL | 은행·카드사 |
| name | text | NOT NULL, CHECK (char_length BETWEEN 1 AND 30) | 별칭 |
| last4 | text | NULL, CHECK (last4 ~ '^[0-9]{4}$') | 끝 4자리만 저장 (전체 번호는 저장 금지) |
| color | text | NOT NULL DEFAULT '#7A5C43' | |
| visibility | visibility | NOT NULL DEFAULT 'family', CHECK (visibility IN ('family','private')) | |
| is_active | boolean | NOT NULL DEFAULT true | |
| sort_order | integer | NOT NULL DEFAULT 0 | |
| financial_connection_id | uuid | NULL, FK → financial_connections ON DELETE SET NULL | P2 외부 연동 |
| external_account_ref | text | NULL | 업체 측 계좌 식별자 (토큰화된 값) |
| version, created_at, updated_at, deleted_at | | | |

- 인덱스: `(family_group_id, owner_id) WHERE deleted_at IS NULL`

### 4.3 거래

#### `transactions`
| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | uuid | PK | 클라이언트 생성 가능 |
| family_group_id | uuid | NOT NULL, FK | |
| type | transaction_type | NOT NULL | |
| amount | bigint | NOT NULL, CHECK (amount > 0 AND amount <= 999999999999) | 원 단위 |
| currency | char(3) | NOT NULL DEFAULT 'KRW' | |
| occurred_on | date | NOT NULL | 그룹 시간대 기준 거래일 |
| occurred_at | timestamptz | NULL | 시각 (선택) |
| category_id | uuid | NULL, FK → categories ON DELETE RESTRICT | 이체는 NULL |
| payment_method_id | uuid | NULL, FK → payment_methods ON DELETE SET NULL | 지출·수입: 결제수단 / 이체: 출금 계좌 |
| transfer_to_payment_method_id | uuid | NULL, FK → payment_methods ON DELETE SET NULL | 이체: 입금 계좌 |
| merchant | text | NULL, CHECK (char_length <= 100) | 사용처 |
| memo | text | NULL, CHECK (char_length <= 500) | 소비 목적 |
| expense_scope | expense_scope | NOT NULL DEFAULT 'shared' | 수입과 이체에도 적용한다 (공동 수입 / 개인 수입) |
| visibility | visibility | NOT NULL DEFAULT 'family' | |
| created_by | uuid | NULL, FK → profiles ON DELETE SET NULL | 등록자 (D3) |
| spent_by | uuid | NULL, FK → profiles ON DELETE SET NULL | 실사용자·수령자 |
| status | transaction_status | NOT NULL DEFAULT 'confirmed' | |
| source | transaction_source | NOT NULL DEFAULT 'manual' | |
| recurring_transaction_id | uuid | NULL, FK → recurring_transactions ON DELETE SET NULL | |
| import_batch_id | uuid | NULL, FK → import_batches ON DELETE SET NULL | |
| external_id | text | NULL | 외부 거래 ID |
| fingerprint | text | NULL | 중복 판별 해시 (FR-FIN-05) |
| has_attachments | boolean | NOT NULL DEFAULT false | 트리거로 관리 (목록 아이콘 표시용) |
| version, created_at, updated_at, deleted_at | | | |

**CHECK 제약**
```sql
CONSTRAINT shared_must_be_family
  CHECK (expense_scope <> 'shared' OR visibility = 'family'),           -- D2
CONSTRAINT transfer_fields
  CHECK ((type = 'transfer') = (transfer_to_payment_method_id IS NOT NULL)),
CONSTRAINT category_for_non_transfer
  CHECK (type = 'transfer' OR category_id IS NOT NULL),
CONSTRAINT transfer_distinct
  CHECK (payment_method_id IS DISTINCT FROM transfer_to_payment_method_id OR type <> 'transfer')
```
**트리거 검증** (`BEFORE INSERT OR UPDATE`, `private.validate_transaction()`)
- `category_id`, `payment_method_id`, `spent_by`는 같은 그룹에 속해야 한다 (`spent_by`는 활성 구성원).
- 카테고리의 `kind`가 거래 `type`과 맞아야 한다. 새로 고르는 카테고리는 `is_active`여야 한다 (기존 값을 그대로 두는 것은 허용).
- `created_by`는 INSERT할 때 `auth.uid()`로 강제로 덮어쓴다 (위조 방지).

**인덱스**
| 인덱스 | 목적 |
|---|---|
| `(family_group_id, occurred_on DESC, id DESC) WHERE deleted_at IS NULL` | 월 목록, 커서 페이지네이션 |
| `(family_group_id, updated_at)` | 증분 동기화 (삭제 표시 포함) |
| `(family_group_id, category_id, occurred_on) WHERE deleted_at IS NULL AND status='confirmed'` | 카테고리 통계 |
| `(family_group_id, spent_by, occurred_on)` | 구성원별 통계 |
| `(created_by)` | RLS (본인 거래) |
| `GIN (merchant gin_trgm_ops)`, `GIN (memo gin_trgm_ops)` | 키워드 검색 |
| `UNIQUE (payment_method_id, external_id) WHERE external_id IS NOT NULL AND deleted_at IS NULL` | 외부 거래 중복 방지 |
| `UNIQUE (family_group_id, fingerprint) WHERE fingerprint IS NOT NULL AND deleted_at IS NULL` | CSV 중복 방지 |
| `(recurring_transaction_id, occurred_on)` UNIQUE | 반복 거래 중복 생성 방지 |

> 데이터가 그룹당 수백만 건 규모로 커지면 `occurred_on` 기준 연 단위 파티셔닝을 검토한다. 초기에는 필요 없다.

#### `transaction_visible_members`
`visibility = 'selected'`일 때 공개 대상을 담는다.

| 컬럼 | 타입 | 제약 |
|---|---|---|
| transaction_id | uuid | FK → transactions ON DELETE CASCADE |
| user_id | uuid | FK → profiles ON DELETE CASCADE |
| family_group_id | uuid | NOT NULL (RLS 성능을 위한 비정규화, 트리거로 일치시킴) |
| | | PK (transaction_id, user_id) |

- 인덱스: `(user_id, transaction_id)`
- `selected`인데 대상이 0명이면 거래 저장을 거부한다 (거래와 함께 RPC `upsert_transaction`에서 검증).

#### `transaction_attachments`
| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | uuid | PK | |
| transaction_id | uuid | NOT NULL, FK ON DELETE CASCADE | |
| family_group_id | uuid | NOT NULL | Storage 경로와 RLS용 |
| storage_path | text | NOT NULL, UNIQUE | `receipts/{group_id}/{transaction_id}/{id}.jpg` |
| thumbnail_path | text | NULL | |
| mime_type | text | NOT NULL, CHECK IN ('image/jpeg','image/heic','image/png') | |
| byte_size | integer | NOT NULL, CHECK (byte_size <= 10485760) | |
| width, height | integer | NULL | |
| sort_order | smallint | NOT NULL DEFAULT 0 | |
| uploaded_by | uuid | FK → profiles ON DELETE SET NULL | |
| created_at | timestamptz | | |

- 거래당 최대 5장은 트리거로 강제한다.

#### `transaction_history`
수정 이력 (FR-TX-10). `AFTER UPDATE` 트리거가 기록한다.

| 컬럼 | 타입 | 설명 |
|---|---|---|
| id | bigint | PK, identity |
| transaction_id | uuid | FK ON DELETE CASCADE |
| changed_by | uuid | |
| changed_at | timestamptz | |
| change_type | text | `update`, `delete`, `restore` |
| diff | jsonb | 바뀐 필드의 {old, new} |

- RLS: 거래를 볼 수 있는 사람만 이력을 볼 수 있다. 직접 쓰기는 금지한다 (트리거만 기록).

#### `recurring_transactions`
| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | uuid | PK | |
| family_group_id | uuid | NOT NULL | |
| template | jsonb | NOT NULL | type, amount, category_id, payment_method_id, transfer_to_payment_method_id, merchant, memo, expense_scope, visibility, spent_by, visible_member_ids |
| rrule | text | NOT NULL | 예: `FREQ=MONTHLY;BYMONTHDAY=25` (D8) |
| starts_on | date | NOT NULL | |
| ends_on | date | NULL | |
| max_occurrences | integer | NULL | |
| occurrence_count | integer | NOT NULL DEFAULT 0 | |
| next_run_on | date | NOT NULL | 스케줄러 인덱스 |
| auto_confirm | boolean | NOT NULL DEFAULT true | false면 `pending_review`로 만든다 |
| is_paused | boolean | NOT NULL DEFAULT false | |
| created_by | uuid | FK → profiles ON DELETE SET NULL | |
| visibility | visibility | NOT NULL | template.visibility와 같은 값 (RLS용 비정규화) |
| version, created_at, updated_at, deleted_at | | | |

- 인덱스: `(next_run_on) WHERE is_paused = false AND deleted_at IS NULL`
- pg_cron `generate_recurring_transactions()`: 매시 10분에 실행한다. 그룹 시간대 기준 오늘 이하인 `next_run_on`을 처리하고, 앱이 꺼져 있던 기간도 따라잡는다. `(recurring_transaction_id, occurred_on)` 유니크 제약으로 멱등성을 보장한다.

### 4.4 예산

#### `budgets`
| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | uuid | PK | |
| family_group_id | uuid | NOT NULL | |
| scope | budget_scope | NOT NULL | D6 |
| owner_id | uuid | NULL, FK → profiles ON DELETE CASCADE | personal이면 필수 |
| period_start | date | NOT NULL | 월 시작일 기준 기간 시작 |
| period_end | date | NOT NULL | |
| total_amount | bigint | NULL, CHECK (total_amount > 0) | NULL이면 카테고리 예산만 |
| warn_threshold_pct | smallint | NOT NULL DEFAULT 80, CHECK (BETWEEN 1 AND 100) | |
| warned_at | timestamptz | NULL | 80% 알림 발송 기록 (중복 방지) |
| exceeded_at | timestamptz | NULL | 100% 알림 발송 기록 |
| version, created_at, updated_at, deleted_at | | | |

- CHECK: `(scope = 'personal') = (owner_id IS NOT NULL)`
- 유니크: `(family_group_id, scope, coalesce(owner_id, '0000…'), period_start) WHERE deleted_at IS NULL`

#### `budget_categories`
| 컬럼 | 타입 | 제약 |
|---|---|---|
| id | uuid | PK |
| budget_id | uuid | FK ON DELETE CASCADE |
| category_id | uuid | FK → categories ON DELETE CASCADE |
| amount | bigint | NOT NULL CHECK (> 0) |
| warned_at, exceeded_at | timestamptz | NULL |
| | | UNIQUE (budget_id, category_id) |

**예산 사용액 계산** (RPC `get_budget_status(p_budget_id)`, SECURITY INVOKER)
- family: `type='expense' AND expense_scope='shared' AND status='confirmed' AND occurred_on BETWEEN period_start AND period_end`
- personal: 위 조건에서 `expense_scope='personal' AND spent_by = owner_id`
- 하위 카테고리 지출은 상위 카테고리 예산에 합산한다.

**예산 알림 판단**: 거래 INSERT/UPDATE 뒤 `AFTER` 트리거가 `private.check_budget(group_id, occurred_on)`을 부른다. 이 함수는 SECURITY DEFINER로 서버 집계를 하고, 임계치를 넘으면 `notifications`에 행을 넣는다. family 예산은 그룹 활성 구성원 전체에게, personal 예산은 소유자에게만 보낸다.

### 4.5 디지털 지갑

#### `wallet_cards`
| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | uuid | PK | |
| scope | wallet_scope | NOT NULL | D1 예외 |
| owner_id | uuid | NOT NULL, FK → profiles ON DELETE CASCADE | 등록자 / 개인 카드 소유자 |
| family_group_id | uuid | NULL, FK ON DELETE CASCADE | family이면 필수 |
| brand_name | text | NOT NULL, CHECK (char_length BETWEEN 1 AND 40) | |
| card_name | text | NULL, CHECK (char_length <= 40) | |
| card_number | text | NULL, CHECK (char_length <= 64) | 회원번호 (결제카드 번호 입력 금지 안내, 클라이언트에서 Luhn 검사로 경고) |
| barcode_value | text | NULL, CHECK (char_length <= 2048) | |
| barcode_type | barcode_type | NOT NULL DEFAULT 'qr' | |
| memo | text | NULL, CHECK (char_length <= 500) | |
| color | text | NOT NULL DEFAULT '#1F4D3A' | |
| logo_path | text | NULL | Storage `wallet-images` |
| image_path | text | NULL | 원본 이미지 (image_only 유형) |
| expires_on | date | NULL | P2 |
| version, created_at, updated_at, deleted_at | | | |

- CHECK: `(scope = 'family') = (family_group_id IS NOT NULL)`
- CHECK: `barcode_type = 'image_only' OR barcode_value IS NOT NULL`
- 인덱스: `(owner_id) WHERE scope='personal' AND deleted_at IS NULL`, `(family_group_id) WHERE scope='family' AND deleted_at IS NULL`, `GIN (brand_name gin_trgm_ops)`

#### `wallet_card_user_prefs`
즐겨찾기와 최근 사용은 사용자마다 다르므로 분리한다 (가족 공유 카드라도 즐겨찾기는 개인별).

| 컬럼 | 타입 | 제약 |
|---|---|---|
| user_id | uuid | FK → profiles ON DELETE CASCADE |
| wallet_card_id | uuid | FK → wallet_cards ON DELETE CASCADE |
| is_favorite | boolean | NOT NULL DEFAULT false |
| last_used_at | timestamptz | NULL |
| sort_order | integer | NULL |
| updated_at | timestamptz | |
| | | PK (user_id, wallet_card_id) |

### 4.6 캘린더

#### `calendar_events`
| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | uuid | PK | |
| family_group_id | uuid | NOT NULL | |
| title | text | NOT NULL, CHECK (char_length BETWEEN 1 AND 100) | |
| description | text | NULL, CHECK (char_length <= 2000) | |
| location_name | text | NULL | |
| location_lat, location_lng | double precision | NULL | P1 |
| starts_at | timestamptz | NOT NULL | |
| ends_at | timestamptz | NOT NULL, CHECK (ends_at >= starts_at) | |
| is_all_day | boolean | NOT NULL DEFAULT false | 종일이면 그룹 시간대 자정 기준 |
| time_zone | text | NOT NULL DEFAULT 'Asia/Seoul' | 반복 전개 기준 |
| color | text | NULL | |
| visibility | visibility | NOT NULL DEFAULT 'family' | 가족(family) / 개인(private) / 선택(selected, 참여자에게만 공개) |
| rrule | text | NULL | 반복 규칙 (D8) |
| recurrence_until | timestamptz | NULL | 조회 범위 계산용 (rrule에서 도출, 무한이면 NULL) |
| created_by | uuid | FK → profiles ON DELETE SET NULL | |
| version, created_at, updated_at, deleted_at | | | |

- 인덱스: `(family_group_id, starts_at) WHERE deleted_at IS NULL`, `(family_group_id, updated_at)`, `(family_group_id) WHERE rrule IS NOT NULL AND deleted_at IS NULL`
- 조회 RPC `get_events(p_group, p_from, p_to)`: 범위 안의 단일 일정과, 범위와 겹칠 수 있는 반복 마스터(`starts_at <= p_to AND (recurrence_until IS NULL OR recurrence_until >= p_from)`)와 예외를 돌려준다. 전개는 클라이언트(`RecurrenceExpander`)가 한다.

#### `event_participants`
| 컬럼 | 타입 | 제약 |
|---|---|---|
| event_id | uuid | FK ON DELETE CASCADE |
| user_id | uuid | FK → profiles ON DELETE CASCADE |
| family_group_id | uuid | NOT NULL (비정규화) |
| response | event_response | NOT NULL DEFAULT 'pending' |
| responded_at | timestamptz | NULL |
| | | PK (event_id, user_id) |

- 인덱스: `(user_id, event_id)`
- `visibility = 'selected'`인 일정은 참여자 테이블을 공개 대상으로 함께 쓴다.

#### `event_exceptions`
반복 일정에서 특정 회차만 수정하거나 삭제한 내역이다.

| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | uuid | PK | |
| event_id | uuid | FK ON DELETE CASCADE | 반복 마스터 |
| original_starts_at | timestamptz | NOT NULL | 원래 회차 시작 시각 |
| is_cancelled | boolean | NOT NULL DEFAULT false | |
| override | jsonb | NULL | 바뀐 필드 (title, starts_at, ends_at, location_name, description) |
| version, created_at, updated_at | | | |
| | | UNIQUE (event_id, original_starts_at) | |

- "이후 일정 모두 수정"은 원래 마스터의 rrule에 UNTIL을 넣어 끊고, 새 마스터를 만든다.

#### `event_reminders`
사용자별 알림 설정이다 (같은 가족 일정이라도 알림 시점은 사람마다 다르다).

| 컬럼 | 타입 | 제약 |
|---|---|---|
| id | uuid | PK |
| event_id | uuid | FK ON DELETE CASCADE |
| user_id | uuid | FK ON DELETE CASCADE |
| minutes_before | integer | NOT NULL CHECK (minutes_before BETWEEN 0 AND 40320) |
| | | UNIQUE (event_id, user_id, minutes_before) |

- 기기 로컬 알림 예약의 원천 데이터다. 기기를 바꿔도 알림 설정이 유지된다.

### 4.7 공지사항

#### `notices`
| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | uuid | PK | |
| family_group_id | uuid | NOT NULL | |
| author_id | uuid | FK → profiles ON DELETE SET NULL | |
| title | text | NOT NULL, CHECK (char_length BETWEEN 1 AND 100) | |
| body | text | NOT NULL, CHECK (char_length <= 5000) | |
| is_pinned | boolean | NOT NULL DEFAULT false | |
| pinned_at | timestamptz | NULL | |
| is_important | boolean | NOT NULL DEFAULT false | P1 |
| edited_at | timestamptz | NULL | 본문 수정 시각 ("수정됨" 표시) |
| version, created_at, updated_at, deleted_at | | | |

- 인덱스: `(family_group_id, is_pinned DESC, created_at DESC) WHERE deleted_at IS NULL`
- 트리거: 그룹당 고정 공지 최대 3개. `is_pinned`는 관리자 이상만 바꿀 수 있다 (트리거로 컬럼 단위 권한 검사).

#### `notice_attachments`
`transaction_attachments`와 같은 구조다 (`notice_id`, `storage_path = notice-images/{group_id}/{notice_id}/{id}.jpg`, 최대 10장).

#### `notice_reads`
| 컬럼 | 타입 | 제약 |
|---|---|---|
| notice_id | uuid | FK ON DELETE CASCADE |
| user_id | uuid | FK → profiles ON DELETE CASCADE |
| family_group_id | uuid | NOT NULL |
| read_at | timestamptz | NOT NULL DEFAULT now() |
| | | PK (notice_id, user_id) |

- 읽음 처리: `INSERT … ON CONFLICT DO NOTHING` (처음 읽은 시각만 남긴다).
- 읽음 현황 RPC `get_notice_read_status(p_notice_id)`: 활성 구성원 목록과 read_at을 LEFT JOIN한 결과를 돌려준다.

### 4.8 할 일

#### `tasks`
| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | uuid | PK | |
| family_group_id | uuid | NOT NULL | |
| title | text | NOT NULL, CHECK (char_length BETWEEN 1 AND 100) | |
| description | text | NULL, CHECK (char_length <= 2000) | |
| status | task_status | NOT NULL DEFAULT 'todo' | |
| priority | task_priority | NOT NULL DEFAULT 'normal' | |
| due_on | date | NULL | |
| due_at | timestamptz | NULL | 시간까지 지정한 경우 |
| visibility | visibility | NOT NULL DEFAULT 'family', CHECK (visibility IN ('family','private')) | |
| completed_at | timestamptz | NULL | |
| completed_by | uuid | NULL, FK → profiles ON DELETE SET NULL | |
| rrule | text | NULL | 반복 할 일 |
| recurrence_parent_id | uuid | NULL, FK → tasks ON DELETE SET NULL | 같은 반복에서 생성된 회차들의 원본 |
| due_soon_notified_at, overdue_notified_at | timestamptz | NULL | 서버 알림 중복 방지 |
| created_by | uuid | FK → profiles ON DELETE SET NULL | |
| version, created_at, updated_at, deleted_at | | | |

- CHECK: `(status = 'done') = (completed_at IS NOT NULL)`
- 인덱스: `(family_group_id, status, due_on) WHERE deleted_at IS NULL`, `(family_group_id, updated_at)`, `(due_on) WHERE status <> 'done' AND deleted_at IS NULL` (마감 스케줄러)
- 반복: 회차가 done이 되면 트리거가 다음 회차를 만든다. 완료하지 않아도 주기가 되면 pg_cron이 다음 회차를 만든다. `(recurrence_parent_id, due_on)` UNIQUE로 중복을 막는다.

#### `task_assignees`
| 컬럼 | 타입 | 제약 |
|---|---|---|
| task_id | uuid | FK ON DELETE CASCADE |
| user_id | uuid | FK → profiles ON DELETE CASCADE |
| family_group_id | uuid | NOT NULL |
| assigned_by | uuid | FK → profiles ON DELETE SET NULL |
| assigned_at | timestamptz | NOT NULL DEFAULT now() |
| | | PK (task_id, user_id) |

- 인덱스: `(user_id, task_id)`
- 트리거: 개인(private) 할 일에는 본인만 담당자로 지정할 수 있다.

### 4.9 알림

#### `notifications`
| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | uuid | PK | |
| recipient_id | uuid | NOT NULL, FK → profiles ON DELETE CASCADE | |
| family_group_id | uuid | NULL, FK ON DELETE CASCADE | |
| type | notification_type | NOT NULL | |
| title | text | NOT NULL | 서버가 만든 표시 문구 |
| body | text | NOT NULL | |
| entity_type | text | NULL | `transaction`, `notice`, `event`, `task`, `budget`, `member` |
| entity_id | uuid | NULL | |
| deep_link | text | NULL | `dokkaebi://group/{gid}/notice/{id}` |
| actor_id | uuid | NULL, FK → profiles ON DELETE SET NULL | 알림을 일으킨 사람 |
| read_at | timestamptz | NULL | |
| push_sent_at | timestamptz | NULL | |
| push_error | text | NULL | |
| created_at | timestamptz | NOT NULL DEFAULT now() | |

- 인덱스: `(recipient_id, created_at DESC)`, `(recipient_id) WHERE read_at IS NULL`
- 행 생성은 서버만 한다 (트리거 / Edge Function, SECURITY DEFINER). 클라이언트는 `read_at` 수정과 DELETE만 할 수 있다.
- 보관: pg_cron이 90일이 지난 알림을 삭제한다.
- 금액이 들어가는 본문(예: "엄마가 식비 32,000원 지출")은 거래를 볼 수 있는 수신자에게만 만든다. 푸시 본문에는 금액을 넣지 않는 옵션(잠금 화면 노출 방지)을 둔다.

#### `notification_preferences`
| 컬럼 | 타입 | 제약 |
|---|---|---|
| user_id | uuid | FK ON DELETE CASCADE |
| family_group_id | uuid | FK ON DELETE CASCADE |
| disabled_types | notification_type[] | NOT NULL DEFAULT '{}' |
| quiet_start, quiet_end | time | NULL |
| hide_amount_in_push | boolean | NOT NULL DEFAULT false |
| task_reminder_time | time | NOT NULL DEFAULT '09:00' |
| | | PK (user_id, family_group_id) |

#### `device_tokens`
| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | uuid | PK | |
| user_id | uuid | NOT NULL, FK ON DELETE CASCADE | |
| token | text | NOT NULL, UNIQUE | APNs 디바이스 토큰 |
| platform | device_platform | NOT NULL DEFAULT 'ios' | |
| environment | text | NOT NULL CHECK IN ('sandbox','production') | |
| app_version | text | NULL | |
| last_seen_at | timestamptz | NOT NULL DEFAULT now() | |
| created_at | timestamptz | | |

- 로그아웃하면 삭제한다. APNs가 410 Unregistered를 돌려주면 Edge Function이 삭제한다.

### 4.10 활동 기록

#### `activity_logs`
홈 화면의 "최근 활동" 피드 (FR-HOME-08).

| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | bigint | PK, identity | |
| family_group_id | uuid | NOT NULL | |
| actor_id | uuid | FK → profiles ON DELETE SET NULL | |
| action | text | NOT NULL | `transaction.created`, `notice.created`, `task.completed`, `event.created`, `member.joined` 등 |
| entity_type | text | NOT NULL | |
| entity_id | uuid | NULL | |
| visibility | visibility | NOT NULL | 원본 데이터의 공개 범위 스냅샷 |
| summary | jsonb | NOT NULL | 표시용 요약 (예: {"category":"식비"}). **금액은 가족 공개 항목에만 넣는다** |
| created_at | timestamptz | NOT NULL DEFAULT now() | |

- 각 도메인 테이블의 AFTER 트리거가 만든다. `private` 데이터는 활동 기록을 남기지 않는다. `selected`는 원본 엔티티 권한 함수로 다시 확인한다.
- 인덱스: `(family_group_id, created_at DESC)`
- 보관 기간 90일.

### 4.11 금융 연동

#### `category_rules`
| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | uuid | PK | |
| family_group_id | uuid | NOT NULL | |
| match_type | text | NOT NULL CHECK IN ('contains','equals','prefix') | |
| pattern | text | NOT NULL | 정규화한 소문자, 공백 제거 |
| category_id | uuid | NOT NULL, FK → categories ON DELETE CASCADE | |
| priority | integer | NOT NULL DEFAULT 0 | |
| hit_count | integer | NOT NULL DEFAULT 0 | |
| created_by | uuid | | |
| created_at, updated_at | | | |
| | | UNIQUE (family_group_id, match_type, pattern) | |

#### `import_batches`
| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | uuid | PK | |
| family_group_id | uuid | NOT NULL | |
| user_id | uuid | NOT NULL, FK | 가져온 사람 |
| payment_method_id | uuid | NULL, FK | |
| file_name | text | NOT NULL | |
| file_sha256 | text | NOT NULL | 같은 파일을 다시 가져오는지 감지 |
| column_mapping | jsonb | NOT NULL | |
| default_expense_scope | expense_scope | NOT NULL | |
| default_visibility | visibility | NOT NULL | |
| status | import_status | NOT NULL | |
| total_rows, imported_rows, duplicate_rows, error_rows | integer | NOT NULL DEFAULT 0 | |
| created_at, completed_at, reverted_at | timestamptz | | |

#### `import_rows`
| 컬럼 | 타입 | 설명 |
|---|---|---|
| id | uuid PK | |
| import_batch_id | uuid FK ON DELETE CASCADE | |
| row_number | integer | |
| raw | jsonb | 원본 행 (완료 후 30일이 지나면 삭제) |
| parsed | jsonb | 정규화 결과 |
| fingerprint | text | |
| status | import_row_status | |
| duplicate_of_transaction_id | uuid NULL | |
| error_message | text NULL | |
| transaction_id | uuid NULL | 만든 거래 |

- RLS: 가져온 사람 본인만 볼 수 있다 (원본 파일에 개인 정보가 있을 수 있기 때문).
- 파싱은 클라이언트에서 한다 (파일을 서버에 올리지 않고 행 데이터만 보낸다). 중복 판정과 저장은 RPC `commit_import(p_batch_id, p_row_ids uuid[])`가 트랜잭션 하나로 처리한다.

#### `financial_connections` (P2)
| 컬럼 | 타입 | 설명 |
|---|---|---|
| id | uuid PK | |
| user_id | uuid FK | |
| family_group_id | uuid FK | 동기화한 거래가 들어갈 그룹 |
| provider | text | 제휴 업체 코드 |
| provider_user_ref | text | 업체 측 사용자 식별자 |
| vault_secret_id | uuid | 액세스·리프레시 토큰은 Supabase Vault에만 보관 |
| consent_scopes | text[] | |
| consented_at, consent_expires_at, revoked_at | timestamptz | |
| last_synced_at | timestamptz | |
| sync_cursor | text | |
| status | text | `active`, `expired`, `revoked`, `error` |

- 클라이언트는 `vault_secret_id`를 볼 수 없다. 뷰 `financial_connections_public`으로 안전한 컬럼만 노출한다.

### 4.12 내부 테이블 (`private` 스키마)
| 테이블 | 용도 |
|---|---|
| `private.rate_limits` | (user_id, action, window_start, count). 초대 코드 시도, 알림 발송 남용 방지 |
| `private.audit_logs` | 권한 변경, 구성원 추방, 그룹 삭제, 소유권 이전, 계정 삭제 등 보안 이벤트 |
| `private.push_queue` | 푸시 재시도 대기열 (지수 백오프) |

---

## 5. 권한 헬퍼 함수

RLS 정책 안에서 `family_members`를 직접 조회하면 재귀와 성능 문제가 생기므로 `SECURITY DEFINER` 함수로 감싼다. 모두 `STABLE`, `SET search_path = ''`로 만들고 `private` 스키마에 둔다.

```sql
-- 현재 사용자가 활성 구성원인 그룹 ID 목록
CREATE FUNCTION private.my_group_ids() RETURNS SETOF uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT family_group_id FROM public.family_members
  WHERE user_id = auth.uid() AND status = 'active';
$$;

CREATE FUNCTION private.is_member(p_group uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT EXISTS (SELECT 1 FROM public.family_members
    WHERE family_group_id = p_group AND user_id = auth.uid() AND status = 'active');
$$;

CREATE FUNCTION private.my_role(p_group uuid) RETURNS public.member_role
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT role FROM public.family_members
  WHERE family_group_id = p_group AND user_id = auth.uid() AND status = 'active';
$$;

CREATE FUNCTION private.is_admin(p_group uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT coalesce(private.my_role(p_group) IN ('owner','admin'), false);
$$;

-- 거래 열람 권한 (D2, D7)
CREATE FUNCTION private.can_view_transaction(t public.transactions) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT private.is_member(t.family_group_id) AND (
       t.visibility = 'family'
    OR t.created_by = auth.uid()
    OR t.spent_by  = auth.uid()
    OR (t.visibility = 'selected' AND EXISTS (
          SELECT 1 FROM public.transaction_visible_members v
          WHERE v.transaction_id = t.id AND v.user_id = auth.uid()))
  );
$$;
```
같은 방식으로 `can_view_event(e)` (family이거나, 작성자이거나, selected이면서 참여자인 경우)와 `can_view_task(t)`를 만든다.

> 성능: RLS 안에서 `auth.uid()`는 `(select auth.uid())` 형태로 감싸 행마다 다시 계산하지 않게 한다. `private.my_group_ids()`는 `family_group_id IN (SELECT private.my_group_ids())` 형태로 쓴다.

---

## 6. Row Level Security 정책

모든 `public` 테이블에 `ALTER TABLE … ENABLE ROW LEVEL SECURITY;`와 `FORCE ROW LEVEL SECURITY`를 건다. `anon` 역할에는 어떤 테이블 권한도 주지 않는다. 아래 정책은 모두 `TO authenticated` 대상이다.

### 6.1 정책 요약표
| 테이블 | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| profiles | 본인, 또는 같은 그룹 활성 구성원 (id, display_name, avatar_path만 노출하는 뷰 `member_profiles` 사용) | 트리거만 | 본인 | ❌ (계정 삭제 Edge Function) |
| family_groups | 구성원 | 인증 사용자 누구나 (RPC `create_family_group`이 owner 멤버십까지 원자적으로 만듦) | 관리자 이상 | ❌ (RPC `delete_family_group`, 소유자만) |
| family_members | 같은 그룹 구성원 | ❌ (RPC `accept_invitation`만) | 본인의 nickname·color / 역할은 소유자 RPC `change_member_role`만 | ❌ (RPC `leave_group`, `remove_member`) |
| family_invitations | 관리자 이상 (또는 `members_can_invite`이면 구성원) | 같은 조건 | 같은 조건 (revoke) | ❌ |
| categories | 구성원 | 구성원 (`members_can_manage_categories` 또는 관리자) | 같은 조건 | ❌ (RPC `delete_category`, 관리자 이상) |
| payment_methods | 구성원이고 (family이거나 소유자 본인) | 구성원이고 owner_id = 본인 | 소유자 본인 또는 관리자 (family 항목) | 소프트 삭제 = UPDATE |
| transactions | `can_view_transaction(t)` (삭제된 행도 권한이 있으면 보임, §1) | 구성원이고 created_by = 본인 | 등록자, 또는 관리자이면서 (expense_scope = shared) | 소프트 삭제 = UPDATE. 물리 삭제 ❌ |
| transaction_visible_members | 해당 거래를 볼 수 있는 사람 | 해당 거래의 등록자 | ❌ | 해당 거래의 등록자 |
| transaction_attachments | 해당 거래를 볼 수 있는 사람 | 거래를 수정할 수 있는 사람 | ❌ | 거래를 수정할 수 있는 사람 |
| transaction_history | 해당 거래를 볼 수 있는 사람 | ❌ (트리거) | ❌ | ❌ |
| recurring_transactions | 구성원이고 (family이거나 created_by = 본인) | 구성원 | 등록자 / 관리자 (family) | 등록자 / 관리자 |
| budgets / budget_categories | family: 구성원 / personal: 소유자 | family: 관리자 이상 / personal: 본인 | 같은 조건 | 같은 조건 |
| wallet_cards | personal: owner_id = 본인 / family: 그룹 구성원 | personal: owner_id = 본인 / family: 구성원이고 owner_id = 본인 | personal: 소유자 / family: 등록자 또는 관리자 | 같은 조건 |
| wallet_card_user_prefs | 본인 | 본인 (대상 카드를 볼 수 있어야 함) | 본인 | 본인 |
| calendar_events | `can_view_event` | 구성원이고 created_by = 본인 | 작성자 / 관리자 (family 일정) | 작성자 / 관리자 |
| event_participants | 일정을 볼 수 있는 사람 | 일정 작성자 / 관리자 | 본인 행의 response만 (트리거로 컬럼 제한) / 작성자 | 일정 작성자 / 관리자 |
| event_exceptions | 일정을 볼 수 있는 사람 | 일정을 수정할 수 있는 사람 | 같은 조건 | 같은 조건 |
| event_reminders | 본인 | 본인 (일정을 볼 수 있어야 함) | 본인 | 본인 |
| notices / notice_attachments | 구성원 | 구성원 (author_id = 본인) | 작성자 (is_pinned는 관리자 이상, 트리거) | 작성자 / 관리자 (소프트 삭제) |
| notice_reads | 같은 그룹 구성원 | 본인 행만 | ❌ | ❌ |
| tasks | `can_view_task` (family이거나 작성자 본인) | 구성원 | 작성자 / 관리자 / 담당자 (담당자는 status·completed_* 컬럼만, 트리거로 검사) | 작성자 / 관리자 |
| task_assignees | 할 일을 볼 수 있는 사람 | 작성자 / 관리자 | ❌ | 작성자 / 관리자 |
| notifications | recipient_id = 본인 | ❌ (서버만) | 본인 (read_at만) | 본인 |
| notification_preferences | 본인 | 본인 | 본인 | 본인 |
| device_tokens | 본인 | 본인 | 본인 | 본인 |
| activity_logs | 구성원이고 (visibility = family 또는 원본 권한 함수 통과) | ❌ (트리거) | ❌ | ❌ |
| category_rules | 구성원 | 카테고리 관리 권한자 | 같은 조건 | 같은 조건 |
| import_batches / import_rows | user_id = 본인 | 본인 | 본인 | 본인 |
| financial_connections | ❌ (뷰를 통해 본인만) | ❌ (Edge Function) | ❌ | ❌ |

### 6.2 대표 정책 SQL
```sql
-- transactions
CREATE POLICY tx_select ON public.transactions FOR SELECT TO authenticated
USING ( private.can_view_transaction(transactions) );   -- deleted_at 필터는 쿼리에서 (§1)

CREATE POLICY tx_insert ON public.transactions FOR INSERT TO authenticated
WITH CHECK ( private.is_member(family_group_id)
             AND created_by = (select auth.uid()) );

CREATE POLICY tx_update ON public.transactions FOR UPDATE TO authenticated
USING (
  private.is_member(family_group_id) AND (
    created_by = (select auth.uid())
    OR (expense_scope = 'shared' AND private.is_admin(family_group_id))
  )
)
WITH CHECK (
  private.is_member(family_group_id)
  -- 관리자가 공동 지출을 개인·비공개로 바꿔 가로채는 것을 막는다
  AND ( created_by = (select auth.uid()) OR expense_scope = 'shared' )
);
-- 물리 DELETE 정책은 만들지 않는다 (소프트 삭제만 허용).

-- wallet_cards
CREATE POLICY wallet_select ON public.wallet_cards FOR SELECT TO authenticated
USING ( (
  (scope = 'personal' AND owner_id = (select auth.uid()))
  OR (scope = 'family' AND private.is_member(family_group_id))
));

-- notifications: 읽음 처리만 허용
CREATE POLICY ntf_update ON public.notifications FOR UPDATE TO authenticated
USING ( recipient_id = (select auth.uid()) )
WITH CHECK ( recipient_id = (select auth.uid()) );
REVOKE UPDATE ON public.notifications FROM authenticated;
GRANT UPDATE (read_at) ON public.notifications TO authenticated;  -- 컬럼 단위 권한
```

### 6.3 컬럼 단위 보호
- `GRANT UPDATE (col, …)` 컬럼 권한과 `BEFORE UPDATE` 트리거로 다음을 막는다.
  - 모든 테이블에서 `family_group_id`, `created_by`, `id`는 바꿀 수 없다.
  - `family_members.role`과 `status`는 RPC로만 바꾼다.
  - `notices.is_pinned`는 관리자 이상만 바꾼다.
  - 할 일 담당자(작성자·관리자가 아닌 경우)는 `status`, `completed_at`, `completed_by`만 바꾼다.

---

## 7. RPC 함수 목록

| 함수 | 보안 | 설명 |
|---|---|---|
| `create_family_group(name, time_zone)` | DEFINER | 그룹, 소유자 멤버십, 기본 카테고리를 원자적으로 만든다 |
| `create_invitation(group, role, max_uses, ttl)` → {code, token} | DEFINER | 권한 확인. 토큰 원문은 이때 한 번만 돌려준다 |
| `preview_invitation(code_or_token)` | DEFINER | 그룹명, 초대자 이름, 인원만 돌려준다 (rate limit 적용) |
| `accept_invitation(code_or_token)` | DEFINER | |
| `leave_group(group)` / `remove_member(group, user)` | DEFINER | 비공개 데이터 정리 (FR-GRP-08), 감사 로그 기록 |
| `change_member_role(group, user, role)` / `transfer_ownership(group, user)` | DEFINER | 소유자만 |
| `delete_family_group(group)` | DEFINER | 소유자만. `deleted_at` 설정 후 30일 뒤 pg_cron이 삭제 |
| `upsert_transaction(payload jsonb, expected_version int)` | INVOKER | 거래, 공개 대상, 첨부 메타데이터를 원자적으로 저장. 버전이 다르면 `40001 conflict` 오류와 서버 행을 돌려준다 |
| `soft_delete(entity text, id uuid, expected_version int)` / `restore(...)` | INVOKER | |
| `delete_category(id, replacement_id)` | DEFINER (내부에서 권한 확인) | |
| `get_dashboard(group, period_start, period_end)` | INVOKER | 홈 화면 카드 데이터를 한 번에 돌려준다 (요청 수 감소) |
| `get_monthly_summary(group, from, to)` | INVOKER | 월별 수입·지출, 공동·개인 지출 |
| `get_category_breakdown(group, from, to, type)` | INVOKER | |
| `get_member_breakdown(group, from, to)` | INVOKER | |
| `get_budget_status(budget_id)` | INVOKER | |
| `search_transactions(group, query, filters jsonb, cursor)` | INVOKER | |
| `sync_changes(group, since timestamptz, tables text[])` | INVOKER | 테이블별 변경분(삭제 표시 포함)과 다음 커서를 돌려준다 |
| `get_events(group, from, to)` | INVOKER | |
| `get_notice_read_status(notice_id)` | INVOKER | |
| `mark_notifications_read(ids uuid[] or all)` | INVOKER | |
| `commit_import(batch_id, row_ids)` | INVOKER | |

> INVOKER 함수는 RLS가 그대로 적용되어 통계에서 비공개 거래가 자동으로 빠진다 (D7). DEFINER 함수는 첫 줄에서 반드시 `auth.uid()` 권한 검사를 하고, `SET search_path = ''`로 만든다.

### 7.1 통계 함수 예시
```sql
CREATE FUNCTION public.get_monthly_summary(p_group uuid, p_from date, p_to date)
RETURNS TABLE (month_start date, income bigint, expense bigint,
               shared_expense bigint, personal_expense bigint)
LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $$
  SELECT private.period_start(p_group, t.occurred_on) AS month_start,
         sum(t.amount) FILTER (WHERE t.type = 'income'),
         sum(t.amount) FILTER (WHERE t.type = 'expense'),
         sum(t.amount) FILTER (WHERE t.type = 'expense' AND t.expense_scope = 'shared'),
         sum(t.amount) FILTER (WHERE t.type = 'expense' AND t.expense_scope = 'personal')
  FROM public.transactions t           -- RLS 적용
  WHERE t.family_group_id = p_group AND t.status = 'confirmed'
    AND t.occurred_on BETWEEN p_from AND p_to
  GROUP BY 1 ORDER BY 1;
$$;
```
`private.period_start(group, date)`는 그룹의 `month_start_day`를 반영해 기간 시작일을 계산한다.

---

## 8. Supabase Storage

| 버킷 | 공개 | 경로 규칙 | 최대 크기 | 허용 MIME |
|---|---|---|---|---|
| `avatars` | 비공개 | `{user_id}/{uuid}.jpg` | 2MB | image/jpeg, image/png, image/heic |
| `group-images` | 비공개 | `{group_id}/{uuid}.jpg` | 5MB | 같음 |
| `receipts` | 비공개 | `{group_id}/{transaction_id}/{attachment_id}.jpg` | 10MB | 같음 |
| `notice-images` | 비공개 | `{group_id}/{notice_id}/{attachment_id}.jpg` | 10MB | 같음 |
| `wallet-images` | 비공개 | personal: `user/{user_id}/{card_id}/{uuid}.png` / family: `group/{group_id}/{card_id}/{uuid}.png` | 5MB | image/png, image/jpeg |

모든 버킷은 비공개이고 Signed URL(유효기간 1시간)로만 읽는다. 클라이언트는 받은 이미지를 로컬 캐시에 보관한다.

### Storage RLS 예시 (`storage.objects`)
```sql
-- receipts: 해당 거래를 볼 수 있는 사람만 읽기
CREATE POLICY receipts_read ON storage.objects FOR SELECT TO authenticated
USING (
  bucket_id = 'receipts' AND EXISTS (
    SELECT 1 FROM public.transaction_attachments a
    JOIN public.transactions t ON t.id = a.transaction_id
    WHERE a.storage_path = storage.objects.name
      AND private.can_view_transaction(t)
  )
);

-- receipts: 업로드는 경로의 거래를 수정할 수 있는 사람만
CREATE POLICY receipts_write ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'receipts'
  AND private.is_member( ((storage.foldername(name))[1])::uuid )
  AND EXISTS (SELECT 1 FROM public.transactions t
              WHERE t.id = ((storage.foldername(name))[2])::uuid
                AND t.family_group_id = ((storage.foldername(name))[1])::uuid
                AND t.created_by = (select auth.uid()))
);
```
- 업로드 순서: (1) 거래 저장 → (2) 파일 업로드 → (3) `transaction_attachments` 행 추가. (2)에서 실패하면 클라이언트 재시도 대기열에 넣는다. 고아 파일(메타데이터 행이 없는 파일)은 매일 pg_cron + Edge Function으로 정리한다.
- 거래를 영구 삭제하면 Edge Function `storage-cleanup`이 파일도 지운다.

---

## 9. Realtime

- 발행 대상 (`supabase_realtime` publication): `transactions`, `transaction_visible_members`, `categories`, `payment_methods`, `budgets`, `budget_categories`, `wallet_cards`, `calendar_events`, `event_participants`, `event_exceptions`, `notices`, `notice_reads`, `tasks`, `task_assignees`, `notifications`, `family_members`, `activity_logs`
- 클라이언트 구독: 현재 그룹에 채널 1개 (`group:{group_id}`)를 열고, 테이블마다 `postgres_changes` 필터 `family_group_id=eq.{group_id}`를 건다. 알림은 `recipient_id=eq.{uid}`로 따로 구독한다. 개인 지갑 카드는 `owner_id=eq.{uid}`.
- Postgres Changes는 구독자별로 RLS를 적용해 이벤트를 전달한다. 볼 수 없는 거래 이벤트는 오지 않는다.
- **주의**: DELETE 이벤트는 RLS를 적용할 수 없어 PK만 전달된다. 그래서 물리 삭제 대신 소프트 삭제(UPDATE)를 쓰고, 클라이언트는 `deleted_at`이 채워진 UPDATE를 삭제로 처리한다. 공개 범위가 바뀌어 더 이상 볼 수 없게 된 거래는 UPDATE 이벤트를 받지 못하므로, 포그라운드로 돌아올 때 `sync_changes`가 돌려주는 "열람 권한 상실 ID 목록"으로 로컬에서 지운다 (APP_STRUCTURE.md §8).
- 테이블에 `REPLICA IDENTITY DEFAULT`를 유지한다 (FULL은 쓰지 않는다. 이전 값에 들어 있는 비공개 데이터가 새어 나가지 않게 하기 위해서다).
- 사용량이 늘면 서버 트리거 + `realtime.broadcast_changes()` 기반 Broadcast 방식으로 바꾸는 것을 검토한다 (확장성이 더 좋다).

---

## 10. 스케줄 작업 (pg_cron)

| 작업 | 주기 | 내용 |
|---|---|---|
| `generate_recurring_transactions` | 매시 10분 | 반복 거래 생성 |
| `generate_recurring_tasks` | 매시 15분 | 반복 할 일 다음 회차 |
| `notify_task_due` | 매시 정각 | 마감 임박(24시간 이내)·마감 초과 서버 알림 |
| `expire_invitations` | 매일 03:00 | 만료된 초대 처리 |
| `purge_soft_deleted` | 매일 04:00 | 30일이 지난 소프트 삭제 데이터 영구 삭제, Storage 정리 요청 |
| `purge_notifications` / `purge_activity_logs` | 매일 04:30 | 90일 보관 |
| `purge_import_raw` | 매일 05:00 | 30일이 지난 import 원본 행 삭제 |
| `retry_push_queue` | 매분 | 푸시 재시도 |

---

## 11. 푸시 발송 파이프라인

1. 도메인 트리거 → `private.enqueue_notification(recipients, type, entity…)`가 수신자별 권한, `notification_preferences`, 방해 금지 시간을 확인한 뒤 `notifications`에 INSERT한다.
2. Database Webhook (`notifications` INSERT) → Edge Function `send-push`
3. `send-push`: 수신자의 `device_tokens`를 조회하고 APNs HTTP/2로 보낸다 (토큰 기반 .p8 키는 Edge Function 시크릿에 보관). `apns-collapse-id`로 묶고, 배지 수 = 읽지 않은 알림 수.
4. 실패하면 `private.push_queue`에 넣어 재시도한다. 410 응답이면 토큰을 삭제한다.

---

## 12. 마이그레이션과 테스트

- 디렉터리: `supabase/migrations/YYYYMMDDHHMMSS_<name>.sql`, `supabase/seed.sql` (로컬 전용 테스트 데이터), `supabase/tests/*.test.sql` (pgTAP)
- pgTAP 필수 시나리오 (SECURITY_POLICY.md §6과 연결):
  - 다른 그룹 사용자는 어떤 행도 SELECT, INSERT, UPDATE할 수 없다.
  - private 거래는 등록자·실사용자 말고는 아무도 볼 수 없다 (소유자, 관리자 포함). 통계 RPC 결과에서도 빠진다.
  - selected 거래는 지정된 구성원만 볼 수 있다.
  - 공동 지출은 private로 저장할 수 없다.
  - 관리자는 다른 사람의 개인 거래를 수정할 수 없다.
  - 탈퇴한 구성원은 즉시 모든 그룹 데이터에 접근할 수 없다.
  - 영수증 Storage 객체는 거래 권한을 그대로 따른다.
  - notifications는 클라이언트가 INSERT할 수 없다.
- 타입 생성: `supabase gen types swift`는 공식 지원이 제한적이므로 DTO는 직접 관리하고, CI에서 스키마 스냅샷과 DTO 필드가 맞는지 확인하는 테스트를 돌린다.
