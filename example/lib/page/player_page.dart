import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_aliplayer/flutter_aliplayer.dart';
import 'package:flutter_aliplayer/flutter_aliplayer_factory.dart';
import 'package:flutter_aliplayer_example/config.dart';
import 'package:flutter_aliplayer_example/page/player_fragment/cache_config_fragment.dart';
import 'package:flutter_aliplayer_example/page/player_fragment/options_fragment.dart';
import 'package:flutter_aliplayer_example/page/player_fragment/play_config_fragment.dart';
import 'package:flutter_aliplayer_example/page/player_fragment/track_fragment.dart';
import 'package:flutter_aliplayer_example/util/formatter_utils.dart';
import 'package:flutter_aliplayer_example/widget/aliyun_slider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity/connectivity.dart';

class PlayerPage extends StatefulWidget {
  final ModeType playMode;
  final Map<String, dynamic> dataSourceMap;

  PlayerPage({Key key, this.playMode, this.dataSourceMap})
      : assert(playMode != null),
        super(key: key);

  @override
  _PlayerPageState createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> with WidgetsBindingObserver {
  FlutterAliplayer fAliplayer;
  int bottomIndex;
  List<Widget> mFramePage;
  ModeType _playMode;
  Map<String, dynamic> _dataSourceMap;
  OptionsFragment mOptionsFragment;
  //是否允许后台播放
  bool _mEnablePlayBack = false;
  //当前播放进度
  int _currentPosition = 0;
  //当前播放时间，用于Text展示
  int _currentPositionText = 0;
  //当前buffer进度
  int _bufferPosition = 0;
  //是否展示loading
  bool _showLoading = false;
  //loading进度
  int _loadingPercent = 0;
  //视频时长
  int _videoDuration = 1;
  //截图保存路径
  String _snapShotPath;
  //提示内容
  String _tipsContent;
  //是否展示提示内容
  bool _showTipsWidget = false;
  //是否有缩略图
  bool _thumbnailSuccess = false;
  //缩略图
  // Uint8List _thumbnailBitmap;
  ImageProvider _imageProvider;
  //当前网络状态
  ConnectivityResult _currentConnectivityResult;

  ///seek中
  bool _inSeek = false;

  bool _isLock = false;
  //网络状态
  bool _isShowMobileNetWork = false;

  //当前播放器状态
  int _currentPlayerState = 0;

  String extSubTitleText = '';
  //网络状态监听
  StreamSubscription _networkSubscriptiion;

  GlobalKey<TrackFragmentState> trackFragmentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    fAliplayer = FlutterAliPlayerFactory.createAliPlayer();
    WidgetsBinding.instance.addObserver(this);
    bottomIndex = 0;
    _playMode = widget.playMode;
    _dataSourceMap = widget.dataSourceMap;

    //开启混音模式
    if (Platform.isIOS) {
      FlutterAliplayer.enableMix(true);
    }

    //设置播放器
    fAliplayer.setPreferPlayerName(GlobalSettings.mPlayerName);

    if (Platform.isAndroid) {
      getExternalStorageDirectories().then((value) {
        if (value.length > 0) {
          _snapShotPath = value[0].path;
          return _snapShotPath;
        }
      });
    }

    mOptionsFragment = OptionsFragment(fAliplayer);
    mFramePage = [
      mOptionsFragment,
      PlayConfigFragment(fAliplayer),
      CacheConfigFragment(fAliplayer),
      TrackFragment(trackFragmentKey, fAliplayer),
    ];

    mOptionsFragment.setOnEnablePlayBackChanged((mEnablePlayBack) {
      this._mEnablePlayBack = mEnablePlayBack;
    });

    _initListener();
  }

