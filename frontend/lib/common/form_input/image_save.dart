import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import './image_class.dart';
import '../image_service.dart';
import '../socket_service.dart';
import '../file_upload_service.dart';
import './input_fields.dart';
import './input_file.dart';
import '../../modules/user_auth/current_user_state.dart';

class ImageSaveComponent extends StatefulWidget {
  var formVals;
  String formValsKey;
  String label;
  String fromTypesString;
  bool multiple;
  bool imageUploadSimple;
  int maxImageSize;

  //ImageSaveComponent({Key key, @required this.multiple, @required this.extensions, this.formVals,
  //  this.formValsKey, this.label = 'File', this.hint = 'Choose File', this.fieldKey = null }) : super(key: key);
  ImageSaveComponent({ required this.formVals, required this.formValsKey, this.label = 'Image',
    this.fromTypesString = 'upload,myImages,allImages', this.multiple = false,
    this.imageUploadSimple = false, this.maxImageSize = 600, });

  @override
  _ImageSaveState createState() => _ImageSaveState();
}

class _ImageSaveState extends State<ImageSaveComponent> {
  List<String> _routeIds = [];
  ImageService _imageService = ImageService();
  FileUploadService _fileUploadService = FileUploadService();
  SocketService _socketService = SocketService();
  InputFields _inputFields = InputFields();

