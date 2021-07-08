//
//  VideoViewFactory.m
//  flutter_aliplayer
//
//  Created by aliyun on 2020/10/9.
//
#import "AliPlayerFactory.h"
#import "FlutterAliPlayerView.h"
#import "NSDictionary+ext.h"
#import "MJExtension.h"
#import "AliPlayerProxy.h"

@interface AliPlayerFactory () {
    NSObject<FlutterBinaryMessenger>* _messenger;
    FlutterMethodChannel* _commonChannel;
    UIView *playerView;
}
@property (nonatomic, assign) BOOL enableMix;

@property (nonatomic, strong) FlutterEventSink eventSink;
@property(nonatomic,strong) NSMutableDictionary *viewDic;
@property(nonatomic,strong) NSMutableDictionary *playerProxyDic;

@end

@implementation AliPlayerFactory

- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
    self = [super init];
    if (self) {
        _messenger = messenger;
        __weak __typeof__(self) weakSelf = self;
        
        _viewDic = @{}.mutableCopy;
        _playerProxyDic = @{}.mutableCopy;
        
        _commonChannel = [FlutterMethodChannel methodChannelWithName:@"plugins.flutter_aliplayer_factory" binaryMessenger:messenger];
        [_commonChannel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
            NSObject* obj = [call arguments];
            if ([obj isKindOfClass:NSDictionary.class]) {
                NSDictionary *dic = (NSDictionary*)obj;
                NSString *playerId = [dic objectForKey:@"playerId"];
                AliPlayerProxy *proxy = [weakSelf.playerProxyDic objectForKey:playerId];
                
                if(!proxy && playerId.length>0 && ![call.method isEqualToString:@"createAliPlayer"]){
                    NSLog(@"flutter aliplayer sdk err : player whith playerId %@ is not exist",playerId);
                    return;
                }
                
                NSObject *arguments= [dic objectForKey:@"arg"];
                [weakSelf onMethodCall:call result:result atObj:proxy?:@"" arg:arguments?:@""];
            }else{
                [weakSelf onMethodCall:call result:result atObj:@"" arg:@""];
            }
        }];
        
        FlutterEventChannel *eventChannel = [FlutterEventChannel eventChannelWithName:@"flutter_aliplayer_event" binaryMessenger:messenger];
        [eventChannel setStreamHandler:self];
        
    }
    return self;
}

