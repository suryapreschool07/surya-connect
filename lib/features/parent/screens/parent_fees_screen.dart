import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';
import '../../../shared/widgets/widgets.dart';

class ParentFeesScreen extends ConsumerWidget {
  const ParentFeesScreen({super.key, required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(dataRepositoryProvider);
    final child = _selectedChild(repo);
    if (child == null) {
      return const EmptyState(message: 'No student selected.');
    }

    final paid = repo.totalPaidForStudent(child.studentId);
    final pending = repo.pendingFeesForStudent(child.studentId);
    final payments = repo.paymentsForStudent(child.studentId);

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        StudentIdLabel(studentId: child.studentId, name: child.name),
        const SizedBox(height: 16),
        StatCard(label: 'Total Fees', value: '₹${child.totalFees}', icon: Icons.receipt_long),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: StatCard(label: 'Paid', value: '₹$paid', icon: Icons.check_circle)),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                label: 'Pending',
                value: '₹$pending',
                icon: Icons.warning_amber,
                color: const Color(0xFFC62828),
              ),
            ),
          ],
        ),
        const SectionHeader(title: 'Payment History'),
        if (payments.isEmpty)
          const Text('No payments recorded yet.')
        else
          ...payments.map(
            (p) => Card(
              child: ListTile(
                title: Text('₹${p.amountPaid} · ${p.method}'),
                subtitle: Text('${p.paymentDate}\n${p.remarks}'),
              ),
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
