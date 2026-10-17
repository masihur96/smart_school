import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/admin/models/academic_calendar_model.dart';
import 'package:smart_school/features/admin/providers/academic_calendar_provider.dart';
import 'package:smart_school/features/admin/screens/academic_calendar_detail_screen.dart';
import 'package:smart_school/features/admin/screens/add_edit_academic_calendar_screen.dart';
import 'package:smart_school/features/admin/widgets/academic_calendar_card.dart';
import 'package:smart_school/l10n/app_localizations.dart';
import 'package:table_calendar/table_calendar.dart';

enum CalendarViewMode { calendar, list }

class AcademicCalendarScreen extends StatefulWidget {
  const AcademicCalendarScreen({super.key});

  @override
  State<AcademicCalendarScreen> createState() => _AcademicCalendarScreenState();
}

class _AcademicCalendarScreenState extends State<AcademicCalendarScreen> {
  CalendarViewMode _viewMode = CalendarViewMode.calendar;
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime(2026, 6, 1);
  DateTime? _selectedDay;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AcademicCalendarProvider>();
      if (provider.events.isEmpty && !provider.isLoading) {
        // Fetch academic calendar events for 2026
        provider.fetchEvents(year: 2026);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterSheet(BuildContext context) {
    final provider = context.read<AcademicCalendarProvider>();

    int? tempYear = provider.filterYear;
    int? tempMonth = provider.filterMonth;
    bool? tempIsHoliday = provider.filterIsHoliday;
    String? tempAcademicYear = provider.filterAcademicYear ?? '2026-2027';
    String? tempTerm = provider.filterTerm;
    String? tempCategory = provider.filterCategory;
    DateTime? tempStartDate = provider.filterStartDate != null
        ? DateTime.tryParse(provider.filterStartDate!)
        : null;
    DateTime? tempEndDate = provider.filterEndDate != null
        ? DateTime.tryParse(provider.filterEndDate!)
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final dateFormat = DateFormat('yyyy-MM-dd');

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(Icons.tune_rounded,
                          color: AppColors.primaryAdmin),
                      const SizedBox(width: 8),
                      Text(
                        'Filter Academic Calendar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                  const Divider(),

                  Expanded(
                    child: ListView(
                      children: [
                        // Quick Curl Preset Button
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primaryAdmin.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primaryAdmin
                                  .withValues(alpha: 0.25),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.terminal_rounded,
                                      size: 16, color: AppColors.primaryAdmin),
                                  SizedBox(width: 6),
                                  Text(
                                    'Curl Query Preset',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryAdmin,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Year=2026, Month=5, Holidays Only, Term=First Term, 2026-2027',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primaryAdmin,
                                    side: const BorderSide(
                                        color: AppColors.primaryAdmin),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    setSheetState(() {
                                      tempYear = 2026;
                                      tempMonth = 5;
                                      tempStartDate = DateTime(2026, 1, 1);
                                      tempEndDate = DateTime(2026, 12, 31);
                                      tempIsHoliday = true;
                                      tempAcademicYear = '2026-2027';
                                      tempTerm = 'First Term';
                                    });
                                  },
                                  child: const Text('Load Curl Preset Values',
                                      style: TextStyle(fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Year Filter
                        const Text('Year',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [2025, 2026, 2027, 2028].map((y) {
                            final isSel = tempYear == y;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(y.toString()),
                                selected: isSel,
                                onSelected: (sel) {
                                  setSheetState(
                                      () => tempYear = sel ? y : null);
                                },
                                selectedColor: AppColors.primaryAdmin,
                                labelStyle: TextStyle(
                                  color: isSel ? Colors.white : null,
                                  fontWeight: isSel ? FontWeight.bold : null,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Month Filter
                        const Text('Month (Optional)',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (int m = 1; m <= 12; m++) ...[
                              ChoiceChip(
                                label: Text(
                                  DateFormat('MMM')
                                      .format(DateTime(2026, m, 1)),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: tempMonth == m ? Colors.white : null,
                                    fontWeight:
                                        tempMonth == m ? FontWeight.bold : null,
                                  ),
                                ),
                                selected: tempMonth == m,
                                selectedColor: AppColors.primaryAdmin,
                                onSelected: (sel) {
                                  setSheetState(
                                      () => tempMonth = sel ? m : null);
                                },
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Holiday Only Switch
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Holidays Only (isHoliday=true)',
                              style: TextStyle(fontSize: 14)),
                          value: tempIsHoliday == true,
                          activeThumbColor: const Color(0xFFEF4444),
                          onChanged: (val) {
                            setSheetState(
                                () => tempIsHoliday = val ? true : null);
                          },
                        ),
                        const SizedBox(height: 12),

                        // Academic Year
                        const Text('Academic Year',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: ['2025-2026', '2026-2027', '2027-2028']
                              .map((ay) {
                            final isSel = tempAcademicYear == ay;
                            return ChoiceChip(
                              label: Text(ay),
                              selected: isSel,
                              onSelected: (sel) {
                                setSheetState(
                                    () => tempAcademicYear = sel ? ay : null);
                              },
                              selectedColor: AppColors.primaryAdmin,
                              labelStyle: TextStyle(
                                color: isSel ? Colors.white : null,
                                fontWeight: isSel ? FontWeight.bold : null,
                                fontSize: 12,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Term
                        const Text('Term',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            'First Term',
                            'Mid Term',
                            'Final Term',
                            'Full Year'
                          ].map((t) {
                            final isSel = tempTerm == t;
                            return ChoiceChip(
                              label: Text(t),
                              selected: isSel,
                              onSelected: (sel) {
                                setSheetState(
                                    () => tempTerm = sel ? t : null);
                              },
                              selectedColor: AppColors.primaryAdmin,
                              labelStyle: TextStyle(
                                color: isSel ? Colors.white : null,
                                fontWeight: isSel ? FontWeight.bold : null,
                                fontSize: 12,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Date Range Filter
                        const Text('Date Range (Start - End)',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  final p = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        tempStartDate ?? DateTime(2026, 1, 1),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2035),
                                  );
                                  if (p != null) {
                                    setSheetState(() => tempStartDate = p);
                                  }
                                },
                                child: Text(
                                  tempStartDate != null
                                      ? dateFormat.format(tempStartDate!)
                                      : 'Start Date',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  final p = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        tempEndDate ?? DateTime(2026, 12, 31),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2035),
                                  );
                                  if (p != null) {
                                    setSheetState(() => tempEndDate = p);
                                  }
                                },
                                child: Text(
                                  tempEndDate != null
                                      ? dateFormat.format(tempEndDate!)
                                      : 'End Date',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // Bottom Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            provider.clearFilters();
                          },
                          child: const Text('Reset All'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryAdmin,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            final sDateStr = tempStartDate != null
                                ? dateFormat.format(tempStartDate!)
                                : null;
                            final eDateStr = tempEndDate != null
                                ? dateFormat.format(tempEndDate!)
                                : null;

                            provider.fetchEvents(
                              year: tempYear,
                              month: tempMonth,
                              startDate: sDateStr,
                              endDate: eDateStr,
                              isHoliday: tempIsHoliday,
                              academicYear: tempAcademicYear,
                              term: tempTerm,
                              category: tempCategory,
                            );

                            if (tempYear != null) {
                              setState(() {
                                _focusedDay = DateTime(
                                  tempYear!,
                                  tempMonth ?? 1,
                                  1,
                                );
                                _selectedDay = _focusedDay;
                              });
                            }
                          },
                          child: const Text('Apply Filters'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<AcademicCalendarProvider>();
    final l10n = AppLocalizations.of(context)!;
    final filteredEvents = provider.filteredEvents;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(l10n.academicCalendar),
        backgroundColor: AppColors.primaryAdmin,
        foregroundColor: Colors.white,
        actions: [
          // Switch view button
          IconButton(
            icon: Icon(
              _viewMode == CalendarViewMode.calendar
                  ? Icons.view_agenda_outlined
                  : Icons.calendar_month_outlined,
            ),
            tooltip: _viewMode == CalendarViewMode.calendar
                ? 'Switch to List View'
                : 'Switch to Calendar View',
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == CalendarViewMode.calendar
                    ? CalendarViewMode.list
                    : CalendarViewMode.calendar;
              });
            },
          ),

          // Filter button with badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list_rounded),
                tooltip: 'Filter',
                onPressed: () => _openFilterSheet(context),
              ),
              if (provider.hasActiveFilters)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),

          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              provider.fetchEvents(
                year: provider.filterYear,
                month: provider.filterMonth,
                startDate: provider.filterStartDate,
                endDate: provider.filterEndDate,
                isHoliday: provider.filterIsHoliday,
                academicYear: provider.filterAcademicYear,
                term: provider.filterTerm,
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await provider.fetchEvents(
            year: provider.filterYear,
            month: provider.filterMonth,
            startDate: provider.filterStartDate,
            endDate: provider.filterEndDate,
            isHoliday: provider.filterIsHoliday,
            academicYear: provider.filterAcademicYear,
            term: provider.filterTerm,
          );
        },
        child: Column(
          children: [
            // Quick Filter Chips Bar
            _buildQuickFiltersBar(context, provider, isDark),

            // Main Body Content
            Expanded(
              child: provider.isLoading && provider.events.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryAdmin,
                      ),
                    )
                  : _viewMode == CalendarViewMode.calendar
                      ? _buildCalendarView(context, provider, isDark)
                      : _buildListView(context, provider, filteredEvents, isDark),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryAdmin,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addAcademicEvent),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditAcademicCalendarScreen(
                initialDate: _selectedDay ?? _focusedDay,
              ),
            ),
          );
          if (result == true && mounted) {
            provider.fetchEvents(
              year: provider.filterYear,
              month: provider.filterMonth,
              startDate: provider.filterStartDate,
              endDate: provider.filterEndDate,
              isHoliday: provider.filterIsHoliday,
              academicYear: provider.filterAcademicYear,
              term: provider.filterTerm,
            );
          }
        },
      ),
    );
  }

  // ── Quick Filter Chips ──────────────────────────────────────────────────────
  Widget _buildQuickFiltersBar(
    BuildContext context,
    AcademicCalendarProvider provider,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Curl Preset Button
            ActionChip(
              avatar: const Icon(Icons.flash_on_rounded,
                  size: 14, color: AppColors.primaryAdmin),
              label: const Text('Curl Preset'),
              backgroundColor: AppColors.primaryAdmin.withValues(alpha: 0.1),
              side: BorderSide(
                color: AppColors.primaryAdmin.withValues(alpha: 0.3),
              ),
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryAdmin,
              ),
              onPressed: () {
                provider.applyCurlPreset();
                setState(() {
                  _focusedDay = DateTime(2026, 5, 1);
                  _selectedDay = _focusedDay;
                });
              },
            ),
            const SizedBox(width: 8),

            // All Chip
            ChoiceChip(
              label: const Text('All Events'),
              selected: !provider.hasActiveFilters,
              onSelected: (sel) {
                if (sel) provider.clearFilters();
              },
              selectedColor: AppColors.primaryAdmin,
              labelStyle: TextStyle(
                fontSize: 12,
                color: !provider.hasActiveFilters ? Colors.white : null,
              ),
            ),
            const SizedBox(width: 8),

            // Holidays Only Chip
            FilterChip(
              avatar: const Icon(Icons.beach_access_rounded,
                  size: 14, color: Color(0xFFEF4444)),
              label: const Text('Holidays'),
              selected: provider.filterIsHoliday == true,
              onSelected: (sel) {
                provider.fetchEvents(
                  year: provider.filterYear,
                  month: provider.filterMonth,
                  isHoliday: sel ? true : null,
                  academicYear: provider.filterAcademicYear,
                  term: provider.filterTerm,
                );
              },
              selectedColor: const Color(0xFFEF4444).withValues(alpha: 0.15),
              checkmarkColor: const Color(0xFFEF4444),
              labelStyle: TextStyle(
                fontSize: 12,
                color: provider.filterIsHoliday == true
                    ? const Color(0xFFEF4444)
                    : null,
                fontWeight: provider.filterIsHoliday == true
                    ? FontWeight.bold
                    : null,
              ),
            ),
            const SizedBox(width: 8),

            // Category Chips
            ...['VACATION', 'EXAM', 'EVENT'].map((cat) {
              final isSel = provider.filterCategory?.toUpperCase() == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat),
                  selected: isSel,
                  onSelected: (sel) {
                    provider.setCategoryFilter(sel ? cat : null);
                  },
                  selectedColor: AppColors.primaryAdmin.withValues(alpha: 0.15),
                  checkmarkColor: AppColors.primaryAdmin,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: isSel ? AppColors.primaryAdmin : null,
                    fontWeight: isSel ? FontWeight.bold : null,
                  ),
                ),
              );
            }),

            if (provider.hasActiveFilters) ...[
              ActionChip(
                avatar: const Icon(Icons.close_rounded, size: 14),
                label: const Text('Clear Filters'),
                onPressed: () => provider.clearFilters(),
                labelStyle: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Calendar View ───────────────────────────────────────────────────────────
  Widget _buildCalendarView(
    BuildContext context,
    AcademicCalendarProvider provider,
    bool isDark,
  ) {
    final selectedEvents = _selectedDay != null
        ? provider.getEventsForDay(_selectedDay!)
        : <AcademicCalendarEvent>[];

    final dateFormat = DateFormat('EEE, MMM dd, yyyy');

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        // Table Calendar Card
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TableCalendar<AcademicCalendarEvent>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonShowsNext: false,
              formatButtonDecoration: BoxDecoration(
                color: AppColors.primaryAdmin.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              formatButtonTextStyle: const TextStyle(
                color: AppColors.primaryAdmin,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              titleTextStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left_rounded,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              todayDecoration: BoxDecoration(
                color: AppColors.primaryAdmin.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(
                color: AppColors.primaryAdmin,
                fontWeight: FontWeight.bold,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppColors.primaryAdmin,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              weekendTextStyle: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day) => provider.getEventsForDay(day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return null;
                return Positioned(
                  bottom: 2,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: events.take(4).map((e) {
                      return Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: e.displayColor,
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ),

        // Selected Day Events Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              Icon(
                Icons.event_note_rounded,
                size: 18,
                color: AppColors.primaryAdmin,
              ),
              const SizedBox(width: 8),
              Text(
                _selectedDay != null
                    ? dateFormat.format(_selectedDay!)
                    : 'Events',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryAdmin.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${selectedEvents.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryAdmin,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Events List for Selected Day
        if (selectedEvents.isEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.event_available_rounded,
                  size: 44,
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
                const SizedBox(height: 10),
                Text(
                  'No events scheduled for this day',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryAdmin,
                    side: const BorderSide(color: AppColors.primaryAdmin),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add Event on this day'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditAcademicCalendarScreen(
                          initialDate: _selectedDay,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          )
        else
          ...selectedEvents.map((event) {
            return AcademicCalendarCard(
              event: event,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AcademicCalendarDetailScreen(event: event),
                  ),
                );
              },
            );
          }),

        const SizedBox(height: 80),
      ],
    );
  }

  // ── List / Agenda View ──────────────────────────────────────────────────────
  Widget _buildListView(
    BuildContext context,
    AcademicCalendarProvider provider,
    List<AcademicCalendarEvent> events,
    bool isDark,
  ) {
    return Column(
      children: [
        // Search Input Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search calendar events by title, location...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        provider.setSearchQuery('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (val) => provider.setSearchQuery(val),
          ),
        ),

        // Events List
        Expanded(
          child: events.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 64,
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No academic calendar events found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.grey.shade300
                                : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.hasActiveFilters
                              ? 'Try resetting the filters or modifying search keywords.'
                              : 'No events have been added yet for this criteria.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.grey.shade500
                                : Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (provider.hasActiveFilters)
                          OutlinedButton.icon(
                            icon: const Icon(Icons.restart_alt_rounded,
                                size: 16),
                            label: const Text('Reset Filters'),
                            onPressed: () => provider.clearFilters(),
                          ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return AcademicCalendarCard(
                      event: event,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AcademicCalendarDetailScreen(event: event),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
