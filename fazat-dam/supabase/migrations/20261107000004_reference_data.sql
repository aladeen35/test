-- =====================================================================
-- FAZAT DAM — reference data (real geography + default settings).
-- Not demonstration data. Cities are configurable by admins afterwards.
-- =====================================================================

insert into public.countries (code, name_ar, name_en, phone_prefix) values
  ('SD', 'السودان', 'Sudan', '+249'),
  ('SA', 'المملكة العربية السعودية', 'Saudi Arabia', '+966')
on conflict (code) do nothing;

insert into public.cities (country_code, name_ar, name_en, sort_order) values
  ('SD', 'الخرطوم', 'Khartoum', 1),
  ('SD', 'أم درمان', 'Omdurman', 2),
  ('SD', 'الخرطوم بحري', 'Khartoum North', 3),
  ('SD', 'بورتسودان', 'Port Sudan', 4),
  ('SD', 'كسلا', 'Kassala', 5),
  ('SD', 'القضارف', 'Gedaref', 6),
  ('SD', 'ود مدني', 'Wad Madani', 7),
  ('SD', 'عطبرة', 'Atbara', 8),
  ('SD', 'الأبيض', 'El Obeid', 9),
  ('SD', 'شندي', 'Shendi', 10),
  ('SD', 'كوستي', 'Kosti', 11),
  ('SD', 'دنقلا', 'Dongola', 12),
  ('SA', 'الرياض', 'Riyadh', 1),
  ('SA', 'جدة', 'Jeddah', 2),
  ('SA', 'مكة المكرمة', 'Makkah', 3),
  ('SA', 'المدينة المنورة', 'Madinah', 4),
  ('SA', 'الطائف', 'Taif', 5),
  ('SA', 'الدمام', 'Dammam', 6),
  ('SA', 'الخبر', 'Khobar', 7),
  ('SA', 'الأحساء', 'Al Ahsa', 8),
  ('SA', 'القصيم (بريدة)', 'Qassim (Buraydah)', 9),
  ('SA', 'أبها', 'Abha', 10),
  ('SA', 'خميس مشيط', 'Khamis Mushait', 11),
  ('SA', 'جازان', 'Jazan', 12),
  ('SA', 'تبوك', 'Tabuk', 13),
  ('SA', 'حائل', 'Hail', 14),
  ('SA', 'نجران', 'Najran', 15),
  ('SA', 'ينبع', 'Yanbu', 16)
on conflict (country_code, name_en) do nothing;

insert into public.app_settings (key, value) values
  ('matching', '{"batch_size": 25}'),
  ('requests', '{"max_open_per_user": 3, "max_per_day": 5, "grace_hours": 24}'),
  ('privacy',  '{"policy_version": "2026-11"}')
on conflict (key) do nothing;
