# Goal Tracker 데이터베이스 스키마 및 테스트 데이터

이 문서는 Goal Tracker 애플리케이션의 데이터베이스 구조와 초기 설정된 테스트 데이터에 대해 설명합니다.

## 1. 데이터베이스 구조 (ERD)

```
+------------------+      +----------------+      +--------------------+
|      users       |      |      goals     |      |   goal_schedule_days |
+------------------+      +----------------+      +--------------------+
| id (PK) (UUID)   |-----<| user_id (FK)   |----->| goal_id (FK, PK)   |
| email            |      | id (PK) (UUID) |      | day_of_week (PK)   |
| password_hash    |      | title          |      +--------------------+
| created_at       |      | created_at     |
+------------------+      +----------------+      +--------------------+
       |                   |                      |      summary       |
       | 1                 | 1                    +--------------------+
       |                   |                      | id (PK) (UUID)     |
+------------------+      |                   /-->| goal_id (FK, UQ) |
|     profiles     |      |                   |   | content            |
+------------------+      |                   |   | created_at         |
| user_id (PK, FK) |<-----/                   |   +--------------------+
| nickname         |                          |
| gender           |                          |
| birthdate        |                          |
| profile_image    |                          |
| created_at       |                          |
+------------------+                          |
                                              |
                               +-----------------+
                               |   goals_sub     |
                               +-----------------+
                               | id (PK) (UUID)  |<---+
                               | goal_id (FK)    |    |
                               | title           |    |
                               | created_at      |    |
                               +-----------------+    |
                                       |              |
                                       |              |
                      +--------------------------+    |
                      | sub_goal_completions     |    |
                      +--------------------------+    |
                      | id (PK) (BIGINT)         |    |
                      | sub_goal_id (FK)         |----/
                      | completed_at             |
                      +--------------------------+
```

## 2. 테이블 상세 설명

### `users`
- **역할**: 사용자의 기본 로그인 계정 정보를 저장합니다.
- **컬럼 설명**:
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | UUID | PRIMARY KEY | 사용자의 고유 식별자 (기본 키) |
| `email` | VARCHAR(255) | UNIQUE, NOT NULL | 사용자의 이메일 주소 (로그인 시 사용) |
| `password_hash` | VARCHAR(255) | NOT NULL | 해시 처리된 사용자의 비밀번호 |
| `created_at` | TIMESTAMP | | 계정 생성 시각 |
- **키 관계**:
- `profiles`, `goals` 테이블의 부모 테이블 역할을 합니다.

### `profiles`
- **역할**: 사용자의 상세 프로필 정보를 저장합니다. `users` 테이블과 1:1 관계를 가집니다.
- **컬럼 설명**:
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `user_id` | UUID | PRIMARY KEY, FOREIGN KEY | `users(id)`를 참조하는 외래 키 |
| `nickname` | VARCHAR(50) | UNIQUE, NOT NULL | 사용자의 별명 |
| `gender` | INT | | 성별 (예: 1=남성, 2=여성) |
| `birthdate` | DATE | | 생년월일 |
| `profile_image` | VARCHAR(255) | | 프로필 이미지 URL |
| `created_at` | TIMESTAMP | | 프로필 생성 시각 |
- **키 관계**:
- **`user_id` (PK, FK)**: `users` 테이블의 `id`를 참조합니다. 사용자가 삭제되면 프로필도 함께 삭제됩니다 (`ON DELETE CASCADE`).

### `goals`
- **역할**: 사용자가 설정한 '대 목표'를 저장합니다.
- **컬럼 설명**:
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | UUID | PRIMARY KEY | 대 목표의 고유 식별자 |
| `user_id` | UUID | NOT NULL, FOREIGN KEY | 이 목표를 소유한 `users(id)`를 참조 |
| `title` | VARCHAR(255) | NOT NULL | 대 목표의 제목 |
| `created_at` | TIMESTAMP | | 목표 생성 시각 |
- **키 관계**:
- **`user_id` (FK)**: `users` 테이블의 `id`를 참조합니다. 사용자가 삭제되면 해당 사용자의 모든 대 목표가 삭제됩니다.
- `goals_sub`, `summary`, `goal_schedule_days` 테이블의 부모 테이블입니다.

