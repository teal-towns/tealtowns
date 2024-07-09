import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:location/location.dart';
import 'package:universal_html/html.dart' as html;
import '../../common/colors_service.dart';
import '../../common/layout_service.dart';
import '../../common/map/mapbox.dart';
import '../../common/math_service.dart';
import '../../common/socket_service.dart';
import '../../common/form_input/input_fields.dart';
import './land_tile_polygon.dart';
import './land_tile_raster.dart';
import './land_tile_save.dart';
import './polygon_select.dart';

class Land extends StatefulWidget {
  final double lat;
  final double lng;
  // final String timeframe;
  // final int year;
  final String underlay;
  final String underlayOpacity;
  final String tileSize;
  final String dataType;
  final String polygonUName;
  final GoRouterState goRouterState;

  Land({ this.lat = -999, this.lng = -999, this.underlay = '', this.underlayOpacity = '0.5', this.tileSize = '', this.dataType = '',
    this.polygonUName = '', required this.goRouterState });

  @override
  _LandState createState() => _LandState();
}

class _LandState extends State<Land> {
  List<String> _routeIds = [];
  ColorsService _colorsService = ColorsService();
  LayoutService _layoutService = LayoutService();
  MathService _mathService = MathService();
  SocketService _socketService = SocketService();
  InputFields _inputFields = InputFields();
  Location _location = Location();

