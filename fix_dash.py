import json
import re

en_file = 'lib/l10n/app_en.arb'
bn_file = 'lib/l10n/app_bn.arb'
dash_file = 'lib/features/teacher/screens/teacher_dashboard_screen.dart'

with open(en_file, 'r', encoding='utf-8') as f:
    en_data = json.load(f)
with open(bn_file, 'r', encoding='utf-8') as f:
    bn_data = json.load(f)

new_keys = {
    'schoolName': ('School Name', 'স্কুলের নাম'),
    'onlineClasses': ('Online Classes', 'অনলাইন ক্লাস'),
    'libraryBooks': ('Library Books', 'লাইব্রেরির বই'),
    'shiftInProgress': ('Shift In Progress', 'শিফট চলছে'),
    'shiftCompleted': ('Shift Completed', 'শিফট সম্পন্ন হয়েছে'),
    'notStartedYet': ('Not Started Yet', 'এখনও শুরু হয়নি'),
    'notYet': ('Not Yet ', 'এখনও না '),
    'todayText': ('Today', 'আজ'),
    'yesterdayText': ('Yesterday', 'গতকাল'),
    'daysAgo': ('{days} days ago', '{days} দিন আগে', {'days': {'type': 'int'}}),
    'adminText': ('Admin', 'অ্যাডমিন'),
    'postedByNotice': ('Posted by {name} • {timeAgo}', '{name} দ্বারা পোস্ট করা হয়েছে • {timeAgo}', {'name': {'type': 'String'}, 'timeAgo': {'type': 'String'}}),
    'meetingText': ('Meeting', 'মিটিং'),
    'confirmSubmitAttendance': ('Are you sure you want to submit your attendance?\\n\\nDistance from center: {distance}m\\nAllowed radius: {radius}m', 'আপনি কি নিশ্চিত যে আপনি আপনার উপস্থিতি জমা দিতে চান?\\n\\nকেন্দ্র থেকে দূরত্ব: {distance}m\\nঅনুমোদিত ব্যাসার্ধ: {radius}m', {'distance': {'type': 'String'}, 'radius': {'type': 'String'}}),
    'outOfRangeDetails': ('{baseMessage} ({distance}m away). Allowed radius: {radius}m', '{baseMessage} ({distance}m দূরে)। অনুমোদিত ব্যাসার্ধ: {radius}m', {'baseMessage': {'type': 'String'}, 'distance': {'type': 'String'}, 'radius': {'type': 'String'}}),
    'classNum': ('Class {id}', 'ক্লাস {id}', {'id': {'type': 'String'}}),
    'subjectNum': ('Subject {id}', 'বিষয় {id}', {'id': {'type': 'String'}}),
    'nowText': ('NOW', 'এখন'),
    'upcomingText': ('UPCOMING', 'আসন্ন'),
    'passedText': ('PASSED', 'অতিবাহিত'),
    'roomNum': ('Room {num}', 'কক্ষ {num}', {'num': {'type': 'String'}}),
    'publishedText': ('Published', 'প্রকাশিত'),
    'routinesCount': ('{count} Routines', '{count} রুটিন', {'count': {'type': 'int'}}),
    'academicBooks': ('Academic Books', 'একাডেমিক বই'),
    'failedToLoadClasses': ('Failed to load classes: {error}', 'ক্লাস লোড করতে ব্যর্থ: {error}', {'error': {'type': 'String'}}),
    'syllabusLabel': ('Syllabus: ', 'সিলেবাস: '),
    'totalText': ('Total', 'মোট'),
}

for key, val in new_keys.items():
    if key not in en_data:
        en_data[key] = val[0]
        bn_data[key] = val[1]
        if len(val) == 3:
            en_data['@'+key] = {'placeholders': val[2]}
            bn_data['@'+key] = {'placeholders': val[2]}

with open(en_file, 'w', encoding='utf-8') as f:
    json.dump(en_data, f, ensure_ascii=False, indent=2)
with open(bn_file, 'w', encoding='utf-8') as f:
    json.dump(bn_data, f, ensure_ascii=False, indent=2)

with open(dash_file, 'r', encoding='utf-8') as f:
    content = f.read()

# Make replacements
replacements = [
    ("user?.designation ?? 'School Name'", "user?.designation ?? l10n.schoolName"),
    ("'Online Classes'", "l10n.onlineClasses"),
    ("'Library Books'", "l10n.libraryBooks"),
    ("'Shift In Progress'", "l10n.shiftInProgress"),
    ("'Shift Completed'", "l10n.shiftCompleted"),
    ("'Not Started Yet'", "l10n.notStartedYet"),
    ("'Not Yet '", "l10n.notYet"),
    ("timeAgo = 'Today'", "timeAgo = l10n.todayText"),
    ("timeAgo = 'Yesterday'", "timeAgo = l10n.yesterdayText"),
    ("'${diff.inDays} days ago'", "l10n.daysAgo(diff.inDays)"),
    ("notice.postedBy ?? 'Admin'", "notice.postedBy ?? l10n.adminText"),
    ("'Posted by ${notice.postedBy ?? 'Admin'} • $timeAgo'", "l10n.postedByNotice(notice.postedBy ?? l10n.adminText, timeAgo)"),
    ("onlineClass.className ?? 'Meeting'", "onlineClass.className ?? l10n.meetingText"),
    ("'Are you sure you want to submit your attendance?\\n\\n'\\n                      'Distance from center: ${distanceInMeters.toStringAsFixed(0)}m\\n'\\n                      'Allowed radius: ${user.radius}m'", "l10n.confirmSubmitAttendance(distanceInMeters.toStringAsFixed(0), user.radius.toString())"),
    ("'${l10n.outOfRange} (${distanceInMeters.toStringAsFixed(0)}m away). Allowed radius: ${user.radius}m'", "l10n.outOfRangeDetails(l10n.outOfRange, distanceInMeters.toStringAsFixed(0), user.radius.toString())"),
    ("'Class ${classInfo.classId}'", "l10n.classNum(classInfo.classId.toString())"),
    ("'Subject ${classInfo.subjectId}'", "l10n.subjectNum(classInfo.subjectId.toString())"),
    ("'NOW'", "l10n.nowText"),
    ("'UPCOMING'", "l10n.upcomingText"),
    ("'PASSED'", "l10n.passedText"),
    ("'Room ${classInfo.roomNumber}'", "l10n.roomNum(classInfo.roomNumber.toString())"),
    ("exam.isPublished ? 'Published' : 'Upcoming'", "exam.isPublished ? l10n.publishedText : l10n.upcomingText"),
    ("'$assignmentsCount Routines'", "l10n.routinesCount(assignmentsCount)"),
    ("'Academic Books'", "l10n.academicBooks"),
    ("'Failed to load classes: $error'", "l10n.failedToLoadClasses(error.toString())"),
    ("'Syllabus: '", "l10n.syllabusLabel"),
    ("'Total'", "l10n.totalText"),
]

for old, new in replacements:
    content = content.replace(old, new)

with open(dash_file, 'w', encoding='utf-8') as f:
    f.write(content)
print('Dashboard replacements done.')
