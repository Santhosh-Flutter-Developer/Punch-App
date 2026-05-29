import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:punch_app/core/constants/app_constants.dart';
import 'package:punch_app/core/theme/app_theme.dart';
import 'package:punch_app/presentation/auth/bindings/initial_binding.dart';
import 'package:punch_app/presentation/not_found/ui/not_found.dart';
import 'package:punch_app/routes/app_pages.dart';
import 'package:punch_app/routes/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://cdsyrbktwxbdptwifbpb.supabase.co',
);
const supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNkc3lyYmt0d3hiZHB0d2lmYnBiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAwNDc1MzgsImV4cCI6MjA5NTYyMzUzOH0.cYt_dy2drgR9Q5HWa1yk1CaYCq5gEOguyl9fFMKSIe0',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //INIT GETSTORAGE

  await GetStorage.init();

  // INIT SUPABASE
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(const PunchApp());
}

class PunchApp extends StatelessWidget {
  const PunchApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialBinding: InitialBinding(),
      initialRoute: isWide ? AppRoutes.routeLogin : AppRoutes.routeSplash,
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
      getPages: AppPages.pages,
      unknownRoute: GetPage(name: '/404', page: () => const NotFound()),
    );
  }
}
