# VidyaDesk V2 Release QA

## Authentication
- Owner signup/login/logout
- Email confirmation flow when enabled
- Teacher/student/parent/employee role routing
- Session refresh and expired-session handling

## Institute
- Setup profile, institute type, GST toggle
- GST fields hidden when disabled
- Logo/contact/bank settings

## Students and fees
- Student create/edit/deactivate
- Same guardian mobile family grouping
- Multiple batch enrollment
- Monthly recurring bills
- Mid-month pro-rata
- Course installments
- Partial/full payment
- Cash/Online/UPI
- Duplicate-fee review
- Family receipt

## Attendance
- Batch marking
- Staff check-in
- Absent notification queue
- Attendance report

## Exams/Learning
- Exam creation
- Batch marks entry
- Result calculation
- Course lesson publish
- Progress/notes/bookmarks
- Homework/timetable

## Staff/Leads
- Employee master
- Salary payment
- Leave request/approval
- Lead statuses/follow-ups

## Reports/export
- Outstanding/day collection/mode summary
- CSV export
- Printable receipt/ID card
- Backup/restore file validation

## Security
- RLS enabled for all application tables
- Role permissions verified
- Activity logs written for privileged changes
- Never expose service-role keys in client code
- Auth/SMTP configuration preserved during schema reset

## Offline
- Queue attendance/fee writes when disconnected
- Reconnect and flush queue
- Verify duplicate/conflict handling before production
