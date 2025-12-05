import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/model/admin_commission.dart';
import 'package:driver/model/coupon_model.dart';
import 'package:driver/model/freight_vehicle.dart';
import 'package:driver/model/intercity_service_model.dart';
import 'package:driver/model/order/location_lat_lng.dart';
import 'package:driver/model/order/positions.dart';
import 'package:driver/model/tax_model.dart';
import 'package:driver/model/zone_model.dart';

import 'contact_model.dart';

class InterCityOrderModel {
  String? sourceCity;
  String? sourceLocationName;
  String? destinationCity;
  String? destinationLocationName;
  String? paymentType;
  LocationLatLng? sourceLocationLAtLng;
  LocationLatLng? destinationLocationLAtLng;
  String? id;
  String? intercityServiceId;
  String? userId;
  String? offerRate;
  String? finalRate;
  String? distance;
  String? distanceType;
  String? status;
  String? driverId;
  String? parcelDimension;
  String? parcelWeight;
  List<dynamic>? parcelImage;

  // Campos para sistema de atribuição automática (paridade com OrderModel)
  String? assignedDriverId;
  Timestamp? assignedAt;
  Timestamp? acceptedAt;
  List<dynamic>? rejectedDriverIds;

  // Campos legados (mantidos apenas para leitura de dados antigos)
  List<dynamic>? acceptedDriverId;
  List<dynamic>? rejectedDriverId;

  Positions? position;
  Timestamp? createdDate;
  Timestamp? updateDate;

  bool? paymentStatus;
  List<TaxModel>? taxList;
  CouponModel? coupon;
  FreightVehicle? freightVehicle;
  IntercityServiceModel? intercityService;
  String? whenDates;
  String? whenTime;
  String? numberOfPassenger;
  String? comments;
  String? otp;
  ContactModel? someOneElse;
  AdminCommission? adminCommission;
  ZoneModel? zone;
  String? zoneId;

  InterCityOrderModel({
    this.position,
    this.intercityServiceId,
    this.paymentType,
    this.sourceLocationName,
    this.sourceCity,
    this.destinationLocationName,
    this.destinationCity,
    this.sourceLocationLAtLng,
    this.destinationLocationLAtLng,
    this.id,
    this.userId,
    this.distance,
    this.distanceType,
    this.status,
    this.driverId,
    this.parcelWeight,
    this.parcelDimension,
    this.offerRate,
    this.finalRate,
    this.paymentStatus,
    this.createdDate,
    this.updateDate,
    this.taxList,
    this.coupon,
    this.intercityService,
    this.whenTime,
    this.numberOfPassenger,
    this.whenDates,
    this.comments,
    this.otp,
    this.someOneElse,
    this.adminCommission,
    this.zone,
    this.zoneId,
    // Campos de auto-assignment
    this.assignedDriverId,
    this.assignedAt,
    this.acceptedAt,
    this.rejectedDriverIds,
    // Campos legados
    this.acceptedDriverId,
    this.rejectedDriverId,
    this.parcelImage,
  });

