//
//  AliDownloaderProxy.h
//  flutter_aliplayer
//
//  Created by aliyun on 2020/11/29.
//

#import <Foundation/Foundation.h>
#import <AliyunMediaDownloader/AliyunMediaDownloader.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface AliDownloaderProxy : NSObject<AMDDelegate>

@property(nonatomic,strong) FlutterResult result;
@property (nonatomic, copy) FlutterEventSink eventSink;
@property(nonatomic,strong) NSMutableDictionary *argMap;

@property(nonatomic,strong) NSString *mVideoId;

@end

NS_ASSUME_NONNULL_END
