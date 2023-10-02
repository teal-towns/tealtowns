import 'dart:io';
//import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

class InputFile extends StatefulWidget {
  bool multiple;
  List<String>? extensions;
  var formVals;
  String? formValsKey;
  String label;
  String hint;
  var fieldKey;
  Function(String)? onChanged;
  bool showChips;
  bool withData;
  String fileType;
  String routeKey;

  InputFile({Key? key, @required this.multiple = false, this.formVals = null,
    this.formValsKey = null, this.extensions = null, this.label = 'File', this.hint = 'Choose File', this.fieldKey = null,
    this.onChanged = null, this.showChips = true, this.withData = true,
    this.fileType = 'custom', this.routeKey = '' }) : super(key: key);
  //InputFile(this.multiple, this. extensions, this.formVals, this.formValsKey, { Key key,
  //  this.label, this.hint, this.fieldKey }) : super(key: key);
  //InputFile(this.multiple, this.extensions, this.formVals, this.formValsKey, this.label, this.hint, this.fieldKey);

  @override
  _InputFileState createState() => _InputFileState();
}

class _InputFileState extends State<InputFile> {
  List<PlatformFile> _files = [];
  bool _loading = false;

  void _pickFile() async {
    setState(() {
      _loading = true;
    });

    List<String>? extensions = widget.extensions;
    FileType fileType = FileType.custom;

    if (widget.fileType == 'image') {
      fileType = FileType.image;
      extensions = null;
    } else if (widget.fileType == 'video') {
      fileType = FileType.video;
      extensions = null;
    } else if (widget.fileType == 'media') {
      fileType = FileType.media;
      extensions = null;
    } else if (widget.fileType == 'audio') {
      fileType = FileType.audio;
      extensions = null;
    } else if (widget.fileType == 'any') {
      fileType = FileType.any;
      extensions = null;
    }

    List<PlatformFile>? filesTemp = [];
    try {
      //_directoryPath = null;
      filesTemp = (await FilePicker.platform.pickFiles(
        type: fileType,
        allowMultiple: widget.multiple,
        allowedExtensions: extensions,
        withData: widget.withData,
      ))?.files;
      _files = filesTemp!;
    } on PlatformException catch (e) {
      print("Unsupported operation" + e.toString());
    } catch (ex) {
      print(ex);
    }

    //debugPrint('_files ${_files}');
    //if (!mounted) return;

    // Android / iOS have bytes as null, so need to read file.
    var futures = <Future>[];
    List<PlatformFile> filesCopy = [];
    for (var file in _files) {
      if (file.bytes == null && file.path != null) {
        futures.add(new File(file.path!).readAsBytes().then((var bytes) {
          //file.bytes = bytes;
          filesCopy.add(PlatformFile.fromMap({
            'path': file.path,
            'name': file.name,
            'bytes': bytes,
            'readStream': file.readStream,
            'size': file.size}));
        }));
      } else {
        filesCopy.add(file);
      }
    }
    if (futures.length > 0) {
      _files = filesCopy;
      Future.wait(futures).then((var resFutures) {
        _onHaveAllFileBytes();
      });
    } else {
      _onHaveAllFileBytes();
    }
  }

  void _onHaveAllFileBytes() {
    setState(() {
      _loading = false;
      //_fileName = _paths != null ? _paths.map((e) => e.name).toString() : '...';
      _files = _files;
    });
    widget.formVals[widget.formValsKey] = _files;
    if(widget.onChanged != null) {
      widget.onChanged!('');
    }
  }

  Widget _buildFileChip(PlatformFile file) {
    return Padding(
      padding: EdgeInsets.only(right: 5),
      child: Chip(
        label: Text(file.name),
        deleteIcon: Icon(
          Icons.close,
          color: Colors.white,
        ),
        onDeleted: () {
          _files.remove(file);
          setState(() {
            _files = _files;
          });
          widget.formVals[widget.formValsKey] = _files;
        }
      )
    );
  }

  Widget _buildFileChips() {
    if (!widget.showChips) {
      return SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: 5),
        Row(
          children: <Widget> [
            ..._files.map((file) => _buildFileChip(file) ).toList(),
          ]
        ),
      ]
    );
  }

  @override
  Widget build(BuildContext context) {
    //if (_loading) {
    //  return Padding(
    //    padding: const EdgeInsets.symmetric(vertical: 16.0),
    //    child: LinearProgressIndicator(
    //    ),
    //  );
    //}
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      //mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: () { _pickFile(); },
          child: Text(widget.hint),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.grey.shade800, backgroundColor: Colors.white,
          ),
        ),
        _buildFileChips(),
      ]
    );
  }
}
