// lib/main.dart (Modificações para integrar Auto Assignment)
import 'package:driver/controller/auto_assignment_controller.dart';
import 'package:driver/controller/global_setting_conroller.dart';
import 'package:driver/services/localization_service.dart';
import 'package:driver/ui/splash_screen.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/Preferences.dart';
import 'package:driver/utils/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase
  await Firebase.initializeApp();

  // Inicializa preferências
  await Preferences.initPref();

  // Inicializa serviço de notificações
  NotificationService notificationService = NotificationService();
  await notificationService.initInfo();
  await notificationService.setupRideAssignmentChannel();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DarkThemeProvider>(
          create: (_) => DarkThemeProvider(),
        ),
      ],
      child: Consumer<DarkThemeProvider>(
          builder: (context, themeChangeProvider, child) {
        return GetMaterialApp(
          title: 'B-21 Driver',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          darkTheme: ThemeData.dark(),
          themeMode: themeChangeProvider.darkTheme == 0
              ? ThemeMode.system
              : themeChangeProvider.darkTheme == 1
                  ? ThemeMode.dark
                  : ThemeMode.light,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: const Locale('pt'),
          supportedLocales: const [Locale('pt', 'BR')],
          fallbackLocale: LocalizationService.locale,
          translations: LocalizationService(),
          builder: EasyLoading.init(),

          // Inicializa controllers globais
          initialBinding: BindingsBuilder(() {
            Get.put(GlobalSettingController());

            // Inicializa AutoAssignmentController apenas quando o usuário estiver logado
            // Isso será feito no DashBoardScreen após login
          }),

          home: GetBuilder<GlobalSettingController>(
            init: GlobalSettingController(),
            builder: (context) {
              return const SplashScreen();
            },
          ),
        );
      }),
    );
  }
}

/// Binding para inicializar controllers específicos do sistema de atribuição
class AutoAssignmentBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AutoAssignmentController());
  }
}
