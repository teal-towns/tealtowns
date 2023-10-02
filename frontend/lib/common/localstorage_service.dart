import 'package:localstorage/localstorage.dart';

class LocalstorageService {
  LocalstorageService._privateConstructor();
  static final LocalstorageService _instance = LocalstorageService._privateConstructor();
  factory LocalstorageService() {
    return _instance;
  }

  LocalStorage? _localstorage;

  void init(storageName) {
    _localstorage = new LocalStorage('${storageName}.json');
  }

  get localstorage => _localstorage;
}