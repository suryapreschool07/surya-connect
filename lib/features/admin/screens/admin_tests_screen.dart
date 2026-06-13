import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';
import '../../../shared/widgets/widgets.dart';

class AdminTestsScreen extends ConsumerStatefulWidget {
  const AdminTestsScreen({super.key});

  @override
  ConsumerState<AdminTestsScreen> createState() => _AdminTestsScreenState();
}

class _AdminTestsScreenState extends ConsumerState<AdminTestsScreen> {
  Future<void> _createTest() async {
    final repo = ref.read(dataRepositoryProvider);
    final classes = repo.data.classes;
    if (classes.isEmpty) return;

    ClassModel? selectedClass = classes.first;
    final nameCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    final maxMarksCtrl = TextEditingController(text: '20');
    final dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Create Test'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<ClassModel>(
                  value: selectedClass,
                  items: classes
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text('${c.name} ${c.section}'),
                          ))
                      .toList(),
                  onChanged: (v) => setLocal(() => selectedClass = v),
                ),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Test Name')),
                TextField(controller: subjectCtrl, decoration: const InputDecoration(labelText: 'Subject')),
                TextField(controller: maxMarksCtrl, decoration: const InputDecoration(labelText: 'Max Marks')),
                TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Date YYYY-MM-DD')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
          ],
        ),
      ),
    );

    if (ok != true || selectedClass == null) return;
    final session = await ref.read(authServiceProvider).loadSession();
    await ref.read(apiClientProvider).crud(
          'tests',
          'create',
          token: session.token,
          data: {
            'classId': selectedClass!.classId,
            'testName': nameCtrl.text.trim(),
            'subject': subjectCtrl.text.trim(),
            'testDate': dateCtrl.text.trim(),
            'maxMarks': int.tryParse(maxMarksCtrl.text.trim()) ?? 20,
            'active': true,
          },
        );
    await ref.read(syncDataProvider.notifier).refresh();
  }

  Future<void> _enterMarks(TestModel test) async {
    final repo = ref.read(dataRepositoryProvider);
    final students = repo.studentsInClass(test.classId);
    final marksCtrl = <String, TextEditingController>{};
    for (final s in students) {
      final existing = repo.resultsForStudent(s.studentId)
          .where((r) => r.testId == test.testId)
          .toList();
      marksCtrl[s.studentId] = TextEditingController(
        text: existing.isNotEmpty ? '${existing.first.marks}' : '',
      );
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Enter Marks · ${test.testName}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: students.map((s) {
              return ListTile(
                title: StudentIdLabel(studentId: s.studentId, name: s.name),
                trailing: SizedBox(
                  width: 70,
                  child: TextField(
                    controller: marksCtrl[s.studentId],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(hintText: '/${test.maxMarks}'),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final session = await ref.read(authServiceProvider).loadSession();
              final api = ref.read(apiClientProvider);
              for (final s in students) {
                final marks = num.tryParse(marksCtrl[s.studentId]!.text.trim());
                if (marks == null) continue;
                await api.crud(
                  'results',
                  'upsert',
                  token: session.token,
                  data: {
                    'testId': test.testId,
                    'studentId': s.studentId,
                    'marks': marks,
                    'grade': _grade(marks, test.maxMarks),
                  },
                );
              }
              await ref.read(syncDataProvider.notifier).refresh();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save Marks'),
          ),
        ],
      ),
    );
  }

  String _grade(num marks, int max) {
    final pct = marks / max * 100;
    if (pct >= 90) return 'A';
    if (pct >= 75) return 'B';
    if (pct >= 60) return 'C';
    return 'D';
  }

  @override
  Widget build(BuildContext context) {
    final tests = ref.watch(dataRepositoryProvider).data.tests;

    return Scaffold(
      appBar: AppBar(title: const Text('Tests')),
      floatingActionButton: FloatingActionButton(
        onPressed: _createTest,
        child: const Icon(Icons.add),
      ),
      body: tests.isEmpty
          ? const EmptyState(message: 'No tests created yet.')
          : ListView.builder(
              itemCount: tests.length,
              itemBuilder: (_, i) {
                final t = tests[i];
                return ListTile(
                  title: Text(t.testName),
                  subtitle: Text('${t.subject} · ${t.testDate} · Max ${t.maxMarks}'),
                  trailing: TextButton(
                    onPressed: () => _enterMarks(t),
                    child: const Text('Marks'),
                  ),
                );
              },
            ),
    );
  }
}

class AdminStaffScreen extends ConsumerStatefulWidget {
  const AdminStaffScreen({super.key});

  @override
  ConsumerState<AdminStaffScreen> createState() => _AdminStaffScreenState();
}

class _AdminStaffScreenState extends ConsumerState<AdminStaffScreen> {
  Future<void> _openForm({StaffModel? staff}) async {
    final nameCtrl = TextEditingController(text: staff?.name ?? '');
    final designationCtrl = TextEditingController(text: staff?.designation ?? '');
    final phoneCtrl = TextEditingController(text: staff?.phone ?? '');
    final emailCtrl = TextEditingController(text: staff?.email ?? '');
    final classIdsCtrl = TextEditingController(text: staff?.classIds ?? '');
    final salaryCtrl = TextEditingController(text: '${staff?.salary ?? 0}');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(staff == null ? 'Add Staff' : 'Edit Staff'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: designationCtrl, decoration: const InputDecoration(labelText: 'Designation')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: classIdsCtrl, decoration: const InputDecoration(labelText: 'Class IDs (comma separated)')),
              TextField(controller: salaryCtrl, decoration: const InputDecoration(labelText: 'Salary')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );

    if (ok != true) return;
    final session = await ref.read(authServiceProvider).loadSession();
    final data = {
      'name': nameCtrl.text.trim(),
      'designation': designationCtrl.text.trim(),
      'phone': phoneCtrl.text.trim(),
      'email': emailCtrl.text.trim(),
      'classIds': classIdsCtrl.text.trim(),
      'salary': int.tryParse(salaryCtrl.text.trim()) ?? 0,
      'active': true,
    };
    final api = ref.read(apiClientProvider);
    if (staff == null) {
      await api.crud('staff', 'create', token: session.token, data: data);
    } else {
      await api.crud('staff', 'update', token: session.token, id: staff.staffId, data: data);
    }
    await ref.read(syncDataProvider.notifier).refresh();
  }

  Future<void> _delete(StaffModel staff) async {
    final session = await ref.read(authServiceProvider).loadSession();
    await ref.read(apiClientProvider).crud(
          'staff',
          'delete',
          token: session.token,
          id: staff.staffId,
        );
    await ref.read(syncDataProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(dataRepositoryProvider).data.staff;

    return Scaffold(
      appBar: AppBar(title: const Text('Staff')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: staff.isEmpty
          ? const EmptyState(message: 'No staff records yet.')
          : ListView.builder(
              itemCount: staff.length,
              itemBuilder: (_, i) {
                final s = staff[i];
                return ListTile(
                  title: Text(s.name),
                  subtitle: Text('${s.designation} · ₹${s.salary}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') _openForm(staff: s);
                      if (v == 'delete') _delete(s);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
