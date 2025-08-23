// lib/ui/inbox_screen.dart - Versão com temas e responsividade
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/inbox_model.dart';
import 'package:driver/model/user_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/ui/chat_screen/chat_screen.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:driver/widget/firebase_pagination/src/firestore_pagination.dart';
import 'package:driver/widget/firebase_pagination/src/models/view_type.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          SizedBox(
            height: Responsive.height(4, context),
            width: Responsive.width(100, context),
          ),
          Expanded(
            child: Container(
              width: Responsive.width(100, context),
              decoration: BoxDecoration(
                color: themeChange.getThem()
                    ? AppColors.darkBackground
                    : AppColors.background,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25)
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    width: Responsive.width(100, context),
                    padding: EdgeInsets.all(Responsive.width(5, context)),
                    child: Row(
                      children: [
                        Icon(
                          Icons.inbox,
                          color: themeChange.getThem() ? Colors.white : Colors.black87,
                          size: Responsive.width(6, context),
                        ),
                        SizedBox(width: Responsive.width(3, context)),
                        Text(
                          'Mensagens',
                          style: GoogleFonts.poppins(
                            fontSize: Responsive.width(5, context),
                            fontWeight: FontWeight.w600,
                            color: themeChange.getThem() ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Messages List
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.width(2.5, context),
                        vertical: Responsive.height(1.2, context),
                      ),
                      child: FirestorePagination(
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, documentSnapshots, index) {
                          final data = documentSnapshots[index].data() as Map<String, dynamic>?;
                          InboxModel inboxModel = InboxModel.fromJson(data!);
                          return _buildInboxItem(context, inboxModel, themeChange);
                        },
                        shrinkWrap: true,
                        onEmpty: _buildEmptyState(context, themeChange),
                        query: FirebaseFirestore.instance
                            .collection(CollectionName.chat)
                            .where("driverId", isEqualTo: FireStoreUtils.getCurrentUid())
                            .orderBy('createdAt', descending: true),
                        viewType: ViewType.list,
                        initialLoader: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                        isLive: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInboxItem(BuildContext context, InboxModel inboxModel, DarkThemeProvider themeChange) {
    return Container(
      margin: EdgeInsets.only(bottom: Responsive.height(1, context)),
      child: InkWell(
        onTap: () async {
          UserModel? customer = await FireStoreUtils.getCustomer(inboxModel.customerId.toString());
          DriverUserModel? driver = await FireStoreUtils.getDriverProfile(inboxModel.driverId.toString());

          Get.to(ChatScreens(
            driverId: driver!.id,
            customerId: customer!.id,
            customerName: customer.fullName,
            customerProfileImage: customer.profilePic,
            driverName: driver.fullName,
            driverProfileImage: driver.profilePic,
            orderId: inboxModel.orderId,
            token: customer.fcmToken,
          ));
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: themeChange.getThem()
                ? AppColors.darkContainerBackground
                : AppColors.containerBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: themeChange.getThem()
                  ? AppColors.darkContainerBorder
                  : AppColors.containerBorder,
              width: 1,
            ),
            boxShadow: themeChange.getThem()
                ? null
                : [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(Responsive.width(4, context)),
            child: Row(
              children: [
                // Profile Image
                Container(
                  width: Responsive.width(12, context),
                  height: Responsive.width(12, context),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      width: Responsive.width(12, context),
                      height: Responsive.width(12, context),
                      imageUrl: inboxModel.customerProfileImage.toString(),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.lightGray,
                        child: Icon(
                          Icons.person,
                          color: AppColors.subTitleColor,
                          size: Responsive.width(6, context),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.lightGray,
                        child: Icon(
                          Icons.person,
                          color: AppColors.subTitleColor,
                          size: Responsive.width(6, context),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: Responsive.width(3.5, context)),

                // Message Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Name and Time
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              inboxModel.customerName.toString(),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: Responsive.width(4, context),
                                color: themeChange.getThem() ? Colors.white : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: Responsive.width(2, context)),
                          Text(
                            Constant.dateFormatTimestamp(inboxModel.createdAt),
                            style: GoogleFonts.poppins(
                              fontSize: Responsive.width(3, context),
                              fontWeight: FontWeight.w400,
                              color: AppColors.subTitleColor,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: Responsive.height(0.5, context)),

                      // Order ID
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.width(2.5, context),
                          vertical: Responsive.height(0.3, context),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "Ride Id : #${inboxModel.orderId}".tr,
                          style: GoogleFonts.poppins(
                            fontSize: Responsive.width(3.2, context),
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ),

                      SizedBox(height: Responsive.height(0.8, context)),

                      // Last Message Preview
                      if (inboxModel.lastMessage?.isNotEmpty == true)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.width(3, context),
                            vertical: Responsive.height(0.6, context),
                          ),
                          decoration: BoxDecoration(
                            color: themeChange.getThem()
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: Responsive.width(3.5, context),
                                color: AppColors.subTitleColor,
                              ),
                              SizedBox(width: Responsive.width(2, context)),
                              Expanded(
                                child: Text(
                                  inboxModel.lastMessage.toString(),
                                  style: GoogleFonts.poppins(
                                    fontSize: Responsive.width(3.2, context),
                                    fontWeight: FontWeight.w400,
                                    color: themeChange.getThem() ? Colors.white70 : Colors.black54,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                SizedBox(width: Responsive.width(2, context)),

                // Arrow Icon
                Icon(
                  Icons.chevron_right,
                  color: AppColors.subTitleColor,
                  size: Responsive.width(5.5, context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, DarkThemeProvider themeChange) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.width(8, context)),
            decoration: BoxDecoration(
              color: AppColors.subTitleColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: Responsive.width(12, context),
              color: AppColors.subTitleColor,
            ),
          ),
          SizedBox(height: Responsive.height(2, context)),
          Text(
            "No Conversion found".tr,
            style: GoogleFonts.poppins(
              fontSize: Responsive.width(4.5, context),
              fontWeight: FontWeight.w600,
              color: AppColors.subTitleColor,
            ),
          ),
          SizedBox(height: Responsive.height(1, context)),
          Text(
            'Suas conversas com passageiros aparecerão aqui',
            style: GoogleFonts.poppins(
              fontSize: Responsive.width(3.5, context),
              color: AppColors.subTitleColor,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}