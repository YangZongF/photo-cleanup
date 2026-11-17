import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_state.dart';
import 'features/home_screen.dart';
import 'l10n/app_localizations.dart';
import 'theme.dart';

void main() {
  runApp(const PhotoCleanupApp());
}

class PhotoCleanupApp extends StatefulWidget {
  const PhotoCleanupApp({super.key});

  @override
  State<PhotoCleanupApp> createState() => _PhotoCleanupAppState();
}

class _PhotoCleanupAppState extends State<PhotoCleanupApp> {
  AppState? _state;

  @override
  void initState() {
    super.initState();
    AppState.load().then((state) {
      if (mounted) setState(() => _state = state);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    return MaterialApp(
      // Language follows the system locale. English + Chinese in V1.
      locale: null,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('zh')],
      theme: cleanTheme(),
      home: state == null
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : HomeScreen(state: state),
    );
  }
}
