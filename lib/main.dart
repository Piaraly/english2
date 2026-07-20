import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'controllers/app_controller.dart';
import 'core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  final controller = AppController();
  await controller.initialize();
  runApp(
    ChangeNotifierProvider.value(
      value: controller,
      child: const EnglishForgeApp(),
    ),
  );
}
