DELETE FROM "occupation_tags";

INSERT INTO "occupation_tags" (label, icon, category) VALUES
('Programmer (Sedentary)', 'terminal', 'Occupation'),
('Doctor (Shifts)', NULL, 'Occupation'),
('Freelancer (Irregular)', NULL, 'Occupation'),
('Teacher (Standing)', NULL, 'Occupation'),
('Seeking Pregnancy', NULL, 'Health'),
('Sugar Control', 'monitor_heart', 'Health'),
('Muscle Gain', NULL, 'Health'),
('Frequent Traveler', NULL, 'Lifestyle'),
('Post-Op Recovery', NULL, 'Health');

DELETE FROM "allergen_tags";

INSERT INTO "allergen_tags" (label, emoji, description, category) VALUES
('Peanuts', '🥜', 'Tree nuts included', 'nuts'),
('Dairy', '🥛', 'Milk, cheese, butter', 'dairy'),
('Shellfish', '🦐', 'Shrimp, crab, lobster', 'seafood'),
('Eggs', '🥚', 'All forms', 'eggs'),
('Gluten', '🌾', 'Wheat, barley, rye', 'grains'),
('Soy', '🫘', 'Soy sauce, tofu', 'legumes');

DELETE FROM "dietary_preference_tags";

INSERT INTO "dietary_preference_tags" (label, emoji) VALUES
('Vegetarian', '🌿'),
('Vegan', '🌱'),
('Halal', '🕌'),
('Kosher', '✡️'),
('Keto', '🔥'),
('Paleo', '🥩');
