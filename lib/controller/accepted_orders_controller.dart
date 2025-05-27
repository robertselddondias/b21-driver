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
  void fetchAcceptedOrders() {
    FirebaseFirestore.instance
        .collection(CollectionName.orders)
        .where('acceptedDriverId', arrayContains: currentUserId)
        .snapshots()
        .listen((snapshot) {
      acceptedOrders.value = snapshot.docs
          .map((doc) => OrderModel.fromJson(doc.data()))
          .toList();
    });
  }

  // Método para obter informações de aceitação do motorista para um pedido específico
  Future<DriverIdAcceptReject?> getDriverIdAcceptReject(String orderId) {
    return FireStoreUtils.getAcceptedOrders(orderId, currentUserId);
  }
}
