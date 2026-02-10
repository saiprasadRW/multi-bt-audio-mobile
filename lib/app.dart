import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'providers/broadcast_provider.dart';
import 'providers/device_provider.dart';
import 'screens/home_screen.dart';

class MultiBTAudioApp extends StatelessWidget {
  const MultiBTAudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        ChangeNotifierProvider(create: (_) => BroadcastProvider()),
      ],
      child: MaterialApp(
        title: 'Multi BT Audio',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.dark,
            surface: AppColors.surface,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.primaryDark,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primaryDark,
            elevation: 0,
          ),
          cardTheme: CardTheme(
            color: AppColors.surfaceLight,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
