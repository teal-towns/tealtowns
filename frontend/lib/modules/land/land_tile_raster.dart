import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../common/colors_service.dart';
import '../../common/socket_service.dart';
import '../../common/form_input/input_fields.dart';

class LandTileRaster extends StatefulWidget {
  var tileRows = [];
  double tileWidth = 100;
  String dataSource = 'mapbox';
  LandTileRaster({ @required this.tileRows = const [], this.tileWidth = 100, this.dataSource = 'mapbox', });

  @override
  _LandTileRasterState createState() => _LandTileRasterState();
}

class _LandTileRasterState extends State<LandTileRaster> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tileRows.length > 0 && widget.tileWidth > 0) {
      if (widget.dataSource == 'mapbox') {
        return _buildMapbox();
      }
    }
    return SizedBox.shrink();
  }

  Widget _buildMapbox() {
    if (widget.tileRows.length < 1) {
      return SizedBox.shrink();
    }
    return Column(
      children: [
        ...widget.tileRows!.asMap().entries.map((entry) {
          var tileRow = entry.value;
          var indexRow = entry.key;
          if (tileRow.length < 1) {
            return SizedBox.shrink();
          }
          return Row(
            children: [
              ...tileRow!.asMap().entries.map((entry) {
                var tile = entry.value;
                var indexColumn = entry.key;
                String zoom = tile['tileZoom'].toString();
                String column = tile['tileX'].toString();
                String row = tile['tileY'].toString();
                String imageUrl = 'https://api.mapbox.com/v4/mapbox.satellite/${zoom}/${column}/${row}@2x.webp?access_token=${dotenv.env['MAPBOX_ACCESS_TOKEN']}';
                return Container(
                  height: widget.tileWidth,
                  width: widget.tileWidth,
                  //child: Expanded(
                  //  child: Image.network(imageUrl, fit: BoxFit.contain),
                  //),
                  child: Image.network(imageUrl),
                );
              })
            ]
          );
        }),
      ]
    );
  }

}
