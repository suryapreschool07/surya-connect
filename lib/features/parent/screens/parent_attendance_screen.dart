import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';
import '../../../shared/widgets/widgets.dart';

class ParentAttendanceScreen extends ConsumerWidget {
  const ParentAttendanceScreen({super.key, required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(dataRepositoryProvider);
    final child = _selectedChild(repo);
    if (child == null) {
      return const EmptyState(message: 'No student selected.');
    }

    final records = repo.attendanceForStudent(child.studentId);
    final pct = repo.attendancePercentage(child.studentId);
    final chartPresent = pct > 0 ? pct : 0.01;
    final chartAbsent = pct < 100 ? (100 - pct) : 0.01;
    final now = DateTime.now();
    final monthRecords = records.where((r) {
      final d = DateTime.tryParse(r.date);
      return d != null && d.year == now.year && d.month == now.month;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        StudentIdLabel(studentId: child.studentId, name: child.name),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 48,
              sections: [
                PieChartSectionData(
                  value: chartPresent,
                  color: AppColors.golden,
                  title: '${pct.toStringAsFixed(0)}%',
                  radius: 42,
                  titleStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textBrown,
                  ),
                ),
                PieChartSectionData(
                  value: chartAbsent,
                  color: AppColors.beige,
                  title: '',
                  radius: 42,
                ),
              ],
            ),
          ),
        ),
        Center(child: Text('Attendance % (Holidays excluded)')),
        const SectionHeader(title: 'This Month'),
        ...monthRecords.map(
          (r) => ListTile(
            title: Text(DateFormat('dd MMM yyyy').format(DateTime.parse(r.date))),
            trailing: StatusPill.attendance(r.status),
          ),
        ),
      ],
    );
  }

  StudentModel? _selectedChild(DataRepository repo) {
    final id = session.selectedStudentId.isNotEmpty
        ? session.selectedStudentId
        : (session.linkedStudentIds.isNotEmpty ? session.linkedStudentIds.first : '');
    return repo.studentById(id);
  }
}
