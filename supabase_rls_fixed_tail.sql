-- Run this ONLY after the main schema has been created successfully.
-- The original generic RLS loop must NOT include relationship-only tables.
-- This file is also the reference for the corrected tail of supabase_schema.sql.

-- Direct institute_id tables
DO $$ DECLARE t text; BEGIN
  FOREACH t IN ARRAY ARRAY[
    'institute_settings','institute_accounts','families','teachers','employees','students','student_documents','batches',
    'fee_plans','batch_enrollments','fee_bills','fee_items','fee_discounts','fee_installments','fee_payments','fee_receipts',
    'attendance','attendance_devices','attendance_logs','homework','diary_entries','study_materials','notices','courses',
    'course_enrollments','exams','exam_attempts','exam_marks','results','timetables','leads','lead_followups','expense_categories',
    'expenses','payroll','leave_requests','user_permissions','notifications','notification_logs','activity_logs','backup_records'
  ] LOOP
    EXECUTE format('DROP POLICY IF EXISTS vd_select ON public.%I',t);
    EXECUTE format('CREATE POLICY vd_select ON public.%I FOR SELECT USING (institute_id = public.vd_my_institute_id())',t);
    EXECUTE format('DROP POLICY IF EXISTS vd_owner_write ON public.%I',t);
    EXECUTE format('CREATE POLICY vd_owner_write ON public.%I FOR ALL USING (public.vd_is_owner() AND institute_id = public.vd_my_institute_id()) WITH CHECK (public.vd_is_owner() AND institute_id = public.vd_my_institute_id())',t);
  END LOOP;
END $$;

-- Family members: institute is inherited through family.
DROP POLICY IF EXISTS vd_family_members_select ON public.family_members;
CREATE POLICY vd_family_members_select ON public.family_members FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.families f WHERE f.id=family_members.family_id AND f.institute_id=public.vd_my_institute_id())
);
DROP POLICY IF EXISTS vd_family_members_owner ON public.family_members;
CREATE POLICY vd_family_members_owner ON public.family_members FOR ALL USING (
  public.vd_is_owner() AND EXISTS (SELECT 1 FROM public.families f WHERE f.id=family_members.family_id AND f.institute_id=public.vd_my_institute_id())
) WITH CHECK (
  public.vd_is_owner() AND EXISTS (SELECT 1 FROM public.families f WHERE f.id=family_members.family_id AND f.institute_id=public.vd_my_institute_id())
);

-- Course sections/lessons inherit institute through course.
DROP POLICY IF EXISTS vd_course_sections_select ON public.course_sections;
CREATE POLICY vd_course_sections_select ON public.course_sections FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.courses c WHERE c.id=course_sections.course_id AND c.institute_id=public.vd_my_institute_id())
);
DROP POLICY IF EXISTS vd_course_sections_owner ON public.course_sections;
CREATE POLICY vd_course_sections_owner ON public.course_sections FOR ALL USING (
  public.vd_is_owner() AND EXISTS (SELECT 1 FROM public.courses c WHERE c.id=course_sections.course_id AND c.institute_id=public.vd_my_institute_id())
) WITH CHECK (
  public.vd_is_owner() AND EXISTS (SELECT 1 FROM public.courses c WHERE c.id=course_sections.course_id AND c.institute_id=public.vd_my_institute_id())
);
DROP POLICY IF EXISTS vd_course_lessons_select ON public.course_lessons;
CREATE POLICY vd_course_lessons_select ON public.course_lessons FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.course_sections s JOIN public.courses c ON c.id=s.course_id WHERE s.id=course_lessons.section_id AND c.institute_id=public.vd_my_institute_id())
);
DROP POLICY IF EXISTS vd_course_lessons_owner ON public.course_lessons;
CREATE POLICY vd_course_lessons_owner ON public.course_lessons FOR ALL USING (
  public.vd_is_owner() AND EXISTS (SELECT 1 FROM public.course_sections s JOIN public.courses c ON c.id=s.course_id WHERE s.id=course_lessons.section_id AND c.institute_id=public.vd_my_institute_id())
) WITH CHECK (
  public.vd_is_owner() AND EXISTS (SELECT 1 FROM public.course_sections s JOIN public.courses c ON c.id=s.course_id WHERE s.id=course_lessons.section_id AND c.institute_id=public.vd_my_institute_id())
);

