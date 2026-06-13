import 'package:flutter_test/flutter_test.dart';
import 'package:surya_connect/core/models/models.dart';

void main() {
  test('StudentModel displayLabel includes ID and name', () {
    final student = StudentModel(
      studentId: 'S001',
      name: 'Rahul Patel',
      className: 'Nursery',
      section: 'A',
    );
    expect(student.displayLabel, 'S001 - Rahul Patel');
  });

  test('pending fees from sync data', () {
    final student = StudentModel(
      studentId: 'S001',
      name: 'Test',
      className: 'Nursery',
      section: 'A',
      totalFees: 10000,
    );
    final data = SyncData(
      students: [student],
      feePayments: [
        FeePaymentModel(
          paymentId: 'P1',
          paymentDate: '2026-01-01',
          studentId: 'S001',
          studentName: 'Test',
          amountPaid: 3000,
        ),
      ],
    );
    final paid = data.feePayments.fold<int>(0, (s, p) => s + p.amountPaid);
    expect(student.totalFees - paid, 7000);
  });
}
