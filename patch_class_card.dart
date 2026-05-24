// class _ClassPerformanceCardWithSubjectDropdown extends StatefulWidget {
//   final MyClassAttendStudent stats;
//   const _ClassPerformanceCardWithSubjectDropdown({required this.stats});
//
//   @override
//   State<_ClassPerformanceCardWithSubjectDropdown> createState() =>
//       _ClassPerformanceCardWithSubjectDropdownState();
//
//
// class _ClassPerformanceCardWithSubjectDropdownState
//     extends State<_ClassPerformanceCardWithSubjectDropdown> {
//   String? _selectedSubjectId;
//
//   // Extract unique subjects from records
//   List<Map<String, String>> _getUniqueSubjects() {
//     final Map<String, String> subjectsMap = {};
//     for (final r in widget.stats.records) {
//       if (r.subjectId != null && r.subjectInfo != null) {
//         subjectsMap[r.subjectId!] = r.subjectInfo!.name;
//       } else if (r.subjectInfo != null) {
//         subjectsMap[r.subjectInfo!.name] = r.subjectInfo!.name; // Fallback
//       }
//     }
//     return subjectsMap.entries
//         .map((e) => {'id': e.key, 'name': e.value})
//         .toList();
//   }
//
//   // Get records filtered by subject and deduplicated by studentId
//   List<TeacherClassAttendRecord> _getFilteredRecords() {
//     if (_selectedSubjectId == null) return [];
//
//     final filtered = widget.stats.records.where((r) =>
//         r.subjectId == _selectedSubjectId ||
//         r.subjectInfo?.name == _selectedSubjectId).toList();
//
//     final Map<String, TeacherClassAttendRecord> seen = {};
//     // Sort descending by date so the latest record is processed first
//     final sorted = [...filtered]
//       ..sort((a, b) => b.date.compareTo(a.date));
//
//     for (final r in sorted) {
//       seen.putIfAbsent(r.studentId, () => r);
//     }
//     return seen.values.toList();
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     final subjects = _getUniqueSubjects();
//     if (subjects.isNotEmpty) {
//       _selectedSubjectId = subjects.first['id'];
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     final stats = widget.stats;
//     final statusColor = stats.attendanceRate > 80
//         ? Colors.green
//         : (stats.attendanceRate > 50 ? Colors.orange : Colors.red);
//
//     final subjects = _getUniqueSubjects();
//     final displayRecords = _getFilteredRecords();
//
//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: () {},
//           borderRadius: BorderRadius.circular(24),
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Stack(
//                       alignment: Alignment.center,
//                       children: [
//                         SizedBox(
//                           width: 65,
//                           height: 65,
//                           child: CircularProgressIndicator(
//                             value: stats.attendanceRate / 100,
//                             strokeWidth: 6,
//                             backgroundColor: statusColor.withOpacity(0.1),
//                             valueColor: AlwaysStoppedAnimation<Color>(
//                               statusColor,
//                             ),
//                             strokeCap: StrokeCap.round,
//                           ),
//                         ),
//                         Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Text(
//                               '${stats.attendanceRate.toInt()}%',
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.bold,
//                                 color: statusColor,
//                               ),
//                             ),
//                             Text(
//                               'RATE',
//                               style: TextStyle(
//                                 fontSize: 8,
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.grey.shade500,
//                                 letterSpacing: 0.5,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                     const SizedBox(width: 20),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             stats.classInfo?.name ?? 'Class',
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 18,
//                               letterSpacing: 0.2,
//                             ),
//                           ),
//                           const SizedBox(height: 12),
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               _buildStatItemLocal(l10n.present, stats.present.toString(), Colors.green),
//                               _buildStatItemLocal(l10n.absent, stats.absent.toString(), Colors.red),
//                               _buildStatItemLocal(l10n.leave, stats.leave.toString(), Colors.orange),
//                               _buildStatItemLocal('Total', stats.total.toString(), Colors.blue),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                     Icon(
//                       Icons.arrow_forward_ios_rounded,
//                       color: Colors.grey.shade300,
//                       size: 16,
//                     ),
//                   ],
//                 ),
//                 if (stats.records.isNotEmpty) ...[
//                   const SizedBox(height: 16),
//                   const Divider(height: 1),
//                   const SizedBox(height: 12),
//
//                   // Subject Dropdown Row
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         'Student Attendance',
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.grey.shade800,
//                         ),
//                       ),
//                       if (subjects.isNotEmpty)
//                         Container(
//                           height: 32,
//                           padding: const EdgeInsets.symmetric(horizontal: 10),
//                           decoration: BoxDecoration(
//                             color: AppColors.primaryTeacher.withOpacity(0.08),
//                             borderRadius: BorderRadius.circular(10),
//                             border: Border.all(color: AppColors.primaryTeacher.withOpacity(0.2)),
//                           ),
//                           child: DropdownButtonHideUnderline(
//                             child: DropdownButton<String>(
//                               value: _selectedSubjectId,
//                               icon: Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.primaryTeacher),
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w600,
//                                 color: AppColors.primaryTeacher,
//                               ),
//                               items: subjects.map((subj) {
//                                 return DropdownMenuItem<String>(
//                                   value: subj['id'],
//                                   child: Text(subj['name'] ?? 'Unknown'),
//                                 );
//                               }).toList(),
//                               onChanged: (val) {
//                                 if (val != null) {
//                                   setState(() => _selectedSubjectId = val);
//                                 }
//                               },
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//
//                   const SizedBox(height: 12),
//
//                   // Horizontal List of Filtered Students
//                   if (displayRecords.isEmpty)
//                     Center(
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(vertical: 20),
//                         child: Text(
//                           'No records for selected subject',
//                           style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
//                         ),
//                       ),
//                     )
//                   else
//                     SizedBox(
//                       height: 85,
//                       child: ListView.builder(
//                         scrollDirection: Axis.horizontal,
//                         physics: const BouncingScrollPhysics(),
//                         itemCount: displayRecords.length,
//                         itemBuilder: (context, index) {
//                           return _buildStudentAvatarCardLocal(displayRecords[index]);
//                         },
//                       ),
//                     ),
//                 ],
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildStatItemLocal(String label, String value, Color color) {
//     return Column(
//       children: [
//         Text(
//           value,
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 16,
//             color: color,
//           ),
//         ),
//         const SizedBox(height: 2),
//         Text(
//           label,
//           style: TextStyle(
//             color: Colors.grey.shade500,
//             fontSize: 10,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }
//
//
//   Widget _buildStudentAvatarCardLocal(TeacherClassAttendRecord record) {
//     Color getStatusColor() {
//       switch (record.status.toLowerCase()) {
//         case 'present': return Colors.green;
//         case 'absent': return Colors.red;
//         case 'late': return Colors.orange;
//         case 'leave': return Colors.blue;
//         default: return Colors.grey;
//       }
//     }
//     final color = getStatusColor();
//     final firstLetter = record.studentName.isNotEmpty ? record.studentName[0] : '?';
//     return Container(
//       width: 65, margin: const EdgeInsets.only(right: 12),
//       child: Column(
//         children: [
//           Stack(
//             children: [
//               CircleAvatar(radius: 25, backgroundColor: color.withOpacity(0.1),
//                 child: Text(firstLetter.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20))),
//               Positioned(right: 0, bottom: 0,
//                 child: Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
//             ],
//           ),
//           const SizedBox(height: 6),
//           Text(record.studentName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
//         ],
//       ),
//     );
//   }
//
// }