-- Course progress/notes/bookmarks inherit institute through lesson -> section -> course.
DROP POLICY IF EXISTS vd_course_progress_select ON public.course_progress;
CREATE POLICY vd_course_progress_select ON public.course_progress FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.course_lessons l JOIN public.course_sections s ON s.id=l.section_id JOIN public.courses c ON c.id=s.course_id WHERE l.id=course_progress.lesson_id AND c.institute_id=public.vd_my_institute_id())
);
DROP POLICY IF EXISTS vd_course_progress_owner ON public.course_progress;
CREATE POLICY vd_course_progress_owner ON public.course_progress FOR ALL USING (public.vd_is_owner() AND EXISTS (SELECT 1 FROM public.course_lessons l JOIN public.course_sections s ON s.id=l.section_id JOIN public.courses c ON c.id=s.course_id WHERE l.id=course_progress.lesson_id AND c.institute_id=public.vd_my_institute_id())) WITH CHECK (public.vd_is_owner() AND EXISTS (SELECT 1 FROM public.course_lessons l JOIN public.course_sections s ON s.id=l.section_id JOIN public.courses c ON c.id=s.course_id WHERE l.id=course_progress.lesson_id AND c.institute_id=public.vd_my_institute_id()));
DROP POLICY IF EXISTS vd_course_notes_select ON public.course_notes;
CREATE POLICY vd_course_notes_select ON public.course_notes FOR SELECT USING (EXISTS (SELECT 1 FROM public.course_lessons l JOIN public.course_sections s ON s.id=l.section_id JOIN public.courses c ON c.id=s.course_id WHERE l.id=course_notes.lesson_id AND c.institute_id=public.vd_my_institute_id()));
DROP POLICY IF EXISTS vd_course_notes_owner ON public.course_notes;
CREATE POLICY vd_course_notes_owner ON public.course_notes FOR ALL USING (public.vd_is_owner() AND EXISTS (SELECT 1 FROM public.course_lessons l JOIN public.course_sections s ON s.id=l.section_id JOIN public.courses c ON c.id=s.course_id WHERE l.id=course_notes.lesson_id AND c.institute_id=public.vd_my_institute_id())) WITH CHECK (public.vd_is_owner() AND EXISTS (SELECT 1 FROM public.course_lessons l JOIN public.course_sections s ON s.id=l.section_id JOIN public.courses c ON c.id=s.course_id WHERE l.id=course_notes.lesson_id AND c.institute_id=public.vd_my_institute_id()));
DROP POLICY IF EXISTS vd_course_bookmarks_select ON public.course_bookmarks;
CREATE POLICY vd_course_bookmarks_select ON public.course_bookmarks FOR SELECT USING (EXISTS (SELECT 1 FROM public.course_lessons l JOIN public.course_sections s ON s.id=l.section_id JOIN public.courses c ON c.id=s.course_id WHERE l.id=course_bookmarks.lesson_id AND c.institute_id=public.vd_my_institute_id()));
DROP POLICY IF EXISTS vd_course_bookmarks_owner ON public.course_bookmarks;
CREATE POLICY vd_course_bookmarks_owner ON public.course_bookmarks FOR ALL USING (public.vd_is_owner() AND EXISTS (SELECT 1 FROM public.course_lessons l JOIN public.course_sections s ON s.id=l.section_id JOIN public.courses c ON c.id=s.course_id WHERE l.id=course_bookmarks.lesson_id AND c.institute_id=public.vd_my_institute_id())) WITH CHECK (public.vd_is_owner() AND EXISTS (SELECT 1 FROM public.course_lessons l JOIN public.course_sections s ON s.id=l.section_id JOIN public.courses c ON c.id=s.course_id WHERE l.id=course_bookmarks.lesson_id AND c.institute_id=public.vd_my_institute_id()));

