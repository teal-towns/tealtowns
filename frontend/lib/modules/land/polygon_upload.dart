import 'package:flutter/material.dart';

import '../../common/form_input/input_file.dart';
import '../../common/file_upload_service.dart';

class PolygonUpload extends StatefulWidget {
  Function(Map<String, dynamic>)? onChange;

  PolygonUpload({ @required this.onChange = null, });

  @override
  _PolygonUploadState createState() => _PolygonUploadState();
}

class _PolygonUploadState extends State<PolygonUpload> {
  FileUploadService _fileUploadService = FileUploadService();

  var _formVals = {};
  //var _formValsUploadFiles = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _buildFileUpload();
  }

  _buildFileUpload() {
    return InputFile(
      multiple: false,
      extensions: ['geojson', 'kml', 'kmz', 'zip'],
      formVals: _formVals,
      formValsKey: 'files',
      showChips: false,
      onChanged: (String v) {
        if (_formVals['files'] != null && _formVals['files'].length > 0) {
          var filesInfo = [];
          for (var file in _formVals['files']) {
            filesInfo.add({ 'file': file, 'title': file.name, });
          }
          _fileUploadService.uploadFiles(filesInfo, (Map<String, dynamic> fileData) {
            if (widget.onChange != null) {
              widget.onChange!(fileData);
            }
          }, fileType: '', routeKey: 'polygonUploadToTiles', );
        }
      }
    );
  }
}
