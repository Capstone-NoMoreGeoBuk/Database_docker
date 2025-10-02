-- Goal Tracker 데이터베이스 초기화 스크립트
-- 이 스크립트는 모든 테이블을 생성하고 관계를 설정합니다.

-- 기존 테이블이 존재할 경우 삭제하여 초기 상태를 보장합니다.
DROP TABLE IF EXISTS sub_goal_completions, goal_schedule_days, summary, goals_sub, goals, profiles, users CASCADE;

-- =============================================
-- 1. 테이블 생성
-- =============================================

-- 사용자 계정 정보
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 사용자 프로필 정보 (users와 1:1 관계)
CREATE TABLE profiles (
    user_id UUID PRIMARY KEY,
    nickname VARCHAR(50) UNIQUE NOT NULL,
    gender INT,
    birthdate DATE,
    profile_image VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 사용자의 대 목표
CREATE TABLE goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    title VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 대 목표에 속한 서브 목표
CREATE TABLE goals_sub (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    goal_id UUID NOT NULL,
    title VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 서브 목표 달성 기록
CREATE TABLE sub_goal_completions (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    sub_goal_id UUID NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 대 목표에 대한 요약 (goals와 1:1 관계)
CREATE TABLE summary (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    goal_id UUID UNIQUE NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 대 목표 수행 요일 설정
CREATE TABLE goal_schedule_days (
    goal_id UUID NOT NULL,
    -- 0: 일요일, 1: 월요일, ..., 6: 토요일
    day_of_week INT NOT NULL,
    CONSTRAINT check_day_of_week CHECK (day_of_week >= 0 AND day_of_week <= 6),
    PRIMARY KEY (goal_id, day_of_week)
);

-- =============================================
-- 2. 외래 키(Foreign Key) 제약 조건 설정
-- =============================================
-- 각 테이블 간의 관계를 정의합니다.
-- 부모 데이터가 삭제될 때 자식 데이터도 함께 삭제되도록 ON DELETE CASCADE 옵션을 추가합니다.

ALTER TABLE profiles ADD CONSTRAINT fk_profiles_users FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE goals ADD CONSTRAINT fk_goals_users FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE goals_sub ADD CONSTRAINT fk_goals_sub_goals FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE CASCADE;

ALTER TABLE sub_goal_completions ADD CONSTRAINT fk_completions_sub_goals FOREIGN KEY (sub_goal_id) REFERENCES goals_sub(id) ON DELETE CASCADE;

ALTER TABLE summary ADD CONSTRAINT fk_summary_goals FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE CASCADE;

ALTER TABLE goal_schedule_days ADD CONSTRAINT fk_schedule_goals FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE CASCADE;


-- =============================================
-- 4. 테스트 데이터 삽입
-- =============================================

-- 사용자 1: 김코딩 (기존 예시)
WITH user_info AS (
  INSERT INTO users (id, email, password_hash) VALUES ('11111111-1111-1111-1111-111111111111', 'koding.kim@example.com', 'hashed_password') RETURNING id
),
profile_info AS (
  INSERT INTO profiles (user_id, nickname, gender, birthdate) VALUES ((SELECT id FROM user_info), '김코딩', 1, '1995-05-10')
),
goal1 AS (
  INSERT INTO goals (id, user_id, title) VALUES ('22222222-2222-2222-2222-222222222222', (SELECT id FROM user_info), '영어 공부') RETURNING id
),
goal2 AS (
  INSERT INTO goals (id, user_id, title) VALUES ('33333333-3333-3333-3333-333333333333', (SELECT id FROM user_info), '건강 챙기기') RETURNING id
),
sub_goal1 AS (
  INSERT INTO goals_sub (id, goal_id, title) VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', (SELECT id FROM goal1), '영어시 번역해서 해석하기') RETURNING id
),
sub_goal2 AS (
  INSERT INTO goals_sub (id, goal_id, title) VALUES ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', (SELECT id FROM goal1), '듀오링고 한트랙씩 하기') RETURNING id
),
sub_goal3 AS (
  INSERT INTO goals_sub (id, goal_id, title) VALUES ('cccccccc-cccc-cccc-cccc-cccccccccccc', (SELECT id FROM goal2), '30분 산책') RETURNING id
),
sub_goal4 AS (
  INSERT INTO goals_sub (id, goal_id, title) VALUES ('dddddddd-dddd-dddd-dddd-dddddddddddd', (SELECT id FROM goal2), '홈트 하기') RETURNING id
)
INSERT INTO sub_goal_completions (sub_goal_id) VALUES 
  ((SELECT id FROM sub_goal2)), 
  ((SELECT id FROM sub_goal3)), 
  ((SELECT id FROM sub_goal2));

INSERT INTO goal_schedule_days (goal_id, day_of_week) VALUES 
  ('22222222-2222-2222-2222-222222222222', 1), ('22222222-2222-2222-2222-222222222222', 3), ('22222222-2222-2222-2222-222222222222', 5),
  ('33333333-3333-3333-3333-333333333333', 1), ('33333333-3333-3333-3333-333333333333', 2), ('33333333-3333-3333-3333-333333333333', 3), 
  ('33333333-3333-3333-3333-333333333333', 4), ('33333333-3333-3333-3333-333333333333', 5), ('33333333-3333-3333-3333-333333333333', 6);

-- 사용자 2: 박해커
WITH user_info AS (
  INSERT INTO users (id, email, password_hash) VALUES ('44444444-4444-4444-4444-444444444444', 'hacker.park@example.com', 'hashed_password') RETURNING id
),
profile_info AS (
  INSERT INTO profiles (user_id, nickname, gender, birthdate) VALUES ((SELECT id FROM user_info), '박해커', 2, '2001-11-23')
),
goal1 AS (
  INSERT INTO goals (id, user_id, title) VALUES ('55555555-5555-5555-5555-555555555555', (SELECT id FROM user_info), '사이드 프로젝트 완성') RETURNING id
),
sub_goal1 AS (
  INSERT INTO goals_sub (id, goal_id, title) VALUES ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', (SELECT id FROM goal1), 'DB 스키마 설계') RETURNING id
),
sub_goal2 AS (
  INSERT INTO goals_sub (id, goal_id, title) VALUES ('ffffffff-ffff-ffff-ffff-ffffffffffff', (SELECT id FROM goal1), 'API 엔드포인트 구현') RETURNING id
)
INSERT INTO sub_goal_completions (sub_goal_id) VALUES 
  ((SELECT id FROM sub_goal1)),
  ((SELECT id FROM sub_goal2)),
  ((SELECT id FROM sub_goal2));

INSERT INTO goal_schedule_days (goal_id, day_of_week) VALUES 
  ('55555555-5555-5555-5555-555555555555', 2), ('55555555-5555-5555-5555-555555555555', 4), ('55555555-5555-5555-5555-555555555555', 6), ('55555555-5555-5555-5555-555555555555', 0);

-- 사용자 3: 이디비
WITH user_info AS (
  INSERT INTO users (id, email, password_hash) VALUES ('66666666-6666-6666-6666-666666666666', 'db.lee@example.com', 'hashed_password') RETURNING id
),
profile_info AS (
  INSERT INTO profiles (user_id, nickname, gender, birthdate) VALUES ((SELECT id FROM user_info), '이디비', 1, '1998-01-15')
),
goal1 AS (
  INSERT INTO goals (id, user_id, title) VALUES ('77777777-7777-7777-7777-777777777777', (SELECT id FROM user_info), '매일 책읽기') RETURNING id
),
goal2 AS (
  INSERT INTO goals (id, user_id, title) VALUES ('88888888-8888-8888-8888-888888888888', (SELECT id FROM user_info), '아침 루틴 만들기') RETURNING id
),
sub_goal1 AS (
  INSERT INTO goals_sub (id, goal_id, title) VALUES ('1a1a1a1a-1a1a-1a1a-1a1a-1a1a1a1a1a1a', (SELECT id FROM goal1), '자기계발 서적 1챕터') RETURNING id
)
INSERT INTO sub_goal_completions (sub_goal_id) VALUES 
  ((SELECT id FROM sub_goal1)), ((SELECT id FROM sub_goal1)), ((SELECT id FROM sub_goal1)), ((SELECT id FROM sub_goal1)), ((SELECT id FROM sub_goal1));

INSERT INTO goal_schedule_days (goal_id, day_of_week) VALUES 
  ('77777777-7777-7777-7777-777777777777', 1), ('77777777-7777-7777-7777-777777777777', 2), ('77777777-7777-7777-7777-777777777777', 3), 
  ('77777777-7777-7777-7777-777777777777', 4), ('77777777-7777-7777-7777-777777777777', 5),
  ('88888888-8888-8888-8888-888888888888', 1), ('88888888-8888-8888-8888-888888888888', 2), ('88888888-8888-8888-8888-888888888888', 3);

-- 사용자 4: 최배포
WITH user_info AS (
  INSERT INTO users (id, email, password_hash) VALUES ('99999999-9999-9999-9999-999999999999', 'deploy.choi@example.com', 'hashed_password') RETURNING id
),
profile_info AS (
  INSERT INTO profiles (user_id, nickname, gender, birthdate) VALUES ((SELECT id FROM user_info), '최배포', 2, '2003-07-02')
),
goal1 AS (
  INSERT INTO goals (id, user_id, title) VALUES ('10101010-1010-1010-1010-101010101010', (SELECT id FROM user_info), '블로그 시작하기') RETURNING id
),
sub_goal1 AS (
  INSERT INTO goals_sub (id, goal_id, title) VALUES ('2b2b2b2b-2b2b-2b2b-2b2b-2b2b2b2b2b2b', (SELECT id FROM goal1), '주제 정하기') RETURNING id
),
sub_goal2 AS (
  INSERT INTO goals_sub (id, goal_id, title) VALUES ('3c3c3c3c-3c3c-3c3c-3c3c-3c3c3c3c3c3c', (SELECT id FROM goal1), '초안 작성하기') RETURNING id
)
-- 최배포 님은 아직 목표를 수행한 기록이 없습니다.
INSERT INTO goal_schedule_days (goal_id, day_of_week) VALUES 
  ('10101010-1010-1010-1010-101010101010', 6), ('10101010-1010-1010-1010-101010101010', 0);

-- 스크립트 종료