  var _formVals = {
    //'timeframe': 'actual',
    //'year': new DateTime.now().year.toString(),
    //'latCenter': 37.7498,
    //'lngCenter': -122.4546,
    //'xCount': 10,
    //'yCount': 10,
    //'zoom': '16',
    // 'autoInsert': 1,
  };
  var _vals = {
    ////'tileWidth': '500',
    //'underlaySource': 'mapbox',
    //'dataType': 'basics',
    //'tileSize': 'xLarge',
  };
  double _tileWidth = 1000;
  double _sideWidth = 300;
  bool _loading = false;
  String _message = '';
  // var _optsYear = [];
  var _tileRows = [];
  var _selectedTile = null;
  int _selectedTileRowIndex = -1;
  int _selectedTileColumnIndex = -1;
  bool _skipCurrentLocation = false;
  double _viewWidth = 0;
  double _viewHeight = 0;
  bool _initedGotTiles = false;
  var _polygons = [];
  var _coordinatesDraw = [];

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('getLandTiles', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _coordinatesDraw = _getTilesBounds(data['tileRows']);
        setState(() {
          _tileRows = data['tileRows'];
          _loading = false;
          _coordinatesDraw = _coordinatesDraw;
        });
      } else {
        setState(() { _message = data['message'].length > 0 ? data['message'] : 'Invalid, please try again'; });
      }
      setState(() { _loading = false; });
    }));

    _routeIds.add(_socketService.onRoute('getPolygonByUName', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _polygons = [ data['polygon'] ];
        setState(() { _polygons = _polygons; });
      }
    }));

    _routeIds.add(_socketService.onRoute('savePolygon', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _polygons = [ data['polygon'] ];
        setState(() { _polygons = _polygons; });
      }
    }));

    _formVals = {
      // 'timeframe': widget.timeframe != '' ? widget.timeframe : 'actual',
      // 'year': widget.year != -999 ? widget.year.toString() : new DateTime.now().year.toString(),
      'latCenter': 37.7498,
      'lngCenter': -122.4546,
      'xCount': 10,
      'yCount': 10,
      'zoom': '16',
      'autoInsert': 1,
    };
    _vals = {
      //'tileWidth': '500',
      'underlaySource': widget.underlay != '' ? widget.underlay : 'mapbox',
      'underlayOpacity': widget.underlayOpacity != '' ? widget.underlayOpacity : '0.5',
      'dataType': widget.dataType != '' ? widget.dataType : 'basics',
      'tileSize': widget.tileSize != '' ? widget.tileSize : 'xLarge',
    };

    if (widget.polygonUName.length > 0) {
      _socketService.emit('getPolygonByUName', { 'uName': widget.polygonUName, });
      _skipCurrentLocation = true;
    } else if (widget.lat != -999 && widget.lng != -999) {
      _formVals['latCenter'] = widget.lat;
      _formVals['lngCenter'] = widget.lng;
      _skipCurrentLocation = true;
      _getTiles();
    }
    WidgetsBinding.instance.addPostFrameCallback((_){
      _init();
    });
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _viewWidth = MediaQuery.of(context).size.width;
    _viewHeight = MediaQuery.of(context).size.height - _layoutService.headerHeight - 1;

    List<Widget> colsTileSave = [];
    if (_selectedTile != null) {
      colsTileSave += [
        Container(
          padding: EdgeInsets.only(left: 10, right: 10,),
          child: LandTileSave(landTile: _selectedTile,
            dataType: _vals['dataType'].toString(), onChanged: (var data) {
              _getTiles();
            }),
        ),
        SizedBox(height: 10),
      ];
    }

    double viewWidth = MediaQuery.of(context).size.width;
    //double viewHeight = MediaQuery.of(context).size.height - _layoutService.headerHeight - 1;
    double mapHeight = (viewWidth < 250) ? viewWidth : 250;
    if (viewWidth < 500) {
      return Column(
        children: [
          AbsorbPointer(
            child: Mapbox(mapWidth: viewWidth, mapHeight: mapHeight, onChanged: _onChangeMap,
              latitude: double.parse(_formVals['latCenter'].toString()), longitude: double.parse(_formVals['lngCenter'].toString()), zoom: 15,
              polygons: _polygons, coordinatesDraw: _coordinatesDraw, ),
          ),
          SizedBox(height: 10),
          // TODO - add back in once add google bucket to backend config.
          //PolygonSelect(onChanged: _onChangePolygon, ),
          //SizedBox(height: 10),
          _buildFilters(context),
          SizedBox(height: 10),
          //Container(
          //  padding: EdgeInsets.only(left: 10),
          //  child: _buildDataTypeFilter(context),
          //),
          //SizedBox(height: 10),
          ...colsTileSave,
          Stack(
            children: [
              LandTileRaster(tileRows: _tileRows, tileWidth: _tileWidth, dataSource: _vals['underlaySource']!),
              _buildTileRows(context),
            ]
          )
        ]
      );
    }

    double spacing = 10;
    double tilesContentWidth = viewWidth - _sideWidth - spacing;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: _sideWidth,
          child: Column(
            children: [
              AbsorbPointer(
                child: Mapbox(mapWidth: _sideWidth, mapHeight: mapHeight, onChanged: _onChangeMap,
                  latitude: double.parse(_formVals['latCenter'].toString()), longitude: double.parse(_formVals['lngCenter'].toString()), zoom: 15,
                  polygons: _polygons, coordinatesDraw: _coordinatesDraw ),
              ),
              SizedBox(height: 10),
              // TODO - add back in once add google bucket to backend config.
              //PolygonSelect(onChanged: _onChangePolygon, ),
              //SizedBox(height: 10),
              _buildFilters(context),
              SizedBox(height: 10),
              //Container(
              //  padding: EdgeInsets.only(left: 10),
              //  child: _buildDataTypeFilter(context),
              //),
              //SizedBox(height: 10),
              ...colsTileSave,
            ],
          ),
        ),
        SizedBox(width: spacing),
        Container(
          width: tilesContentWidth,
          child: Column(
            children: [
              Stack(
                children: [
                  LandTileRaster(tileRows: _tileRows, tileWidth: _tileWidth, dataSource: _vals['underlaySource']!),
                  _buildTileRows(context),
                ]
              )
            ]
          ),
        ),
      ]
    );
  }

  void _onChangeMap(var data) {
    _formVals['latCenter'] = data['latitude'];
    _formVals['lngCenter'] = data['longitude'];
    // TODO - once add more zoom levels, can use this to go to next closest zoom we have.
    //_formVals['zoom'] = data['zoom'];
    setState(() {_formVals = _formVals;});
    _getTiles();
  }

  void _onChangePolygon(var data) {
    // Existing polygon; fetch.
    if (data.containsKey('uName') && !data.containsKey('fileUrl')) {
      _socketService.emit('getPolygonByUName', { 'uName': data['uName'], });
    } else if (!data.containsKey('uName')) {
      _socketService.emit('savePolygon', { 'polygon': data });
    }
    //_polygons = [ data ];
    setState(() {
      _polygons = [];
    });
  }

  void _init() async {
    if (!_skipCurrentLocation) {
      var coordinates = await _location.getLocation();
      if (coordinates.latitude != null) {
        _formVals['latCenter'] = coordinates.latitude!;
        _formVals['lngCenter'] = coordinates.longitude!;
        setState(() {
          _formVals = _formVals;
        });
        _getTiles();
      }
    }
    if (!_initedGotTiles) {
      _getTiles();
    }

  }

  String _UpdateUrl(formVals, vals){
    String? lat = formVals['latCenter']?.toString();
    String? lng = formVals['lngCenter']?.toString();
    // String? year = formVals['year']?.toString();
    // String? tf = formVals['timeframe'];
    String? dt = vals['dataType'];
    String? size = vals['tileSize'];
    html.window.history.pushState({}, '', '/land?lat=${lat}&&lng=${lng}&&dt=${dt}&&size=${size}');
    final url =  html.window.history.state.toString();
    return url;
  }

  // void _setYears() {
  //   DateTime now = new DateTime.now();
  //   int yearMin = now.year - 10;
  //   int yearMax = now.year + 31;
  //   // TODO - add backend call to get these year ranges based on the data we have.
  //   if (_formVals['timeframe'] == 'actual') {
  //     yearMin = 2023;
  //     yearMax = 2023;
  //   } else if (_formVals['timeframe'] == 'past') {
  //     yearMin = 2013;
  //     yearMax = 2022;
  //   } else if (_formVals['timeframe'] == 'future' || _formVals['timeframe'] == 'futureBest') {
  //     yearMin = 2024;
  //     yearMax = 2054;
  //   }
  //   _optsYear = [];
  //   bool selectedYearFound = false;
  //   for (int ii = yearMin; ii <= yearMax; ii++) {
  //     _optsYear.add({ 'value': ii.toString(), 'label': ii.toString() });
  //     if (ii.toString() == _formVals['year']) {
  //       selectedYearFound = true;
  //     }
  //   }
  //   if (!selectedYearFound) {
  //     _formVals['year'] = yearMin.toString();
  //   }
  //   setState(() {
  //     _optsYear = _optsYear;
  //     _formVals = _formVals;
  //   });
  // }

  void _getTiles() {
    if (_viewWidth > 0) {
      setState(() { _coordinatesDraw = []; });
      _initedGotTiles = true;
      _getTilesCount();
      _socketService.emit('getLandTiles', _formVals);
    }
  }

  Widget _buildFilters(context) {
    // var optsTimeframe = [
    //   //{ 'value': 'past', 'label': 'Past' },
    //   { 'value': 'actual', 'label': 'Actual' },
    //   //{ 'value': 'future', 'label': 'Future' },
    //   //{ 'value': 'futureBest', 'label': 'Future Best' },
    // ];
    // _setYears();
    //var optsZoom = [
    //  //{ 'value': '5', 'label': '5' },
    //  { 'value': '7', 'label': 'Zoom 7' },
    //  { 'value': '10', 'label': 'Zoom 10' },
    //  { 'value': '13', 'label': 'Zoom 13' },
    //  { 'value': '16', 'label': 'Zoom 16' },
    //];
    //var optsTileWidth = [
    //  { 'value': '100', 'label': 'Tile 100' },
    //  { 'value': '250', 'label': 'Tile 250' },
    //  { 'value': '500', 'label': 'Tile 500' },
    //  { 'value': '1000', 'label': 'Tile 1000' },
    //];
    var optsUnderlaySource = [
      { 'value': 'none', 'label': 'None' },
      { 'value': 'mapbox', 'label': 'Mapbox' },
    ];
    var optsTileSize = [
      { 'value': 'xSmall', 'label': 'XSmall', },
      { 'value': 'small', 'label': 'Small', },
      { 'value': 'medium', 'label': 'Medium', },
      { 'value': 'large', 'label': 'Large', },
      { 'value': 'xLarge', 'label': 'XLarge', },
    ];
    var optsUnderlayOpacity = [
      { 'value': '0.1', 'label': '0.1', },
      { 'value': '0.2', 'label': '0.2', },
      { 'value': '0.3', 'label': '0.3', },
      { 'value': '0.4', 'label': '0.4', },
      { 'value': '0.5', 'label': '0.5', },
      { 'value': '0.6', 'label': '0.6', },
      { 'value': '0.7', 'label': '0.7', },
      { 'value': '0.8', 'label': '0.8', },
      { 'value': '0.9', 'label': '0.9', },
    ];

    double width = 90;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        //Container(
        //  width: width,
        //  child: _inputFields.inputNumber(_formVals, 'latCenter', hint: 'latitude'),
        //),
        //SizedBox(width: 10),
        //Container(
        //  width: width,
        //  child: _inputFields.inputNumber(_formVals, 'lngCenter', hint: 'longitude'),
        //),
        //SizedBox(width: 10),
        //Container(
        //  width: width,
        //  child: _inputFields.inputSelect(optsZoom, _formVals, 'zoom', onChanged: (String newVal) {
        //      setState(() { _formVals = _formVals; });
        //    }
        //  ),
        //),
        //SizedBox(width: 10),
        // Container(
        //   width: width,
        //   child: _inputFields.inputSelect(optsTimeframe, _formVals, 'timeframe', onChanged: (String newVal) {
        //       //setState(() { _formVals = _formVals; });
        //       _setYears();
        //       _getTiles();
        //       if(kIsWeb){
        //         _UpdateUrl(_formVals, _vals);
        //       }
        //     }
        //   ),
        // ),
        // //SizedBox(width: 10),
        // Container(
        //   width: width,
        //   child: _inputFields.inputSelect(_optsYear, _formVals, 'year', onChanged: (String newVal) {
        //       setState(() { _formVals = _formVals; });
        //       _getTiles();
        //       if(kIsWeb){
        //         _UpdateUrl(_formVals, _vals);
        //       }
        //     }
        //   ),
        // ),
        //SizedBox(width: 10),
        //Container(
        //  width: width,
        //  child: _inputFields.inputSelect(optsTileWidth, _vals, 'tileWidth', onChanged: (String newVal) {
        //      setState(() {
        //        _vals = _vals;
        //        _tileWidth = double.parse(_vals['tileWidth']!);
        //      });
        //    }
        //  ),
        //),
        //SizedBox(width: 10),
        //ElevatedButton(
        //  onPressed: () {
        //    _getTiles();
        //  },
        //  child: Text('Get Tiles'),
        //),
        //SizedBox(width: 10),
        Container(
          width: width,
          child: _inputFields.inputSelect(optsUnderlaySource, _vals, 'underlaySource', onChanged: (String newVal) {
              setState(() { _vals = _vals; });
              if(kIsWeb){
                _UpdateUrl(_formVals, _vals);
              }
            }
          ),
        ),
        Container(
          width: width,
          child: _inputFields.inputSelect(optsUnderlayOpacity, _vals, 'underlayOpacity', onChanged: (String newVal) {
              setState(() { _vals = _vals; });
              if(kIsWeb){
                _UpdateUrl(_formVals, _vals);
              }
            }
          ),
        ),
        //SizedBox(width: 10),
        Container(
          width: width,
          child: _inputFields.inputSelect(optsTileSize, _vals, 'tileSize', onChanged: (String newVal) {
              setState(() {
                _vals = _vals;
              });
              _getTiles();
              if(kIsWeb){
                _UpdateUrl(_formVals, _vals);
              }
            }
          ),
        ),
        Container(
          width: 190,
          child: _buildDataTypeFilter(context),
        ),
      ]
    );
  }

  Widget _buildDataTypeFilter(context) {
    var optsDataType = [
      { 'value': 'basics', 'label': 'Basics' },
      { 'value': 'precipitationMmAnnual', 'label': 'Precipitation' },
      { 'value': 'temperatureCelsiusAnnual', 'label': 'Temperature' },
      //{ 'value': 'biomass', 'label': 'Biomass' },
      //{ 'value': 'maxBiomassTon', 'label': 'Max Biomass' },
      //{ 'value': 'carbon', 'label': 'Carbon' },
      //{ 'value': 'profit', 'label': 'Profit' },
      //{ 'value': 'baselineEmissionsTCO2', 'label': 'Baseline Emissions tCO2' },
      //{ 'value': 'plannedDeforestationTon', 'label': 'Planned Deforestation' },
      //{ 'value': 'reforestationEligibility', 'label': 'Reforestation Eligibility' },
    ];
    return _inputFields.inputSelect(optsDataType, _vals, 'dataType', onChanged: (String newVal) {
        setState(() {_vals = _vals;});
        if(kIsWeb){
          _UpdateUrl(_formVals, _vals);
        }
      }
    );
  }

  Widget _buildTileRows(context) {
    if (_tileRows.length < 1) {
      return SizedBox.shrink();
    }
    return Column(
      children: [
        ..._tileRows!.asMap().entries.map((entry) => _buildTileRow(entry.value, entry.key, context)),
      ]
    );
  }

  Widget _buildTileRow(tileRow, indexRow, context) {
    if (tileRow.length < 1) {
      return SizedBox.shrink();
    }
    return Row(
      children: [
        ...tileRow!.asMap().entries.map((entry) => _buildTile(entry.value, indexRow, entry.key, context)),
      ]
    );
  }

  Widget _buildTile(tile, indexRow, indexColumn, context) {
    double borderWidth = 0;
    var border = Border();
    if (_selectedTileRowIndex == indexRow && _selectedTileColumnIndex == indexColumn) {
      borderWidth = 1;
      border = Border.all(width: borderWidth, color: _colorsService.colors['greyDark']);
    }

    List<Widget> content = [ SizedBox.shrink() ];
    double lightness = 0;
    double opacity = _vals['underlaySource'] == 'none' ? 1 : double.parse(_vals['underlayOpacity']);
    Color color = Color.fromRGBO(255, 255, 255, opacity);
    double lighter = 1.0;
    double darker = 0.5;
    if (_vals['dataType'] == 'precipitationMmAnnual') {
      if (tile.containsKey('precipitationMmAnnual') && tile['precipitationMmAnnual']['value'] != null) {
        lightness = _mathService.rangeValue(tile['precipitationMmAnnual']['value'], 0, 10000, lighter, darker);
        color = HSLColor.fromAHSL(opacity, 270, 1.0, lightness).toColor();
      }
    } else if (_vals['dataType'] == 'temperatureCelsiusAnnual') {
      if (tile.containsKey('temperatureCelsiusAnnual') && tile['temperatureCelsiusAnnual']['value'] != null) {
        if (tile['temperatureCelsiusAnnual']['value'] < 20) {
          lightness = _mathService.rangeValue(tile['temperatureCelsiusAnnual']['value'], 0, 20, darker, lighter);
          color = HSLColor.fromAHSL(opacity, 240, 1.0, lightness).toColor();
        } else {
          lightness = _mathService.rangeValue(tile['temperatureCelsiusAnnual']['value'], 20, 40, lighter, darker);
          color = HSLColor.fromAHSL(opacity, 30, 1.0, lightness).toColor();
        }
      }
    } else if (_vals['dataType'] == 'biomass') {
      if (tile.containsKey('aboveGroundBiomassTon') && tile.containsKey('belowGroundBiomassTon') &&
          tile['aboveGroundBiomassTon']?['value'] != null && tile['belowGroundBiomassTon']['value'] != null ) {
        double biomassTon = tile['aboveGroundBiomassTon']['value'] + tile['belowGroundBiomassTon']['value'];
        lightness = _mathService.rangeValue(biomassTon, 0, 1000, lighter, darker);
        color = HSLColor.fromAHSL(opacity, 120, 1.0, lightness).toColor();
      }
    } else if (_vals['dataType'] == 'maxBiomassTon') {
      if (tile.containsKey('maxBiomassTon') && tile['maxBiomassTon']['value'] != null) {
        lightness = _mathService.rangeValue(tile['maxBiomassTon']['value'], 100, 1500, lighter, darker);
        color = HSLColor.fromAHSL(opacity, 150, 1.0, lightness).toColor();
      }
    } else if (_vals['dataType'] == 'carbon') {
      if (tile.containsKey('tCO2Equivalent') && tile['tCO2Equivalent']['value'] != null) {
        lightness = _mathService.rangeValue(tile['tCO2Equivalent']['value'], 0, 400, lighter, darker);
        color = HSLColor.fromAHSL(opacity, 90, 1.0, lightness).toColor();
      }
    } else if (_vals['dataType'] == 'profit') {
      if (tile.containsKey('costUSD') && tile.containsKey('revenueUSD') &&
        tile['costUSD']['value'] != null && tile['revenueUSD']['value'] != null) {
        double profit = tile['revenueUSD']['value'] - tile['costUSD']['value'];
        if (profit < 0) {
          lightness = _mathService.rangeValue(profit, -100000, 0, darker, lighter);
          color = HSLColor.fromAHSL(opacity, 0, 1.0, lightness).toColor();
        } else {
          lightness = _mathService.rangeValue(profit, 0, 100000, lighter, darker);
          color = HSLColor.fromAHSL(opacity, 90, 1.0, lightness).toColor();
        }
      }
    } else if (_vals['dataType'] == 'baselineEmissionsTCO2') {
      if (tile.containsKey('baselineEmissionsTCO2') && tile['baselineEmissionsTCO2']['value'] != null) {
        lightness = _mathService.rangeValue(tile['baselineEmissionsTCO2']['value'], 0, 1000, lighter, darker);
        color = HSLColor.fromAHSL(opacity, 15, 1.0, lightness).toColor();
      }
    } else if (_vals['dataType'] == 'plannedDeforestationTon') {
      if (tile.containsKey('plannedDeforestationTon') && tile['plannedDeforestationTon']['value'] != null) {
        lightness = _mathService.rangeValue(tile['plannedDeforestationTon']['value'], 0, 1000, lighter, darker);
        color = HSLColor.fromAHSL(opacity, 30, 1.0, lightness).toColor();
      }
    } else if (_vals['dataType'] == 'reforestationEligibility') {
      if (tile.containsKey('reforestationEligibility') && tile['reforestationEligibility']['value'] != null) {
        lightness = _mathService.rangeValue(tile['reforestationEligibility']['value'], 0, 1, lighter, darker);
        color = HSLColor.fromAHSL(opacity, 300, 1.0, lightness).toColor();
      }
    }

    return GestureDetector(
      onTapUp: (details) {
        // print ("details ${details.localPosition}");
        // TODO - handle position for editing polygons.

        if (_selectedTileRowIndex > -1 && _selectedTileColumnIndex > -1) {
          _tileRows[_selectedTileRowIndex][_selectedTileColumnIndex]['xSelected'] = false;
        }
        _tileRows[indexRow][indexColumn]['xSelected'] = true;
        _selectedTile = _tileRows[indexRow][indexColumn];
        _selectedTileRowIndex = indexRow;
        _selectedTileColumnIndex = indexColumn;
        setState(() {
          _tileRows = _tileRows;
          _selectedTile = _selectedTile;
          _selectedTileRowIndex = _selectedTileRowIndex;
          _selectedTileColumnIndex = _selectedTileColumnIndex;
        });
      },
      child: Container(
        height: _tileWidth,
        width: _tileWidth,
        //color: color,
        decoration: BoxDecoration(
          border: border,
          color: color,
        ),
        child: Wrap(
          children: [
            Stack(
              children: [
                ...content,
                LandTilePolygon(landTileId: tile['_id'], tileXMeters: tile['xMeters'], tileYMeters: tile['yMeters'],
                  tileXPixels: _tileWidth, tileYPixels: _tileWidth),
              ]
            )
          ]
        ),
      )
    );
  }

  void _getTilesCount() {
    double defaultHeight = 500;
    double maxTileSize = 2000;
    double mapHeight = (_viewWidth < defaultHeight) ? _viewWidth : defaultHeight;
    int tilesXCount = 1;
    int tilesYCount = 1;
    double tilesContentWidth = _viewWidth;
    Map<String, int> tileSizeCount = {
      'xSmall': 8,
      'small': 4,
      'medium': 3,
      'large': 2,
      'xLarge': 1,
    };
    tilesXCount = tileSizeCount[_vals['tileSize']] ?? 4;
    if (_viewWidth < 500) {
      _tileWidth = tilesContentWidth / tilesXCount;
      if (_tileWidth < 50) {
        _tileWidth = 50;
        tilesXCount = (tilesContentWidth / _tileWidth).ceil();
        _tileWidth = tilesContentWidth / tilesXCount;
      }
      if (_tileWidth > maxTileSize) {
        _tileWidth = maxTileSize;
        tilesXCount = (tilesContentWidth / _tileWidth).ceil();
        _tileWidth = tilesContentWidth / tilesXCount;
      }
      _tileWidth = _viewWidth / tilesXCount;
      if (tilesXCount > 32) {
        tilesXCount = 32;
      }
      if (tilesXCount < 1) {
        tilesXCount = 1;
      }
      _formVals['xCount'] = tilesXCount;
      // Set to the same.
      _formVals['yCount'] = tilesXCount;
    } else {
      double spacing = 10;
      tilesContentWidth = _viewWidth - _sideWidth - spacing;
      if (_viewWidth < 800) {
        _sideWidth = 250;
      }
      _tileWidth = tilesContentWidth / tilesXCount;
      if (_tileWidth < 50) {
        _tileWidth = 50;
        tilesXCount = (tilesContentWidth / _tileWidth).ceil();
        _tileWidth = tilesContentWidth / tilesXCount;
      }
      double maxSize = maxTileSize < tilesContentWidth ? maxTileSize : tilesContentWidth;
      if (_tileWidth > maxSize) {
        _tileWidth = maxSize;
        tilesXCount = (tilesContentWidth / _tileWidth).ceil();
        _tileWidth = tilesContentWidth / tilesXCount;
      }
      //tilesXCount = (tilesContentWidth / _tileWidth).ceil();
      tilesYCount = (_viewHeight / _tileWidth).floor();
      if (tilesXCount > 32) {
        tilesXCount = 32;
      }
      if (tilesXCount < 1) {
        tilesXCount = 1;
      }
      if (tilesYCount > 32) {
        tilesYCount = 32;
      }
      if (tilesYCount < 1) {
        tilesYCount = 1;
      }
      _formVals['xCount'] = tilesXCount;
      _formVals['yCount'] = tilesYCount;
    }
  }

  dynamic _getTilesBounds(tileRows) {
    List<dynamic> coordinates = [[]];
    int rowsCount = tileRows.length;
    int columnsCount = tileRows[0].length;
    double tileYMeters = tileRows[(rowsCount - 1)][0]['yMeters'];
    double tileXMeters = tileRows[0][(columnsCount - 1)]['xMeters'];
    double earthRadiusKm = 6378;
    double topLat = tileRows[0][0]['latTopLeft'];
    double bottomLat = tileRows[(rowsCount - 1)][0]['latTopLeft'] - (tileYMeters / 1000 / earthRadiusKm) * (180 / pi);
    double leftLng = tileRows[0][0]['lngTopLeft'];
    double rightLng =  tileRows[0][(columnsCount - 1)]['lngTopLeft'] + (tileXMeters / 1000 / earthRadiusKm) * (180 / pi) / cos(bottomLat * pi / 180);

    coordinates[0].add([ leftLng, topLat ]);
    coordinates[0].add([ rightLng, topLat ]);
    // We want a connected polygon, so order matters - do bottom right before bottom left.
    coordinates[0].add([ rightLng, bottomLat ]);
    // Bottom left.
    // TODO - need to add tile height to get bottom edge instead of top.
    coordinates[0].add([ leftLng, bottomLat ]);
    // Close loop - add the starting one to end too.
    coordinates[0].add(coordinates[0][0]);
    return coordinates;
  }

}
