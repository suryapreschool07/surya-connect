import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';
import '../../../shared/widgets/widgets.dart';

class AdminClassesScreen extends ConsumerStatefulWidget {
  const AdminClassesScreen({super.key});

  @override
  ConsumerState<AdminClassesScreen> createState() => _AdminClassesScreenState();
}

class _AdminClassesScreenState extends ConsumerState<AdminClassesScreen> {
  Future<void> _addClass() async {
    final nameCtrl = TextEditingController();
    final sectionCtrl = TextEditingController(text: 'A');
    final yearCtrl = TextEditingController(text: '2025-2026');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Class'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Class Name'),
            ),
            TextField(
              controller: sectionCtrl,
              decoration: const InputDecoration(labelText: 'Section'),
            ),
            TextField(
              controller: yearCtrl,
              decoration: const InputDecoration(labelText: 'Academic Year'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
        ],
      ),
    );
    if (ok != true) return;
    final session = await ref.read(authServiceProvider).loadSession();
    await ref.read(apiClientProvider).crud(
          'classes',
          'create',
          token: session.token,
          data: {
            'name': nameCtrl.text.trim(),
            'section': sectionCtrl.text.trim(),
            'academicYear': yearCtrl.text.trim(),
            'active': true,
          },
        );
    await ref.read(syncDataProvider.notifier).refresh();
  }

  Future<void> _deleteClass(ClassModel c) async {
    final students = ref.read(dataRepositoryProvider).studentsInClass(c.classId);
    if (students.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Remove students before deleting class')),
        );
      }
      return;
    }
    final session = await ref.read(authServiceProvider).loadSession();
    await ref.read(apiClientProvider).crud(
          'classes',
          'delete',
          token: session.token,
          id: c.classId,
        );
    await ref.read(syncDataProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final classes = ref.watch(dataRepositoryProvider).data.classes;

    return Scaffold(
      appBar: AppBar(title: const Text('Classes')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addClass,
        child: const Icon(Icons.add),
      ),
      body: classes.isEmpty
          ? const EmptyState(message: 'No classes yet. Create one to get started.')
          : ListView.builder(
              itemCount: classes.length,
              itemBuilder: (_, i) {
                final c = classes[i];
                final count =
                    ref.watch(dataRepositoryProvider).studentsInClass(c.classId).length;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ExpansionTile(
                    title: Text('${c.name} - ${c.section}'),
                    subtitle: Text('$count students · ${c.academicYear}'),
                    children: [
                      ...ref.watch(dataRepositoryProvider).studentsInClass(c.classId).map(
                            (s) => ListTile(
                              title: StudentIdLabel(studentId: s.studentId, name: s.name),
                            ),
                          ),
                      ListTile(
                        leading: const Icon(Icons.delete_outline, color: Colors.red),
                        title: const Text('Delete Class'),
                        onTap: () => _deleteClass(c),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
