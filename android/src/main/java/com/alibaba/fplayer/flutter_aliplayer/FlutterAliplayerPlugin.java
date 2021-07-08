package com.alibaba.fplayer.flutter_aliplayer;

import android.content.Context;
import android.os.Build;
import android.text.TextUtils;

import androidx.annotation.NonNull;

import com.aliyun.player.AliPlayerFactory;
import com.aliyun.private_service.PrivateService;
import com.cicada.player.utils.Logger;

import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

/**
 * FlutterAliplayerPlugin
 */
public class FlutterAliplayerPlugin extends PlatformViewFactory implements FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler, FlutterAliPlayerView.FlutterAliPlayerViewListener {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private FlutterAliDownloader mAliyunDownload;
    private FlutterPluginBinding flutterPluginBinding;
    private FlutterAliListPlayer mFlutterAliListPlayer;
    private Map<String,FlutterAliPlayer> mFlutterAliPlayerMap = new HashMap<>();
    private Map<Integer, FlutterAliPlayerView> mFlutterAliPlayerViewMap = new HashMap<>();
    private EventChannel.EventSink mEventSink;
    private EventChannel mEventChannel;
    private Integer playerType = -1;

    public FlutterAliplayerPlugin() {
        super(StandardMessageCodec.INSTANCE);
    }


    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        this.flutterPluginBinding = flutterPluginBinding;
        flutterPluginBinding.getPlatformViewRegistry().registerViewFactory("flutter_aliplayer_render_view", this);
        mAliyunDownload = new FlutterAliDownloader(flutterPluginBinding.getApplicationContext(), flutterPluginBinding);
        MethodChannel mAliPlayerFactoryMethodChannel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "plugins.flutter_aliplayer_factory");
        mAliPlayerFactoryMethodChannel.setMethodCallHandler(this);
        mEventChannel = new EventChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), "flutter_aliplayer_event");
        mEventChannel.setStreamHandler(this);
    }

    //   This static function is optional and equivalent to onAttachedToEngine. It supports the old
