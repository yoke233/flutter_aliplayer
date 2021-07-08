//
//  VideoViewFactory.h
//  flutter_aliplayer
//
//  Created by aliyun on 2020/10/9.
//
#import <Flutter/Flutter.h>
#import <Foundation/Foundation.h>
#import <AliyunPlayer/AliyunPlayer.h>

NS_ASSUME_NONNULL_BEGIN

@interface AliPlayerFactory : NSObject<FlutterPlatformViewFactory,FlutterStreamHandler,CicadaAudioSessionDelegate>

- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger>*)messenger;

@end

NS_ASSUME_NONNULL_END
