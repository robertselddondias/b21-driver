import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/utils.dart';
import 'package:driver/widget/osm_map_search_place.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:get/get.dart';
import 'package:osm_nominatim/osm_nominatim.dart';
import 'package:provider/provider.dart';

class LocationPicker extends StatefulWidget {
  const LocationPicker({super.key});

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  GeoPoint? selectedLocation;
  late MapController mapController;
  Place? place;
  TextEditingController textController = TextEditingController();
  final List<GeoPoint> _markers = [];

  @override
  void initState() {
    super.initState();
    mapController = MapController(
      initMapWithUserPosition: const UserTrackingOption(enableTracking: false, unFollowUser: true),
    );
  }

  _listerTapPosition() async {
    mapController.listenerMapSingleTapping.addListener(() async {
      if (mapController.listenerMapSingleTapping.value != null) {
        GeoPoint position = mapController.listenerMapSingleTapping.value!;
        addMarker(position);
        place = await Nominatim.reverseSearch(
          lat: position.latitude,
          lon: position.longitude,
          zoom: 14,
          addressDetails: true,
          extraTags: true,
          nameDetails: true,
        );
      }
    });
  }

  addMarker(GeoPoint? position) async {
    if (position != null) {
      for (var marker in _markers) {
        await mapController.removeMarker(marker);
      }
      setState(() {
        _markers.clear();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await mapController
            .addMarker(position,
                markerIcon: MarkerIcon(
                  icon: Icon(Icons.location_on, size: Responsive.width(6.5, context)),
                ))
            .then((v) {
          _markers.add(position);
        });

        place = await Nominatim.reverseSearch(
          lat: position.latitude,
          lon: position.longitude,
          zoom: 14,
          addressDetails: true,
          extraTags: true,
          nameDetails: true,
        );
        setState(() {});
        mapController.moveTo(position, animate: true);
      });
    }
  }

  Future<void> _setUserLocation() async {
    try {
      final locationData = await Utils.getCurrentLocation();
      setState(() async {
        selectedLocation = GeoPoint(
          latitude: locationData.latitude,
          longitude: locationData.longitude,
        );
        await addMarker(selectedLocation!);
        mapController.moveTo(selectedLocation!, animate: true);
        place = await Nominatim.reverseSearch(
          lat: selectedLocation!.latitude,
          lon: selectedLocation!.longitude,
          zoom: 14,
          addressDetails: true,
          extraTags: true,
          nameDetails: true,
        );
      });
    } catch (e) {
      print("Error getting location: $e");
      // Handle error (e.g., show a snackbar to the user)
    }
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Picker'),
      ),
      body: Stack(
        children: [
          OSMFlutter(
            controller: mapController,
            mapIsLoading: const Center(child: CircularProgressIndicator()),
            osmOption: OSMOption(
              userLocationMarker: UserLocationMaker(
                  personMarker: MarkerIcon(iconWidget: Image.asset("assets/images/pickup.png")),
                  directionArrowMarker: MarkerIcon(iconWidget: Image.asset("assets/images/pickup.png"))),
              isPicker: true,
              zoomOption: const ZoomOption(initZoom: 14),
            ),
            onMapIsReady: (active) {
              if (active) {
                _setUserLocation();
                _listerTapPosition();
              }
            },
          ),
          if (place?.displayName != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: EdgeInsets.only(
                  bottom: Responsive.height(12, context),
                  left: Responsive.width(10, context),
                  right: Responsive.width(10, context),
                ),
                padding: EdgeInsets.all(Responsive.width(5, context)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(Responsive.width(2.5, context)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: Responsive.width(1.5, context),
                      offset: Offset(0, Responsive.height(0.25, context)),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        place?.displayName ?? '',
                        style: TextStyle(
                          fontSize: Responsive.width(4, context),
                          color: Colors.black,
                        ),
                      ),
                    ),
                    IconButton(
                        onPressed: () {
                          Get.back(result: place);
                        },
                        icon: Icon(
                          Icons.check_circle,
                          size: Responsive.width(10, context),
                          color: Colors.black,
                        ))
                  ],
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.width(1.5, context),
              vertical: Responsive.height(0.5, context),
            ),
            child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: Responsive.height(0.5, context),
                  horizontal: Responsive.width(1, context),
                ),
                child: InkWell(
                  onTap: () async {
                    Get.to(const OsmSearchPlacesApi())?.then((value) async {
                      if (value != null) {
                        SearchInfo place = value;
                        textController = TextEditingController(text: place.address.toString());
                        await addMarker(place.point);
                        print("Search :: ${place.point.toString()}");
                      }
                    });
                  },
                  child: buildTextField(
                    context: context,
                    title: "Search Address".tr,
                    textController: textController,
                  ),
                )),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _setUserLocation,
        child: Icon(Icons.my_location, color: themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary),
      ),
    );
  }

  Widget buildTextField({
    required BuildContext context,
    required String title,
    required TextEditingController textController,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: Responsive.width(1, context)),
      child: TextField(
        controller: textController,
        textInputAction: TextInputAction.done,
        style: TextStyle(
          color: Colors.black,
          fontSize: Responsive.width(4, context),
        ),
        decoration: InputDecoration(
          prefixIcon: IconButton(
            icon: Icon(
              Icons.location_on,
              color: Colors.black,
              size: Responsive.width(6, context),
            ),
            onPressed: () {},
          ),
          fillColor: Colors.white,
          filled: true,
          hintText: title,
          hintStyle: TextStyle(
            color: Colors.black,
            fontSize: Responsive.width(3.5, context),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Responsive.width(2.5, context)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Responsive.width(2.5, context)),
          ),
          enabled: false,
        ),
      ),
    );
  }
}