### `goals_sub`
- **역할**: '대 목표'에 속한 '서브 목표'들을 저장합니다.
- **컬럼 설명**:
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | UUID | PRIMARY KEY | 서브 목표의 고유 식별자 |
| `goal_id` | UUID | NOT NULL, FOREIGN KEY | 이 서브 목표가 속한 `goals(id)`를 참조 |
| `title` | VARCHAR(255) | NOT NULL | 서브 목표의 제목 |
| `created_at` | TIMESTAMP | | 서브 목표 생성 시각 |
- **키 관계**:
- **`goal_id` (FK)**: `goals` 테이블의 `id`를 참조합니다. 대 목표가 삭제되면 모든 하위 서브 목표도 함께 삭제됩니다.

### `sub_goal_completions`
- **역할**: 사용자가 '서브 목표'를 완료했을 때의 기록을 저장합니다.
- **컬럼 설명**:
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | PRIMARY KEY | 완료 기록의 고유 식별자 (자동 증가) |
| `sub_goal_id` | UUID | NOT NULL, FOREIGN KEY | 완료된 `goals_sub(id)`를 참조 |
| `completed_at` | TIMESTAMP | | 목표 완료 시각 |
- **키 관계**:
- **`sub_goal_id` (FK)**: `goals_sub` 테이블의 `id`를 참조합니다. 서브 목표가 삭제되면 해당 목표의 완료 기록도 모두 삭제됩니다.

### `summary`
- **역할**: '대 목표'에 대한 최종 요약 또는 회고를 저장합니다. `goals` 테이블과 1:1 관계를 가집니다.
- **컬럼 설명**:
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | UUID | PRIMARY KEY | 요약의 고유 식별자 |
| `goal_id` | UUID | UNIQUE, NOT NULL, FOREIGN KEY | 요약이 속한 `goals(id)`를 참조 |
| `content` | TEXT | NOT NULL | 요약 내용 |
| `created_at` | TIMESTAMP | | 요약 생성 시각 |
- **키 관계**:
- **`goal_id` (UQ, FK)**: `goals` 테이블의 `id`를 참조합니다. 대 목표 하나당 하나의 요약만 가질 수 있습니다.

### `goal_schedule_days`
- **역할**: 사용자가 '대 목표'를 수행하기로 계획한 요일을 저장합니다.
- **컬럼 설명**:
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `goal_id` | UUID | PRIMARY KEY, FOREIGN KEY | 스케줄이 속한 `goals(id)`를 참조 |
| `day_of_week` | INT | PRIMARY KEY, CHECK | 요일 (0:일, 1:월, ... 6:토) |
- **키 관계**:
- **(`goal_id`, `day_of_week`) (Composite PK)**: 목표 ID와 요일의 조합은 고유해야 합니다.
- **`goal_id` (FK)**: `goals` 테이블의 `id`를 참조합니다.

## 3. 테스트 데이터

`init.sql` 스크립트는 4명의 가상 사용자와 각 사용자의 목표 데이터를 미리 삽입합니다.

### 1. 김코딩 (`koding.kim@example.com`)
- **대 목표**:
- `영어 공부`
- `건강 챙기기`
- **서브 목표**:
- (영어 공부) `영어시 번역해서 해석하기`
- (영어 공부) `듀오링고 한트랙씩 하기`
- (건강 챙기기) `30분 산책`
- (건강 챙기기) `홈트 하기`
- **수행 기록**: `듀오링고 한트랙씩 하기` 2회, `30분 산책` 1회 완료.
- **수행 요일**:
- 영어 공부: 월, 수, 금
- 건강 챙기기: 월, 화, 수, 목, 금, 토

### 2. 박해커 (`hacker.park@example.com`)
- **대 목표**:
- `사이드 프로젝트 완성`
- **서브 목표**:
- `DB 스키마 설계`
- `API 엔드포인트 구현`
- **수행 기록**: `DB 스키마 설계` 1회, `API 엔드포인트 구현` 2회 완료.
- **수행 요일**:
- 사이드 프로젝트 완성: 일, 화, 목, 토

### 3. 이디비 (`db.lee@example.com`)
- **대 목표**:
- `매일 책읽기`
- `아침 루틴 만들기`
- **서브 목표**:
- (매일 책읽기) `자기계발 서적 1챕터`
- **수행 기록**: `자기계발 서적 1챕터` 5회 완료.
- **수행 요일**:
- 매일 책읽기: 월, 화, 수, 목, 금
- 아침 루틴 만들기: 월, 화, 수

### 4. 최배포 (`deploy.choi@example.com`)
- **대 목표**:
- `블로그 시작하기`
- **서브 목표**:
- `주제 정하기`
- `초안 작성하기`
- **수행 기록**: 없음.
- **수행 요일**:
- 블로그 시작하기: 일, 토
