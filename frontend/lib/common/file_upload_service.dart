import 'dart:convert';
//import 'dart:io';
import 'dart:math';
//import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
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
  Map<String, bool> _inited = {};
  var _callbacksById = {};

  void init({ String serverKey = 'default', }) {
    if (!_inited.containsKey(serverKey)) {
      _inited[serverKey] = true;
      _routeIds.add(_socketService.onRoute('saveFileData', serverKey: serverKey, callback: (String resString) {
        var res = jsonDecode(resString);
        var data = res['data'];
        String id = '';
        if (data.containsKey('_msgId')) {
          id = data['_msgId'].toString();
        }
        if (_callbacksById.containsKey(id)) {
          _callbacksById[id](data);
          _callbacksById.remove(id);
        }
      }));
    }
  }

  void uploadFiles(var filesInfo, Function(List<Map<String, dynamic>>) callback,
    { String fileType = 'image', bool saveToUserImages = false, int maxImageSize = 600,
    String serverKey = 'default', String routeKey = '', }) {
    init(serverKey: serverKey);
    //String randId = new Random().nextInt(1000000).toString();
    //_callbacksById[randId] = {
    //  'callback': callback,
    //  ''
    //};
    List<Map<String, dynamic>> callbackDatas = [];
    int countDone = 0;
    for (int ii = 0; ii < filesInfo.length; ii++) {
      // Seed with an empty value.
      // callbackDatas.add('');
      var fileInfo = filesInfo[ii];
      upload(fileInfo['file'].bytes, fileInfo['file'].name, fileInfo['title'], (Map<String, dynamic> resData) {
        callbackDatas.add(resData);
        countDone += 1;
        if (countDone == filesInfo.length) {
          callback(callbackDatas);
          // callback(resData);
        }
      }, fileType: fileType, saveToUserImages: saveToUserImages, maxImageSize: maxImageSize,
        serverKey: serverKey, routeKey: routeKey );
    }
  }

  void upload(var binaryData, String fileName, String title, Function(Map<String, dynamic>) callback,
    { String fileType = 'image', bool saveToUserImages = false, int maxImageSize = 600,
    String serverKey = 'default', String routeKey = '' }) {
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
      'routeKey': routeKey,
    };
    //if (fileType == 'image') {
    //  var extInfo = getExtensionInfo(fileName);
    //  dataSend['extension'] = extInfo['ext'];
    //}
    _socketService.emit('saveFileData', dataSend, serverKey: serverKey);
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