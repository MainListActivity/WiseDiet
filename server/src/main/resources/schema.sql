CREATE TABLE IF NOT EXISTS "occupation_tags" (
    id SERIAL PRIMARY KEY,
    label VARCHAR(255) NOT NULL,
    icon VARCHAR(255),
    category VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS "user_profiles" (
    id SERIAL PRIMARY KEY,
    gender VARCHAR(50),
    age INT,
    height FLOAT,
    weight FLOAT,
    occupation_tag_ids TEXT,
    family_members INT
);

CREATE TABLE IF NOT EXISTS "users" (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    provider VARCHAR(50),
    provider_user_id VARCHAR(255),
    onboarding_step INT
);

CREATE TABLE IF NOT EXISTS "admin_whitelist" (
    id SERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS "meal_plans" (
    id SERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending'
);

CREATE TABLE IF NOT EXISTS "dishes" (
    id SERIAL PRIMARY KEY,
    meal_plan_id BIGINT NOT NULL,
    name VARCHAR(255) NOT NULL,
    recommendation_reason TEXT,
    image_url TEXT,
    difficulty INT DEFAULT 3,
    prep_min INT DEFAULT 10,
    cook_min INT DEFAULT 10,
    nutrient_tags TEXT,
    selected BOOLEAN DEFAULT FALSE,
    meal_type VARCHAR(20) NOT NULL
);
