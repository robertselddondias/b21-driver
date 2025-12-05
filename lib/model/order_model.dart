// lib/model/order_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/model/admin_commission.dart';
import 'package:driver/model/contact_model.dart';
import 'package:driver/model/coupon_model.dart';
import 'package:driver/model/order/location_lat_lng.dart';
import 'package:driver/model/order/positions.dart';
import 'package:driver/model/service_model.dart';
import 'package:driver/model/tax_model.dart';
import 'package:driver/model/zone_model.dart';

class OrderModel {
  String? sourceLocationName;
  String? destinationLocationName;
  LocationLatLng? sourceLocationLAtLng;
  LocationLatLng? destinationLocationLAtLng;
  String? id;
  String? serviceId;
  String? userId;
  String? offerRate;
  String? finalRate;
  String? distance;
  String? distanceType;
  String? status;
  String? driverId;
  String? otp;

  // Campos para sistema de atribuição automática
  String? assignedDriverId;
  Timestamp? assignedAt;
  Timestamp? acceptedAt;
  List<dynamic>? rejectedDriverIds;

  // Campos legados (mantidos apenas para leitura de dados antigos)
  // DEPRECADO: Use rejectedDriverIds ao invés de rejectedDriverId
  List<dynamic>? acceptedDriverId;
  List<dynamic>? rejectedDriverId;

  /// Retorna lista unificada de motoristas que rejeitaram
  /// Combina dados novos (rejectedDriverIds) com legados (rejectedDriverId)
  List<dynamic> get allRejectedDriverIds {
    final Set<dynamic> rejected = {};
    if (rejectedDriverIds != null) {
      rejected.addAll(rejectedDriverIds!);
    }
    if (rejectedDriverId != null) {
      rejected.addAll(rejectedDriverId!);
    }
    return rejected.toList();
  }

  /// Retorna lista unificada de motoristas que aceitaram
  /// Combina dados novos com legados
  List<dynamic> get allAcceptedDriverIds {
    final Set<dynamic> accepted = {};
    if (assignedDriverId != null) {
      accepted.add(assignedDriverId!);
    }
    if (acceptedDriverId != null) {
      accepted.addAll(acceptedDriverId!);
    }
    return accepted.toList();
  }

  Positions? position;
  Timestamp? createdDate;
  Timestamp? updateDate;
  bool? paymentStatus;
  List<TaxModel>? taxList;
  ContactModel? someOneElse;
  CouponModel? coupon;
  ServiceModel? service;
  AdminCommission? adminCommission;
  ZoneModel? zone;
  String? zoneId;

  OrderModel({
    this.position,
    this.serviceId,
    this.sourceLocationName,
    this.destinationLocationName,
    this.sourceLocationLAtLng,
    this.destinationLocationLAtLng,
    this.id,
    this.userId,
    this.distance,
    this.distanceType,
    this.status,
    this.driverId,
    this.otp,
    this.offerRate,
    this.finalRate,
    this.paymentStatus,
    this.createdDate,
    this.updateDate,
    this.taxList,
    this.coupon,
    this.someOneElse,
    this.service,
    this.adminCommission,
    this.zone,
    this.zoneId,
    // Novos campos
    this.assignedDriverId,
    this.assignedAt,
    this.acceptedAt,
    this.rejectedDriverIds,
    // Campos legados
    this.acceptedDriverId,
    this.rejectedDriverId,
  });

