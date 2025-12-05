import 'package:driver/controller/osm_search_place_controller.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class OsmSearchPlacesApi extends StatelessWidget {
  const OsmSearchPlacesApi({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX(
        init: OsmSearchPlaceController(),
        builder: (controller) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: AppColors.primary,
              leading: InkWell(
                onTap: () {
                  Get.back();
                },
                child: Icon(
                  Icons.arrow_back,
                  color: themeChange.getThem() ? AppColors.lightGray : AppColors.lightGray,
                ),
              ),
              title: Text(
                'Search places Api',
                style: TextStyle(
                  color: themeChange.getThem() ? AppColors.lightGray : AppColors.lightGray,
                  fontSize: Responsive.width(4, context),
                ),
              ),
            ),
            body: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.width(4, context),
                vertical: Responsive.height(1.2, context),
              ),
              child: Column(
                children: [
                  TextFormField(
                      validator: (value) => value != null && value.isNotEmpty ? null : 'Required',
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.sentences,
                      controller: controller.searchTxtController.value,
                      textAlign: TextAlign.start,
                      style: GoogleFonts.poppins(color: Colors.black ),
                      decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: themeChange.getThem() ? AppColors.darkTextField : AppColors.textField,
                          contentPadding: EdgeInsets.symmetric(vertical: Responsive.height(1.5, context)),
                          prefixIcon: const Icon(Icons.map),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(Responsive.width(1, context))),
                            borderSide: BorderSide(color: themeChange.getThem() ? AppColors.darkTextFieldBorder : AppColors.textFieldBorder, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(Responsive.width(1, context))),
                            borderSide: BorderSide(color: themeChange.getThem() ? AppColors.darkTextFieldBorder : AppColors.textFieldBorder, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(Responsive.width(1, context))),
                            borderSide: BorderSide(color: themeChange.getThem() ? AppColors.darkTextFieldBorder : AppColors.textFieldBorder, width: 1),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(Responsive.width(1, context))),
                            borderSide: BorderSide(color: themeChange.getThem() ? AppColors.darkTextFieldBorder : AppColors.textFieldBorder, width: 1),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(Responsive.width(1, context))),
                            borderSide: BorderSide(color: themeChange.getThem() ? AppColors.darkTextFieldBorder : AppColors.textFieldBorder, width: 1),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.cancel),
                            onPressed: () {
                              controller.searchTxtController.value.clear();
                            },
                          ),
                          hintText: "Search your location here".tr)),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      primary: true,
                      itemCount: controller.suggestionsList.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(controller.suggestionsList[index].address.toString(),style: TextStyle(color:  Colors.black),),
                          onTap: () {
                            Get.back(result: controller.suggestionsList[index]);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
