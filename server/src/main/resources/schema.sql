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