#pragma mark - FlutterStreamHandler
- (FlutterError* _Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(FlutterEventSink)eventSink{
    self.eventSink = eventSink;
    return nil;
}

- (FlutterError* _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    return nil;
}

- (NSObject<FlutterMessageCodec>*)createArgsCodec {
    return [FlutterStandardMessageCodec sharedInstance];
}

- (nonnull NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame
                                            viewIdentifier:(int64_t)viewId
                                                 arguments:(id _Nullable)args {
    NSString *viewIdKey = [NSString stringWithFormat:@"%lli",viewId];
    FlutterAliPlayerView *fapv = [_viewDic objectForKey:viewIdKey];
    if (fapv) {
        //更新参数
        [fapv updateWithWithFrame:frame arguments:args];
    }else{
        fapv =
        [[FlutterAliPlayerView alloc] initWithWithFrame:frame
                                         viewIdentifier:viewId
                                              arguments:args
                                        binaryMessenger:_messenger];
        [_viewDic setObject:fapv forKey:viewIdKey];
    }
    
    return fapv;
}

- (void)onMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result atObj:(NSObject*)player arg:(NSObject*)arg{
    NSString* method = [call method];
    SEL methodSel=NSSelectorFromString([NSString stringWithFormat:@"%@:",method]);
    NSArray *arr = @[call,result,player,arg];
    if([self respondsToSelector:methodSel]){
        IMP imp = [self methodForSelector:methodSel];
        void (*func)(id, SEL, NSArray*) = (void *)imp;
        func(self, methodSel, arr);
    }else{
        result(FlutterMethodNotImplemented);
    }
}


- (void)initService:(NSArray*)arr {
    FlutterMethodCall* call = arr.firstObject;
    FlutterResult result = arr[1];
    FlutterStandardTypedData* fdata = [call arguments];
    [AliPrivateService initKeyWithData:fdata.data];
    result(nil);
}

-(void)createAliPlayer:(NSArray*)arr {
    FlutterMethodCall* call = arr.firstObject;
    FlutterResult result = arr[1];
    NSDictionary *dic = [call arguments];
    NSString *playerId = [dic objectForKey:@"playerId"];
    NSNumber *type= [dic objectForKey:@"arg"];
    AliPlayerProxy *proxy = [AliPlayerProxy new];
    proxy.playerType = type.intValue;
    proxy.playerId = playerId;
    proxy.eventSink = self.eventSink;
    
    [_playerProxyDic setObject:proxy forKey:playerId];
    
    result(nil);
}

- (void)setPlayerView:(NSArray*)arr {
    AliPlayerProxy *proxy = arr[2];
    NSNumber* viewId = arr[3];
    FlutterAliPlayerView *fapv = [_viewDic objectForKey:[NSString stringWithFormat:@"%@",viewId]];
//    [proxy.player setPlayerView:fapv.view];
    [proxy bindPlayerView:fapv];
}

- (void)setUrl:(NSArray*)arr {
    AliPlayerProxy *proxy = arr[2];
    NSString* url = arr[3];
    AVPUrlSource *source = [[AVPUrlSource alloc] urlWithString:url];
    [proxy.player setUrlSource:source];
}

- (void)prepare:(NSArray*)arr {
    AliPlayerProxy *proxy = arr[2];
    [proxy.player prepare];
}

- (void)play:(NSArray*)arr {
    FlutterResult result = arr[1];
    AliPlayerProxy *proxy = arr[2];
    [proxy.player start];
    result(nil);
}

- (void)pause:(NSArray*)arr {
    FlutterResult result = arr[1];
    AliPlayerProxy *proxy = arr[2];
    [proxy.player pause];
    result(nil);
}

- (void)stop:(NSArray*)arr {
    FlutterResult result = arr[1];
    AliPlayerProxy *proxy = arr[2];
    [proxy.player stop];
    result(nil);
}

- (void)destroy:(NSArray*)arr {
    FlutterResult result = arr[1];
    AliPlayerProxy *proxy = arr[2];
    [proxy.player destroy];
    
    if ([_playerProxyDic objectForKey:proxy.playerId]) {
        [_playerProxyDic removeObjectForKey:proxy.playerId];
    }
    
    if (proxy.fapv) {
        NSString *viewId = [NSString stringWithFormat:@"%li",(long)proxy.fapv.viewId];
        if ([_viewDic objectForKey:viewId]) {
            [_viewDic removeObjectForKey:viewId];
        }
    }
    //TODO 销毁注意移除对应的字典
//    if([player isKindOfClass:AliListPlayer.class]){
//        self.aliListPlayer = nil;
//    }else{
//        self.aliPlayer = nil;
//    }
    result(nil);
}

-(void)enableMix:(NSArray*)arr {
    FlutterMethodCall* call = arr.firstObject;
    FlutterResult result = arr[1];
    NSNumber* val = [call arguments];
    self.enableMix = val.boolValue;
    if (val.boolValue) {
        [AliPlayer setAudioSessionDelegate:self];
    }else{
        [AliPlayer setAudioSessionDelegate:nil];
    }
    result(nil);
}

- (void)isLoop:(NSArray*)arr {
    FlutterResult result = arr[1];
    AliPlayerProxy *proxy = arr[2];
    result(@([proxy.player isLoop]));
}

- (void)setLoop:(NSArray*)arr {
    AliPlayerProxy *proxy = arr[2];
    NSNumber* isLoop = arr[3];
    [proxy.player setLoop:isLoop.boolValue];
}

- (void)isAutoPlay:(NSArray*)arr {
    FlutterResult result = arr[1];
    AliPlayerProxy *proxy = arr[2];
    result(@([proxy.player isAutoPlay]));
}

- (void)setAutoPlay:(NSArray*)arr {
    AliPlayerProxy *proxy = arr[2];
    NSNumber* val = arr[3];
    [proxy.player setAutoPlay:val.boolValue];
}

- (void)isMuted:(NSArray*)arr {
    FlutterResult result = arr[1];
    AliPlayerProxy *proxy = arr[2];
    result(@([proxy.player isMuted]));
}

- (void)setMuted:(NSArray*)arr {
    NSNumber* val = arr[3];
    AliPlayerProxy *proxy = arr[2];
    [proxy.player setMuted:val.boolValue];
}

- (void)enableHardwareDecoder:(NSArray*)arr {
    FlutterResult result = arr[1];
    AliPlayerProxy *proxy = arr[2];
    result(@([proxy.player enableHardwareDecoder]));
}

- (void)setEnableHardwareDecoder:(NSArray*)arr {
    AliPlayerProxy *proxy = arr[2];
    NSNumber* val = arr[3];
    [proxy.player setEnableHardwareDecoder:val.boolValue];
}

- (void)getRotateMode:(NSArray*)arr {
    AliPlayerProxy *proxy = arr[2];
    FlutterResult result = arr[1];
    result(@(proxy.player.rotateMode));
}

- (void)setRotateMode:(NSArray*)arr {
    AliPlayerProxy *proxy = arr[2];
    NSNumber* val = arr[3];
    [proxy.player setRotateMode:val.intValue];
}

- (void)getScalingMode:(NSArray*)arr {
    FlutterResult result = arr[1];
    AliPlayerProxy *proxy = arr[2];
    int mode = 0;
    switch (proxy.player.scalingMode) {
        case AVP_SCALINGMODE_SCALEASPECTFIT:
            mode = 0;
            break;
        case AVP_SCALINGMODE_SCALEASPECTFILL:
            mode = 1;
            break;
        case AVP_SCALINGMODE_SCALETOFILL:
            mode = 2;
            break;

        default:
            break;
    }
    result(@(mode));
}

- (void)setScalingMode:(NSArray*)arr {
    FlutterResult result = arr[1];
    AliPlayerProxy *proxy = arr[2];
    NSNumber* val = arr[3];
//    与android保持一致
    int mode = AVP_SCALINGMODE_SCALEASPECTFIT;
    switch (val.intValue) {
        case 0:
            mode = AVP_SCALINGMODE_SCALEASPECTFIT;
            break;
        case 1:
            mode = AVP_SCALINGMODE_SCALEASPECTFILL;
            break;
        case 2:
            mode = AVP_SCALINGMODE_SCALETOFILL;
            break;

        default:
            break;
    }
    [proxy.player setScalingMode:mode];
    result(nil);
}

- (void)getMirrorMode:(NSArray*)arr {
    FlutterResult result = arr[1];
    AliPlayerProxy *proxy = arr[2];
    result(@(proxy.player.mirrorMode));
}

- (void)setMirrorMode:(NSArray*)arr {
    AliPlayerProxy *proxy = arr[2];
    NSNumber* val = arr[3];
    [proxy.player setMirrorMode:val.intValue];
}

- (void)getRate:(NSArray*)arr {
    FlutterResult result = arr[1];
    AliPlayerProxy *proxy = arr[2];
    result(@(proxy.player.rate));
}

- (void)setRate:(NSArray*)arr {
    AliPlayerProxy *proxy = arr[2];
    NSNumber* val = arr[3];
    [proxy.player setRate:val.floatValue];
}

- (void)snapshot:(NSArray*)arr {
    AliPlayerProxy *proxy = arr[2];
    NSString* val = arr[3];
    proxy.snapshotPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    if (val.length>0) {
        proxy.snapshotPath = [proxy.snapshotPath stringByAppendingPathComponent:val];
    }
    [proxy.player snapShot];
}

- (void)createThumbnailHelper:(NSArray*)arr {
    AliPlayerProxy *proxy = arr[2];
    NSString* val = arr[3];
    [proxy.player setThumbnailUrl:val];
    self.eventSink(@{kAliPlayerMethod:@"thumbnail_onPrepared_Success"});
}

- (void)requestBitmapAtPosition:(NSArray*)arr {
    AliPlayerProxy *proxy = arr[2];
    NSNumber* val = arr[3];
    [proxy.player getThumbnail:val.integerValue];
}

- (void)getVolume:(NSArray*)arr {
    FlutterResult result = arr[1];
    AliPlayerProxy *proxy = arr[2];
    result(@(proxy.player.volume));
}

- (void)setVolume:(NSArray*)arr {
    AliPlayerProxy *proxy = arr[2];
    NSNumber* val = arr[3];
    [proxy.player setVolume:val.floatValue];
}

- (void)setVideoBackgroundColor:(NSArray*)arr {
    AliPlayerProxy *proxy = arr[2];
    NSNumber* val = arr[3];
    int c = val.intValue;
    UIColor *color = [UIColor colorWithRed:((c>>16)&0xFF)/255.0 green:((c>>8)&0xFF)/255.0 blue:((c)&0xFF)/255.0  alpha:((c>>24)&0xFF)/255.0];
    [proxy.player setVideoBackgroundColor:color];
}

-(void)getSDKVersion:(NSArray*)arr{
    FlutterResult result = arr[1];
    result([AliPlayer getSDKVersion]);
}

- (void)enableConsoleLog:(NSArray*)arr {
    FlutterMethodCall* call = arr.firstObject;
    NSNumber* val = [call arguments];
    [AliPlayer setEnableLog:val.boolValue];
}

- (void)getLogLevel:(NSArray*)arr {
    FlutterResult result = arr[1];
    //TODO 拿不到
    result(@(-1));
}

- (void)setLogLevel:(NSArray*)arr {
    FlutterMethodCall* call = arr.firstObject;
    NSNumber* val = [call arguments];
    [AliPlayer setLogCallbackInfo:val.intValue callbackBlock:nil];
}

- (void)seekTo:(NSArray*)arr {
    AliPlayerProxy *proxy = arr[2];
    NSDictionary* dic = arr[3];
    NSNumber *position = dic[@"position"];
    NSNumber *seekMode = dic[@"seekMode"];
    [proxy.player seekToTime:position.integerValue seekMode:seekMode.intValue];
}

//TODO 应该是根据已经有的key 替换比较合理
- (void)setConfig:(NSArray*)arr {
    AliPlayerProxy *proxy = arr[2];
    NSDictionary* val = arr[3];
    AVPConfig *config = [proxy.player getConfig];

    [AVPConfig mj_setupReplacedKeyFromPropertyName:^NSDictionary *{
        return @{
            @"httpProxy" : @"mHttpProxy",
            @"referer" :@"mReferrer",
            @"networkTimeout" :@"mNetworkTimeout",
            @"highBufferDuration":@"mHighBufferDuration",
            @"maxDelayTime" :@"mMaxDelayTime",
            @"maxBufferDuration" :@"mMaxBufferDuration",
            @"startBufferDuration" :@"mStartBufferDuration",
            @"maxProbeSize" :@"mMaxProbeSize",
            @"maxProbeSize" :@"mMaxProbeSize",
            @"clearShowWhenStop" :@"mClearFrameWhenStop",
            @"enableVideoTunnelRender" :@"mEnableVideoTunnelRender",
            @"enableSEI" :@"mEnableSEI",
            @"userAgent" :@"mUserAgent",
            @"networkRetryCount" :@"mNetworkRetryCount",
            @"liveStartIndex" :@"mLiveStartIndex",
            @"customHeaders" :@"mCustomHeaders",
            @"disableAudio":@"mDisableAudio",
            @"disableVideo":@"mDisableVideo",
        };
    }];

    config = [AVPConfig mj_objectWithKeyValues:val];

    [proxy.player setConfig:config];

}

//- (void)getCacheConfig:(NSArray*)arr {
//    FlutterResult result = arr[1];
//    AliPlayer *player = arr[2];
//    [AVPCacheConfig mj_setupReplacedKeyFromPropertyName:^NSDictionary *{
//        return @{
//                 @"enable" : @"mEnable",
//                 @"path" :@"mDir",
//                 @"maxSizeMB" :@"mMaxSizeMB",
//                 @"maxDuration" :@"mMaxDurationS",
//                 };
//    }];
//    result(config.mj_keyValues);
//}

- (void)setCacheConfig:(NSArray*)arr {
    AliPlayerProxy *proxy = arr[2];
    NSDictionary* val = arr[3];

    [AVPCacheConfig mj_setupReplacedKeyFromPropertyName:^NSDictionary *{
        return @{
            @"enable" : @"mEnable",
            @"path" :@"mDir",
            @"maxSizeMB" :@"mMaxSizeMB",
            @"maxDuration" :@"mMaxDurationS",
        };
    }];
    AVPCacheConfig *config = [AVPCacheConfig mj_objectWithKeyValues:val];
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    [config setPath:[path stringByAppendingPathComponent:config.path]];

    [proxy.player setCacheConfig:config];

}

- (void)getConfig:(NSArray*)arr {
    FlutterResult result = arr[1];
    AliPlayerProxy *proxy = arr[2];
    AVPConfig *config = [proxy.player getConfig];

    [AVPConfig mj_setupReplacedKeyFromPropertyName:^NSDictionary *{
        return @{
            @"httpProxy" : @"mHttpProxy",
            @"referer" :@"mReferrer",
            @"networkTimeout" :@"mNetworkTimeout",
            @"highBufferDuration":@"mHighBufferDuration",
            @"maxDelayTime" :@"mMaxDelayTime",
            @"maxBufferDuration" :@"mMaxBufferDuration",
            @"startBufferDuration" :@"mStartBufferDuration",
            @"maxProbeSize" :@"mMaxProbeSize",
            @"maxProbeSize" :@"mMaxProbeSize",
            @"clearShowWhenStop" :@"mClearFrameWhenStop",
            @"enableVideoTunnelRender" :@"mEnableVideoTunnelRender",
            @"enableSEI" :@"mEnableSEI",
            @"userAgent" :@"mUserAgent",
            @"networkRetryCount" :@"mNetworkRetryCount",
            @"liveStartIndex" :@"mLiveStartIndex",
            @"customHeaders" :@"mCustomHeaders",
        };
    }];
    result(config.mj_keyValues);
}

-(void)setSource:(AVPSource*)source withDefinitions:(NSDictionary*)dic{
    NSArray *definitionList = [dic objectForKey:@"definitionList"];
    if (definitionList && [definitionList isKindOfClass:NSArray.class] && definitionList.count>0) {
        NSMutableString *mutStr = @"".mutableCopy;
        for (NSString *str in definitionList) {
            [mutStr appendString:str];
            [mutStr appendString:@","];
        }
        [mutStr deleteCharactersInRange:NSMakeRange(mutStr.length-1, 1)];
        [source setDefinitions:mutStr];
    }
}

- (void)setVidSts:(NSArray*)arr {
    AliPlayerProxy *proxy = arr[2];
    NSDictionary *dic = arr[3];
    AVPVidStsSource *source = [AVPVidStsSource mj_objectWithKeyValues:dic];

    NSString *previewTime = [dic getStrByKey:@"previewTime"];
    if(previewTime && previewTime.length>0){
        VidPlayerConfigGenerator* vp = [[VidPlayerConfigGenerator alloc] init];
        [vp setPreviewTime:previewTime.intValue];
        source.playConfig = [vp generatePlayerConfig];
    }

    [self setSource:source withDefinitions:dic];
    [proxy.player setStsSource:source];
}

- (void)setVidAuth:(NSArray*)arr {
    AliPlayerProxy *proxy = arr[2];
    NSDictionary *dic = arr[3];
    AVPVidAuthSource *source = [AVPVidAuthSource mj_objectWithKeyValues:dic];

    NSString *previewTime = [dic getStrByKey:@"previewTime"];
    if(previewTime && previewTime.length>0){
        VidPlayerConfigGenerator* vp = [[VidPlayerConfigGenerator alloc] init];
        [vp setPreviewTime:previewTime.intValue];
        source.playConfig = [vp generatePlayerConfig];
    }

    [self setSource:source withDefinitions:dic];
    [proxy.player setAuthSource:source];
}

- (void)setVidMps:(NSArray*)arr {
    AliPlayerProxy *proxy = arr[2];
    AVPVidMpsSource *source = [[AVPVidMpsSource alloc] init];
    NSDictionary *dic = [arr[3] removeNull];
    [source setVid:dic[@"vid"]];
    [source setAccId:dic[@"accessKeyId"]];
    [source setRegion:dic[@"region"]];
    [source setStsToken:dic[@"securityToken"]];
    [source setAccSecret:dic[@"accessKeySecret"]];
    [source setPlayDomain:dic[@"playDomain"]];
    [source setAuthInfo:dic[@"authInfo"]];
    [source setMtsHlsUriToken:dic[@"hlsUriToken"]];
    [self setSource:source withDefinitions:dic];
    [proxy.player setMpsSource:source];
}

- (void)addVidSource:(NSArray*)arr {
    AliPlayerProxy *proxy = arr[2];
    NSDictionary *dic = arr[3];
    [(AliListPlayer*)proxy.player addVidSource:dic[@"vid"] uid:dic[@"uid"]];
}

- (void)addUrlSource:(NSArray*)arr {
    AliPlayerProxy *proxy = arr[2];
    NSDictionary *dic = arr[3];
    [(AliListPlayer*)proxy.player addUrlSource:dic[@"url"] uid:dic[@"uid"]];
}

- (void)moveTo:(NSArray*)arr {
    AliPlayerProxy *proxy = arr[2];
    NSDictionary *dic = [arr[3] removeNull];

    NSString *aacId = [dic getStrByKey:@"accId"];
    if (aacId.length>0) {
        [(AliListPlayer*)proxy.player moveTo:dic[@"uid"] accId:dic[@"accId"] accKey:dic[@"accKey"] token:dic[@"token"] region:dic[@"region"]];
    }else{
        [(AliListPlayer*)proxy.player moveTo:dic[@"uid"]];
    }
}

- (void)moveToNext:(NSArray*)arr {
    AliPlayerProxy *proxy = arr[2];
    NSDictionary *dic = [arr[3] removeNull];
    [(AliListPlayer*)proxy.player moveToNext:dic[@"accId"] accKey:dic[@"accKey"] token:dic[@"token"] region:dic[@"region"]];
}

- (void)setPreloadCount:(NSArray*)arr {
    AliPlayerProxy *proxy = arr[2];
    NSNumber* val = arr[3];
    [(AliListPlayer*)proxy.player setPreloadCount:val.intValue];
}

- (void)getMediaInfo:(NSArray*)arr {
    FlutterResult result = arr[1];
    AliPlayerProxy *proxy = arr[2];
    AVPMediaInfo * info = [proxy.player getMediaInfo];

    //TODO 后面需要统一键值转换规则
    [AVPMediaInfo mj_setupReplacedKeyFromPropertyName:^NSDictionary *{
        return @{
            @"mTitle":@"title",
            @"mCoverUrl":@"coverURL",
            @"mTrackInfos":@"tracks",
        };
    }];

    [AVPTrackInfo mj_setupReplacedKeyFromPropertyName:^NSDictionary *{
        return @{
            @"vodDefinition":@"trackDefinition",
            @"index":@"trackIndex",
        };
    }];

    [AVPThumbnailInfo mj_setupReplacedKeyFromPropertyName:^NSDictionary *{
        return @{
            @"URL" : @"url",
        };
    }];
//    NSLog(@"getMediaInfo==%@",info.mj_JSONString);
    result(info.mj_keyValues);
}

- (void)getCurrentTrack:(NSArray*)arr {
    FlutterResult result = arr[1];
    AliPlayerProxy *proxy = arr[2];
    NSNumber *idxNum = arr[3];
    AVPTrackInfo * info = [proxy.player getCurrentTrack:idxNum.intValue];
//    NSLog(@"getCurrentTrack==%@",info.mj_JSONString);
    result(info.mj_keyValues);
}

- (void)selectTrack:(NSArray*)arr {
    AliPlayerProxy *proxy = arr[2];
    NSDictionary *dic = [arr[3] removeNull];
    NSNumber *trackIdxNum = dic[@"trackIdx"];
    NSNumber *accurateNum = dic[@"accurate"];
    if (accurateNum.intValue==-1) {
        [proxy.player selectTrack:trackIdxNum.intValue];
    }else{
        [proxy.player selectTrack:trackIdxNum.intValue accurate:accurateNum.boolValue];
    }

}

- (void)addExtSubtitle:(NSArray*)arr {
    AliPlayerProxy *proxy = arr[2];
    NSString *url = arr[3];
    [proxy.player addExtSubtitle:url];
}

- (void)selectExtSubtitle:(NSArray*)arr {
    FlutterResult result = arr[1];
    AliPlayerProxy *proxy = arr[2];
    NSDictionary *dic = [arr[3] removeNull];
    NSNumber *trackIdxNum = dic[@"trackIndex"];
    NSNumber *enableNum = dic[@"enable"];
    [proxy.player selectExtSubtitle:trackIdxNum.intValue enable:enableNum.boolValue];
    result(nil);
}

- (void)setStreamDelayTime:(NSArray*)arr {
    FlutterResult result = arr[1];
    AliPlayerProxy *proxy = arr[2];
    NSDictionary *dic = [arr[3] removeNull];
    NSNumber *trackIdxNum = dic[@"index"];
    NSNumber *timeNum = dic[@"time"];
    [proxy.player setStreamDelayTime:trackIdxNum.intValue time:timeNum.intValue];
    result(nil);
}

- (void)setPreferPlayerName:(NSArray*)arr {
    FlutterResult result = arr[1];
    AliPlayerProxy *proxy = arr[2];
    NSString *playerName = arr[3];
    [proxy.player setPreferPlayerName:playerName];
    result(nil);
}

- (void)getPlayerName:(NSArray*)arr {
    FlutterResult result = arr[1];
    AliPlayerProxy *proxy = arr[2];
    result([proxy.player getPlayerName]);
}

#pragma --mark CicadaAudioSessionDelegate
- (BOOL)setActive:(BOOL)active error:(NSError **)outError
{
    return [[AVAudioSession sharedInstance] setActive:active error:outError];
}

- (BOOL)setCategory:(NSString *)category withOptions:(AVAudioSessionCategoryOptions)options error:(NSError **)outError
{
    if (self.enableMix) {
        options = AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionDuckOthers;
    }
    return [[AVAudioSession sharedInstance] setCategory:category withOptions:options error:outError];
}

- (BOOL)setCategory:(AVAudioSessionCategory)category mode:(AVAudioSessionMode)mode routeSharingPolicy:(AVAudioSessionRouteSharingPolicy)policy options:(AVAudioSessionCategoryOptions)options error:(NSError **)outError
{
    if (self.enableMix) {
        return YES;
    }

    if (@available(iOS 11.0, tvOS 11.0, *)) {
        return [[AVAudioSession sharedInstance] setCategory:category mode:mode routeSharingPolicy:policy options:options error:outError];
    }
    return NO;
}

@end

