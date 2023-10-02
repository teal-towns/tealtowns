import 'dart:convert';
//import 'dart:io';
import 'dart:math';
//import 'package:http/http.dart' as http;
//import 'package:flutter_dotenv/flutter_dotenv.dart';

import './socket_service.dart';

class FileUploadService {
  FileUploadService._privateConstructor();
  static final FileUploadService _instance = FileUploadService._privateConstructor();
  factory FileUploadService() {
    return _instance;
  }

  SocketService _socketService = SocketService();

  List<String> _routeIds = [];
  bool _inited = false;
  var _callbacksById = {};

  void init() {
    if (!_inited) {
      _inited = true;
      _routeIds.add(_socketService.onRoute('saveFileData', callback: (String resString) {
        var res = jsonDecode(resString);
        var data = res['data'];
        String id = '';
        if (data.containsKey('_msgId')) {
          id = data['_msgId'].toString();
        }
        if (_callbacksById.containsKey(id)) {
          _callbacksById[id](data['url']);
          _callbacksById.remove(id);
        }
      }));
    }
  }

  void uploadFiles(var filesInfo, Function(List<String>) callback,
    { String fileType = 'image', bool saveToUserImages = false, int maxImageSize = 600 }) {
    init();
    //String randId = new Random().nextInt(1000000).toString();
    //_callbacksById[randId] = {
    //  'callback': callback,
    //  ''
    //};
    List<String> callbackUrls = [];
    int countDone = 0;
    for (int ii = 0; ii < filesInfo.length; ii++) {
      // Seed with an empty value.
      callbackUrls.add('');
      var fileInfo = filesInfo[ii];
      upload(fileInfo['file'].bytes, fileInfo['file'].name, fileInfo['title'], (String fileUrl) {
        callbackUrls[ii] = fileUrl;
        countDone += 1;
        if (countDone == filesInfo.length) {
          callback(callbackUrls);
        }
      }, fileType: fileType, saveToUserImages: saveToUserImages, maxImageSize: maxImageSize);
    }
  }

  void upload(var binaryData, String fileName, String title, Function(String) callback,
    { String fileType = 'image', bool saveToUserImages = false, int maxImageSize = 600 }) {
    if (title.length < 1) {
      title = 'title';
    }
    String randId = new Random().nextInt(1000000).toString();
    _callbacksById[randId] = callback;
    var dataSend = {
      '_msgId': randId,
      'fileData': binaryData,
      'fileType': fileType,
      'fileName': fileName,
      'saveToUserImages': saveToUserImages,
      'title': title,
      'maxSize': maxImageSize,
    };
    //if (fileType == 'image') {
    //  var extInfo = getExtensionInfo(fileName);
    //  dataSend['extension'] = extInfo['ext'];
    //}
    _socketService.emit('saveFileData', dataSend);
  }

  //Map<String, String> getExtensionInfo(String fileName) {
  //  var extensionInfo = [
  //    { 'ext': 'jpg', 'mime': 'image/jpeg', },
  //    { 'ext': 'jpeg', 'mime': 'image/jpeg', },
  //    { 'ext': 'png', 'mime': 'image/png', },
  //  ];
  //  for (var extInfo in extensionInfo) {
  //    if (fileName.contains('.${extInfo["ext"]}')) {
  //      return extInfo;
  //    }
  //  }
  //  // Default.
  //  return extensionInfo[0];
  //}
}