  late List<String> _fromTypes;

  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;
  var formValsImageSave = {};
  bool _loadingUpload = false;
  String _message = '';
  bool _editing = true;
  var formValsUploadFiles = {};
  String _messageUploadFiles = '';
  String _messageImages = '';
  bool _loadingImages = false;
  List<ImageClass> _images = [];
  int _lastPageNumberImages = 1;
  List<String> _selectedImageUrls = [];
  bool _initLoad = false;

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('getImages', callback: (String resString) {
      _messageImages = '';
      var res = json.decode(resString);
      var data = res['data'];
      if (int.parse(data['valid']) == 1 && data.containsKey('images')) {
        _images = [];
        for (var image in data['images']) {
          _images.add(ImageClass.fromJson(image));
        }
      } else {
         _messageImages = data['message'].length > 0 ? data['message'] : 'No images found';
      }
      setState(() {
        _loadingImages = false;
        _messageImages = _messageImages;
        _images = _images;
        _loadingUpload = false;
      });
    }));
  }

  Widget _buildMessageUploadFiles(BuildContext context) {
    if (_messageUploadFiles.length > 0) {
      return Text(_messageUploadFiles);
    }
    return SizedBox.shrink();
  }

  Widget _buildLoadingUpload(BuildContext context) {
    if (_loadingUpload) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: LinearProgressIndicator(
        ),
      );
    }
    return SizedBox.shrink();
  }

  Widget _buildMessageImages(BuildContext context) {
    if (_messageImages.length > 0) {
      return Text(_messageImages);
    }
    return SizedBox.shrink();
  }

  Widget _buildChangeButtons(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          //ElevatedButton(
          //  onPressed: () {
          //    setState(() { _editing = !_editing; });
          //  },
          //  child: Text('Change'),
          //),
          //SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {
              widget.formVals[widget.formValsKey] = widget.multiple ? [] : '';
              formValsImageSave['image_urls'] = [];
              formValsImageSave['image_files'] = [];
              setState(() {
                formValsImageSave = formValsImageSave;
                _editing = true;
                formValsUploadFiles = {};
              });
            },
            //child: Text('Remove'),
            child: Text('Change'),
          ),
        ]
      )
    );
  }

  Widget _buildFileSave(String formValsUploadFilesKey, BuildContext context) {
    return Container(
      width: 125,
      padding: EdgeInsets.only(right: 10),
      child: Form(
        key: formValsUploadFiles[formValsUploadFilesKey]['formKey'],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Image.memory(formValsUploadFiles[formValsUploadFilesKey]['file'].bytes),
            SizedBox(height: 5),
            _inputFields.inputText(formValsUploadFiles[formValsUploadFilesKey], 'title', label: 'Title', hint: 'Image Title'),
          ]
        )
      )
    );
  }

  Widget _buildUploadForms(BuildContext context) {
    if (formValsImageSave['image_files'] != null && formValsImageSave['image_files'].length > 0) {
      Widget saveButton = SizedBox.shrink();
      if (!_loadingUpload) {
        saveButton = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _messageUploadFiles = '';
                _loadingUpload = false;
                var filesInfo = [];
                bool valid = true;
                for (String key in formValsUploadFiles.keys) {
                  formValsUploadFiles[key]['formKey'].currentState.save();
                  if (formValsUploadFiles[key]['title'].length < 1) {
                    valid = false;
                    break;
                  }
                  filesInfo.add(formValsUploadFiles[key]);
                }
                if (valid) {
                  _loadingUpload = true;
                  _fileUploadService.uploadFiles(filesInfo, (List<Map<String, dynamic>> fileData) {
                    List<String> fileUrls = [];
                    if (widget.multiple) {
                      for (int ii = 0; ii < fileData.length; ii++) {
                        fileUrls.add(fileData[ii]['url']);
                      }
                      widget.formVals[widget.formValsKey] = fileUrls;
                    } else {
                      fileUrls.add(fileData[0]['url']);
                      widget.formVals[widget.formValsKey] = fileUrls[0];
                    }
                    // Copy to local state to display images.
                    formValsImageSave['image_urls'] = fileUrls;
                    setState(() {
                      formValsImageSave = formValsImageSave;
                      _editing = false;
                      _loadingUpload = false;
                    });
                  }, fileType: 'image', maxImageSize: widget.maxImageSize);
                } else {
                  _messageUploadFiles = 'Enter a title for all images';
                }
                //setState(() { _editing = !_editing; });
                setState(() {
                  _messageUploadFiles = _messageUploadFiles;
                  _loadingUpload = _loadingUpload;
                });
              },
              child: Text('Save Image Files'),
            ),
            SizedBox(height: 5),
          ]
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ...formValsUploadFiles.keys.map((keyTemp) => _buildFileSave(keyTemp, context) ).toList(),
            ]
          ),
          saveButton,
          _buildLoadingUpload(context),
          _buildMessageUploadFiles(context),
        ]
      );
    }
    return SizedBox.shrink();
  }

  Widget _buildImageSelect(ImageClass image, BuildContext context) {
    Color color = Colors.transparent;
    if (_selectedImageUrls.contains(image.url)) {
      color = Colors.grey.shade300;
    }
    return InkWell(
      onTap: () {
        if (widget.multiple) {
          if (!_selectedImageUrls.contains(image.url)) {
            _selectedImageUrls.add(image.url);
          } else {
            _selectedImageUrls.remove(image.url);
          }
          setState(() {
            _selectedImageUrls = _selectedImageUrls;
          });
        } else {
          _selectImageUrls([image.url]);
        }
      },
      child: Container(
        //height: 105,
        //width: 105,
        padding: EdgeInsets.all(5),
        color: color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              height: 100,
              width: 100,
              child: Image.network(_imageService.GetUrl(image.url)),
            ),
            SizedBox(height: 5),
            Text(image.title),
          ]
        )
      )
    );
  }

  Widget _buildImagesSelect(BuildContext context) {
    if (_images.length > 0) {
      Widget widgetButton = SizedBox.shrink();
      if (widget.multiple) {
        widgetButton = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _selectImageUrls(_selectedImageUrls);
              },
              child: Text('Select Images'),
            )
          ]
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: <Widget> [
              SizedBox(height: 10),
              ..._images.map((image) => _buildImageSelect(image, context) ).toList(),
            ]
          ),
          widgetButton,
        ]
      );
    }
    return _buildMessageImages(context);
  }

  Widget _buildSelect(BuildContext context, var currentUserState) {
    Widget widgetSelect = SizedBox.shrink();
    Widget widgetByType = SizedBox.shrink();
    if (_editing) {
      if (_fromTypes.length > 1) {
        List<Map<String, String>> selectOpts = [];
        if (_fromTypes.contains('upload')) {
          selectOpts.add({ 'value': 'upload', 'label': 'Upload' });
        }
        if (_fromTypes.contains('myImages')) {
          selectOpts.add({ 'value': 'myImages', 'label': 'My Images' });
        }
        if (_fromTypes.contains('allImages')) {
          selectOpts.add({ 'value': 'allImages', 'label': 'All Images' });
        }
        widgetSelect = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _inputFields.inputSelect(selectOpts, formValsImageSave, 'from_type', onChanged: (String newVal) {
              _getImages('', currentUserState);
              setState(() {
                formValsImageSave = formValsImageSave;
              });
            }),
            SizedBox(height: 10),
          ]
        );
      } else {
        formValsImageSave['from_type'] = _fromTypes[0];
      }

      if (formValsImageSave['from_type'] == 'upload') {
        String hint = 'Choose File' + (widget.multiple ? 's' : '');
        widgetByType = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            InputFile(multiple: widget.multiple, fileType: 'image', extensions: ['jpg', 'jpeg', 'png'], formVals: formValsImageSave,
              formValsKey: 'image_files', label: 'Image', showChips: false, hint: hint, onChanged: (String v) {
              if (formValsImageSave['image_files'] != null && formValsImageSave['image_files'].length > 0) {
                formValsUploadFiles = {};
                for (var file in formValsImageSave['image_files']) {
                  String randId = new Random().nextInt(1000000).toString();
                  formValsUploadFiles[randId] = { 'file': file, 'title': '', 'formKey': GlobalKey<FormState>(), };
                }
                setState(() {
                  formValsUploadFiles = formValsUploadFiles;
                });
              }
            }),
            _buildUploadForms(context),
          ]
        );
      } else if (formValsImageSave['from_type'] == 'myImages' || formValsImageSave['from_type'] == 'allImages') {
        widgetByType = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _inputFields.inputText(formValsImageSave, 'search_images', hint: 'Search for images', debounceChange: 1000, onChange: (String val) {
              _getImages(val, currentUserState);
            }),
            SizedBox(height: 10),
            _buildImagesSelect(context),
          ]
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        widgetSelect,
        widgetByType,
      ]
    );
  }

  Widget _buildImageDisplay(String imageUrl) {
    return Container(
      height: 100,
      width: 110,
      padding: EdgeInsets.only(right: 10),
      child: Image.network(_imageService.GetUrl(imageUrl)),
    );
  }

  Widget _buildImagesDisplay(BuildContext context) {
    if (formValsImageSave.containsKey('image_urls') && formValsImageSave['image_urls'] != null &&
      formValsImageSave['image_urls'].length > 0 && !_editing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              ...formValsImageSave['image_urls'].map((imageUrl) => _buildImageDisplay(imageUrl) ).toList(),
            ]
          ),
          SizedBox(height: 10),
          _buildChangeButtons(context),
        ]
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _buildImagePicker(BuildContext context, var currentUserState) {
    if (widget.imageUploadSimple) {
      if (_editing) {
        return _buildImageSimple(context);
      }
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSelect(context, currentUserState),
        //_buildImageSimple(context),
        //_buildSubmit(context),
        //_buildMessage(context),
      ]
    );
  }

  Widget _buildImageSimple(BuildContext context) {
    Widget input = SizedBox.shrink();
    if (!_loadingUpload) {
      String hint = 'Choose File' + (widget.multiple ? 's' : '');
      input = InputFile(multiple: widget.multiple, fileType: 'image', extensions: ['jpg', 'jpeg', 'png'], formVals: formValsImageSave,
        formValsKey: 'image_simple', showChips: false, hint: hint, onChanged: (String v) {
        setState(() {
          _loadingUpload = true;
        });
        var filesInfo = [];
        for (var file in formValsImageSave["image_simple"]) {
          filesInfo.add({ 'file': file, 'title': '' });
        }
        _fileUploadService.uploadFiles(filesInfo, (List<Map<String, dynamic>> fileData) {
          List<String> fileUrls = [];
          if (widget.multiple) {
            for (int ii = 0; ii < fileData.length; ii++) {
              fileUrls.add(fileData[ii]['url']);
            }
            widget.formVals[widget.formValsKey] = fileUrls;
          } else {
            fileUrls.add(fileData[0]['url']);
            widget.formVals[widget.formValsKey] = fileUrls[0];
          }
          // Copy to local state to display images.
          formValsImageSave['image_urls'] = fileUrls;
          setState(() {
            formValsImageSave = formValsImageSave;
            _editing = false;
            _loadingUpload = false;
          });
        }, fileType: 'image', maxImageSize: widget.maxImageSize);
      });
    }

    Widget image = SizedBox.shrink();
    if (formValsImageSave.containsKey('image_urls') && formValsImageSave['image_urls'] != null &&
      formValsImageSave['image_urls'].length > 0) {
      image = Image.network(_imageService.GetUrl(formValsImageSave['image_urls'][0]));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        input,
        SizedBox(height: 5),
        _buildLoadingUpload(context),
        image,
      ]
    );
  }

  @override
  Widget build(BuildContext context) {
    var currentUserState = context.watch<CurrentUserState?>();

    _fromTypes = widget.fromTypesString.split(",");
    if (!formValsImageSave.containsKey('from_type')) {
      formValsImageSave['from_type'] = _fromTypes[0];
    }
    if (widget.formVals.containsKey(widget.formValsKey) && widget.formVals[widget.formValsKey] != null) {
      if (widget.formVals[widget.formValsKey] is String) {
        formValsImageSave['image_urls'] = [ widget.formVals[widget.formValsKey] ];
      } else {
        formValsImageSave['image_urls'] = widget.formVals[widget.formValsKey];
      }
      if (!_initLoad) {
        _initLoad = true;
        _editing = false;
      }
    }

    return Align(
      alignment: Alignment.center,
      child: Container(
        //width: 600,
        width: double.infinity,
        padding: const EdgeInsets.only(top: 20),
        child: Form(
          key: _formKey,
          autovalidateMode: _autoValidate,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(widget.label),
              _buildImagesDisplay(context),
              _buildImagePicker(context, currentUserState),
            ]
          ),
        ),
      ),
    );
  }

  void _selectImageUrls(List<String> imageUrls) {
    if (widget.multiple) {
      widget.formVals[widget.formValsKey] = imageUrls;
    } else {
      widget.formVals[widget.formValsKey] = imageUrls[0];
    }
    // Copy to local state to display images.
    formValsImageSave['image_urls'] = imageUrls;
    setState(() {
      formValsImageSave = formValsImageSave;
      _editing = false;
      _selectedImageUrls = [];
    });
  }

  void _getImages(String search, var currentUserState) {
    String userIdCreator = '';
    if (formValsImageSave['from_type'] == 'myImages' && currentUserState.isLoggedIn) {
      userIdCreator = currentUserState.currentUser.id;
    }
    int limit = 20;
    // TODO - handle paging / load more (update backend to return count).
    var dataSend = {
      'limit': limit,
      'skip': (_lastPageNumberImages - 1) * limit,
      'title': search,
      'userIdCreator': userIdCreator,
    };
    _socketService.emit('getImages', dataSend);

    setState(() {
      _images = [];
      _lastPageNumberImages =_lastPageNumberImages;
      _loadingImages = true;
      _messageImages = '';
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
}