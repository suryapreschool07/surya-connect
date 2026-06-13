import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';
import '../../../shared/widgets/widgets.dart';

class AdminFeesScreen extends ConsumerStatefulWidget {
  const AdminFeesScreen({super.key});

  @override
  ConsumerState<AdminFeesScreen> createState() => _AdminFeesScreenState();
}

class _AdminFeesScreenState extends ConsumerState<AdminFeesScreen> {
  Future<void> _addPayment() async {
    final repo = ref.read(dataRepositoryProvider);
    final students = repo.data.students.where((s) => s.active).toList();
    if (students.isEmpty) return;

    StudentModel? selected = students.first;
    final amountCtrl = TextEditingController();
    final methodCtrl = TextEditingController(text: 'cash');
    final remarksCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Record Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<StudentModel>(
                  value: selected,
                  decoration: const InputDecoration(labelText: 'Student'),
                  items: students
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.displayLabel)))
                      .toList(),
                  onChanged: (v) => setLocal(() => selected = v),
                ),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount Paid'),
                ),
                TextField(
                  controller: methodCtrl,
                  decoration: const InputDecoration(labelText: 'Method (cash/online/cheque)'),
                ),
                TextField(
                  controller: remarksCtrl,
                  decoration: const InputDecoration(labelText: 'Remarks'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (ok != true || selected == null) return;
    final session = await ref.read(authServiceProvider).loadSession();
    await ref.read(apiClientProvider).crud(
          'fees',
          'create',
          token: session.token,
          data: {
            'paymentDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
            'studentId': selected!.studentId,
            'studentName': selected!.name,
            'amountPaid': int.tryParse(amountCtrl.text.trim()) ?? 0,
            'method': methodCtrl.text.trim(),
            'remarks': remarksCtrl.text.trim(),
          },
        );
    await ref.read(syncDataProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(dataRepositoryProvider);
    final students = repo.data.students.where((s) => s.active).toList();

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: students.length,
          itemBuilder: (_, i) {
            final s = students[i];
            final paid = repo.totalPaidForStudent(s.studentId);
            final pending = repo.pendingFeesForStudent(s.studentId);
            return Card(
              child: ExpansionTile(
                title: StudentIdLabel(studentId: s.studentId, name: s.name),
                subtitle: Text('Paid ₹$paid · Pending ₹$pending'),
                children: repo.paymentsForStudent(s.studentId).map((p) {
                  return ListTile(
                    title: Text('₹${p.amountPaid} · ${p.method}'),
                    subtitle: Text('${p.paymentDate} · ${p.remarks}'),
                  );
                }).toList(),
              ),
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: _addPayment,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
