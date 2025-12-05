// accepted_orders_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/model/order/driverId_accept_reject.dart';
import 'package:driver/model/order_model.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class AcceptedOrdersController extends GetxController {
  RxList<OrderModel> acceptedOrders = <OrderModel>[].obs;
  final String currentUserId = FireStoreUtils.getCurrentUid();

  @override
  void onInit() {
    super.onInit();
    fetchAcceptedOrders();
  }

  // Método para buscar pedidos aceitos
  // NOTA: Busca tanto no campo novo (assignedDriverId) quanto no legado (acceptedDriverId)
  void fetchAcceptedOrders() {
    // Busca 1: Pedidos com sistema novo (assignedDriverId)
    final stream1 = FirebaseFirestore.instance
        .collection(CollectionName.orders)
        .where('assignedDriverId', isEqualTo: currentUserId)
        .where('status', whereIn: ['new', 'confirmed'])
        .snapshots();

    // Busca 2: Pedidos com sistema legado (acceptedDriverId array)
    final stream2 = FirebaseFirestore.instance
        .collection(CollectionName.orders)
        .where('acceptedDriverId', arrayContains: currentUserId)
        .where('status', whereIn: ['new', 'confirmed'])
        .snapshots();

    // Combina ambos os streams
    stream1.listen((snapshot1) {
      stream2.listen((snapshot2) {
        final Set<String> orderIds = {};
        final List<OrderModel> orders = [];

        // Adiciona pedidos do stream1
        for (var doc in snapshot1.docs) {
          if (!orderIds.contains(doc.id)) {
            orderIds.add(doc.id);
            orders.add(OrderModel.fromJson(doc.data()));
          }
        }

        // Adiciona pedidos do stream2 (se não duplicados)
        for (var doc in snapshot2.docs) {
          if (!orderIds.contains(doc.id)) {
            orderIds.add(doc.id);
            orders.add(OrderModel.fromJson(doc.data()));
          }
        }

        acceptedOrders.value = orders;
      });
    });
  }

  // Método para obter informações de aceitação do motorista para um pedido específico
  Future<DriverIdAcceptReject?> getDriverIdAcceptReject(String orderId) {
    return FireStoreUtils.getAcceptedOrders(orderId, currentUserId);
  }
}