  _initListener() {
    fAliplayer.setOnPrepared((playerId) {
      Fluttertoast.showToast(msg: "OnPrepared ");
      fAliplayer
          .getPlayerName()
          .then((value) => print("getPlayerName==${value}"));
      fAliplayer.getMediaInfo().then((value) {
        _videoDuration = value['duration'];
        setState(() {});
      });
    });
    fAliplayer.setOnRenderingStart((playerId) {
      Fluttertoast.showToast(msg: " OnFirstFrameShow ");
    });
    fAliplayer.setOnVideoSizeChanged((width, height, playerId) {});
    fAliplayer.setOnStateChanged((newState, playerId) {
      _currentPlayerState = newState;
      print("aliyun : onStateChanged $newState");
      switch (newState) {
        case FlutterAvpdef.AVPStatus_AVPStatusStarted:
          setState(() {
            _showTipsWidget = false;
            _showLoading = false;
          });
          break;
        case FlutterAvpdef.AVPStatus_AVPStatusPaused:
          break;
        default:
      }
    });
    fAliplayer.setOnLoadingStatusListener(loadingBegin: (playerId) {
      setState(() {
        _loadingPercent = 0;
        _showLoading = true;
      });
    }, loadingProgress: (percent, netSpeed, playerId) {
      _loadingPercent = percent;
      if (percent == 100) {
        _showLoading = false;
      }
      setState(() {});
    }, loadingEnd: (playerId) {
      setState(() {
        _showLoading = false;
      });
    });
    fAliplayer.setOnSeekComplete((playerId) {
      _inSeek = false;
    });
    fAliplayer.setOnInfo((infoCode, extraValue, extraMsg, playerId) {
      if (infoCode == FlutterAvpdef.CURRENTPOSITION) {
        if (_videoDuration != 0 && extraValue <= _videoDuration) {
          _currentPosition = extraValue;
        }
        if (!_inSeek) {
          setState(() {
            _currentPositionText = extraValue;
          });
        }
      } else if (infoCode == FlutterAvpdef.BUFFEREDPOSITION) {
        _bufferPosition = extraValue;
        if(mounted){
          setState(() {});
        }
      } else if (infoCode == FlutterAvpdef.AUTOPLAYSTART) {
        Fluttertoast.showToast(msg: "AutoPlay");
      } else if (infoCode == FlutterAvpdef.CACHESUCCESS) {
        Fluttertoast.showToast(msg: "Cache Success");
      } else if (infoCode == FlutterAvpdef.CACHEERROR) {
        Fluttertoast.showToast(msg: "Cache Error $extraMsg");
      } else if (infoCode == FlutterAvpdef.LOOPINGSTART) {
        Fluttertoast.showToast(msg: "Looping Start");
      } else if (infoCode == FlutterAvpdef.SWITCHTOSOFTWAREVIDEODECODER) {
        Fluttertoast.showToast(msg: "change to soft ware decoder");
        mOptionsFragment.switchHardwareDecoder();
      }
    });
    fAliplayer.setOnCompletion((playerId) {
      _showTipsWidget = true;
      _showLoading = false;
      _tipsContent = "播放完成";
      setState(() {
        _currentPosition = _videoDuration;
      });
    });
    fAliplayer.setOnTrackReady((playerId) {
      fAliplayer.getMediaInfo().then((value) {
        setState(() {});
        List thumbnails = value['thumbnails'];
        if (thumbnails != null && thumbnails.isNotEmpty) {
          fAliplayer.createThumbnailHelper(thumbnails[0]['url']);
        } else {
          _thumbnailSuccess = false;
        }
      });
      trackFragmentKey.currentState.loadData();
      setState(() {});
    });

    fAliplayer.setOnSnapShot((path, playerId) {
      print("aliyun : snapShotPath = $path");
      Fluttertoast.showToast(msg: "SnapShot Save : $path");
    });
    fAliplayer.setOnError((errorCode, errorExtra, errorMsg, playerId) {
      _showTipsWidget = true;
      _showLoading = false;
      _tipsContent = "$errorCode \n $errorMsg";
      setState(() {});
    });

    fAliplayer.setOnTrackChanged((value, playerId) {
      AVPTrackInfo info = AVPTrackInfo.fromJson(value);
      if (info != null && info.trackDefinition.length > 0) {
        trackFragmentKey.currentState.onTrackChanged(info);
        Fluttertoast.showToast(msg: "${info.trackDefinition}切换成功");
      }
    });

    fAliplayer.setOnThumbnailPreparedListener(preparedSuccess: (playerId) {
      _thumbnailSuccess = true;
    }, preparedFail: (playerId) {
      _thumbnailSuccess = false;
    });

    fAliplayer.setOnThumbnailGetListener(
        onThumbnailGetSuccess: (bitmap, range, playerId) {
          // _thumbnailBitmap = bitmap;
          var provider = MemoryImage(bitmap);
          precacheImage(provider, context).then((_) {
            setState(() {
              _imageProvider = provider;
            });
          });
        },
        onThumbnailGetFail: (playerId) {});

    this.fAliplayer.setOnSubtitleHide((trackIndex, subtitleID, playerId) {
      if (mounted) {
        setState(() {
          extSubTitleText = '';
        });
      }
    });

    this
        .fAliplayer
        .setOnSubtitleShow((trackIndex, subtitleID, subtitle, playerId) {
      if (mounted) {
        setState(() {
          extSubTitleText = subtitle;
        });
      }
    });

    _setNetworkChangedListener();
  }

