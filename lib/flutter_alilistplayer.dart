import 'package:flutter/material.dart';
import 'package:flutter_aliplayer/flutter_aliplayer_factory.dart';

import 'flutter_aliplayer.dart';
export 'flutter_aliplayer.dart';

class FlutterAliListPlayer extends FlutterAliplayer {
  FlutterAliListPlayer.init(String id) : super.init(id);

  @override
  Future<void> create() async {
    return FlutterAliPlayerFactory.methodChannel.invokeMethod('createAliPlayer',
        wrapWithPlayerId(arg: PlayerType.PlayerType_List));
  }

  Future<void> setPreloadCount(int count) async {
    return FlutterAliPlayerFactory.methodChannel.invokeMethod(
        "setPreloadCount", wrapWithPlayerId(arg: count));
  }

  Future<void> addVidSource({@required vid, @required uid}) async {
    Map<String, dynamic> info = {'vid': vid, 'uid': uid};
    return FlutterAliPlayerFactory.methodChannel.invokeMethod(
        "addVidSource", wrapWithPlayerId(arg: info));
  }

  Future<void> addUrlSource({@required url, @required uid}) async {
    Map<String, dynamic> info = {'url': url, 'uid': uid};
    return FlutterAliPlayerFactory.methodChannel.invokeMethod(
        "addUrlSource", wrapWithPlayerId(arg: info));
  }

  Future<void> removeSource(String uid) async {
    return FlutterAliPlayerFactory.methodChannel.invokeMethod(
        "removeSource", wrapWithPlayerId(arg: uid));
  }

  Future<void> clear() async {
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("clear", wrapWithPlayerId());
  }

  Future<void> moveToNext(
      {@required accId,
      @required accKey,
      @required token,
      @required region}) async {
    Map<String, dynamic> info = {
      'accId': accId,
      'accKey': accKey,
      'token': token,
      'region': region
    };
    return FlutterAliPlayerFactory.methodChannel
        .invokeMethod("moveToNext", wrapWithPlayerId(arg: info));
  }

  Future<void> moveToPre(
      {@required accId,
      @required accKey,
      @required token,
      @required region,
      playerId}) async {
    Map<String, dynamic> info = {
      'accId': accId,
      'accKey': accKey,
      'token': token,
      'region': region
    };
    return FlutterAliPlayerFactory.methodChannel.invokeMethod(
        "moveToPre", wrapWithPlayerId(arg: info));
  }

  ///移动到指定位置开始准备播放,url播放方式只需要填写uid；sts播放方式，需要更新sts信息
  ///uid 指定资源的uid，代表在列表中的唯一标识
  Future<void> moveTo(
      {@required String? uid,
      String? accId,
      String? accKey,
      String? token,
      String? region,
      playerId}) async {
    Map<String, dynamic> info = {
      'uid': uid,
      'accId': accId,
      'accKey': accKey,
      'token': token,
      'region': region
    };
    return FlutterAliPlayerFactory.methodChannel.invokeMethod(
        "moveTo", wrapWithPlayerId(arg: info));
  }
}
