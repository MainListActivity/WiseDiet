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
