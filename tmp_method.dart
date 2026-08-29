
  Widget _buildMyAssignedSubjects(
      BuildContext context, String currentUserId) {
    // Filter assignments where the logged-in teacher is the examiner
    final myAssignments = widget.exam.assignments
        .where((a) => a.examinerId == currentUserId)
        .toList();

    // Sort: today first → upcoming → past
    myAssignments.sort(_compareAssignments);

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded,
                color: Colors.orange.shade700, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Results not published yet. Showing your assigned subjects for this exam.',
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (myAssignments.isEmpty) {
      return Column(
        children: [
          header,
          Expanded(
            child: _emptyState(
              icon: Icons.assignment_ind_outlined,
              message: 'You have no subjects assigned for this exam.',
            ),
          ),
        ],
      );
    }

    // Group by class name for tabs
    final grouped = <String, List<ExamAssignment>>{};
    for (final a in myAssignments) {
      grouped.putIfAbsent(a.className, () => []).add(a);
    }
    final classNames = grouped.keys.toList()..sort();

    return Column(
      children: [
        header,
        Expanded(
          child: DefaultTabController(
            length: classNames.length,
            child: Column(
              children: [
                // Class filter tabs (shown even for single class for consistency)
                Container(
                  color: Colors.white,
                  child: TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorColor: AppColors.primaryTeacher,
                    indicatorWeight: 3,
                    labelColor: AppColors.primaryTeacher,
                    unselectedLabelColor: Colors.grey.shade400,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    tabs: classNames.map((c) {
                      final count = grouped[c]!.length;
                      return Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Class $c'),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryTeacher
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryTeacher,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: classNames.map((className) {
                      final items = grouped[className]!;
                      // Items already sorted globally; no re-sort needed
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                        itemCount: items.length,
                        itemBuilder: (context, i) =>
                            _AssignedSubjectCard(examId: widget.exam.id, assignment: items[i]),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
