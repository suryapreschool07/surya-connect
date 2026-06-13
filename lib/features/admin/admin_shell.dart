import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/providers.dart';
import '../../shared/widgets/widgets.dart';
import 'screens/admin_attendance_screen.dart';
import 'screens/admin_classes_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_fees_screen.dart';
import 'screens/admin_gallery_screen.dart';
import 'screens/admin_staff_screen.dart';
import 'screens/admin_students_screen.dart';
import 'screens/admin_tests_screen.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _index = 0;

  final _screens = const [
    AdminDashboardScreen(),
    AdminStudentsScreen(),
    AdminAttendanceScreen(),
    AdminFeesScreen(),
    AdminGalleryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () => ref.read(syncDataProvider.notifier).refresh(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                await ref.read(authServiceProvider).logout();
                if (context.mounted) context.go('/role-select');
              } else if (value == 'classes') {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AdminClassesScreen()),
                );
              } else if (value == 'tests') {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AdminTestsScreen()),
                );
              } else if (value == 'staff') {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AdminStaffScreen()),
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'classes', child: Text('Classes')),
              PopupMenuItem(value: 'tests', child: Text('Tests')),
              PopupMenuItem(value: 'staff', child: Text('Staff')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: syncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (state) => SyncRefreshWrapper(
          isRefreshing: state.isRefreshing,
          onRefresh: () => ref.read(syncDataProvider.notifier).refresh(),
          child: _screens[_index],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.school_outlined), label: 'Students'),
          NavigationDestination(icon: Icon(Icons.event_available_outlined), label: 'Attendance'),
          NavigationDestination(icon: Icon(Icons.payments_outlined), label: 'Fees'),
          NavigationDestination(icon: Icon(Icons.photo_library_outlined), label: 'Gallery'),
        ],
      ),
    );
  }
}
