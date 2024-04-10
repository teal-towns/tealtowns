import 'dart:convert';
import 'package:flutter/material.dart';

import '../../common/socket_service.dart';
import '../../common/form_input/input_fields.dart';

class LandTileSave extends StatefulWidget {
  final landTile;
  // final year;
  // final String timeframe;
  final String dataType;
  final Function(Map<String, dynamic>)? onChange;

  LandTileSave({ this.landTile = const {},
    this.dataType = 'basics', this.onChange = null });

  @override
  _LandTileSaveState createState() => _LandTileSaveState();
}

class _LandTileSaveState extends State<LandTileSave> {
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  InputFields _inputFields = InputFields();

  bool _loading = false;
  String _message = '';

  @override
  void initState() {
    super.initState();

    if (widget.landTile != null) {
      List<String> keys = ['precipitationMmAnnual', 'temperatureCelsiusAnnual', 'aboveGroundBiomassTon',
        'belowGroundBiomassTon', 'maxBiomassTon', 'tCO2Equivalent', 'costUSD', 'revenueUSD', 'baselineEmissionsTCO2',
        'plannedDeforestationTon', 'reforestationEligibility'];
      for (int ii = 0; ii < keys.length; ii++) {
        if (!widget.landTile.containsKey(keys[ii])) {
          widget.landTile[keys[ii]] = {};
        }
      }
    }

    _routeIds.add(_socketService.onRoute('saveLandTile', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        setState(() {
          _loading = false;
        });
        if (widget.onChange != null) {
          widget.onChange!({});
        }
      } else {
        setState(() { _message = data['message'].length > 0 ? data['message'] : 'Invalid, please try again'; });
      }
      setState(() { _loading = false; });
    }));
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds,);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.landTile == null) {
      return SizedBox.shrink();
    }

    double width = 80;
    List<Widget> cols = [];
    if (widget.dataType == 'basics') {
      cols += [
        Text('${widget.landTile['latTopLeft'].toStringAsFixed(4)}, ${widget.landTile['lngTopLeft'].toStringAsFixed(4)}'),
        SizedBox(height: 10),
        //_inputFields.inputText(widget.landTile, 'country', label: 'Country', hint: 'Country'),
        //SizedBox(height: 10),
        //_inputFields.inputText(widget.landTile, 'state', label: 'State', hint: 'State'),
        //SizedBox(height: 10),
        //_inputFields.inputText(widget.landTile, 'ecozone', label: 'Ecozone', hint: 'Ecozone'),
        //SizedBox(height: 10),
        //_inputFields.inputNumber(widget.landTile, 'slopeDegreesAverage', label: 'Slope Degrees (average)', hint: 'Slope Degrees (average)'),
        //SizedBox(height: 10),
      ];
    } else if (widget.dataType == 'precipitationMmAnnual') {
      cols += [
        _buildInputs(context, 'precipitationMmAnnual', 'number'),
      ];
    } else if (widget.dataType == 'temperatureCelsiusAnnual') {
      cols += [
        _buildInputs(context, 'temperatureCelsiusAnnual', 'number'),
      ];
    } else if (widget.dataType == 'biomass') {
      cols += [
        _buildInputs(context, 'aboveGroundBiomassTon', 'number'),
        _buildInputs(context, 'belowGroundBiomassTon', 'number'),
      ];
    } else if (widget.dataType == 'maxBiomassTon') {
      cols += [
        _buildInputs(context, 'maxBiomassTon', 'number'),
      ];
    } else if (widget.dataType == 'carbon') {
      cols += [
        _buildInputs(context, 'tCO2Equivalent', 'number'),
      ];
    } else if (widget.dataType == 'profit') {
      cols += [
        _buildInputs(context, 'costUSD', 'number'),
        _buildInputs(context, 'revenueUSD', 'number'),
      ];
    } else if (widget.dataType == 'baselineEmissionsTCO2') {
      cols += [
        _buildInputs(context, 'baselineEmissionsTCO2', 'number'),
      ];
    } else if (widget.dataType == 'plannedDeforestationTon') {
      cols += [
        _buildInputs(context, 'plannedDeforestationTon', 'number'),
      ];
    } else if (widget.dataType == 'reforestationEligibility') {
      cols += [
        _buildInputs(context, 'reforestationEligibility', 'number'),
      ];
    }
    // TODO: land covers, elevations, species, speciesPatterns

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...cols,
        ElevatedButton(
          child: Text('Save'),
          onPressed: () {
            _saveLandTile();
          },
        ),
        SizedBox(height: 10),
      ]
    );
  }

  _buildInputs(BuildContext context, String key, String dataType) {
    if (!widget.landTile.containsKey(key)) {
      widget.landTile[key] = {};
    }
    List<Widget> inputs = [
      Text('${key}'),
      SizedBox(height: 10),
    ];
    double width = 85;
    if (dataType == 'number') {
      inputs += [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            Container(
              width: width,
              child: _inputFields.inputNumber(widget.landTile[key], 'value', label: 'Value', hint: '', onChange: (double? val)  {
                widget.landTile[key]['value'] = val;
              }),
            ),
            //SizedBox(height: 10),
            Container(
              width: width,
              child: _inputFields.inputNumber(widget.landTile[key], 'min', label: 'Min', hint: '', onChange: (double? val)  {
                widget.landTile[key]['min'] = val;
              }),
            ),
            //SizedBox(height: 10),
            Container(
              width: width,
              child: _inputFields.inputNumber(widget.landTile[key], 'max', label: 'Max', hint: '', onChange: (double? val)  {
                widget.landTile[key]['max'] = val;
              }),
            ),
            //SizedBox(height: 10),
          ]
        ),
        SizedBox(height: 10),
      ];
    } else {
      inputs += [
        _inputFields.inputText(widget.landTile[key], 'value', label: 'Value', hint: '', onChange: (String val)  {
          widget.landTile[key]['value'] = val;
        }),
        SizedBox(height: 10),
      ];
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...inputs,
        _inputFields.inputText(widget.landTile[key], 'source', label: 'Source', hint: 'Source', onChange: (String val)  {
          widget.landTile[key]['source'] = val;
        }),
        SizedBox(height: 10),
        _inputFields.inputNumber(widget.landTile[key], 'confidencePercent', min: 0.0, max: 100.0,
          label: 'Confidence (0 to 100)', hint: 'Confidence (0 to 100)', onChange: (double? val)  {
          widget.landTile[key]['confidencePercent'] = val;
        }),
        SizedBox(height: 10),
        _inputFields.inputText(widget.landTile[key], 'notes', label: 'Notes', hint: 'Notes', onChange: (String val)  {
          widget.landTile[key]['notes'] = val;
        }),
        SizedBox(height: 10),
        SizedBox(height: 10),
      ],
    );
  }

  _saveLandTile() {
    var data = {
      // 'timeframe': widget.timeframe,
      // 'year': widget.year,
      'zoom': widget.landTile['tileZoom'],
      'tile': {
        'tileX': widget.landTile['tileX'],
        'tileY': widget.landTile['tileY'],
        'tileZoom': widget.landTile['tileZoom'],
        'tileNumber': widget.landTile['tileNumber'],
      },
    };
    if (widget.landTile.containsKey('_id')) {
      data['tile']['_id'] = widget.landTile['_id'];
    }
    List<String> keys = [];
    if (widget.dataType == 'basics') {
      //keys = ['country', 'state', 'ecozone', 'slopeDegreesAverage'];
      keys = ['slopeDegreesAverage'];
    } else if (widget.dataType == 'biomass') {
      keys = ['aboveGroundBiomassTon', 'belowGroundBiomassTon'];
    } else if (widget.dataType == 'carbon') {
      keys = ['tCO2Equivalent'];
    } else if (widget.dataType == 'profit') {
      keys = ['costUSD', 'revenueUSD'];
    } else {
      keys = [widget.dataType];
    }
    for (int ii = 0; ii < keys.length; ii++) {
      if (widget.landTile.containsKey(keys[ii])) {
        data['tile'][keys[ii]] = widget.landTile[keys[ii]];
      }
    }
    // TODO: land covers, elevations, species, speciesPatterns
    _socketService.emit('saveLandTile', data,);
  }

}
