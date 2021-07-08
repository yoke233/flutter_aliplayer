package com.alibaba.fplayer.flutter_aliplayer;

import android.content.Context;
import android.graphics.Bitmap;
import android.text.TextUtils;

import com.aliyun.player.AliPlayer;
import com.aliyun.player.AliPlayerFactory;
import com.aliyun.player.IPlayer;
import com.aliyun.player.VidPlayerConfigGen;
import com.aliyun.player.bean.ErrorInfo;
import com.aliyun.player.bean.InfoBean;
import com.aliyun.player.nativeclass.CacheConfig;
import com.aliyun.player.nativeclass.MediaInfo;
import com.aliyun.player.nativeclass.PlayerConfig;
import com.aliyun.player.nativeclass.Thumbnail;
import com.aliyun.player.nativeclass.TrackInfo;
import com.aliyun.player.source.Definition;
import com.aliyun.player.source.UrlSource;
import com.aliyun.player.source.VidAuth;
import com.aliyun.player.source.VidMps;
import com.aliyun.player.source.VidSts;
import com.aliyun.thumbnail.ThumbnailBitmapInfo;
import com.aliyun.thumbnail.ThumbnailHelper;
import com.aliyun.utils.ThreadManager;
import com.google.gson.Gson;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class FlutterAliPlayer {

    private final Gson mGson;
    private Context mContext;
    private String mSnapShotPath;
    private ThumbnailHelper mThumbnailHelper;
    private AliPlayer mAliPlayer;
    private String mPlayerId;
    private FlutterAliPlayerListener mFlutterAliPlayerListener;

    public FlutterAliPlayer(FlutterPlugin.FlutterPluginBinding flutterPluginBinding,String playerId) {
        this.mPlayerId = playerId;
//        this.mFlutterPluginBinding = flutterPluginBinding;
        this.mContext = flutterPluginBinding.getApplicationContext();
        mGson = new Gson();
        mAliPlayer = AliPlayerFactory.createAliPlayer(mContext);
        initListener(mAliPlayer);
    }

    public void setOnFlutterListener(FlutterAliPlayerListener listener){
        this.mFlutterAliPlayerListener = listener;
    }

    private void initListener(final IPlayer player){
        player.setOnPreparedListener(new IPlayer.OnPreparedListener() {
            @Override
            public void onPrepared() {
                Map<String,Object> map = new HashMap<>();
                map.put("method","onPrepared");
                map.put("playerId",mPlayerId);
//                mEventSink.success(map);
                if(mFlutterAliPlayerListener != null){
                    mFlutterAliPlayerListener.onPrepared(map);
                }
            }
        });

        player.setOnRenderingStartListener(new IPlayer.OnRenderingStartListener() {
            @Override
            public void onRenderingStart() {
                Map<String,Object> map = new HashMap<>();
                map.put("method","onRenderingStart");
                map.put("playerId",mPlayerId);
//                mEventSink.success(map);
                if(mFlutterAliPlayerListener != null){
                    mFlutterAliPlayerListener.onRenderingStart(map);
                }
            }
        });

        player.setOnVideoSizeChangedListener(new IPlayer.OnVideoSizeChangedListener() {
            @Override
            public void onVideoSizeChanged(int width, int height) {
                Map<String,Object> map = new HashMap<>();
                map.put("method","onVideoSizeChanged");
                map.put("width",width);
                map.put("height",height);
                map.put("playerId",mPlayerId);
//                mEventSink.success(map);
                if(mFlutterAliPlayerListener != null){
                    mFlutterAliPlayerListener.onVideoSizeChanged(map);
                }
            }
        });

        player.setOnSnapShotListener(new IPlayer.OnSnapShotListener() {
            @Override
            public void onSnapShot(final Bitmap bitmap, int width, int height) {
                final Map<String,Object> map = new HashMap<>();
                map.put("method","onSnapShot");
                map.put("snapShotPath",mSnapShotPath);
                map.put("playerId",mPlayerId);

                ThreadManager.threadPool.execute(new Runnable() {
                    @Override
                    public void run() {
                        File f = new File(mSnapShotPath);
                        FileOutputStream out = null;
                        if (f.exists()) {
                            f.delete();
                        }
                        try {
                            out = new FileOutputStream(f);
                            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out);
                            out.flush();
                            out.close();
                        } catch (FileNotFoundException e) {
                            e.printStackTrace();
                        } catch (IOException e) {
                            e.printStackTrace();
                        }finally{
                            if(out != null){
                                try {
                                    out.close();
                                } catch (IOException e) {
                                    e.printStackTrace();
                                }
                            }
                        }
                    }
                });

                if(mFlutterAliPlayerListener != null){
                    mFlutterAliPlayerListener.onSnapShot(map);
                }

//                mEventSink.success(map);

            }
        });

        player.setOnTrackChangedListener(new IPlayer.OnTrackChangedListener() {
            @Override
            public void onChangedSuccess(TrackInfo trackInfo) {
                Map<String,Object> map = new HashMap<>();
                map.put("method","onTrackChanged");
                map.put("playerId",mPlayerId);
                Map<String,Object> infoMap = new HashMap<>();
                infoMap.put("vodFormat",trackInfo.getVodFormat());
                infoMap.put("videoHeight",trackInfo.getVideoHeight());
                infoMap.put("videoWidth",trackInfo.getVideoHeight());
                infoMap.put("subtitleLanguage",trackInfo.getSubtitleLang());
                infoMap.put("trackBitrate",trackInfo.getVideoBitrate());
                infoMap.put("vodFileSize",trackInfo.getVodFileSize());
                infoMap.put("trackIndex",trackInfo.getIndex());
                infoMap.put("trackDefinition",trackInfo.getVodDefinition());
                infoMap.put("audioSampleFormat",trackInfo.getAudioSampleFormat());
                infoMap.put("audioLanguage",trackInfo.getAudioLang());
                infoMap.put("vodPlayUrl",trackInfo.getVodPlayUrl());
                infoMap.put("trackType",trackInfo.getType().ordinal());
                infoMap.put("audioSamplerate",trackInfo.getAudioSampleRate());
                infoMap.put("audioChannels",trackInfo.getAudioChannels());
                map.put("info",infoMap);
//                mEventSink.success(map);
                if(mFlutterAliPlayerListener != null){
                    mFlutterAliPlayerListener.onTrackChangedSuccess(map);
                }
            }

            @Override
            public void onChangedFail(TrackInfo trackInfo, ErrorInfo errorInfo) {
                Map<String,Object> map = new HashMap<>();
                map.put("method","onChangedFail");
                map.put("playerId",mPlayerId);
//                mEventSink.success(map);
                if(mFlutterAliPlayerListener != null){
                    mFlutterAliPlayerListener.onTrackChangedFail(map);
                }
            }
        });

        player.setOnSeekCompleteListener(new IPlayer.OnSeekCompleteListener() {
            @Override
            public void onSeekComplete() {
                Map<String,Object> map = new HashMap<>();
                map.put("method","onSeekComplete");
                map.put("playerId",mPlayerId);
//                mEventSink.success(map);
                if(mFlutterAliPlayerListener != null){
                    mFlutterAliPlayerListener.onSeekComplete(map);
                }
            }
        });

        player.setOnSeiDataListener(new IPlayer.OnSeiDataListener() {
            @Override
            public void onSeiData(int type, byte[] bytes) {
                Map<String,Object> map = new HashMap<>();
                map.put("method","onSeiData");
                map.put("playerId",mPlayerId);
                //TODO
//                mEventSink.success(map);
                if(mFlutterAliPlayerListener != null){
                    mFlutterAliPlayerListener.onSeiData(map);
                }
            }
        });

        player.setOnLoadingStatusListener(new IPlayer.OnLoadingStatusListener() {
            @Override
            public void onLoadingBegin() {
                Map<String,Object> map = new HashMap<>();
                map.put("method","onLoadingBegin");
                map.put("playerId",mPlayerId);
//                mEventSink.success(map);
                if(mFlutterAliPlayerListener != null){
                    mFlutterAliPlayerListener.onLoadingBegin(map);
                }
            }

            @Override
            public void onLoadingProgress(int percent, float netSpeed) {
                Map<String,Object> map = new HashMap<>();
                map.put("method","onLoadingProgress");
                map.put("percent",percent);
                map.put("netSpeed",netSpeed);
                map.put("playerId",mPlayerId);
//                mEventSink.success(map);
                if(mFlutterAliPlayerListener != null){
                    mFlutterAliPlayerListener.onLoadingProgress(map);
                }
            }

            @Override
            public void onLoadingEnd() {
                Map<String,Object> map = new HashMap<>();
                map.put("method","onLoadingEnd");
                map.put("playerId",mPlayerId);
//                mEventSink.success(map);
                if(mFlutterAliPlayerListener != null){
                    mFlutterAliPlayerListener.onLoadingEnd(map);
                }
            }
        });

        player.setOnStateChangedListener(new IPlayer.OnStateChangedListener() {
            @Override
            public void onStateChanged(int newState) {
                Map<String,Object> map = new HashMap<>();
                map.put("method","onStateChanged");
                map.put("newState",newState);
                map.put("playerId",mPlayerId);
//                mEventSink.success(map);
                if(mFlutterAliPlayerListener != null){
                    mFlutterAliPlayerListener.onStateChanged(map);
                }
            }
        });

        player.setOnSubtitleDisplayListener(new IPlayer.OnSubtitleDisplayListener() {
            @Override
            public void onSubtitleExtAdded(int trackIndex, String url) {
                Map<String,Object> map = new HashMap<>();
                map.put("method","onSubtitleExtAdded");
                map.put("trackIndex",trackIndex);
                map.put("url",url);
                map.put("playerId",mPlayerId);
//                mEventSink.success(map);
                if(mFlutterAliPlayerListener != null){
                    mFlutterAliPlayerListener.onSubtitleExtAdded(map);
                }
            }

            @Override
            public void onSubtitleShow(int trackIndex, long id, String data) {
                Map<String,Object> map = new HashMap<>();
                map.put("method","onSubtitleShow");
                map.put("trackIndex",trackIndex);
                map.put("subtitleID",id);
                map.put("subtitle",data);
                map.put("playerId",mPlayerId);
//                mEventSink.success(map);
                if(mFlutterAliPlayerListener != null){
                    mFlutterAliPlayerListener.onSubtitleShow(map);
                }
            }

            @Override
            public void onSubtitleHide(int trackIndex, long id) {
                Map<String,Object> map = new HashMap<>();
                map.put("method","onSubtitleHide");
                map.put("trackIndex",trackIndex);
                map.put("subtitleID",id);
                map.put("playerId",mPlayerId);
//                mEventSink.success(map);
                if(mFlutterAliPlayerListener != null){
                    mFlutterAliPlayerListener.onSubtitleHide(map);
                }
            }
        });

        player.setOnInfoListener(new IPlayer.OnInfoListener() {
            @Override
            public void onInfo(InfoBean infoBean) {
                Map<String,Object> map = new HashMap<>();
                map.put("method","onInfo");
                map.put("infoCode",infoBean.getCode().getValue());
                map.put("extraValue",infoBean.getExtraValue());
                map.put("extraMsg",infoBean.getExtraMsg());
                map.put("playerId",mPlayerId);
//                mEventSink.success(map);
                if(mFlutterAliPlayerListener != null){
                    mFlutterAliPlayerListener.onInfo(map);
                }
            }
        });

        player.setOnErrorListener(new IPlayer.OnErrorListener() {
            @Override
            public void onError(ErrorInfo errorInfo) {
                Map<String,Object> map = new HashMap<>();
                map.put("method","onError");
                map.put("errorCode",errorInfo.getCode().getValue());
                map.put("errorExtra",errorInfo.getExtra());
                map.put("errorMsg",errorInfo.getMsg());
                map.put("playerId",mPlayerId);
//                mEventSink.success(map);
                if(mFlutterAliPlayerListener != null){
                    mFlutterAliPlayerListener.onError(map);
                }
            }
        });

        player.setOnTrackReadyListener(new IPlayer.OnTrackReadyListener() {
            @Override
            public void onTrackReady(MediaInfo mediaInfo) {
                Map<String,Object> map = new HashMap<>();
                map.put("method","onTrackReady");
                map.put("playerId",mPlayerId);
//                mEventSink.success(map);
                if(mFlutterAliPlayerListener != null){
                    mFlutterAliPlayerListener.onTrackReady(map);
                }
            }
        });

        player.setOnCompletionListener(new IPlayer.OnCompletionListener() {
            @Override
            public void onCompletion() {
                Map<String,Object> map = new HashMap<>();
                map.put("method","onCompletion");
                map.put("playerId",mPlayerId);
//                mEventSink.success(map);
                if(mFlutterAliPlayerListener != null){
                    mFlutterAliPlayerListener.onCompletion(map);
                }
            }
        });

    }

    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
        switch (methodCall.method) {
            case "setUrl":
                String url = methodCall.argument("arg");
                setDataSource(mAliPlayer,url);
                result.success(null);
                break;
            case "setPlayerView":
//                Integer viewId = (Integer) methodCall.argument("arg");
//                FlutterAliPlayerView flutterAliPlayerView = mFlutterAliPlayerViewMap.get(viewId);
//                if(flutterAliPlayerView != null){
//                    flutterAliPlayerView.setPlayer(mAliPlayer);
//                }
                break;
            case "setVidSts":
                Map<String,Object> stsMap = (Map<String,Object>)methodCall.argument("arg");
                VidSts vidSts = new VidSts();
                vidSts.setRegion((String) stsMap.get("region"));
                vidSts.setVid((String) stsMap.get("vid"));
                vidSts.setAccessKeyId((String) stsMap.get("accessKeyId"));
                vidSts.setAccessKeySecret((String) stsMap.get("accessKeySecret"));
                vidSts.setSecurityToken((String) stsMap.get("securityToken"));

                List<String> stsMaplist = (List<String>) stsMap.get("definitionList");
                if(stsMaplist != null){
                    List<Definition> definitionList = new ArrayList<>();
                    for (String item : stsMaplist) {
                        if(Definition.DEFINITION_AUTO.getName().equals(item)){
                            definitionList.add(Definition.DEFINITION_AUTO);
                        }else{
                            if(Definition.DEFINITION_FD.getName().equals(item)){
                                definitionList.add(Definition.DEFINITION_FD);
                            }else if(Definition.DEFINITION_LD.getName().equals(item)){
                                definitionList.add(Definition.DEFINITION_LD);
                            }else if(Definition.DEFINITION_SD.getName().equals(item)){
                                definitionList.add(Definition.DEFINITION_SD);
                            }else if(Definition.DEFINITION_HD.getName().equals(item)){
                                definitionList.add(Definition.DEFINITION_HD);
                            }else if(Definition.DEFINITION_OD.getName().equals(item)){
                                definitionList.add(Definition.DEFINITION_OD);
                            }else if(Definition.DEFINITION_2K.getName().equals(item)){
                                definitionList.add(Definition.DEFINITION_2K);
                            }else if(Definition.DEFINITION_4K.getName().equals(item)){
                                definitionList.add(Definition.DEFINITION_4K);
                            }else if(Definition.DEFINITION_SQ.getName().equals(item)){
                                definitionList.add(Definition.DEFINITION_SQ);
                            }else if(Definition.DEFINITION_HQ.getName().equals(item)){
                                definitionList.add(Definition.DEFINITION_HQ);
                            }
                        }
                    }
                    vidSts.setDefinition(definitionList);
                }

                if(stsMap.containsKey("previewTime") && !TextUtils.isEmpty((CharSequence) stsMap.get("previewTime"))){
                    VidPlayerConfigGen vidPlayerConfigGen = new VidPlayerConfigGen();
                    int previewTime = Integer.valueOf((String)stsMap.get("previewTime"));
                    vidPlayerConfigGen.setPreviewTime(previewTime);
                    vidSts.setPlayConfig(vidPlayerConfigGen);
                }
                setDataSource(mAliPlayer,vidSts);
                break;
            case "setVidAuth":
                Map<String,Object> authMap = (Map<String,Object>)methodCall.argument("arg");
                VidAuth vidAuth = new VidAuth();
                vidAuth.setVid((String) authMap.get("vid"));
                vidAuth.setRegion((String) authMap.get("region"));
                vidAuth.setPlayAuth((String) authMap.get("playAuth"));

                List<String> authMaplist = (List<String>) authMap.get("definitionList");
                if(authMaplist != null){
                    List<Definition> definitionList = new ArrayList<>();
                    for (String item : authMaplist) {
                        if(Definition.DEFINITION_AUTO.getName().equals(item)){
                            definitionList.add(Definition.DEFINITION_AUTO);
                        }else{
                            if(Definition.DEFINITION_FD.getName().equals(item)){
                                definitionList.add(Definition.DEFINITION_FD);
                            }else if(Definition.DEFINITION_LD.getName().equals(item)){
                                definitionList.add(Definition.DEFINITION_LD);
                            }else if(Definition.DEFINITION_SD.getName().equals(item)){
                                definitionList.add(Definition.DEFINITION_SD);
                            }else if(Definition.DEFINITION_HD.getName().equals(item)){
                                definitionList.add(Definition.DEFINITION_HD);
                            }else if(Definition.DEFINITION_OD.getName().equals(item)){
                                definitionList.add(Definition.DEFINITION_OD);
                            }else if(Definition.DEFINITION_2K.getName().equals(item)){
                                definitionList.add(Definition.DEFINITION_2K);
                            }else if(Definition.DEFINITION_4K.getName().equals(item)){
                                definitionList.add(Definition.DEFINITION_4K);
                            }else if(Definition.DEFINITION_SQ.getName().equals(item)){
                                definitionList.add(Definition.DEFINITION_SQ);
                            }else if(Definition.DEFINITION_HQ.getName().equals(item)){
                                definitionList.add(Definition.DEFINITION_HQ);
                            }
                        }
                    }
                    vidAuth.setDefinition(definitionList);
                }

                if(authMap.containsKey("previewTime") && !TextUtils.isEmpty((String) authMap.get("previewTime"))){
                    VidPlayerConfigGen vidPlayerConfigGen = new VidPlayerConfigGen();
                    int previewTime = Integer.valueOf((String) authMap.get("previewTime"));
                    vidPlayerConfigGen.setPreviewTime(previewTime);
                    vidAuth.setPlayConfig(vidPlayerConfigGen);
                }
                setDataSource(mAliPlayer,vidAuth);
                break;
            case "setVidMps":
                Map<String,Object> mpsMap = (Map<String,Object>)methodCall.argument("arg");
                VidMps vidMps = new VidMps();
                vidMps.setMediaId((String) mpsMap.get("vid"));
                vidMps.setRegion((String) mpsMap.get("region"));
                vidMps.setAccessKeyId((String) mpsMap.get("accessKeyId"));
                vidMps.setAccessKeySecret((String) mpsMap.get("accessKeySecret"));

                List<String> mpsMaplist = (List<String>) mpsMap.get("definitionList");
                if(mpsMaplist != null){
                    List<Definition> definitionList = new ArrayList<>();
                    for (String item : mpsMaplist) {
                        if(Definition.DEFINITION_AUTO.getName().equals(item)){
                            definitionList.add(Definition.DEFINITION_AUTO);
                        }else{
                            if(Definition.DEFINITION_FD.getName().equals(item)){
                                definitionList.add(Definition.DEFINITION_FD);
                            }else if(Definition.DEFINITION_LD.getName().equals(item)){
                                definitionList.add(Definition.DEFINITION_LD);
                            }else if(Definition.DEFINITION_SD.getName().equals(item)){
                                definitionList.add(Definition.DEFINITION_SD);
                            }else if(Definition.DEFINITION_HD.getName().equals(item)){
                                definitionList.add(Definition.DEFINITION_HD);
                            }else if(Definition.DEFINITION_OD.getName().equals(item)){
                                definitionList.add(Definition.DEFINITION_OD);
                            }else if(Definition.DEFINITION_2K.getName().equals(item)){
                                definitionList.add(Definition.DEFINITION_2K);
                            }else if(Definition.DEFINITION_4K.getName().equals(item)){
                                definitionList.add(Definition.DEFINITION_4K);
                            }else if(Definition.DEFINITION_SQ.getName().equals(item)){
                                definitionList.add(Definition.DEFINITION_SQ);
                            }else if(Definition.DEFINITION_HQ.getName().equals(item)){
                                definitionList.add(Definition.DEFINITION_HQ);
                            }
                        }
                    }
                    vidMps.setDefinition(definitionList);
                }

                if(mpsMap.containsKey("playDomain") && !TextUtils.isEmpty((String) mpsMap.get("playDomain"))){
                    vidMps.setPlayDomain((String) mpsMap.get("playDomain"));
                }
                vidMps.setAuthInfo((String) mpsMap.get("authInfo"));
                vidMps.setHlsUriToken((String) mpsMap.get("hlsUriToken"));
                vidMps.setSecurityToken((String) mpsMap.get("securityToken"));
                setDataSource(mAliPlayer,vidMps);
                break;
            case "prepare":
                prepare(mAliPlayer);
                break;
            case "play":
                start(mAliPlayer);
                break;
            case "pause":
                pause(mAliPlayer);
                break;
            case "stop":
                stop(mAliPlayer);
                break;
            case "destroy":
                release(mAliPlayer);
                break;
            case "seekTo":
            {
                Map<String,Object> seekToMap = (Map<String,Object>)methodCall.argument("arg");
                Integer position = (Integer) seekToMap.get("position");
                Integer seekMode = (Integer) seekToMap.get("seekMode");
                seekTo(mAliPlayer,position,seekMode);
            }
            break;
            case "getMediaInfo":
            {
                MediaInfo mediaInfo = getMediaInfo(mAliPlayer);
                if(mediaInfo != null){
                    Map<String,Object> getMediaInfoMap = new HashMap<>();
                    getMediaInfoMap.put("title",mediaInfo.getTitle());
                    getMediaInfoMap.put("status",mediaInfo.getStatus());
                    getMediaInfoMap.put("mediaType",mediaInfo.getMediaType());
                    getMediaInfoMap.put("duration",mediaInfo.getDuration());
                    getMediaInfoMap.put("transcodeMode",mediaInfo.getTransCodeMode());
                    getMediaInfoMap.put("coverURL",mediaInfo.getCoverUrl());
                    List<Thumbnail> thumbnail = mediaInfo.getThumbnailList();
                    List<Map<String,Object>> thumbailList = new ArrayList<>();
                    for (Thumbnail thumb : thumbnail) {
                        Map<String,Object> map = new HashMap<>();
                        map.put("url",thumb.mURL);
                        thumbailList.add(map);
                        getMediaInfoMap.put("thumbnails",thumbailList);
                    }
                    List<TrackInfo> trackInfos = mediaInfo.getTrackInfos();
                    List<Map<String,Object>> trackInfoList = new ArrayList<>();
                    for (TrackInfo trackInfo : trackInfos) {
                        Map<String,Object> map = new HashMap<>();
                        map.put("vodFormat",trackInfo.getVodFormat());
                        map.put("videoHeight",trackInfo.getVideoHeight());
                        map.put("videoWidth",trackInfo.getVideoHeight());
                        map.put("subtitleLanguage",trackInfo.getSubtitleLang());
                        map.put("trackBitrate",trackInfo.getVideoBitrate());
                        map.put("vodFileSize",trackInfo.getVodFileSize());
                        map.put("trackIndex",trackInfo.getIndex());
                        map.put("trackDefinition",trackInfo.getVodDefinition());
                        map.put("audioSampleFormat",trackInfo.getAudioSampleFormat());
                        map.put("audioLanguage",trackInfo.getAudioLang());
                        map.put("vodPlayUrl",trackInfo.getVodPlayUrl());
                        map.put("trackType",trackInfo.getType().ordinal());
                        map.put("audioSamplerate",trackInfo.getAudioSampleRate());
                        map.put("audioChannels",trackInfo.getAudioChannels());
                        trackInfoList.add(map);
                        getMediaInfoMap.put("tracks",trackInfoList);
                    }
                    result.success(getMediaInfoMap);
                }
            }
            break;
            case "snapshot":
                mSnapShotPath = methodCall.argument("arg").toString();
                snapshot(mAliPlayer);
                break;
            case "setLoop":
                setLoop(mAliPlayer,(Boolean)methodCall.argument("arg"));
                break;
            case "isLoop":
                result.success(isLoop(mAliPlayer));
                break;
            case "setAutoPlay":
                setAutoPlay(mAliPlayer,(Boolean)methodCall.argument("arg"));
                break;
            case "isAutoPlay":
                result.success(isAutoPlay(mAliPlayer));
                break;
            case "setMuted":
                setMuted(mAliPlayer,(Boolean)methodCall.argument("arg"));
                break;
            case "isMuted":
                result.success(isMuted(mAliPlayer));
                break;
            case "setEnableHardwareDecoder":
                Boolean setEnableHardwareDecoderArgumnt = (Boolean) methodCall.argument("arg");
                setEnableHardWareDecoder(mAliPlayer,setEnableHardwareDecoderArgumnt);
                break;
            case "setScalingMode":
                setScaleMode(mAliPlayer,(Integer) methodCall.argument("arg"));
                break;
            case "getScalingMode":
                result.success(getScaleMode(mAliPlayer));
                break;
            case "setMirrorMode":
                setMirrorMode(mAliPlayer,(Integer) methodCall.argument("arg"));
                break;
            case "getMirrorMode":
                result.success(getMirrorMode(mAliPlayer));
                break;
            case "setRotateMode":
                setRotateMode(mAliPlayer,(Integer) methodCall.argument("arg"));
                break;
            case "getRotateMode":
                result.success(getRotateMode(mAliPlayer));
                break;
            case "setRate":
                setSpeed(mAliPlayer,(Double) methodCall.argument("arg"));
                break;
            case "getRate":
                result.success(getSpeed(mAliPlayer));
                break;
            case "setVideoBackgroundColor":
                setVideoBackgroundColor(mAliPlayer,(Long) methodCall.argument("arg"));
                break;
            case "setVolume":
                setVolume(mAliPlayer,(Double) methodCall.argument("arg"));
                break;
            case "getVolume":
                result.success(getVolume(mAliPlayer));
                break;
            case "setConfig":
            {
                Map<String,Object> setConfigMap = (Map<String, Object>) methodCall.argument("arg");
                PlayerConfig config = getConfig(mAliPlayer);
                if(config != null){
                    String configJson = mGson.toJson(setConfigMap);
                    config = mGson.fromJson(configJson,PlayerConfig.class);
                    setConfig(mAliPlayer,config);
                }
            }
            break;
            case "getConfig":
                PlayerConfig config = getConfig(mAliPlayer);
                String json = mGson.toJson(config);
                Map<String,Object> configMap = mGson.fromJson(json,Map.class);
                result.success(configMap);
                break;
            case "getCacheConfig":
                CacheConfig cacheConfig = getCacheConfig();
                String cacheConfigJson = mGson.toJson(cacheConfig);
                Map<String,Object> cacheConfigMap = mGson.fromJson(cacheConfigJson,Map.class);
                result.success(cacheConfigMap);
                break;
            case "setCacheConfig":
                Map<String,Object> setCacheConnfigMap = (Map<String, Object>) methodCall.argument("arg");
                String setCacheConfigJson = mGson.toJson(setCacheConnfigMap);
                CacheConfig setCacheConfig = mGson.fromJson(setCacheConfigJson,CacheConfig.class);
                setCacheConfig(mAliPlayer,setCacheConfig);
                break;
            case "getCurrentTrack":
                Integer currentTrackIndex = (Integer) methodCall.argument("arg");
                TrackInfo currentTrack = getCurrentTrack(mAliPlayer,currentTrackIndex);
                if(currentTrack != null){
                    Map<String,Object> map = new HashMap<>();
                    map.put("vodFormat",currentTrack.getVodFormat());
                    map.put("videoHeight",currentTrack.getVideoHeight());
                    map.put("videoWidth",currentTrack.getVideoHeight());
                    map.put("subtitleLanguage",currentTrack.getSubtitleLang());
                    map.put("trackBitrate",currentTrack.getVideoBitrate());
                    map.put("vodFileSize",currentTrack.getVodFileSize());
                    map.put("trackIndex",currentTrack.getIndex());
                    map.put("trackDefinition",currentTrack.getVodDefinition());
                    map.put("audioSampleFormat",currentTrack.getAudioSampleFormat());
                    map.put("audioLanguage",currentTrack.getAudioLang());
                    map.put("vodPlayUrl",currentTrack.getVodPlayUrl());
                    map.put("trackType",currentTrack.getType().ordinal());
                    map.put("audioSamplerate",currentTrack.getAudioSampleRate());
                    map.put("audioChannels",currentTrack.getAudioChannels());
                    result.success(map);
                }
                break;
            case "selectTrack":
                Map<String,Object> selectTrackMap = (Map<String, Object>) methodCall.argument("arg");
                Integer trackIdx = (Integer) selectTrackMap.get("trackIdx");
                Integer accurate = (Integer) selectTrackMap.get("accurate");
                selectTrack(mAliPlayer,trackIdx, accurate == 1);
                break;
            case "addExtSubtitle":
                String extSubtitlUrl = (String) methodCall.argument("arg");
                addExtSubtitle(mAliPlayer,extSubtitlUrl);
                break;
            case "selectExtSubtitle":
                Map<String,Object> selectExtSubtitleMap = (Map<String, Object>) methodCall.argument("arg");
                Integer trackIndex = (Integer) selectExtSubtitleMap.get("trackIndex");
                Boolean selectExtSubtitlEnable = (Boolean) selectExtSubtitleMap.get("enable");
                selectExtSubtitle(mAliPlayer,trackIndex,selectExtSubtitlEnable);
                result.success(null);
                break;
            case "createThumbnailHelper":
                String thhumbnailUrl = (String) methodCall.argument("arg");
                createThumbnailHelper(thhumbnailUrl);
                break;
            case "requestBitmapAtPosition":
                Integer requestBitmapProgress = (Integer) methodCall.argument("arg");
                requestBitmapAtPosition(requestBitmapProgress);
                break;
            case "setPreferPlayerName":
                String playerName = methodCall.argument("arg");
                setPlayerName(mAliPlayer,playerName);
                break;
            case "getPlayerName":
                result.success(getPlayerName(mAliPlayer));
                break;
            case "setStreamDelayTime":
                Map<String,Object> streamDelayTimeMap = (Map<String, Object>) methodCall.argument("arg");
                Integer index = (Integer) streamDelayTimeMap.get("index");
                Integer time = (Integer) streamDelayTimeMap.get("time");
                setStreamDelayTime(mAliPlayer,index,time);
                break;
            default:
                result.notImplemented();
        }
    }

    public IPlayer getAliPlayer(){
        return mAliPlayer;
    }

    private void setDataSource(AliPlayer mAliPlayer,String url){
        if(mAliPlayer != null){
            UrlSource urlSource = new UrlSource();
            urlSource.setUri(url);
            ((AliPlayer)mAliPlayer).setDataSource(urlSource);
        }
    }

    private void setDataSource(AliPlayer mAliPlayer,VidSts vidSts){
        if(mAliPlayer != null){
            ((AliPlayer)mAliPlayer).setDataSource(vidSts);
        }
    }

    private void setDataSource(AliPlayer mAliPlayer,VidAuth vidAuth){
        if(mAliPlayer != null){
            ((AliPlayer)mAliPlayer).setDataSource(vidAuth);
        }
    }

    private void setDataSource(AliPlayer mAliPlayer,VidMps vidMps){
        if(mAliPlayer != null){
            ((AliPlayer)mAliPlayer).setDataSource(vidMps);
        }
    }

    private void prepare(AliPlayer mAliPlayer){
        if(mAliPlayer != null){
            mAliPlayer.prepare();
        }
    }

    private void start(AliPlayer mAliPlayer){
        if(mAliPlayer != null){
            mAliPlayer.start();
        }
    }

    private void pause(AliPlayer mAliPlayer){
        if(mAliPlayer != null){
            mAliPlayer.pause();
        }
    }

    private void stop(AliPlayer mAliPlayer){
        if(mAliPlayer != null){
            mAliPlayer.stop();
        }
    }

    private void release(AliPlayer mAliPlayer){
        if(mAliPlayer != null){
            mAliPlayer.release();
            mAliPlayer = null;
        }
    }

    private void seekTo(AliPlayer mAliPlayer,long position,int seekMode){
        if(mAliPlayer != null){
            IPlayer.SeekMode mSeekMode;
            if(seekMode == IPlayer.SeekMode.Accurate.getValue()){
                mSeekMode = IPlayer.SeekMode.Accurate;
            }else{
                mSeekMode = IPlayer.SeekMode.Inaccurate;
            }
            mAliPlayer.seekTo(position,mSeekMode);
        }
    }


    private MediaInfo getMediaInfo(AliPlayer mAliPlayer){
        if(mAliPlayer != null){
            return mAliPlayer.getMediaInfo();
        }
        return null;
    }

    private void snapshot(AliPlayer mAliPlayer){
        if(mAliPlayer != null){
            mAliPlayer.snapshot();
        }
    }

    private void setLoop(AliPlayer mAliPlayer,Boolean isLoop){
        if(mAliPlayer != null){
            mAliPlayer.setLoop(isLoop);
        }
    }

    private Boolean isLoop(AliPlayer mAliPlayer){
        return mAliPlayer != null && mAliPlayer.isLoop();
    }

    private void setAutoPlay(AliPlayer mAliPlayer,Boolean isAutoPlay){
        if(mAliPlayer != null){
            mAliPlayer.setAutoPlay(isAutoPlay);
        }
    }

    private Boolean isAutoPlay(AliPlayer mAliPlayer){
        if (mAliPlayer != null) {
            return mAliPlayer.isAutoPlay();
        }
        return false;
    }

    private void setMuted(AliPlayer mAliPlayer,Boolean muted){
        if(mAliPlayer != null){
            mAliPlayer.setMute(muted);
        }
    }

    private Boolean isMuted(AliPlayer mAliPlayer){
        if (mAliPlayer != null) {
            return mAliPlayer.isMute();
        }
        return false;
    }

    private void setEnableHardWareDecoder(AliPlayer mAliPlayer,Boolean mEnableHardwareDecoder){
        if(mAliPlayer != null){
            mAliPlayer.enableHardwareDecoder(mEnableHardwareDecoder);
        }
    }

    private void setScaleMode(AliPlayer mAliPlayer,int model){
        if(mAliPlayer != null){
            IPlayer.ScaleMode mScaleMode = IPlayer.ScaleMode.SCALE_ASPECT_FIT;
            if(model == IPlayer.ScaleMode.SCALE_ASPECT_FIT.getValue()){
                mScaleMode = IPlayer.ScaleMode.SCALE_ASPECT_FIT;
            }else if(model == IPlayer.ScaleMode.SCALE_ASPECT_FILL.getValue()){
                mScaleMode = IPlayer.ScaleMode.SCALE_ASPECT_FILL;
            }else if(model == IPlayer.ScaleMode.SCALE_TO_FILL.getValue()){
                mScaleMode = IPlayer.ScaleMode.SCALE_TO_FILL;
            }
            mAliPlayer.setScaleMode(mScaleMode);
        }
    }

    private int getScaleMode(AliPlayer mAliPlayer){
        int scaleMode = IPlayer.ScaleMode.SCALE_ASPECT_FIT.getValue();
        if (mAliPlayer != null) {
            scaleMode =  mAliPlayer.getScaleMode().getValue();
        }
        return scaleMode;
    }

    private void setMirrorMode(AliPlayer mAliPlayer,int mirrorMode){
        if(mAliPlayer != null){
            IPlayer.MirrorMode mMirrorMode;
            if(mirrorMode == IPlayer.MirrorMode.MIRROR_MODE_HORIZONTAL.getValue()){
                mMirrorMode = IPlayer.MirrorMode.MIRROR_MODE_HORIZONTAL;
            }else if(mirrorMode == IPlayer.MirrorMode.MIRROR_MODE_VERTICAL.getValue()){
                mMirrorMode = IPlayer.MirrorMode.MIRROR_MODE_VERTICAL;
            }else{
                mMirrorMode = IPlayer.MirrorMode.MIRROR_MODE_NONE;
            }
            mAliPlayer.setMirrorMode(mMirrorMode);
        }
    }

    private int getMirrorMode(AliPlayer mAliPlayer){
        int mirrorMode = IPlayer.MirrorMode.MIRROR_MODE_NONE.getValue();
        if (mAliPlayer != null) {
            mirrorMode = mAliPlayer.getMirrorMode().getValue();
        }
        return mirrorMode;
    }

    private void setRotateMode(AliPlayer mAliPlayer,int rotateMode){
        if(mAliPlayer != null){
            IPlayer.RotateMode mRotateMode;
            if(rotateMode == IPlayer.RotateMode.ROTATE_90.getValue()){
                mRotateMode = IPlayer.RotateMode.ROTATE_90;
            }else if(rotateMode == IPlayer.RotateMode.ROTATE_180.getValue()){
                mRotateMode = IPlayer.RotateMode.ROTATE_180;
            }else if(rotateMode == IPlayer.RotateMode.ROTATE_270.getValue()){
                mRotateMode = IPlayer.RotateMode.ROTATE_270;
            }else{
                mRotateMode = IPlayer.RotateMode.ROTATE_0;
            }
            mAliPlayer.setRotateMode(mRotateMode);
        }
    }

    private int getRotateMode(AliPlayer mAliPlayer){
        int rotateMode = IPlayer.RotateMode.ROTATE_0.getValue();
        if(mAliPlayer != null){
            rotateMode =  mAliPlayer.getRotateMode().getValue();
        }
        return rotateMode;
    }

    private void setSpeed(AliPlayer mAliPlayer,double speed){
        if(mAliPlayer != null){
            mAliPlayer.setSpeed((float) speed);
        }
    }

    private double getSpeed(AliPlayer mAliPlayer){
        double speed = 0;
        if(mAliPlayer != null){
            speed = mAliPlayer.getSpeed();
        }
        return speed;
    }

    private void setVideoBackgroundColor(AliPlayer mAliPlayer,long color){
        if(mAliPlayer != null){
            mAliPlayer.setVideoBackgroundColor((int) color);
        }
    }

    private void setVolume(AliPlayer mAliPlayer,double volume){
        if(mAliPlayer != null){
            mAliPlayer.setVolume((float)volume);
        }
    }

    private double getVolume(AliPlayer mAliPlayer){
        double volume = 1.0;
        if(mAliPlayer != null){
            volume = mAliPlayer.getVolume();
        }
        return volume;
    }

    private void setConfig(AliPlayer mAliPlayer,PlayerConfig playerConfig){
        if(mAliPlayer != null){
            mAliPlayer.setConfig(playerConfig);
        }
    }

    private PlayerConfig getConfig(AliPlayer mAliPlayer){
        if(mAliPlayer != null){
            return mAliPlayer.getConfig();
        }
        return null;
    }

    private CacheConfig getCacheConfig(){
        return new CacheConfig();
    }

    private void setCacheConfig(AliPlayer mAliPlayer,CacheConfig cacheConfig){
        if(mAliPlayer != null){
            mAliPlayer.setCacheConfig(cacheConfig);
        }
    }

    private TrackInfo getCurrentTrack(AliPlayer mAliPlayer,int currentTrackIndex){
        if(mAliPlayer != null){
            return mAliPlayer.currentTrack(currentTrackIndex);
        }else{
            return null;
        }
    }

    private void selectTrack(AliPlayer mAliPlayer,int trackId,boolean accurate){
        if(mAliPlayer != null){
            mAliPlayer.selectTrack(trackId,accurate);
        }
    }

    private void addExtSubtitle(AliPlayer mAliPlayer,String url){
        if(mAliPlayer != null){
            mAliPlayer.addExtSubtitle(url);
        }
    }

    private void selectExtSubtitle(AliPlayer mAliPlayer,int trackIndex,boolean enable){
        if(mAliPlayer != null){
            mAliPlayer.selectExtSubtitle(trackIndex,enable);
        }
    }

    private void createThumbnailHelper(String url){
        mThumbnailHelper = new ThumbnailHelper(url);
        mThumbnailHelper.setOnPrepareListener(new ThumbnailHelper.OnPrepareListener() {
            @Override
            public void onPrepareSuccess() {
                Map<String,Object> map = new HashMap<>();
                map.put("method","thumbnail_onPrepared_Success");
//                mEventSink.success(map);
                if(mFlutterAliPlayerListener != null){
                    mFlutterAliPlayerListener.onThumbnailPrepareSuccess(map);
                }
            }

            @Override
            public void onPrepareFail() {
                Map<String,Object> map = new HashMap<>();
                map.put("method","thumbnail_onPrepared_Fail");
//                mEventSink.success(map);
                if(mFlutterAliPlayerListener != null){
                    mFlutterAliPlayerListener.onThumbnailPrepareFail(map);
                }
            }
        });

        mThumbnailHelper.setOnThumbnailGetListener(new ThumbnailHelper.OnThumbnailGetListener() {
            @Override
            public void onThumbnailGetSuccess(long l, ThumbnailBitmapInfo thumbnailBitmapInfo) {
                if(thumbnailBitmapInfo != null && thumbnailBitmapInfo.getThumbnailBitmap() != null){
                    Map<String,Object> map = new HashMap<>();

                    Bitmap thumbnailBitmap = thumbnailBitmapInfo.getThumbnailBitmap();
                    ByteArrayOutputStream stream = new ByteArrayOutputStream();
                    thumbnailBitmap.compress(Bitmap.CompressFormat.JPEG, 100, stream);
                    thumbnailBitmap.recycle();
                    long[] positionRange = thumbnailBitmapInfo.getPositionRange();

                    map.put("method","onThumbnailGetSuccess");
                    map.put("thumbnailbitmap",stream.toByteArray());
                    map.put("thumbnailRange",positionRange);
//                    mEventSink.success(map);
                    if(mFlutterAliPlayerListener != null){
                        mFlutterAliPlayerListener.onThumbnailGetSuccess(map);
                    }
                }
            }

            @Override
            public void onThumbnailGetFail(long l, String s) {
                Map<String,Object> map = new HashMap<>();
                map.put("method","onThumbnailGetFail");
//                mEventSink.success(map);
                if(mFlutterAliPlayerListener != null){
                    mFlutterAliPlayerListener.onThumbnailGetFail(map);
                }
            }
        });
        mThumbnailHelper.prepare();
    }

    private void requestBitmapAtPosition(int position){
        if(mThumbnailHelper != null){
            mThumbnailHelper.requestBitmapAtPosition(position);
        }
    }

    private void setPlayerName(AliPlayer mAliPlayer,String playerName) {
        if(mAliPlayer != null){
            mAliPlayer.setPreferPlayerName(playerName);
        }
    }

    private String getPlayerName(AliPlayer mAliPlayer){
        return mAliPlayer == null ? "" : mAliPlayer.getPlayerName();
    }

    private void setStreamDelayTime(AliPlayer mAliPlayer,int index,int time){
        if(mAliPlayer != null){
            mAliPlayer.setStreamDelayTime(index,time);
        }
    }
}
