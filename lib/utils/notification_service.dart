// lib/utils/notification_service.dart
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:driver/controller/auto_assignment_controller.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/order_model.dart';
import 'package:driver/model/user_model.dart';
import 'package:driver/ui/chat_screen/chat_screen.dart';
import 'package:driver/ui/order_screen/complete_order_screen.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

Future<void> firebaseMessageBackgroundHandle(RemoteMessage message) async {
  log("BackGround Message :: ${message.messageId}");

  // Processa notificações de atribuição automática mesmo em background
  if (message.data['type'] == 'ride_assignment') {
    NotificationService._handleRideAssignmentNotification(message.data);
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initInfo() async {
    try {
      // Configurações do Firebase Messaging
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Solicita permissões
      NotificationSettings settings =
          await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true, // Importante para iOS
        provisional: false,
        sound: true,
      );

      log('Notification Permission Status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Configurações do Android
        const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('@mipmap/ic_launcher');

        // Configurações do iOS
        const DarwinInitializationSettings iosInitializationSettings =
            DarwinInitializationSettings(
                requestAlertPermission: true,
                requestBadgePermission: true,
                requestSoundPermission: true,
                requestCriticalPermission: true);

        final InitializationSettings initializationSettings =
            InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: iosInitializationSettings,
        );

        await flutterLocalNotificationsPlugin.initialize(
          initializationSettings,
          onDidReceiveNotificationResponse: _onNotificationResponse,
        );

        // Configura canais de notificação
        await _setupNotificationChannels();

        // Configura listeners
        await setupInteractedMessage();

        log('NotificationService inicializado com sucesso');
      } else {
        log('Permissões de notificação negadas');
      }
    } catch (e) {
      log('Erro ao inicializar NotificationService: $e');
    }
  }

  /// Método separado para configurar canal de ride assignment
  /// Chamado no main.dart após inicialização
  Future<void> setupRideAssignmentChannel() async {
    try {
      if (Platform.isAndroid) {
        const AndroidNotificationChannel rideAssignmentChannel =
            AndroidNotificationChannel(
          'ride_assignment_channel',
          'Atribuição de Corridas',
          description: 'Notificações de corridas atribuídas automaticamente',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
          enableLights: true,
          ledColor: Color(0xFFFF6B35),
        );

        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin>();

        await androidImplementation
            ?.createNotificationChannel(rideAssignmentChannel);
        log('Canal de ride assignment configurado');
      }
    } catch (e) {
      log('Erro ao configurar canal de ride assignment: $e');
    }
  }

  Future<void> _setupNotificationChannels() async {
    if (Platform.isAndroid) {
      try {
        // Canal principal
        const AndroidNotificationChannel mainChannel =
            AndroidNotificationChannel(
          'b21_driver_channel',
          'B-21 Driver Notifications',
          description: 'Notificações gerais do app B-21 Driver',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );

        // Canal para chat
        const AndroidNotificationChannel chatChannel =
            AndroidNotificationChannel(
          'chat_channel',
          'Mensagens de Chat',
          description: 'Notificações de mensagens de chat',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );

        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin>();

        await androidImplementation?.createNotificationChannel(mainChannel);
        await androidImplementation?.createNotificationChannel(chatChannel);

        log('Canais básicos de notificação configurados');
      } catch (e) {
        log('Erro ao configurar canais básicos: $e');
      }
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    log('Notification clicked: ${response.payload}');

    if (response.payload != null) {
      try {
        Map<String, dynamic> data = jsonDecode(response.payload!);
        _handleNotificationData(data);
      } catch (e) {
        log('Erro ao processar payload da notificação: $e');
      }
    }
  }

  void _handleNotificationData(Map<String, dynamic> data) {
    String type = data['type'] ?? '';

    switch (type) {
      case 'ride_assignment':
        _handleRideAssignmentNotification(data);
        break;
      case 'order':
        String orderId = data['orderId'] ?? '';
        if (orderId.isNotEmpty) _navigateToOrder(orderId);
        break;
      case 'chat':
        String senderId = data['senderId'] ?? '';
        String orderId = data['orderId'] ?? '';
        if (senderId.isNotEmpty && orderId.isNotEmpty) {
          _navigateToChat(senderId, orderId);
        }
        break;
    }
  }

  Future<void> setupInteractedMessage() async {
    // Mensagem que abriu o app
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Mensagem clicada quando o app está em background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // Mensagens recebidas em foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Mensagem recebida em foreground: ${message.messageId}');
      log('Dados: ${message.data}');

      if (message.notification != null) {
        log('Notificação: ${message.notification?.title} - ${message.notification?.body}');
      }

      // Processa diferentes tipos de notificação
      String type = message.data['type'] ?? '';

      if (type == 'ride_assignment') {
        _handleRideAssignmentNotification(message.data);
      } else {
        // Mostra notificação local para outros tipos
        _showLocalNotification(message);
      }
    });
  }

  void _handleMessage(RemoteMessage message) {
    log('_handleMessage: ${message.messageId}');

    try {
      _handleNotificationData(message.data);
    } catch (e) {
      log('Erro ao processar mensagem: $e');
    }
  }

  /// Processa notificações de atribuição automática de corridas
  static void _handleRideAssignmentNotification(Map<String, dynamic> data) {
    try {
      String orderId = data['orderId'] ?? '';

      if (orderId.isEmpty) {
        log('OrderId vazio na notificação de ride assignment');
        return;
      }

      log('Processando atribuição automática para pedido: $orderId');

      // Verifica se o AutoAssignmentController está registrado
      if (Get.isRegistered<AutoAssignmentController>()) {
        AutoAssignmentController autoController =
            Get.find<AutoAssignmentController>();

        // Força verificação de nova atribuição
        autoController.checkForAvailableRides();

        log('AutoAssignmentController notificado da nova corrida');
      } else {
        log('AutoAssignmentController não está registrado - usuário pode não estar logado');

        // Se não estiver registrado, pode ser que o usuário não esteja logado
        // Registra o controller temporariamente para processar a notificação
        try {
          Get.put(AutoAssignmentController());
          AutoAssignmentController autoController =
              Get.find<AutoAssignmentController>();
          autoController.checkForAvailableRides();
          log('AutoAssignmentController criado temporariamente para processar notificação');
        } catch (e) {
          log('Erro ao criar AutoAssignmentController temporariamente: $e');
        }
      }
    } catch (e) {
      log('Erro ao processar atribuição automática: $e');
    }
  }

  void _navigateToOrder(String orderId) async {
    try {
      var orderData = await FireStoreUtils.getOrder(orderId);
      if (orderData != null) {
        Get.to(() => CompleteOrderScreen(), arguments: {
          "orderModel": orderData,
        });
      }
    } catch (e) {
      log('Erro ao navegar para pedido: $e');
    }
  }

  void _navigateToChat(String senderId, String orderId) async {
    try {
      UserModel? sender = await FireStoreUtils.getCustomer(senderId);
      DriverUserModel? driver =
          await FireStoreUtils.getDriverProfile(FireStoreUtils.getCurrentUid());

      if (sender != null && driver != null) {
        Get.to(() => ChatScreens(), arguments: {
          "customerName": sender.fullName ?? '',
          "customerProfilePic": sender.profilePic ?? '',
          "customerId": sender.id ?? '',
          "orderId": orderId,
          "driverModel": driver,
        });
      }
    } catch (e) {
      log('Erro ao navegar para chat: $e');
    }
  }

  /// Mostra notificação local
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      String channelId = _getChannelIdFromType(message.data['type'] ?? '');

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'b21_driver_channel',
        'B-21 Driver Notifications',
        channelDescription: 'Notificações do app B-21 Driver',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await flutterLocalNotificationsPlugin.show(
        message.hashCode,
        message.notification?.title ?? 'B-21',
        message.notification?.body ?? 'Nova notificação',
        platformChannelSpecifics,
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      log('Erro ao mostrar notificação local: $e');
    }
  }

  String _getChannelIdFromType(String type) {
    switch (type) {
      case 'chat':
        return 'chat_channel';
      case 'ride_assignment':
        return 'ride_assignment_channel';
      default:
        return 'b21_driver_channel';
    }
  }

  /// Mostra notificação de alta prioridade para atribuição de corrida
  Future<void> showRideAssignmentNotification(OrderModel order) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'ride_assignment_channel',
        'Atribuição de Corridas',
        channelDescription:
            'Notificações de corridas atribuídas automaticamente',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.call,
        visibility: NotificationVisibility.public,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFFFF6B35),
        enableLights: true,
        ledColor: Color(0xFFFF6B35),
        ledOnMs: 1000,
        ledOffMs: 500,
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
        sound: 'default',
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      String title = 'Nova Corrida Atribuída! 🚗';
      String body = 'De: ${order.sourceLocationName ?? 'Origem'}\n'
          'Para: ${order.destinationLocationName ?? 'Destino'}\n'
          'Valor: R\$ ${order.offerRate ?? '0.00'}';

      await flutterLocalNotificationsPlugin.show(
        999, // ID fixo para substituir notificações anteriores
        title,
        body,
        platformChannelSpecifics,
        payload: jsonEncode({
          'type': 'ride_assignment',
          'orderId': order.id,
        }),
      );
    } catch (e) {
      log('Erro ao mostrar notificação de atribuição: $e');
    }
  }

  /// Cancela notificação de atribuição
  Future<void> cancelRideAssignmentNotification() async {
    try {
      await flutterLocalNotificationsPlugin.cancel(999);
    } catch (e) {
      log('Erro ao cancelar notificação de atribuição: $e');
    }
  }

  /// Cancela todas as notificações
  Future<void> cancelAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
    } catch (e) {
      log('Erro ao cancelar todas as notificações: $e');
    }
  }

  /// Método para ser chamado quando o usuário fizer login
  /// Garantir que todos os canais estão configurados
  Future<void> initializeForLoggedUser() async {
    try {
      await setupRideAssignmentChannel();

      // Atualiza o token FCM se necessário
      String token = await getToken();
      if (token.isNotEmpty) {
        log('FCM Token atualizado após login: $token');
        // Aqui você pode salvar o token no Firestore se necessário
      }

      log('NotificationService configurado para usuário logado');
    } catch (e) {
      log('Erro ao inicializar NotificationService para usuário logado: $e');
    }
  }

  static Future<String> getToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      log('FCM Token: $token');
      return token ?? '';
    } catch (e) {
      log('Erro ao obter FCM token: $e');
      return '';
    }
  }

  /// Verifica status das permissões
  Future<bool> hasNotificationPermission() async {
    try {
      NotificationSettings settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      log('Erro ao verificar permissões: $e');
      return false;
    }
  }

  /// Solicita permissões novamente
  Future<bool> requestNotificationPermission() async {
    try {
      NotificationSettings settings =
          await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        criticalAlert: true,
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      log('Erro ao solicitar permissões: $e');
      return false;
    }
  }
}