  InterCityOrderModel.fromJson(Map<String, dynamic> json) {
    intercityServiceId = json['intercityServiceId'];
    sourceLocationName = json['sourceLocationName'];
    sourceCity = json['sourceCity'];
    paymentType = json['paymentType'];
    destinationLocationName = json['destinationLocationName'];
    destinationCity = json['destinationCity'];
    sourceLocationLAtLng = json['sourceLocationLAtLng'] != null
        ? LocationLatLng.fromJson(json['sourceLocationLAtLng'])
        : null;
    destinationLocationLAtLng = json['destinationLocationLAtLng'] != null
        ? LocationLatLng.fromJson(json['destinationLocationLAtLng'])
        : null;
    coupon =
        json['coupon'] != null ? CouponModel.fromJson(json['coupon']) : null;
    freightVehicle = json['freightVehicle'] != null
        ? FreightVehicle.fromJson(json['freightVehicle'])
        : null;
    intercityService = json['intercityService'] != null
        ? IntercityServiceModel.fromJson(json['intercityService'])
        : null;
    id = json['id'];
    userId = json['userId'];
    offerRate = json['offerRate'];
    finalRate = json['finalRate'];
    distance = json['distance'];
    distanceType = json['distanceType'];
    status = json['status'];
    driverId = json['driverId'];
    parcelWeight = json['parcelWeight'];
    parcelDimension = json['parcelDimension'];
    createdDate = json['createdDate'];
    updateDate = json['updateDate'];
    parcelImage = json['parcelImage'];
    paymentStatus = json['paymentStatus'];

    // Campos de auto-assignment
    assignedDriverId = json['assignedDriverId'];
    assignedAt = json['assignedAt'];
    acceptedAt = json['acceptedAt'];
    rejectedDriverIds = json['rejectedDriverIds'];

    // Campos legados
    acceptedDriverId = json['acceptedDriverId'];
    rejectedDriverId = json['rejectedDriverId'];
    whenTime = json['whenTime'];
    whenDates = json['whenDates'];
    numberOfPassenger = json['numberOfPassenger'];
    comments = json['comments'];
    otp = json['otp'];
    position =
        json['position'] != null ? Positions.fromJson(json['position']) : null;
    adminCommission = json['adminCommission'] != null
        ? AdminCommission.fromJson(json['adminCommission'])
        : null;
    someOneElse = json['someOneElse'] != null
        ? ContactModel.fromJson(json['someOneElse'])
        : null;
    zone = json['zone'] != null ? ZoneModel.fromJson(json['zone']) : null;
    zoneId = json['zoneId'];
    if (json['taxList'] != null) {
      taxList = <TaxModel>[];
      json['taxList'].forEach((v) {
        taxList!.add(TaxModel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['intercityServiceId'] = intercityServiceId;
    data['sourceLocationName'] = sourceLocationName;
    data['sourceCity'] = sourceCity;
    data['destinationLocationName'] = destinationLocationName;
    data['destinationCity'] = destinationCity;
    if (sourceLocationLAtLng != null) {
      data['sourceLocationLAtLng'] = sourceLocationLAtLng!.toJson();
    }
    if (coupon != null) {
      data['coupon'] = coupon!.toJson();
    }
    if (freightVehicle != null) {
      data['freightVehicle'] = freightVehicle!.toJson();
    }
    if (intercityService != null) {
      data['intercityService'] = intercityService!.toJson();
    }
    if (someOneElse != null) {
      data['someOneElse'] = someOneElse!.toJson();
    }
    if (destinationLocationLAtLng != null) {
      data['destinationLocationLAtLng'] = destinationLocationLAtLng!.toJson();
    }
    if (zone != null) {
      data['zone'] = zone!.toJson();
    }
    data['zoneId'] = zoneId;
    data['id'] = id;
    data['userId'] = userId;
    data['paymentType'] = paymentType;
    data['offerRate'] = offerRate;
    data['finalRate'] = finalRate;
    data['distance'] = distance;
    data['distanceType'] = distanceType;
    data['status'] = status;
    data['driverId'] = driverId;
    data['parcelWeight'] = parcelWeight;
    data['parcelDimension'] = parcelDimension;
    data['createdDate'] = createdDate;
    data['updateDate'] = updateDate;
    data['parcelImage'] = parcelImage;
    data['paymentStatus'] = paymentStatus;

    // Campos de auto-assignment
    data['assignedDriverId'] = assignedDriverId;
    data['assignedAt'] = assignedAt;
    data['acceptedAt'] = acceptedAt;
    data['rejectedDriverIds'] = rejectedDriverIds;

    // Campos legados
    data['acceptedDriverId'] = acceptedDriverId;
    data['rejectedDriverId'] = rejectedDriverId;
    data['whenTime'] = whenTime;
    data['whenDates'] = whenDates;
    data['numberOfPassenger'] = numberOfPassenger;
    data['comments'] = comments;
    data['otp'] = otp;
    if (taxList != null) {
      data['taxList'] = taxList!.map((v) => v.toJson()).toList();
    }
    if (position != null) {
      data['position'] = position!.toJson();
    }
    if (adminCommission != null) {
      data['adminCommission'] = adminCommission!.toJson();
    }
    return data;
  }

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
