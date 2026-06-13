import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_service.dart';
import '../../core/providers/providers.dart';
import '../../shared/widgets/widgets.dart';
import 'screens/parent_attendance_screen.dart';
import 'screens/parent_dashboard_screen.dart';
import 'screens/parent_fees_screen.dart';
import 'screens/parent_gallery_screen.dart';
import 'screens/parent_results_screen.dart';

class ParentShell extends ConsumerStatefulWidget {
  const ParentShell({super.key});

  @override
  ConsumerState<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends ConsumerState<ParentShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncDataProvider);
    final sessionFuture = ref.read(authServiceProvider).loadSession();

    return FutureBuilder<AuthSession>(
      future: sessionFuture,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final session = snap.data!;
        final screens = [
          ParentDashboardScreen(session: session),
          ParentAttendanceScreen(session: session),
          ParentFeesScreen(session: session),
          ParentResultsScreen(session: session),
          ParentGalleryScreen(),
        ];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Parent Portal'),
            actions: [
              IconButton(
                icon: const Icon(Icons.sync),
                onPressed: () => ref.read(syncDataProvider.notifier).refresh(),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await ref.read(authServiceProvider).logout();
                  if (context.mounted) context.go('/role-select');
                },
              ),
            ],
          ),
          body: syncState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (state) => SyncRefreshWrapper(
              isRefreshing: state.isRefreshing,
              onRefresh: () => ref.read(syncDataProvider.notifier).refresh(),
              child: screens[_index],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.event_available_outlined), label: 'Attendance'),
              NavigationDestination(icon: Icon(Icons.payments_outlined), label: 'Fees'),
              NavigationDestination(icon: Icon(Icons.assignment_outlined), label: 'Results'),
              NavigationDestination(icon: Icon(Icons.photo_library_outlined), label: 'Gallery'),
            ],
          ),
        );
      },
    );
  }
}
