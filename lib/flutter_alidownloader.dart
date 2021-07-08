import 'package:flutter/services.dart';

class FlutterAliDownloader {
  MethodChannel _methodChannel = MethodChannel("plugins.flutter_alidownload");
  EventChannel _eventChannel =
      EventChannel("plugins.flutter_alidownload_event");

  Stream<dynamic>? _receiveStream;

  FlutterAliDownloader.init() {
    _receiveStream = _eventChannel.receiveBroadcastStream();
    //TODO iOS必须在这里监听 才能回调
    _eventChannel.receiveBroadcastStream().listen(_onEvent, onError: _onError);
  }

  ///type {FlutterAvpdef.DOWNLOADTYPE_STS / FlutterAvpdef.DOWNLOADTYPE_AUTH}
  ///STS {vid,accessKeyId,accessKeySecret,securityToken}
  ///AUTH {vid,playAuth}
  Future<dynamic> prepare(String type, String vid,
      {int? index,
      String? accessKeyId,
      String? accessKeySecret,
      String? securityToken,
      String? playAuth}) async {
    var map = {
      'type': type,
      'vid': vid,
      'index': index,
      'accessKeyId': accessKeyId,
      'accessKeySecret': accessKeySecret,
      'securityToken': securityToken,
      'playAuth': playAuth
    };
    return _methodChannel.invokeMethod("prepare", map);
  }

  Stream<dynamic>? start(String vid, int index) {
    var map = {'vid': vid, 'index': index};
    _methodChannel.invokeMethod("start", map);
    return _receiveStream;
  }

  Future<dynamic> selectItem(String vid, int index) {
    var map = {'vid': vid, 'index': index};
    return _methodChannel.invokeMethod("selectItem", map);
  }

  void setSaveDir(String path) {
    _methodChannel.invokeMethod("setSaveDir", path);
  }

  Future<dynamic> stop(String vid, int index) {
    var map = {'vid': vid, 'index': index};
    return _methodChannel.invokeMethod("stop", map);
  }

  Future<dynamic> delete(String vid, int index) {
    var map = {'vid': vid, 'index': index};
    return _methodChannel.invokeMethod("delete", map);
  }

  Future<dynamic> getFilePath(String vid, int index) {
    var map = {'vid': vid, 'index': index};
    return _methodChannel.invokeMethod("getFilePath", map);
  }

  Future<dynamic> release(String vid, int index) {
    var map = {'vid': vid, 'index': index};
    return _methodChannel.invokeMethod("release", map);
  }

  Future<dynamic> updateSource(String type, String vid, String index,
      {String? accessKeyId,
      String? accessKeySecret,
      String? securityToken,
      String? playAuth}) {
    var map = {
      'type': type,
      'vid': vid,
      'index': index,
      'accessKeyId': accessKeyId,
      'accessKeySecret': accessKeySecret,
      'securityToken': securityToken,
      'playAuth': playAuth
    };
    return _methodChannel.invokeMethod("updateSource", map);
  }

  Future<dynamic> setDownloaderConfig(String vid, String index,
      {String? userAgent,
      String? referrer,
      String? httpProxy,
      int? connectTimeoutS,
      int? networkTimeoutMs}) {
    var map = {
      'vid': vid,
      'index': index,
      'UserAgent': userAgent,
      'Referrer': referrer,
      'HttpProxy': httpProxy,
      'ConnectTimeoutS': connectTimeoutS,
      'NetworkTimeoutMs': networkTimeoutMs
    };
    return _methodChannel.invokeMethod("setDownloaderConfig", map);
  }

  void _onEvent(dynamic event) {}

  void _onError(dynamic error) {}
}
