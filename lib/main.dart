import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: Firebase.initializeApp() 추가
  runApp(const ProviderScope(child: PhotoShieldApp()));
}
