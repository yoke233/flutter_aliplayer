//
//  AliDownloaderProxy.m
//  flutter_aliplayer
//
//  Created by aliyun on 2020/11/29.
//

#import "AliDownloaderProxy.h"
#import "MJExtension.h"

@implementation AliDownloaderProxy


#pragma --mark AMDDelegate
-(void)onPrepared:(AliMediaDownloader*)downloader mediaInfo:(AVPMediaInfo*)info{
    [AVPMediaInfo mj_setupReplacedKeyFromPropertyName:^NSDictionary *{
        return @{
                 @"title" : @"mTitle",
                 @"coverURL":@"mCoverUrl",
                 @"tracks":@"mTrackInfos",
                 };
    }];
    
    [AVPTrackInfo mj_setupReplacedKeyFromPropertyName:^NSDictionary *{
        return @{
                 @"trackDefinition" : @"vodDefinition",
                 @"trackIndex" :@"index",
                 };
    }];
    
    NSMutableDictionary *dic = info.mj_keyValues;
    if (_mVideoId) {
        [dic setObject:_mVideoId forKey:@"mVideoId"];
    }
    self.result(dic.mj_JSONString);
}

- (void)onError:(AliMediaDownloader*)downloader errorModel:(AVPErrorModel *)errorModel{
    NSLog(@"=========onErr==%@",errorModel.mj_JSONString);
    if(self.eventSink){
        [self.argMap setObject:@"download_error" forKey:@"method"];
        [self.argMap setObject:[NSString stringWithFormat:@"%lu",(unsigned long)errorModel.code] forKey:@"errorCode"];
        [self.argMap setObject:errorModel.message forKey:@"errorMsg"];
        self.eventSink(self.argMap);
    }
}

- (void)onDownloadingProgress:(AliMediaDownloader*)downloader percentage:(int)percent{
    if(self.eventSink){
        [self.argMap setObject:@"download_progress" forKey:@"method"];
        [self.argMap setObject:[NSString stringWithFormat:@"%i",percent] forKey:@"download_progress"];
        self.eventSink(self.argMap);
    }
}

- (void)onProcessingProgress:(AliMediaDownloader*)downloader percentage:(int)percent{
    if(self.eventSink){
        [self.argMap setObject:@"download_progress" forKey:@"method"];
        [self.argMap setObject:[NSString stringWithFormat:@"%i",percent] forKey:@"download_progress"];
        self.eventSink(self.argMap);
    }
}

- (void)onCompletion:(AliMediaDownloader*)downloader{
    if(self.eventSink){
        [self.argMap setObject:@"download_completion" forKey:@"method"];
        [self.argMap setObject:[NSString stringWithFormat:@"%@",downloader.downloadedFilePath] forKey:@"savePath"];
        self.eventSink(self.argMap);
    }
}

@end
