// lib/utils/notification_service.dart
import 'dart:convert';
import 'dart:developer';

import 'package:driver/controller/auto_assignment_controller.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/intercity_order_model.dart';
import 'package:driver/model/order_model.dart';
import 'package:driver/model/user_model.dart';
import 'package:driver/ui/chat_screen/chat_screen.dart';
import 'package:driver/ui/home_screens/order_map_screen.dart';
import 'package:driver/ui/order_intercity_screen/complete_intecity_order_screen.dart';
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
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  initInfo() async {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    var request = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (request.authorizationStatus == AuthorizationStatus.authorized ||
        request.authorizationStatus == AuthorizationStatus.provisional) {

      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      var iosInitializationSettings = const DarwinInitializationSettings();

      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: iosInitializationSettings,
      );

      await flutterLocalNotificationsPlugin.initialize(
          initializationSettings,
          onDidReceiveNotificationResponse: (payload) {}
      );

      setupInteractedMessage();
    }
  }

  Future<void> setupInteractedMessage() async {
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // Listener para mensagens em foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Got a message whilst in the foreground!');
      log('Message data: ${message.data}');

      if (message.notification != null) {
        log('Message also contained a notification: ${message.notification}');
      }

      // Processa notificações de atribuição automática
      if (message.data['type'] == 'ride_assignment') {
        NotificationService._handleRideAssignmentNotification(message.data);
      } else {
        // Mostra notificação local para outros tipos
        _showLocalNotification(message);
      }
    });
  }

  void _handleMessage(RemoteMessage message) {
    log('_handleMessage');

    try {
      // Processa diferentes tipos de notificação
      if (message.data['type'] == 'ride_assignment') {
        NotificationService._handleRideAssignmentNotification(message.data);
        return;
      }

      if (message.data['type'] == 'order') {
        String orderId = message.data['orderId'] ?? '';
        _navigateToOrder(orderId);
      } else if (message.data['type'] == 'chat') {
        String senderId = message.data['senderId'] ?? '';
        String orderId = message.data['orderId'] ?? '';
        _navigateToChat(senderId, orderId);
      }

    } catch (e) {
      log('Erro ao processar mensagem: $e');
    }
  }

  /// Processa notificações de atribuição automática de corridas
  static void _handleRideAssignmentNotification(Map<String, dynamic> data) {
    try {
      String orderId = data['orderId'] ?? '';

      if (orderId.isEmpty) return;

      // Verifica se o AutoAssignmentController está inicializado
      if (Get.isRegistered<AutoAssignmentController>()) {
        AutoAssignmentController autoController = AutoAssignmentController.instance;

        // Força verificação de nova atribuição
        autoController.checkForAvailableRides();
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
      DriverUserModel? driver = await FireStoreUtils.getDriverProfile(FireStoreUtils.getCurrentUid());

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
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
      DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
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

  /// Mostra notificação de alta prioridade para atribuição de corrida
  Future<void> showRideAssignmentNotification(OrderModel order) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'ride_assignment_channel',
        'Atribuição de Corridas',
        channelDescription: 'Notificações de corridas atribuídas automaticamente',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        fullScreenIntent: true, // Mostra em tela cheia
        category: AndroidNotificationCategory.call,
        visibility: NotificationVisibility.public,
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
      DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
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

  /// Método estático para obter FCM token
  static getToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    return token!;
  }

  /// Configurações específicas para notificações de atribuição automática
  Future<void> setupRideAssignmentChannel() async {
    try {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'ride_assignment_channel',
        'Atribuição de Corridas',
        description: 'Canal para notificações de corridas atribuídas automaticamente',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (e) {
      log('Erro ao configurar canal de notificação: $e');
    }
  }
}