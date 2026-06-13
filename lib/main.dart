import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../core/storage/hive_storage.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = HiveStorage();
  await storage.init();
  runApp(const ProviderScope(child: SuryaConnectApp()));
}
