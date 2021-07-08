import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_aliplayer/flutter_aliplayer_factory.dart';
import 'package:flutter_aliplayer_example/config.dart';
import 'package:flutter_aliplayer_example/model/video_model.dart';
import 'package:flutter_aliplayer_example/util/network_utils.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter_aliplayer/flutter_alilistplayer.dart';

class VideoGridPage extends StatefulWidget {
  final ModeType playMode;

  const VideoGridPage({Key key, this.playMode}) : super(key: key);

  @override
  _VideoGridPageState createState() => _VideoGridPageState();
}

class _VideoGridPageState extends State<VideoGridPage>
    with WidgetsBindingObserver {
  List _dataList = [];
  int _page = 1;
  VideoShowMode _showMode = VideoShowMode.Grid;

  RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  PageController _pageController;

  FlutterAliListPlayer fAliListPlayer;

  int _curIdx = 0;
  int _lastCurIndex = -1;

  bool _isPause = false;

  double _playerY = 0;

  bool _isFirstRenderShow = false;

  bool _isBackgroundMode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fAliListPlayer = FlutterAliPlayerFactory.createAliListPlayer();
    fAliListPlayer.setAutoPlay(true);
      fAliListPlayer.setLoop(true);
      var configMap = {
        'mClearFrameWhenStop': true,
      };
      fAliListPlayer.setConfig(configMap);

      fAliListPlayer.setOnRenderingStart((playerId) {
        print('_isFirstRenderShow==$_curIdx');
        Future.delayed(Duration(milliseconds: 50), () {
          setState(() {
            _isFirstRenderShow = true;
          });
        });
      });

      fAliListPlayer.setOnStateChanged((newState, playerId) {
        switch (newState) {
          case FlutterAvpdef.AVPStatus_AVPStatusStarted:
            setState(() {
              _isBackgroundMode = false;
              _isPause = false;
            });
            break;
          case FlutterAvpdef.AVPStatus_AVPStatusPaused:
            setState(() {
              _isPause = true;
            });
            break;
          default:
        }
      });

      fAliListPlayer.setOnError((errorCode, errorExtra, errorMsg, playerId) {
        Fluttertoast.showToast(msg: errorMsg);
      });

      _onRefresh();
  }

  @override
  void dispose() {
    super.dispose();
    this.fAliListPlayer.clear();
    this.fAliListPlayer.stop();
    this.fAliListPlayer.destroy();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_showMode == VideoShowMode.Grid) {
      return;
    }
    switch (state) {
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.resumed:
        fAliListPlayer.play();
        break;
      case AppLifecycleState.paused:
        _isBackgroundMode = true;
        fAliListPlayer.pause();
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  _onRefresh() async {
    _page = 1;
    _dataList = [];
    _loadData();
  }

  _onLoadMore() async {
    _page++;
    _loadData();
  }

  _loadData() async {
    NetWorkUtils.instance.getHttp(HttpConstant.GET_RANDOM_USER,
        successCallback: (data) {
      String token = data['token'];
      NetWorkUtils.instance.getHttp(HttpConstant.GET_RECOMMEND_VIDEO_LIST,
          params: {'token': token, "pageIndex": _page, "pageSize": 10},
          successCallback: (data) {
        print('data=$data');
        _loadDataFinish(data);
      }, errorCallback: (error) {
        print("error");
      });
    }, errorCallback: (error) {
      print("error");
    });
  }

  _loadDataFinish(data) {
    VideoListModel videoListModel = VideoListModel.fromJson(data);
    if (videoListModel.videoList.isNotEmpty) {
      videoListModel.videoList.forEach((element) {
        if (widget.playMode == ModeType.URL) {
          fAliListPlayer.addUrlSource(
              url: element.fileUrl, uid: element.videoId);
        } else if (widget.playMode == ModeType.STS) {
          fAliListPlayer.addVidSource(
              vid: element.videoId, uid: element.videoId);
        }
      });

      _dataList.addAll(videoListModel.videoList);
    }
    _refreshController.refreshCompleted();
    if (videoListModel.videoList.length < 10) {
      _refreshController.loadNoData();
    } else {
      _refreshController.loadComplete();
    }
    setState(() {});
  }

  _buildGridView() {
    return Scaffold(
      appBar: AppBar(
        title: Text('播放列表'),
      ),
      body: SmartRefresher(
        enablePullDown: true,
        enablePullUp: true,
        header: ClassicHeader(),
        footer: ClassicFooter(
          loadStyle: LoadStyle.ShowWhenLoading,
        ),
        controller: _refreshController,
        onRefresh: _onRefresh,
        onLoading: _onLoadMore,
        child: GridView.builder(
          shrinkWrap: true,
          itemCount: _dataList.length,
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 9 / 16,
          ),
          itemBuilder: (context, index) {
            VideoModel model = _dataList[index];
            return InkWell(
              onTap: () {
                setState(() {
                  _curIdx = index;
                  _lastCurIndex = index;
                  _showMode = VideoShowMode.Srceen;
                  _pageController = PageController(initialPage: _curIdx);
                });
                start();
              },
              child: Container(
                color: Colors.black,
                child: Image.network(
                  model.coverUrl,
                  fit: BoxFit.fitWidth,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  _buildFullScreenView() {
    return WillPopScope(
      onWillPop: () async {
        if (_showMode == VideoShowMode.Srceen) {
          _exitScreenMode();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: NotificationListener(
          onNotification: (ScrollNotification notification) {
            if (notification.depth == 0 &&
                notification is ScrollUpdateNotification) {
              final PageMetrics metrics = notification.metrics as PageMetrics;
              _playerY =
                  metrics.pixels - _curIdx * MediaQuery.of(context).size.height;
              setState(() {});
            } else if (notification is ScrollEndNotification) {
              _playerY = 0.0;
              PageMetrics metrics = notification.metrics as PageMetrics;
              _curIdx = metrics.page.round();
              if (_lastCurIndex != _curIdx) {
                start();
              }
              _lastCurIndex = _curIdx;
            }
            return false;
          },
          child: Stack(
            children: [
              Positioned(
                left: 0,
                bottom: _playerY,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: Container(
                  color: Colors.black,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: AliPlayerView(
                    onCreated: onViewPlayerCreated,
                    x: 0,
                    y: _playerY,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                  ),
                ),
              ),
              SmartRefresher(
                enablePullDown: true,
                enablePullUp: true,
                header: ClassicHeader(),
                footer: ClassicFooter(
                  loadStyle: LoadStyle.ShowWhenLoading,
                ),
                controller: _refreshController,
                onRefresh: _onRefresh,
                onLoading: _onLoadMore,
                child: CustomScrollView(
                  physics: PageScrollPhysics(),
                  controller: _pageController,
                  slivers: <Widget>[
                    SliverFillViewport(
                        delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        return _buildSingleScreen(index);
                      },
                      childCount: _dataList.length,
                    ))
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  _exitScreenMode();
                },
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Icon(
                      Icons.arrow_back_ios,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleScreen(int index) {
    VideoModel model = _dataList[index];
    return GestureDetector(
      onTap: () {
        setState(() {
          _isPause = !_isPause;
        });
        if (_isPause) {
          this.fAliListPlayer.pause();
        } else {
          this.fAliListPlayer.play();
        }
      },
      child: Container(
        // color: Colors.black,
        child: Stack(
          children: [
            Offstage(
              offstage: _curIdx == index && _isFirstRenderShow,
              child: Container(
                color: Colors.black,
                child: Image.network(
                  model.coverUrl,
                  // color:Colors.black,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            Container(
              color: Colors.black.withAlpha(0),
              alignment: Alignment.center,
              child: Offstage(
                offstage: _isPause == false || _isBackgroundMode == true,
                child: Icon(
                  Icons.play_circle_filled,
                  size: 48,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _showMode == VideoShowMode.Srceen
        ? _buildFullScreenView()
        : _buildGridView();
  }

  void onViewPlayerCreated(viewId) async {
    print('onViewPlayerCreated===');
    fAliListPlayer.setPlayerView(viewId);
  }

  void start() async {
    if (_dataList != null &&
        _dataList.length > 0 &&
        _curIdx < _dataList.length) {
      VideoModel model = _dataList[_curIdx];
      setState(() {
        _isPause = false;
        _isFirstRenderShow = false;
      });
      this.fAliListPlayer.stop();
      if (widget.playMode == ModeType.URL) {
        this.fAliListPlayer.moveTo(uid: model.videoId);
      } else if (widget.playMode == ModeType.STS) {
        NetWorkUtils.instance.getHttp(HttpConstant.GET_STS,
            successCallback: (data) {
          this.fAliListPlayer.moveTo(
              uid: model.videoId,
              accId: data["accessKeyId"],
              accKey: data["accessKeySecret"],
              token: data["securityToken"],
              region: DataSourceRelated.DEFAULT_REGION);
          print('========${model.videoId}');
        }, errorCallback: (error) {
          print("error");
        });
      }
    }
  }

  void _exitScreenMode() {
    setState(() {
      _showMode = VideoShowMode.Grid;
    });
    this.fAliListPlayer.stop();
  }
}
