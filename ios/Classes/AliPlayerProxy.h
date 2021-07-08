//
//  AliPlayerProxy.h
//  flutter_aliplayer
//
//  Created by aliyun on 2021/5/18.
//

#import <Foundation/Foundation.h>
#import <AliyunPlayer/AliyunPlayer.h>
#import <Flutter/Flutter.h>
#import "FlutterAliPlayerView.h"

#define kAliPlayerMethod    @"method"
#define kAliPlayerId        @"playerId"

NS_ASSUME_NONNULL_BEGIN

@interface AliPlayerProxy : NSObject<AVPDelegate>

//@property(nonatomic,strong) FlutterResult result;
@property (nonatomic, copy) FlutterEventSink eventSink;

@property(nonatomic,strong) NSString *snapshotPath;

@property(nonatomic,strong,nullable)AliPlayer *player;

@property(nonatomic,strong) NSString *playerId;

@property(nonatomic,assign) int playerType;

@property(nonatomic,strong) FlutterAliPlayerView *fapv;

-(void)bindPlayerView:(FlutterAliPlayerView*)fapv;

@end

NS_ASSUME_NONNULL_END