  _setNetworkChangedListener() {
    _networkSubscriptiion = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      if (result == ConnectivityResult.mobile) {
        fAliplayer.pause();
        setState(() {
          _isShowMobileNetWork = true;
        });
      } else if (result == ConnectivityResult.wifi) {
        //从4G网络或者无网络切换到wifi
        if (_currentConnectivityResult == ConnectivityResult.mobile ||
            _currentConnectivityResult == ConnectivityResult.none) {
          fAliplayer.play();
        }
        setState(() {
          _isShowMobileNetWork = false;
        });
      }
      _currentConnectivityResult = result;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.resumed:
        _setNetworkChangedListener();
        break;
      case AppLifecycleState.paused:
        if (!_mEnablePlayBack) {
          fAliplayer.pause();
        }
        if (_networkSubscriptiion != null) {
          _networkSubscriptiion.cancel();
        }
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    if (Platform.isIOS) {
      FlutterAliplayer.enableMix(false);
    }

    fAliplayer.stop();
    fAliplayer.destroy();
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    if (_networkSubscriptiion != null) {
      _networkSubscriptiion.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    var x = 0.0;
    var y = 0.0;
    Orientation orientation = MediaQuery.of(context).orientation;
    var width = MediaQuery.of(context).size.width;

    var height;
    if (orientation == Orientation.portrait) {
      height = width * 9.0 / 16.0;
    } else {
      height = MediaQuery.of(context).size.height;
    }
    AliPlayerView aliPlayerView = AliPlayerView(
        onCreated: onViewPlayerCreated,
        x: x,
        y: y,
        width: width,
        height: height);
    return OrientationBuilder(
      builder: (BuildContext context, Orientation orientation) {
        return Scaffold(
          appBar: _buildAppBar(orientation),
          body: Column(
            children: [
              Stack(
                children: [
                  Container(
                      color: Colors.black,
                      child: aliPlayerView,
                      width: width,
                      height: height),
                  Container(
                    width: width,
                    height: height,
                    // padding: EdgeInsets.only(bottom: 25.0),
                    child: Offstage(
                        offstage: _isLock,
                        child: _buildContentWidget(orientation)),
                  ),
                  _buildProgressBar(width, height),
                  _buildTipsWidget(width, height),
                  _buildThumbnail(width, height),
                  _buildNetWorkTipsWidget(width, height),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      extSubTitleText,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  Positioned(
                    left: 30,
                    top: height / 2,
                    child: Offstage(
                        offstage: orientation == Orientation.portrait,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _isLock = !_isLock;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                                color: Colors.black.withAlpha(150),
                                borderRadius: BorderRadius.circular(20)),
                            child: Icon(
                              _isLock ? Icons.lock : Icons.lock_open,
                              color: Colors.white,
                            ),
                          ),
                        )),
                  )
                ],
              ),
              _buildControlBtns(orientation),
              _buildFragmentPage(orientation),
            ],
          ),
          bottomNavigationBar: _buildBottomNavigationBar(orientation),
        );
      },
    );
  }

  void onViewPlayerCreated(viewId) async {
    this.fAliplayer.setPlayerView(viewId);
    switch (_playMode) {
      case ModeType.URL:
        this.fAliplayer.setUrl(_dataSourceMap[DataSourceRelated.URL_KEY]);
        break;
      case ModeType.STS:
        this.fAliplayer.setVidSts(
            vid: _dataSourceMap[DataSourceRelated.VID_KEY],
            region: _dataSourceMap[DataSourceRelated.REGION_KEY],
            accessKeyId: _dataSourceMap[DataSourceRelated.ACCESSKEYID_KEY],
            accessKeySecret:
                _dataSourceMap[DataSourceRelated.ACCESSKEYSECRET_KEY],
            securityToken: _dataSourceMap[DataSourceRelated.SECURITYTOKEN_KEY],
            definitionList: _dataSourceMap[DataSourceRelated.DEFINITION_LIST],
            previewTime: _dataSourceMap[DataSourceRelated.PREVIEWTIME_KEY]);
        break;
      case ModeType.AUTH:
        this.fAliplayer.setVidAuth(
            vid: _dataSourceMap[DataSourceRelated.VID_KEY],
            region: _dataSourceMap[DataSourceRelated.REGION_KEY],
            playAuth: _dataSourceMap[DataSourceRelated.PLAYAUTH_KEY],
            definitionList: _dataSourceMap[DataSourceRelated.DEFINITION_LIST],
            previewTime: _dataSourceMap[DataSourceRelated.PREVIEWTIME_KEY]);
        break;
      case ModeType.MPS:
        this.fAliplayer.setVidMps(_dataSourceMap);
        break;
      default:
    }
  }

  _buildAppBar(Orientation orientation) {
    if (orientation == Orientation.portrait) {
      return AppBar(
        title: const Text('Plugin for aliplayer'),
      );
    }
  }

  /// MARK: 私有方法
  _buildControlBtns(Orientation orientation) {
    return Offstage(
      offstage: orientation == Orientation.landscape,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            InkWell(
                child: Text('准备'),
                onTap: () {
                  _showTipsWidget = false;
                  _showLoading = false;
                  trackFragmentKey.currentState.prepared();
                  setState(() {});
                  fAliplayer.prepare();
                }),
            InkWell(
                child: Text('播放'),
                onTap: () {
                  fAliplayer.play();
                }),
            InkWell(
              child: Text('停止'),
              onTap: () {
                fAliplayer.stop();
              },
            ),
            InkWell(
                child: Text('暂停'),
                onTap: () {
                  fAliplayer.pause();
                }),
            InkWell(
                child: Text('截图'),
                onTap: () {
                  if (Platform.isIOS) {
                    fAliplayer.snapshot(
                        DateTime.now().millisecondsSinceEpoch.toString() +
                            ".png");
                  } else {
                    fAliplayer.snapshot(_snapShotPath +
                        "/snapshot_" +
                        new DateTime.now().millisecondsSinceEpoch.toString() +
                        ".png");
                  }
                }),
          ],
        ),
      ),
    );
  }

  _buildFragmentPage(Orientation orientation) {
    return Expanded(
        child: Offstage(
      offstage: orientation == Orientation.landscape,
      child: IndexedStack(index: bottomIndex, children: mFramePage),
    )); //mFramePage
  }

  ///缩略图
  _buildThumbnail(double width, double height) {
    if (_inSeek && _thumbnailSuccess) {
      return Container(
        alignment: Alignment.center,
        width: width,
        height: height,
        child: Wrap(
          direction: Axis.vertical,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text("${FormatterUtils.getTimeformatByMs(_currentPosition)}",
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center),
            _imageProvider == null
                ? Container()
                : Image(
                    width: width / 2,
                    height: height / 2,
                    image: _imageProvider,
                  ),
          ],
        ),
      );
    } else {
      return Container();
    }
  }

  ///提示Widget
  _buildTipsWidget(double width, double height) {
    if (_showTipsWidget) {
      return Container(
        alignment: Alignment.center,
        width: width,
        height: height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_tipsContent,
                maxLines: 3,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center),
            SizedBox(
              height: 5.0,
            ),
            OutlineButton(
              shape: BeveledRectangleBorder(
                side: BorderSide(
                  style: BorderStyle.solid,
                  color: Colors.blue,
                  width: 5,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text("Replay", style: TextStyle(color: Colors.white)),
              onPressed: () {
                setState(() {
                  _showTipsWidget = false;
                });
                fAliplayer.prepare();
                fAliplayer.play();
              },
            ),
          ],
        ),
      );
    } else {
      return Container();
    }
  }

  //网络提示Widget
  _buildNetWorkTipsWidget(double widgetWidth, double widgetHeight) {
    return Offstage(
      offstage: !_isShowMobileNetWork,
      child: Container(
        alignment: Alignment.center,
        width: widgetWidth,
        height: widgetHeight,
        child: Wrap(
          direction: Axis.vertical,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text("当前为移动网络",
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center),
            SizedBox(
              height: 30.0,
            ),
            Wrap(
              direction: Axis.horizontal,
              children: [
                OutlineButton(
                  shape: BeveledRectangleBorder(
                    side: BorderSide(
                      style: BorderStyle.solid,
                      color: Colors.blue,
                      width: 5,
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text("继续播放", style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    setState(() {
                      _isShowMobileNetWork = false;
                    });
                    fAliplayer.play();
                  },
                ),
                SizedBox(
                  width: 10.0,
                ),
                OutlineButton(
                  shape: BeveledRectangleBorder(
                    side: BorderSide(
                      style: BorderStyle.solid,
                      color: Colors.blue,
                      width: 5,
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text("退出播放", style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    setState(() {
                      _isShowMobileNetWork = false;
                      Navigator.pop(context);
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ///Loading
  _buildProgressBar(double width, double height) {
    if (_showLoading) {
      return Positioned(
        left: width / 2 - 20,
        top: height / 2 - 20,
        child: Column(
          children: [
            CircularProgressIndicator(
              backgroundColor: Colors.white,
              strokeWidth: 3.0,
            ),
            SizedBox(
              height: 10.0,
            ),
            Text(
              "$_loadingPercent%",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    } else {
      return SizedBox();
    }
  }

  ///播放进度和buffer
  _buildContentWidget(Orientation orientation) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 5.0),
            child: Text(
              "buffer : ${FormatterUtils.getTimeformatByMs(_bufferPosition)}",
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
          Row(
            children: [
              SizedBox(
                width: 5.0,
              ),
              Text(
                "${FormatterUtils.getTimeformatByMs(_currentPositionText)} / ${FormatterUtils.getTimeformatByMs(_videoDuration)}",
                style: TextStyle(color: Colors.white, fontSize: 11),
              ),
              Expanded(
                child: AliyunSlider(
                  max: _videoDuration == 0 ? 1 : _videoDuration.toDouble(),
                  min: 0,
                  bufferColor: Colors.white,
                  bufferValue: _bufferPosition.toDouble(),
                  value: _currentPosition.toDouble(),
                  onChangeStart: (value) {
                    _inSeek = true;
                    _showLoading = false;
                    setState(() {});
                  },
                  onChangeEnd: (value) {
                    _inSeek = false;
                    setState(() {
                      if (_currentPlayerState == FlutterAvpdef.completion &&
                          _showTipsWidget) {
                        setState(() {
                          _showTipsWidget = false;
                        });
                      }
                    });
                    fAliplayer.seekTo(
                        value.ceil(),
                        GlobalSettings.mEnableAccurateSeek
                            ? FlutterAvpdef.ACCURATE
                            : FlutterAvpdef.INACCURATE);
                  },
                  onChanged: (value) {
                    if (_thumbnailSuccess) {
                      fAliplayer.requestBitmapAtPosition(value.ceil());
                    }
                    setState(() {
                      _currentPosition = value.ceil();
                    });
                  },
                ),
              ),
              IconButton(
                icon: Icon(
                  orientation == Orientation.portrait
                      ? Icons.fullscreen
                      : Icons.fullscreen_exit,
                  color: Colors.white,
                ),
                onPressed: () {
                  if (orientation == Orientation.portrait) {
                    SystemChrome.setPreferredOrientations([
                      DeviceOrientation.landscapeLeft,
                      DeviceOrientation.landscapeRight
                    ]);
                  } else {
                    SystemChrome.setPreferredOrientations([
                      DeviceOrientation.portraitUp,
                      DeviceOrientation.portraitDown
                    ]);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  //底部tab
  _buildBottomNavigationBar(Orientation orientation) {
    if (orientation == Orientation.portrait) {
      return BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
              title: Text('options'), icon: Icon(Icons.control_point)),
          BottomNavigationBarItem(
              title: Text('play_cfg'), icon: Icon(Icons.control_point)),
          BottomNavigationBarItem(
              title: Text('cache_cfg'), icon: Icon(Icons.control_point)),
          BottomNavigationBarItem(
              title: Text('track'), icon: Icon(Icons.control_point)),
        ],
        currentIndex: bottomIndex,
        onTap: (index) {
          if (index != bottomIndex) {
            setState(() {
              bottomIndex = index;
            });
          }
        },
      );
    }
  }
}