-- Course discussions inherit institute through lesson.
DROP POLICY IF EXISTS vd_course_discussions_select ON public.course_discussions;
CREATE POLICY vd_course_discussions_select ON public.course_discussions FOR SELECT USING (EXISTS (SELECT 1 FROM public.course_lessons l JOIN public.course_sections s ON s.id=l.section_id JOIN public.courses c ON c.id=s.course_id WHERE l.id=course_discussions.lesson_id AND c.institute_id=public.vd_my_institute_id()));
DROP POLICY IF EXISTS vd_course_discussions_owner ON public.course_discussions;
CREATE POLICY vd_course_discussions_owner ON public.course_discussions FOR ALL USING (public.vd_is_owner() AND EXISTS (SELECT 1 FROM public.course_lessons l JOIN public.course_sections s ON s.id=l.section_id JOIN public.courses c ON c.id=s.course_id WHERE l.id=course_discussions.lesson_id AND c.institute_id=public.vd_my_institute_id())) WITH CHECK (public.vd_is_owner() AND EXISTS (SELECT 1 FROM public.course_lessons l JOIN public.course_sections s ON s.id=l.section_id JOIN public.courses c ON c.id=s.course_id WHERE l.id=course_discussions.lesson_id AND c.institute_id=public.vd_my_institute_id()));

-- Exam questions/answers inherit institute through exam/attempt.
DROP POLICY IF EXISTS vd_exam_questions_select ON public.exam_questions;
CREATE POLICY vd_exam_questions_select ON public.exam_questions FOR SELECT USING (EXISTS (SELECT 1 FROM public.exams e WHERE e.id=exam_questions.exam_id AND e.institute_id=public.vd_my_institute_id()));
DROP POLICY IF EXISTS vd_exam_questions_owner ON public.exam_questions;
CREATE POLICY vd_exam_questions_owner ON public.exam_questions FOR ALL USING (public.vd_is_owner() AND EXISTS (SELECT 1 FROM public.exams e WHERE e.id=exam_questions.exam_id AND e.institute_id=public.vd_my_institute_id())) WITH CHECK (public.vd_is_owner() AND EXISTS (SELECT 1 FROM public.exams e WHERE e.id=exam_questions.exam_id AND e.institute_id=public.vd_my_institute_id()));
DROP POLICY IF EXISTS vd_exam_answers_select ON public.exam_answers;
CREATE POLICY vd_exam_answers_select ON public.exam_answers FOR SELECT USING (EXISTS (SELECT 1 FROM public.exam_attempts a WHERE a.id=exam_answers.attempt_id AND a.institute_id=public.vd_my_institute_id()));
DROP POLICY IF EXISTS vd_exam_answers_owner ON public.exam_answers;
CREATE POLICY vd_exam_answers_owner ON public.exam_answers FOR ALL USING (public.vd_is_owner() AND EXISTS (SELECT 1 FROM public.exam_attempts a WHERE a.id=exam_answers.attempt_id AND a.institute_id=public.vd_my_institute_id())) WITH CHECK (public.vd_is_owner() AND EXISTS (SELECT 1 FROM public.exam_attempts a WHERE a.id=exam_answers.attempt_id AND a.institute_id=public.vd_my_institute_id()));

-- Batch permissions inherit institute through batch.
DROP POLICY IF EXISTS vd_batch_permissions_select ON public.batch_permissions;
CREATE POLICY vd_batch_permissions_select ON public.batch_permissions FOR SELECT USING (EXISTS (SELECT 1 FROM public.batches b WHERE b.id=batch_permissions.batch_id AND b.institute_id=public.vd_my_institute_id()));
DROP POLICY IF EXISTS vd_batch_permissions_owner ON public.batch_permissions;
CREATE POLICY vd_batch_permissions_owner ON public.batch_permissions FOR ALL USING (public.vd_is_owner() AND EXISTS (SELECT 1 FROM public.batches b WHERE b.id=batch_permissions.batch_id AND b.institute_id=public.vd_my_institute_id())) WITH CHECK (public.vd_is_owner() AND EXISTS (SELECT 1 FROM public.batches b WHERE b.id=batch_permissions.batch_id AND b.institute_id=public.vd_my_institute_id()));
