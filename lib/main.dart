import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'providers/habit_provider.dart';
import 'providers/fitness_provider.dart';
import 'providers/water_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/habit_tracker/habit_grid_screen.dart';
import 'screens/fitness_tracker/week_list_screen.dart';
import 'screens/water_tracker/water_tracking_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'services/widget_service.dart';
import 'services/health_service.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar');
  await initializeDateFormatting('en');
  await WidgetService.initialize();
  final savedLocale = await LocaleProvider.getSavedLocale();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(HabitGameApp(initialLocale: savedLocale));
}

class HabitGameApp extends StatelessWidget {
  final Locale initialLocale;

  const HabitGameApp({super.key, required this.initialLocale});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HabitProvider()),
        ChangeNotifierProvider(create: (_) => FitnessProvider()),
        ChangeNotifierProvider(create: (_) => WaterProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider(initialLocale)),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            title: 'Refit',
            debugShowCheckedModeBanner: false,
            locale: localeProvider.locale,
            supportedLocales: const [
              Locale('ar'),
              Locale('en'),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.dark(isArabic: localeProvider.isArabic),
            darkTheme: AppTheme.dark(isArabic: localeProvider.isArabic),
            themeMode: ThemeMode.dark,
            builder: (context, child) {
              return Directionality(
                textDirection: localeProvider.textDirection,
                child: child!,
              );
            },
            home: const MainShell(),
          );
        },
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;

  final _screens = const [
    HabitGridScreen(),
    WeekListScreen(),
    WaterTrackingScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncHealthOnStart());
  }

  Future<void> _syncHealthOnStart() async {
    try {
      final health = HealthService();
      if (await health.isEnabled) {
        if (mounted) {
          await context.read<FitnessProvider>().syncHealthData();
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _syncWidget();
    }
    if (state == AppLifecycleState.resumed) {
      _syncHealthOnStart();
    }
  }

  void _syncWidget() {
    final habitProvider = context.read<HabitProvider>();
    final waterProvider = context.read<WaterProvider>();
    WidgetService.updateWidgetData(
      habitProvider: habitProvider,
      waterProvider: waterProvider,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.check_circle_outline, Icons.check_circle, l.habits),
                _buildNavItem(1, Icons.fitness_center_outlined, Icons.fitness_center, l.fitness),
                _buildNavItem(2, Icons.water_drop_outlined, Icons.water_drop, l.water),
                _buildNavItem(3, Icons.build_outlined, Icons.build, l.tools),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isActive ? AppColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? AppColors.background : AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive ? AppColors.accent : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
