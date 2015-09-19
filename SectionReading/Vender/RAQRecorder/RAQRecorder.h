//
//  RAQRecorder.h
//  ReadASection
//
//  Created by guangbo on 15/9/2.
//  Copyright (c) 2015年 guangbo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

typedef NS_ENUM(NSUInteger, RAQRecorderStatus) {
    RAQRecorderStatusStopped = 0,
    RAQRecorderStatusRecording,
    RAQRecorderStatusPaused,
};

@interface RAQRecorder : NSObject

/// 录音文件名
@property (nonatomic) NSString *audioFilePath;
@property (nonatomic) AudioFileTypeID audioFileType;
@property (nonatomic) AudioFormatID audioFormatType;

/// 录音时长，单位毫秒
@property (nonatomic, readonly) float duration;
/// 状态
@property (nonatomic, readonly) RAQRecorderStatus status;

/**
 开始录音或暂停后继续录音
 */
- (void)record;

/**
 暂停录音
 */
- (void)pause;

/**
 停止录音
 */
- (void)stop;

@end
