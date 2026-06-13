import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';
import '../../../shared/widgets/widgets.dart';

class AdminStudentsScreen extends ConsumerStatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  ConsumerState<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends ConsumerState<AdminStudentsScreen> {
  String _query = '';

  Future<void> _openForm({StudentModel? student}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _StudentFormSheet(
        student: student,
        onSaved: () => ref.read(syncDataProvider.notifier).refresh(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final students = ref.watch(dataRepositoryProvider).data.students.where((s) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return s.displayLabel.toLowerCase().contains(q) ||
          s.fatherPhone.contains(q) ||
          s.motherPhone.contains(q);
    }).toList();

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search students...',
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: students.isEmpty
                  ? const EmptyState(message: 'No students found.')
                  : ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (_, i) {
                        final s = students[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: s.profilePhotoUrl.isNotEmpty
                                ? NetworkImage(s.profilePhotoUrl)
                                : null,
                            child: s.profilePhotoUrl.isEmpty
                                ? Text(s.name.isNotEmpty ? s.name[0] : '?')
                                : null,
                          ),
                          title: StudentIdLabel(studentId: s.studentId, name: s.name),
                          subtitle: Text('${s.className} ${s.section}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _openForm(student: s),
                              ),
                            ],
                          ),
                          onTap: () => _openForm(student: s),
                        );
                      },
                    ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () => _openForm(),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _StudentFormSheet extends ConsumerStatefulWidget {
  const _StudentFormSheet({this.student, required this.onSaved});

  final StudentModel? student;
  final VoidCallback onSaved;

  @override
  ConsumerState<_StudentFormSheet> createState() => _StudentFormSheetState();
}

class _StudentFormSheetState extends ConsumerState<_StudentFormSheet> {
  late final Map<String, TextEditingController> _c;
  bool _saving = false;
  String _photoUrl = '';

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _photoUrl = s?.profilePhotoUrl ?? '';
    _c = {
      'name': TextEditingController(text: s?.name ?? ''),
      'className': TextEditingController(text: s?.className ?? ''),
      'section': TextEditingController(text: s?.section ?? 'A'),
      'dob': TextEditingController(text: s?.dob ?? ''),
      'admissionDate': TextEditingController(text: s?.admissionDate ?? ''),
      'fatherName': TextEditingController(text: s?.fatherName ?? ''),
      'fatherPhone': TextEditingController(text: s?.fatherPhone ?? ''),
      'fatherEmail': TextEditingController(text: s?.fatherEmail ?? ''),
      'motherName': TextEditingController(text: s?.motherName ?? ''),
      'motherPhone': TextEditingController(text: s?.motherPhone ?? ''),
      'motherEmail': TextEditingController(text: s?.motherEmail ?? ''),
      'address': TextEditingController(text: s?.address ?? ''),
      'aadharNo': TextEditingController(text: s?.aadharNo ?? ''),
      'totalFees': TextEditingController(text: '${s?.totalFees ?? 0}'),
    };
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final session = await ref.read(authServiceProvider).loadSession();
    final url = await ref.read(apiClientProvider).uploadMedia(
          token: session.token,
          base64Data: base64Encode(bytes),
          fileName: file.name,
          mimeType: 'image/jpeg',
        );
    setState(() => _photoUrl = url);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final session = await ref.read(authServiceProvider).loadSession();
      final data = {
        'name': _c['name']!.text.trim(),
        'class': _c['className']!.text.trim(),
        'section': _c['section']!.text.trim(),
        'dob': _c['dob']!.text.trim(),
        'admissionDate': _c['admissionDate']!.text.trim(),
        'fatherName': _c['fatherName']!.text.trim(),
        'fatherPhone': _c['fatherPhone']!.text.trim(),
        'fatherEmail': _c['fatherEmail']!.text.trim(),
        'motherName': _c['motherName']!.text.trim(),
        'motherPhone': _c['motherPhone']!.text.trim(),
        'motherEmail': _c['motherEmail']!.text.trim(),
        'address': _c['address']!.text.trim(),
        'aadharNo': _c['aadharNo']!.text.trim(),
        'totalFees': int.tryParse(_c['totalFees']!.text.trim()) ?? 0,
        'profilePhotoUrl': _photoUrl,
        'active': true,
      };
      final api = ref.read(apiClientProvider);
      if (widget.student == null) {
        await api.crud('students', 'create', token: session.token, data: data);
      } else {
        await api.crud(
          'students',
          'update',
          token: session.token,
          id: widget.student!.studentId,
          data: data,
        );
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (widget.student == null) return;
    final session = await ref.read(authServiceProvider).loadSession();
    await ref.read(apiClientProvider).crud(
          'students',
          'delete',
          token: session.token,
          id: widget.student!.studentId,
        );
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.student == null ? 'Add Student' : 'Edit Student',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (widget.student != null)
              Text(widget.student!.displayLabel),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage:
                      _photoUrl.isNotEmpty ? NetworkImage(_photoUrl) : null,
                  child: _photoUrl.isEmpty ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Photo'),
                ),
              ],
            ),
            for (final entry in _c.entries) ...[
              const SizedBox(height: 8),
              TextField(
                controller: entry.value,
                decoration: InputDecoration(labelText: _label(entry.key)),
                keyboardType: entry.key == 'totalFees' || entry.key.contains('Phone')
                    ? TextInputType.number
                    : TextInputType.text,
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save Student'),
            ),
            if (widget.student != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _delete,
                child: const Text('Delete Student', style: TextStyle(color: Colors.red)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _label(String key) {
    const map = {
      'name': 'Student Name',
      'className': 'Class',
      'section': 'Section',
      'dob': 'Date of Birth (YYYY-MM-DD)',
      'admissionDate': 'Admission Date',
      'fatherName': 'Father Name',
      'fatherPhone': 'Father Phone',
      'fatherEmail': 'Father Email',
      'motherName': 'Mother Name',
      'motherPhone': 'Mother Phone',
      'motherEmail': 'Mother Email',
      'address': 'Address',
      'aadharNo': 'Aadhar No',
      'totalFees': 'Total Fees',
    };
    return map[key] ?? key;
  }
}
