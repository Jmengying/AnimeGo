import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'app.dart';
import 'services/source_service.dart';
import 'providers/source_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  final sourceService = SourceService();
  await sourceService.init();

  runApp(
    ProviderScope(
      overrides: [
        sourceServiceProvider.overrideWithValue(sourceService),
      ],
      child: const AnimeApp(),
    ),
  );
}
