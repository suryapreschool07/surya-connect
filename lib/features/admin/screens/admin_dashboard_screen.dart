import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../shared/widgets/widgets.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(dataRepositoryProvider);
    final data = repo.data;
    final latestGallery = [...data.gallery]
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Text('Good ${_greeting()}, Admin', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            StatCard(
              label: 'Total Students',
              value: '${data.students.where((s) => s.active).length}',
              icon: Icons.people_outline,
            ),
            StatCard(
              label: 'Present Today',
              value: '${repo.dashboardPresentToday()}',
              icon: Icons.check_circle_outline,
              color: const Color(0xFF2E7D32),
            ),
            StatCard(
              label: 'Absent Today',
              value: '${repo.dashboardAbsentToday()}',
              icon: Icons.cancel_outlined,
              color: const Color(0xFFC62828),
            ),
            StatCard(
              label: 'Pending Fees',
              value: '₹${repo.totalPendingFees()}',
              icon: Icons.account_balance_wallet_outlined,
            ),
          ],
        ),
        const SectionHeader(title: 'Latest Gallery'),
        if (latestGallery.isEmpty)
          const EmptyState(message: 'No gallery items yet.')
        else
          ...latestGallery.take(3).map(
                (item) => ListTile(
                  leading: Icon(
                    item.isYoutube ? Icons.play_circle_outline : Icons.image_outlined,
                  ),
                  title: Text(item.title),
                  subtitle: Text(item.date),
                ),
              ),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}
