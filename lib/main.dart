import 'package:flutter/material.dart';
import 'app.dart';
import 'core/app_dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dependencies = await AppDependencies.create();

  runApp(
    AuthNotificationApp(dependencies: dependencies),
  );
}