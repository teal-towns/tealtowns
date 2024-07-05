import 'package:flutter/material.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';

import './input_fields.dart';
import '../location_service.dart';
import '../parse_service.dart';

// class InputLocationClass {
//   List<double?> lngLat = [0,0];
//   Map<String, dynamic> address = {};
// }

class InputLocation extends StatefulWidget {
  var formVals;
  String formValsKey;
  String label;
  Function(Map<String, dynamic>)? onChange;
  bool nestedCoordinates;
  bool guessLocation;
  bool useUserLocation;
  bool updateCachedLocation;
  String helpText;

  InputLocation({Key? key, this.formVals = null, this.formValsKey = '',
    this.label = '', this.onChange = null, this.nestedCoordinates = false,
    this.guessLocation = true, this.useUserLocation = false,
    this.updateCachedLocation = true, this.helpText = '',}) : super(key: key);

  @override
  _InputLocationState createState() => _InputLocationState();
}

class _InputLocationState extends State<InputLocation> {
  InputFields _inputFields = InputFields();
  LocationService _locationService = LocationService();
  ParseService _parseService = ParseService();

  final OverlayPortalController _overlayController = OverlayPortalController();

  final _link = LayerLink();
  Map<String, dynamic> _formVals = {
    'lngLatString': '',
    'address': {},
  };
  String _formValsKey = 'lngLatString';

  double? _dropdownWidth;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.nestedCoordinates) {
      _formVals['lngLatString'] = '${widget.formVals[widget.formValsKey]['lngLat']['coordinates'][0]}, ${widget.formVals[widget.formValsKey]['lngLat']['coordinates'][1]}';
    } else {
      _formVals['lngLatString'] = '${widget.formVals[widget.formValsKey]['lngLat'][0]}, ${widget.formVals[widget.formValsKey]['lngLat'][1]}';
    }
    _formVals['address'] = widget.formVals[widget.formValsKey]['address'];
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (BuildContext context) {
          return CompositedTransformFollower(
            link: _link,
            targetAnchor: Alignment.bottomLeft,
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: DropdownWidget(width: _dropdownWidth),
            ),
          );
        },
        child: _inputFields.inputText(_formVals, _formValsKey, label: widget.label, helpText: widget.helpText,
          onTap: onTap, onChange: (String val) {
          List<String> lngLatString = val.split(',');
          double lng = _parseService.toDoubleNoNull(lngLatString[0]);
          double lat = _parseService.toDoubleNoNull(lngLatString[1]);
          UpdateLngLat(lng, lat);
        }),
      ),
    );
  }

  void _init() async {
    // Handled with trackMyPosition now.
    if (mounted && widget.guessLocation) {
      List<double> lngLat = await _locationService.GetLocation(context, useUser: widget.useUserLocation);
      if (mounted) {
        _formVals[_formValsKey] = '${lngLat[0]}, ${lngLat[1]}';
        setState(() {
          _formVals = _formVals;
        });
        UpdateLngLat(lngLat[0], lngLat[1]);
      }
    }
  }

  List<double> UpdateLngLat(double lng, double lat, {Map<String, dynamic> address = const {}}) {
    List<double> lngLat = [_parseService.Precision(lng, 5), _parseService.Precision(lat, 5)];
    if (widget.updateCachedLocation) {
      _locationService.SetLngLat(lngLat);
    }
    if (widget.nestedCoordinates) {
      widget.formVals[widget.formValsKey]['lngLat']['coordinates'] = lngLat;
    } else {
      widget.formVals[widget.formValsKey]['lngLat'] = lngLat;
    }
    widget.formVals[widget.formValsKey]['address'] = address;
    if (widget.onChange != null) {
      // widget.onChange!(widget.formVals[widget.formValsKey]);
      Map<String, dynamic> locationVal = { 'lngLat': widget.formVals[widget.formValsKey]['lngLat'],
        'address': address };
      widget.onChange!(locationVal);
    }
    return lngLat;
  }

  void onTap() {
    _dropdownWidth = context.size?.width;
    _overlayController.toggle();
  }

  Widget DropdownWidget({double? width = 300, double height = 300}) {
    double lng;
    double lat;
    if (widget.nestedCoordinates) {
      lng = widget.formVals[widget.formValsKey]['lngLat']['coordinates'][0];
      lat = widget.formVals[widget.formValsKey]['lngLat']['coordinates'][1];
    } else {
      lng = widget.formVals[widget.formValsKey]['lngLat'][0];
      lat = widget.formVals[widget.formValsKey]['lngLat'][1];
    }
    LatLong latLong = LatLong(lat, lng);
    bool trackMyPosition = _locationService.LocationValid([lng, lat]) ? false : true;
    return Container(
      width: width,
      height: height,
      color: Colors.white,
      child: FlutterLocationPicker(
        initPosition: latLong,
        initZoom: 11,
        minZoomLevel: 1,
        maxZoomLevel: 20,
        trackMyPosition: trackMyPosition,
        selectLocationButtonText: 'Select Location',
        onPicked: (pickedData) {
          Map<String, dynamic> address = ParseAddress(pickedData.addressData);
          List<double> lngLat = UpdateLngLat(pickedData.latLong.longitude, pickedData.latLong.latitude,
            address: address);
          setState(() {
            _formVals['lngLatString'] = '${lngLat[0]}, ${lngLat[1]}';
          });
          _overlayController.toggle();
        }
      )
    );
  }

  // void _onChangeMap(var data) {
  //   List<double> lngLat = UpdateLngLat(data['longitude'], data['latitude']);
  //   setState(() {
  //     _formVals['lngLatString'] = '${lngLat[0]}, ${lngLat[1]}';
  //   });
  // }

  Map<String, dynamic> ParseAddress(Map<String, dynamic> addressIn) {
    Map<String, dynamic> address = {};
    if (addressIn != null) {
      if (addressIn.containsKey('house_number') || addressIn.containsKey('road')) {
        String houseNumber = addressIn.containsKey('house_number') ? addressIn['house_number'] : '';
        String road = addressIn.containsKey('road') ? addressIn['road'] : '';
        address['street'] = '${houseNumber} ${road}';
      }
      if (addressIn.containsKey('town')) {
        address['city'] = addressIn['town'];
      } else if (addressIn.containsKey('city')) {
        address['city'] = addressIn['city'];
      }
      if (addressIn.containsKey('state')) {
        address['state'] = addressIn['state'];
      }
      if (addressIn.containsKey('postcode')) {
        address['zip'] = addressIn['postcode'];
      }
      if (addressIn.containsKey('country')) {
        address['country'] = addressIn['country'];
      }
    }
    return address;
  }
}