  OrderModel.fromJson(Map<String, dynamic> json) {
    serviceId = json['serviceId'];
    sourceLocationName = json['sourceLocationName'];
    destinationLocationName = json['destinationLocationName'];
    sourceLocationLAtLng = json['sourceLocationLAtLng'] != null
        ? LocationLatLng.fromJson(json['sourceLocationLAtLng'])
        : null;
    destinationLocationLAtLng = json['destinationLocationLAtLng'] != null
        ? LocationLatLng.fromJson(json['destinationLocationLAtLng'])
        : null;
    coupon =
        json['coupon'] != null ? CouponModel.fromJson(json['coupon']) : null;
    someOneElse = json['someOneElse'] != null
        ? ContactModel.fromJson(json['someOneElse'])
        : null;
    id = json['id'];
    userId = json['userId'];
    offerRate = json['offerRate'];
    finalRate = json['finalRate'];
    distance = json['distance'];
    distanceType = json['distanceType'];
    status = json['status'];
    driverId = json['driverId'];
    otp = json['otp'];
    createdDate = json['createdDate'];
    updateDate = json['updateDate'];
    paymentStatus = json['paymentStatus'];

    // Novos campos para atribuição automática
    assignedDriverId = json['assignedDriverId'];
    assignedAt = json['assignedAt'];
    acceptedAt = json['acceptedAt'];
    rejectedDriverIds = json['rejectedDriverIds'];

    // Campos legados (mantidos para compatibilidade)
    acceptedDriverId = json['acceptedDriverId'];
    rejectedDriverId = json['rejectedDriverId'];

    position =
        json['position'] != null ? Positions.fromJson(json['position']) : null;

    if (json['taxList'] != null) {
      taxList = <TaxModel>[];
      json['taxList'].forEach((v) {
        taxList!.add(TaxModel.fromJson(v));
      });
    }

    service =
        json['service'] != null ? ServiceModel.fromJson(json['service']) : null;
    adminCommission = json['adminCommission'] != null
        ? AdminCommission.fromJson(json['adminCommission'])
        : null;
    zone = json['zone'] != null ? ZoneModel.fromJson(json['zone']) : null;
    zoneId = json['zoneId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['serviceId'] = serviceId;
    data['sourceLocationName'] = sourceLocationName;
    data['destinationLocationName'] = destinationLocationName;
    if (sourceLocationLAtLng != null) {
      data['sourceLocationLAtLng'] = sourceLocationLAtLng!.toJson();
    }
    if (destinationLocationLAtLng != null) {
      data['destinationLocationLAtLng'] = destinationLocationLAtLng!.toJson();
    }
    if (coupon != null) {
      data['coupon'] = coupon!.toJson();
    }
    if (someOneElse != null) {
      data['someOneElse'] = someOneElse!.toJson();
    }
    data['id'] = id;
    data['userId'] = userId;
    data['offerRate'] = offerRate;
    data['finalRate'] = finalRate;
    data['distance'] = distance;
    data['distanceType'] = distanceType;
    data['status'] = status;
    data['driverId'] = driverId;
    data['otp'] = otp;
    data['createdDate'] = createdDate;
    data['updateDate'] = updateDate;
    data['paymentStatus'] = paymentStatus;

    // Novos campos
    data['assignedDriverId'] = assignedDriverId;
    data['assignedAt'] = assignedAt;
    data['acceptedAt'] = acceptedAt;
    data['rejectedDriverIds'] = rejectedDriverIds;

    // Campos legados
    data['acceptedDriverId'] = acceptedDriverId;
    data['rejectedDriverId'] = rejectedDriverId;

    if (position != null) {
      data['position'] = position!.toJson();
    }
    if (taxList != null) {
      data['taxList'] = taxList!.map((v) => v.toJson()).toList();
    }
    if (service != null) {
      data['service'] = service!.toJson();
    }
    if (adminCommission != null) {
      data['adminCommission'] = adminCommission!.toJson();
    }
    if (zone != null) {
      data['zone'] = zone!.toJson();
    }
    data['zoneId'] = zoneId;
    return data;
  }

  /// Verifica se a corrida foi atribuída automaticamente
  bool get isAutoAssigned => assignedDriverId != null;

  /// Verifica se a corrida foi aceita pelo motorista atribuído
  bool get isAcceptedByAssignedDriver =>
      assignedDriverId != null &&
      driverId == assignedDriverId &&
      acceptedAt != null;

  /// Verifica se o motorista rejeitou a corrida
  /// Usa lista unificada (dados novos + legados)
  bool isRejectedByDriver(String driverId) =>
      allRejectedDriverIds.contains(driverId);

  /// Tempo desde a atribuição em minutos
  int get minutesSinceAssignment {
    if (assignedAt == null) return 0;
    return DateTime.now().difference(assignedAt!.toDate()).inMinutes;
  }

  /// Verifica se a atribuição expirou (15 minutos)
  bool get isAssignmentExpired => minutesSinceAssignment > 15;
}