//   pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
//   plugin registration via this function while apps migrate to use the new Android APIs
//   post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
//
//   It is encouraged to share logic between onAttachedToEngine and registerWith to keep
//   them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
//   depending on the user's project. onAttachedToEngine or registerWith must both be defined
//   in the same class.
    public static void registerWith(Registrar registrar) {
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case "createAliPlayer":
                playerType = call.argument("arg");
                if(0 == playerType){
                    //AliPlayer
                    String createPlayerId = call.argument("playerId");
                    FlutterAliPlayer flutterAliPlayer = new FlutterAliPlayer(flutterPluginBinding,createPlayerId);
                    initListener(flutterAliPlayer);
                    mFlutterAliPlayerMap.put(createPlayerId,flutterAliPlayer);
                }else if(1 == playerType){
                    //AliListPlayer
                    mFlutterAliListPlayer = new FlutterAliListPlayer(flutterPluginBinding);
                    initListener(mFlutterAliListPlayer);
                }else{

                }

                result.success(null);
                break;
            case "initService":
                byte[] datas = (byte[]) call.arguments;
                PrivateService.initService(flutterPluginBinding.getApplicationContext(),datas);
                break;
            case "getSDKVersion":
                result.success(AliPlayerFactory.getSdkVersion());
                break;
            case "getLogLevel":
                result.success(getLogLevel());
                break;
            case "enableConsoleLog":
                Boolean enableLog = (Boolean) call.argument("arg");
                enableConsoleLog(enableLog);
                break;
            case "setLogLevel":
                Integer level = (Integer) call.argument("arg");
                setLogLevel(level);
                break;
            case "createDeviceInfo":
                result.success(createDeviceInfo());
                break;
            case "addBlackDevice":
                Map<String,String> addBlackDeviceMap = call.arguments();
                String blackType = addBlackDeviceMap.get("black_type");
                String blackDevice = addBlackDeviceMap.get("black_device");
                addBlackDevice(blackType,blackDevice);
                break;
            case "setPlayerView":
                Integer viewId = (Integer) call.argument("arg");
                FlutterAliPlayerView flutterAliPlayerView = mFlutterAliPlayerViewMap.get(viewId);
                if(playerType == 0){
                    String setPlayerViewPlayerId = call.argument("playerId");
                    FlutterAliPlayer mSetPlayerViewCurrentFlutterAliPlayer = mFlutterAliPlayerMap.get(setPlayerViewPlayerId);
//                    if(mSetPlayerViewCurrentFlutterAliPlayer != null){
//                        mSetPlayerViewCurrentFlutterAliPlayer.setViewMap(mFlutterAliPlayerViewMap);
//                    }
                    if(flutterAliPlayerView != null && mSetPlayerViewCurrentFlutterAliPlayer != null){
                        flutterAliPlayerView.setPlayer(mSetPlayerViewCurrentFlutterAliPlayer.getAliPlayer());
                    }
                }else if(playerType == 1){
//                    mFlutterAliListPlayer.setViewMap(mFlutterAliPlayerViewMap);
                    if(flutterAliPlayerView != null && mFlutterAliListPlayer != null){
                        flutterAliPlayerView.setPlayer(mFlutterAliListPlayer.getAliPlayer());
                    }
                }

            default:
                if(playerType == 0){
                    String playerId = call.argument("playerId");
                    FlutterAliPlayer mCurrentFlutterAliPlayer = mFlutterAliPlayerMap.get(playerId);
                    if(call.method.equals("destroy")){
                        mFlutterAliPlayerMap.remove(playerId);
                    }
                    if(mCurrentFlutterAliPlayer != null){
                        mCurrentFlutterAliPlayer.onMethodCall(call,result);
                    }
                }else if(playerType == 1){
                    mFlutterAliListPlayer.onMethodCall(call,result);
                }

                break;
        }
    }

    private Integer getLogLevel(){
        return Logger.getInstance(flutterPluginBinding.getApplicationContext()).getLogLevel().getValue();
    }

    private String createDeviceInfo(){
        AliPlayerFactory.DeviceInfo deviceInfo = new AliPlayerFactory.DeviceInfo();
        deviceInfo.model = Build.MODEL;
        return deviceInfo.model;
    }

    private void addBlackDevice(String blackType,String modelInfo){
        AliPlayerFactory.DeviceInfo deviceInfo = new AliPlayerFactory.DeviceInfo();
        deviceInfo.model = modelInfo;
        AliPlayerFactory.BlackType aliPlayerBlackType;
        if(!TextUtils.isEmpty(blackType) && blackType.equals("HW_Decode_H264")){
            aliPlayerBlackType = AliPlayerFactory.BlackType.HW_Decode_H264;
        }else{
            aliPlayerBlackType = AliPlayerFactory.BlackType.HW_Decode_HEVC;
        }
        AliPlayerFactory.addBlackDevice(aliPlayerBlackType,deviceInfo);
    }

    private void enableConsoleLog(Boolean enableLog){
        Logger.getInstance(flutterPluginBinding.getApplicationContext()).enableConsoleLog(enableLog);
    }

    private void setLogLevel(int level){
        Logger.LogLevel mLogLevel;
        if(level == Logger.LogLevel.AF_LOG_LEVEL_NONE.getValue()){
            mLogLevel = Logger.LogLevel.AF_LOG_LEVEL_NONE;
        }else if(level == Logger.LogLevel.AF_LOG_LEVEL_FATAL.getValue()){
            mLogLevel = Logger.LogLevel.AF_LOG_LEVEL_FATAL;
        }else if(level == Logger.LogLevel.AF_LOG_LEVEL_ERROR.getValue()){
            mLogLevel = Logger.LogLevel.AF_LOG_LEVEL_ERROR;
        }else if(level == Logger.LogLevel.AF_LOG_LEVEL_WARNING.getValue()){
            mLogLevel = Logger.LogLevel.AF_LOG_LEVEL_WARNING;
        }else if(level == Logger.LogLevel.AF_LOG_LEVEL_INFO.getValue()){
            mLogLevel = Logger.LogLevel.AF_LOG_LEVEL_INFO;
        }else if(level == Logger.LogLevel.AF_LOG_LEVEL_DEBUG.getValue()){
            mLogLevel = Logger.LogLevel.AF_LOG_LEVEL_DEBUG;
        }else if(level == Logger.LogLevel.AF_LOG_LEVEL_TRACE.getValue()){
            mLogLevel = Logger.LogLevel.AF_LOG_LEVEL_TRACE;
        }else{
            mLogLevel = Logger.LogLevel.AF_LOG_LEVEL_NONE;
        }
        Logger.getInstance(flutterPluginBinding.getApplicationContext()).setLogLevel(mLogLevel);
    }

    /**
     * 设置监听
     */
    private void initListener(FlutterAliPlayer flutterAliPlayer) {
        flutterAliPlayer.setOnFlutterListener(new FlutterAliPlayerListener() {
            @Override
            public void onPrepared(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onTrackReady(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onCompletion(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onRenderingStart(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onVideoSizeChanged(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onSnapShot(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onTrackChangedSuccess(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onTrackChangedFail(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onSeekComplete(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onSeiData(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onLoadingBegin(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onLoadingProgress(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onLoadingEnd(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onStateChanged(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onSubtitleExtAdded(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onSubtitleShow(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onSubtitleHide(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onInfo(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onError(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onThumbnailPrepareSuccess(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onThumbnailPrepareFail(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onThumbnailGetSuccess(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onThumbnailGetFail(Map<String, Object> map) {
                mEventSink.success(map);
            }
        });
    }

    /**
     * 设置监听
     */
    private void initListener(FlutterAliListPlayer flutterAliPlayer) {
        flutterAliPlayer.setOnFlutterListener(new FlutterAliPlayerListener() {
            @Override
            public void onPrepared(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onTrackReady(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onCompletion(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onRenderingStart(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onVideoSizeChanged(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onSnapShot(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onTrackChangedSuccess(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onTrackChangedFail(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onSeekComplete(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onSeiData(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onLoadingBegin(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onLoadingProgress(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onLoadingEnd(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onStateChanged(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onSubtitleExtAdded(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onSubtitleShow(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onSubtitleHide(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onInfo(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onError(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onThumbnailPrepareSuccess(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onThumbnailPrepareFail(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onThumbnailGetSuccess(Map<String, Object> map) {
                mEventSink.success(map);
            }

            @Override
            public void onThumbnailGetFail(Map<String, Object> map) {
                mEventSink.success(map);
            }
        });
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    }

    @Override
    public PlatformView create(Context context, int viewId, Object args) {
        FlutterAliPlayerView flutterAliPlayerView = new FlutterAliPlayerView(context,viewId);
        flutterAliPlayerView.setFlutterAliPlayerViewListener(this);
        mFlutterAliPlayerViewMap.put(viewId,flutterAliPlayerView);
        return flutterAliPlayerView;
    }

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        this.mEventSink = events;
    }

    @Override
    public void onCancel(Object arguments) {
    }

    @Override
    public void onDispose(int viewId) {
        mFlutterAliPlayerViewMap.remove(viewId);
    }
}
