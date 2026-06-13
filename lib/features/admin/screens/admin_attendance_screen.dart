import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';
import '../../../shared/widgets/widgets.dart';

class AdminAttendanceScreen extends ConsumerStatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  ConsumerState<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends ConsumerState<AdminAttendanceScreen> {
  String? _selectedClassId;
  DateTime _date = DateTime.now();
  final Map<String, String> _statusByStudent = {};
  bool _saving = false;

  String get _dateKey => DateFormat('yyyy-MM-dd').format(_date);

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(dataRepositoryProvider);
    final classes = repo.data.classes;
    _selectedClassId ??= classes.isNotEmpty ? classes.first.classId : null;
    final students = _selectedClassId == null
        ? <StudentModel>[]
        : repo.studentsInClass(_selectedClassId!);

    for (final s in students) {
      _statusByStudent.putIfAbsent(
        s.studentId,
        () => repo.attendanceFor(s.studentId, _dateKey)?.status ?? 'P',
      );
    }

    if (classes.isEmpty) {
      return const EmptyState(message: 'Create a class first to mark attendance.');
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        DropdownButtonFormField<String>(
          value: _selectedClassId,
          decoration: const InputDecoration(labelText: 'Class'),
          items: classes
              .map(
                (c) => DropdownMenuItem(
                  value: c.classId,
                  child: Text('${c.name} ${c.section}'),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() {
            _selectedClassId = v;
            _statusByStudent.clear();
          }),
        ),
        const SizedBox(height: 12),
        ListTile(
          title: const Text('Date'),
          subtitle: Text(DateFormat('dd MMM yyyy').format(_date)),
          trailing: IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() {
                  _date = picked;
                  _statusByStudent.clear();
                });
              }
            },
          ),
        ),
        const SectionHeader(title: 'Mark Attendance'),
        ...students.map((s) {
          final status = _statusByStudent[s.studentId] ?? 'P';
          return Card(
            child: ListTile(
              title: StudentIdLabel(studentId: s.studentId, name: s.name),
              subtitle: StatusPill.attendance(status),
              trailing: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'P', label: Text('P')),
                  ButtonSegment(value: 'A', label: Text('A')),
                  ButtonSegment(value: 'H', label: Text('H')),
                ],
                selected: {status},
                onSelectionChanged: (set) {
                  setState(() => _statusByStudent[s.studentId] = set.first);
                },
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _saving || students.isEmpty ? null : _saveBatch,
          child: Text(_saving ? 'Saving...' : 'Save Attendance'),
        ),
      ],
    );
  }

  Future<void> _saveBatch() async {
    setState(() => _saving = true);
    try {
      final session = await ref.read(authServiceProvider).loadSession();
      final api = ref.read(apiClientProvider);
      final repo = ref.read(dataRepositoryProvider);
      for (final entry in _statusByStudent.entries) {
        final student = repo.studentById(entry.key);
        if (student == null) continue;
        await api.crud(
          'attendance',
          'upsert',
          token: session.token,
          data: {
            'date': _dateKey,
            'studentId': student.studentId,
            'studentName': student.name,
            'classId': student.classId,
            'status': entry.value,
          },
        );
      }
      await ref.read(syncDataProvider.notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
