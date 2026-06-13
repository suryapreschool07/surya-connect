import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';
import '../../../shared/widgets/widgets.dart';

class ParentResultsScreen extends ConsumerWidget {
  const ParentResultsScreen({super.key, required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(dataRepositoryProvider);
    final child = _selectedChild(repo);
    if (child == null) {
      return const EmptyState(message: 'No student selected.');
    }

    final results = repo.resultsForStudent(child.studentId);

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        StudentIdLabel(studentId: child.studentId, name: child.name),
        const SectionHeader(title: 'Test Scores'),
        if (results.isEmpty)
          const EmptyState(message: 'No test results published yet.')
        else
          ...results.map((r) {
            final test = repo.testById(r.testId);
            return Card(
              child: ListTile(
                title: Text(test?.testName ?? r.testId),
                subtitle: Text('${test?.subject ?? ''} · ${test?.testDate ?? ''}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${r.marks}/${test?.maxMarks ?? '-'}'),
                    Text('Grade ${r.grade}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            );
          }),
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
