import 'package:driver/constant/constant.dart';
import 'package:driver/controller/online_registration_controller.dart';
import 'package:driver/model/document_model.dart';
import 'package:driver/model/driver_document_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/ui/online_registration/details_upload_screen.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class OnlineRegistrationScreen extends StatelessWidget {
  const OnlineRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetBuilder<OnlineRegistrationController>(
        init: OnlineRegistrationController(),
        builder: (controller) {
          return Scaffold(
            backgroundColor: AppColors.primary,
            appBar: AppBar(
              backgroundColor: AppColors.primary,
              elevation: 0,
              title: Text(
                "Registro Online".tr,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
              leading: InkWell(
                  onTap: () {
                    Get.back();
                  },
                  child: const Icon(
                    Icons.arrow_back,
                  )),
            ),
            body: controller.isLoading.value
                ? Constant.loader(context)
                : Column(
              children: [
                SizedBox(
                  height: Responsive.width(10, context),
                  width: Responsive.width(100, context),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(25),
                            topRight: Radius.circular(25))),
                    child: Column(
                      children: [
                        // Header informativo
                        Padding(
                          padding: EdgeInsets.all(Responsive.width(5, context)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(Responsive.width(2.5, context)),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.description_outlined,
                                      color: AppColors.primary,
                                      size: Responsive.width(6, context),
                                    ),
                                  ),
                                  SizedBox(width: Responsive.width(3, context)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Documentos Necessários".tr,
                                          style: GoogleFonts.poppins(
                                            fontSize: Responsive.width(4.2, context),
                                            fontWeight: FontWeight.w600,
                                            color: themeChange.getThem()
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                        SizedBox(height: Responsive.height(0.3, context)),
                                        Text(
                                          "${controller.documentList.length} documentos".tr,
                                          style: GoogleFonts.poppins(
                                            fontSize: Responsive.width(3.2, context),
                                            color: themeChange.getThem()
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Lista de documentos
                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.width(4, context),
                              vertical: Responsive.height(1, context),
                            ),
                            itemCount: controller.documentList.length,
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              DocumentModel documentModel =
                              controller.documentList[index];
                              Documents documents = Documents();

                              var contain = controller.driverDocumentList
                                  .where((element) =>
                              element.documentId ==
                                  documentModel.id);
                              if (contain.isNotEmpty) {
                                documents = controller.driverDocumentList
                                    .firstWhere((itemToCheck) =>
                                itemToCheck.documentId ==
                                    documentModel.id);
                              }

                              final bool isVerified =
                                  documents.verified == true;

                              return InkWell(
                                onTap: () {
                                  Get.to(const DetailsUploadScreen(),
                                      arguments: {
                                        'documentModel': documentModel
                                      });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  margin: EdgeInsets.only(
                                      bottom: Responsive.height(1.5, context)),
                                  decoration: BoxDecoration(
                                    color: themeChange.getThem()
                                        ? AppColors.darkContainerBackground
                                        : AppColors.containerBackground,
                                    borderRadius:
                                    BorderRadius.circular(12),
                                    border: Border.all(
                                        color: themeChange.getThem()
                                            ? AppColors.darkContainerBorder
                                            : AppColors.containerBorder,
                                        width: 1),
                                    boxShadow: themeChange.getThem()
                                        ? null
                                        : [
                                      BoxShadow(
                                        color: Colors.black
                                            .withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(
                                        Responsive.width(4, context)),
                                    child: Row(
                                      children: [
                                        // Ícone do documento
                                        Container(
                                          width: Responsive.width(12, context),
                                          height: Responsive.width(12, context),
                                          decoration: BoxDecoration(
                                            color: isVerified
                                                ? (themeChange.getThem()
                                                ? AppColors.darkSuccess
                                                .withOpacity(0.15)
                                                : AppColors.success
                                                .withOpacity(0.1))
                                                : (themeChange.getThem()
                                                ? AppColors.darkWarning
                                                .withOpacity(0.15)
                                                : AppColors.warning
                                                .withOpacity(0.1)),
                                            borderRadius:
                                            BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            isVerified
                                                ? Icons.verified_outlined
                                                : Icons.description_outlined,
                                            color: isVerified
                                                ? (themeChange.getThem()
                                                ? AppColors.darkSuccess
                                                : AppColors.success)
                                                : (themeChange.getThem()
                                                ? AppColors.darkWarning
                                                : AppColors.warning),
                                            size: Responsive.width(6, context),
                                          ),
                                        ),

                                        SizedBox(
                                            width: Responsive.width(3, context)),

                                        // Informações do documento
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                documentModel.title
                                                    .toString(),
                                                style: GoogleFonts.poppins(
                                                  fontSize: Responsive.width(
                                                      3.8, context),
                                                  fontWeight: FontWeight.w600,
                                                  color: themeChange.getThem()
                                                      ? Colors.white
                                                      : Colors.black87,
                                                ),
                                              ),
                                              SizedBox(
                                                  height: Responsive.height(
                                                      0.5, context)),
                                              Row(
                                                children: [
                                                  Container(
                                                    width: Responsive.width(
                                                        1.5, context),
                                                    height: Responsive.width(
                                                        1.5, context),
                                                    decoration: BoxDecoration(
                                                      color: isVerified
                                                          ? (themeChange
                                                          .getThem()
                                                          ? AppColors
                                                          .darkSuccess
                                                          : AppColors
                                                          .success)
                                                          : (themeChange
                                                          .getThem()
                                                          ? AppColors
                                                          .darkWarning
                                                          : AppColors
                                                          .warning),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                      width: Responsive.width(
                                                          1.5, context)),
                                                  Text(
                                                    isVerified
                                                        ? "Verificado".tr
                                                        : "Pendente".tr,
                                                    style:
                                                    GoogleFonts.poppins(
                                                      fontSize:
                                                      Responsive.width(
                                                          3.2, context),
                                                      fontWeight:
                                                      FontWeight.w500,
                                                      color: isVerified
                                                          ? (themeChange
                                                          .getThem()
                                                          ? AppColors
                                                          .darkSuccess
                                                          : AppColors
                                                          .success)
                                                          : (themeChange
                                                          .getThem()
                                                          ? AppColors
                                                          .darkWarning
                                                          : AppColors
                                                          .warning),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Ícone de navegação
                                        Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          color: themeChange.getThem()
                                              ? Colors.grey.shade600
                                              : Colors.grey.shade400,
                                          size: Responsive.width(4, context),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }
}