import 'package:flutter/material.dart';

import './input_fields.dart';
import '../mapbox/mapbox.dart';
import '../parse_service.dart';

class InputLocation extends StatefulWidget {
  var formVals;
  String formValsKey;
  // double width;
  String label;
  Function(List<double?>)? onChange;

  InputLocation({Key? key, this.formVals = null, this.formValsKey = '',
    this.label = '', this.onChange = null}) : super(key: key);

  @override
  _InputLocationState createState() => _InputLocationState();
}

class _InputLocationState extends State<InputLocation> {
  InputFields _inputFields = InputFields();
  ParseService _parseService = ParseService();

  final OverlayPortalController _tooltipController = OverlayPortalController();

  final _link = LayerLink();
  Map<String, String> _formVals = {
    'lngLatString': '',
  };
  String _formValsKey = 'lngLatString';

  /// width of the button after the widget rendered
  // double? _buttonWidth;
  double? _dropdownWidth;

  // @override
  // void initState() {
  //   super.initState();
  // }

  @override
  Widget build(BuildContext context) {
    _formVals['lngLatString'] = '${widget.formVals[widget.formValsKey][0]}, ${widget.formVals[widget.formValsKey][1]}';
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _tooltipController,
        overlayChildBuilder: (BuildContext context) {
          return CompositedTransformFollower(
            link: _link,
            targetAnchor: Alignment.bottomLeft,
            child: Align(
              alignment: AlignmentDirectional.topStart,
              // child: MenuWidget(width: widget.width),
              child: DropdownWidget(width: _dropdownWidth),
            ),
          );
        },
        // child: ElevatedButton(
        //   onPressed: () { onTap(); },
        //   child: Text('Button'),
        // ),
        child: _inputFields.inputText(_formVals, _formValsKey, label: widget.label, onTap: onTap, onChange: (String val) {
          List<String> lngLatString = val.split(',');
          double lng = _parseService.toDoubleNoNull(lngLatString[0]);
          double lat = _parseService.toDoubleNoNull(lngLatString[1]);
          UpdateLngLat(lng, lat);
        }),
      ),
    );
  }

  List<double> UpdateLngLat(double lng, double lat) {
    widget.formVals[widget.formValsKey] = [_parseService.Precision(lng, 6),
      _parseService.Precision(lat, 6)];
    if (widget.onChange != null) {
      widget.onChange!(widget.formVals[widget.formValsKey]);
    }
    return widget.formVals[widget.formValsKey];
  }

  void onTap() {
    // _buttonWidth = context.size?.width;
    _dropdownWidth = context.size?.width;
    _tooltipController.toggle();
  }

  Widget DropdownWidget({double? width = 300, double height = 300}) {
    return Container(
      width: width,
      height: height,
      // decoration: ShapeDecoration(
      //   color: Colors.black26,
      //   shape: RoundedRectangleBorder(
      //     side: const BorderSide(
      //       width: 1.5,
      //       color: Colors.black,
      //     ),
      //     borderRadius: BorderRadius.circular(12),
      //   ),
      //   shadows: const [
      //     BoxShadow(
      //       color: Color(0x11000000),
      //       blurRadius: 32,
      //       offset: Offset(0, 20),
      //       spreadRadius: -8,
      //     ),
      //   ],
      // ),
      color: Colors.white,
      // child: Text('test'),
      child: Mapbox(mapWidth: width!, mapHeight: height, onChange: _onChangeMap,
        longitude: widget.formVals[widget.formValsKey][0], latitude: widget.formVals[widget.formValsKey][1],
        zoom: 15,
      ),
    );
  }

  void _onChangeMap(var data) {
    List<double> lngLat = UpdateLngLat(data['longitude'], data['latitude']);
    setState(() {
      _formVals['lngLatString'] = '${lngLat[0]}, ${lngLat[1]}';
    });
  }
}
