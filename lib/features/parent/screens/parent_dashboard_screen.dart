import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';
import '../../../shared/widgets/widgets.dart';

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key, required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(dataRepositoryProvider);
    final children = session.linkedStudentIds
        .map(repo.studentById)
        .whereType<StudentModel>()
        .toList();

    if (children.isEmpty) {
      return const EmptyState(message: 'No linked student found for your phone number.');
    }

    return StatefulBuilder(
      builder: (context, setLocal) {
        var selectedId = session.selectedStudentId.isNotEmpty
            ? session.selectedStudentId
            : children.first.studentId;
        final child = repo.studentById(selectedId) ?? children.first;
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final todayAtt = repo.attendanceFor(child.studentId, today);
        final paid = repo.totalPaidForStudent(child.studentId);
        final pending = repo.pendingFeesForStudent(child.studentId);
        final gallery = [...repo.data.gallery]..sort((a, b) => b.date.compareTo(a.date));

        return ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (children.length > 1)
              DropdownButtonFormField<String>(
                value: child.studentId,
                decoration: const InputDecoration(labelText: 'Select Child'),
                items: children
                    .map((c) => DropdownMenuItem(
                          value: c.studentId,
                          child: Text(c.displayLabel),
                        ))
                    .toList(),
                onChanged: (v) async {
                  if (v == null) return;
                  await ref.read(authServiceProvider).setSelectedStudent(v);
                  setLocal(() => selectedId = v);
                },
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundImage: child.profilePhotoUrl.isNotEmpty
                          ? NetworkImage(child.profilePhotoUrl)
                          : null,
                      child: child.profilePhotoUrl.isEmpty
                          ? Text(child.name.isNotEmpty ? child.name[0] : '?')
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StudentIdLabel(studentId: child.studentId, name: child.name),
                          Text('${child.className} · Section ${child.section}'),
                          if (todayAtt != null) ...[
                            const SizedBox(height: 8),
                            StatusPill.attendance(todayAtt.status),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StatCard(label: 'Paid', value: '₹$paid', icon: Icons.check),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: 'Pending',
                    value: '₹$pending',
                    icon: Icons.pending_actions,
                    color: const Color(0xFFC62828),
                  ),
                ),
              ],
            ),
            const SectionHeader(title: 'Latest Gallery'),
            if (gallery.isEmpty)
              const Text('No gallery updates yet.')
            else
              ...gallery.take(5).map(
                    (g) => ListTile(
                      leading: Icon(g.isYoutube ? Icons.play_circle : Icons.image),
                      title: Text(g.title),
                      subtitle: Text(g.date),
                    ),
                  ),
          ],
        );
      },
    );
  }
}
