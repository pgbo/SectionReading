//
//  RAQRecorder.m
//  ReadASection
//
//  Created by guangbo on 15/9/2.
//  Copyright (c) 2015年 guangbo. All rights reserved.
//

#import "RAQRecorder.h"
#import <AVFoundation/AVFoundation.h>

static const int kNumberBuffers = 3;
typedef struct AQRecorderState {
    AudioQueueBufferRef          mBuffers[kNumberBuffers];
    SInt64                       mCurrentPacket;
} AQRecorderState;

@interface RAQRecorder ()

// MARK: - Private properties

@property (nonatomic) AQRecorderState *aqData;

/// 状态
@property (nonatomic, readwrite) RAQRecorderStatus status;

@property (nonatomic) AudioStreamBasicDescription  *mDataFormat;
@property (nonatomic) AudioQueueRef mQueue;
@property (nonatomic) AudioFileID mAudioFile;

@end

@implementation RAQRecorder

// MARK: - Private method

- (void)CopyEncoderCookieToFile
{
    UInt32 cookieSize;
    // get the magic cookie, if any, from the converter
    OSStatus err = AudioQueueGetPropertySize(self.mQueue,
                                             kAudioQueueProperty_MagicCookie,
                                             &cookieSize);
    
    // we can get a noErr result and also a propertySize == 0
    // -- if the file format does support magic cookies, but this file doesn't have one.
    if (err == noErr && cookieSize > 0) {
        
        char* magicCookie = (char *) malloc (cookieSize);
        UInt32 magicCookieSize;
        err = AudioQueueGetProperty(self.mQueue,
                                    kAudioQueueProperty_MagicCookie,
                                    magicCookie,
                                    &cookieSize);
        if (err != noErr) {
            NSAssert(NO, @"%@, can't get audio converter's magic cookie", @(err));
        }
        
        magicCookieSize = cookieSize;	// the converter lies and tell us the wrong size
        
        // now set the magic cookie on the output file
        UInt32 willEatTheCookie = false;
        // the converter wants to give us one; will the file take it?
        err = AudioFileGetPropertyInfo(self.mAudioFile, kAudioFilePropertyMagicCookieData, NULL, &willEatTheCookie);
        if (err == noErr && willEatTheCookie) {
            err = AudioFileSetProperty(self.mAudioFile, kAudioFilePropertyMagicCookieData, magicCookieSize, magicCookie);
            if (err != noErr) {
                NSAssert(NO, @"%@, can't set audio file's magic cookie", @(err));
            }
        }
        free (magicCookie);
    }
}

- (void)SetupAudioFormat:(AudioFormatID)inFormatID
{
//    self.aqData->mDataFormat.mFormatID         = inFormatID;
//    self.aqData->mDataFormat.mSampleRate       = 4100 /*[[AVAudioSession sharedInstance]sampleRate]*/;
//    self.aqData->mDataFormat.mChannelsPerFrame = 1/*(UInt32)[[AVAudioSession sharedInstance]inputNumberOfChannels]*/;
//    if (inFormatID == kAudioFormatLinearPCM) {
//        self.aqData->mDataFormat.mBitsPerChannel   = 16;
//        self.aqData->mDataFormat.mBytesPerPacket   = 2;
//        self.aqData->mDataFormat.mBytesPerFrame =
//        self.aqData->mDataFormat.mChannelsPerFrame * sizeof (SInt16);
//        self.aqData->mDataFormat.mFramesPerPacket  = 1;
//        
//        self.aqData->mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
//    }
    
    self.mDataFormat->mFormatID         = inFormatID;
    self.mDataFormat->mSampleRate       = 44100.0 /*[[AVAudioSession sharedInstance]sampleRate]*/;
    self.mDataFormat->mChannelsPerFrame = 1/*(UInt32)[[AVAudioSession sharedInstance]inputNumberOfChannels]*/;
    self.mDataFormat->mBitsPerChannel   = 16;
    self.mDataFormat->mBytesPerPacket   = 2;
    self.mDataFormat->mBytesPerFrame =
    self.mDataFormat->mChannelsPerFrame * sizeof (SInt16);
    self.mDataFormat->mFramesPerPacket  = 1;
    
    if (inFormatID == kAudioFormatLinearPCM) {
        self.mDataFormat->mBitsPerChannel   = 16;
        self.mDataFormat->mBytesPerPacket   = 2;
        self.mDataFormat->mBytesPerFrame =
        self.mDataFormat->mChannelsPerFrame * sizeof (SInt16);
        self.mDataFormat->mFramesPerPacket  = 1;
        
        self.mDataFormat->mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    }
}

- (int)ComputeRecordBufferSizeWithformat:(AudioStreamBasicDescription)format seconds:(float)seconds
{
    int packets, frames, bytes = 0;
    
    frames = (int)ceil(seconds * format.mSampleRate);
    
    if (format.mBytesPerFrame > 0)
        bytes = frames * format.mBytesPerFrame;
    else {
        UInt32 maxPacketSize;
        if (format.mBytesPerPacket > 0)
            maxPacketSize = format.mBytesPerPacket;	// constant packet size
        else {
            UInt32 propertySize = sizeof(maxPacketSize);
            OSStatus status = AudioQueueGetProperty(self.mQueue,
                                                    kAudioQueueProperty_MaximumOutputPacketSize,
                                                    &maxPacketSize,
                                                    &propertySize);
            if (status != noErr) {
                NSAssert(NO, @"%@, couldn't get queue's maximum output packet size", @(status));
            }
        }
        if (format.mFramesPerPacket > 0)
            packets = frames / format.mFramesPerPacket;
        else
            packets = frames;	// worst-case scenario: 1 frame in a packet
        if (packets == 0)		// sanity check
            packets = 1;
        bytes = packets * maxPacketSize;
    }
    
    return bytes;
}


// ____________________________________________________________________________________
// AudioQueue callback function, called when an input buffers has been filled.
void MyInputBufferHandler(            void *								inUserData,
                                      AudioQueueRef                         inAQ,
                                      AudioQueueBufferRef					inBuffer,
                                      const AudioTimeStamp *				inStartTime,
                                      UInt32								inNumPackets,
                                      const AudioStreamPacketDescription*	inPacketDesc)
{
    RAQRecorder *rAqr = (__bridge RAQRecorder *)inUserData;
    if (inNumPackets > 0 && rAqr.status == RAQRecorderStatusRecording) {
        
        NSLog(@"rAqr.aqData->mCurrentPacket: %@", @(rAqr.aqData->mCurrentPacket));
        
        // write packets to file
        OSStatus err = AudioFileWritePackets(rAqr.mAudioFile,
                                             NO,
                                             inBuffer->mAudioDataByteSize,
                                             inPacketDesc,
                                             rAqr.aqData->mCurrentPacket,
                                             &inNumPackets,
                                             inBuffer->mAudioData);
        if (err != noErr) {
            NSLog(@"AudioFileWritePackets failed, err: %@", @(err));
            return;
        }
        rAqr.aqData->mCurrentPacket += inNumPackets;
    }
    
    // if we're not stopping, re-enqueue the buffe so that it gets filled again
    if (rAqr.status == RAQRecorderStatusRecording) {
        OSStatus err = AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
        if (err != noErr) {
            NSLog(@"AudioQueueEnqueueBuffer failed, err: %@", @(err));
        }
    }
}


// MARK: - Public method

- (instancetype)init
{
    if (self = [super init]) {
        self.status = RAQRecorderStatusStopped;
        self.audioFileType = kAudioFileCAFType;
        self.audioFormatType = kAudioFormatMPEG4AAC;
        self.aqData = malloc(sizeof(AQRecorderState));
        self.aqData->mCurrentPacket = 0;
        self.mDataFormat = malloc(sizeof(AudioStreamBasicDescription));
    }
    return self;
}

- (void)delloc
{
    if (self.mQueue != nil) {
        AudioQueueDispose(self.mQueue, YES);
    }
    if (self.mAudioFile != nil) {
        AudioFileClose(self.mAudioFile);
    }
    
    free(self.aqData);
    free(self.mDataFormat);
}

- (void)record
{
    if (self.status == RAQRecorderStatusRecording)
        return;
    
    if (!self.audioFilePath) {
        NSAssert(NO, @"filePath must be configured before start recording.");
    }
    
    
    if (self.status == RAQRecorderStatusPaused) {
    
        // 从暂停状态继续录音
        
        // resume the queue

        self.status = RAQRecorderStatusRecording;
        
        OSStatus err = AudioQueueStart(self.mQueue, NULL);
        if (err != noErr) {
            
            self.status = RAQRecorderStatusStopped;
            
            NSLog(@"AudioQueueStart failed");
        }
        
        
    } else if (self.status == RAQRecorderStatusStopped) {
    
        // 从停止状态开始录音
    
        // specify the recording format
        [self SetupAudioFormat:self.audioFormatType];
        
        // create the queue
        OSStatus err = AudioQueueNewInput(
                                          _mDataFormat,
                                          MyInputBufferHandler,
                                          (__bridge void *)(self) /* userData */,
                                          NULL /* run loop */,
                                          NULL /* run loop mode */,
                                          0 /* flags */,
                                          &_mQueue);
        if (err != noErr) {
            NSLog(@"AudioQueueNewInput failed, err: %@", @(err));
            return;
        }
        
        // get the record format back from the queue's audio converter --
        // the file may require a more specific stream description than was necessary to create the encoder.
        
        UInt32 size = sizeof(AudioStreamBasicDescription);
        err = AudioQueueGetProperty(self.mQueue,
                                    kAudioQueueProperty_StreamDescription,
                                    self.mDataFormat,
                                    &size);
        if (err != noErr) {
            NSLog(@"couldn't get queue's format, err: %@", @(err));
            return;
        }
        
        CFURLRef url = CFURLCreateWithString(kCFAllocatorDefault, (CFStringRef)self.audioFilePath, NULL);
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.audioFilePath]) {
            err = AudioFileOpenURL(url, kAudioFileReadWritePermission, self.audioFileType, &_mAudioFile);
            if (err == noErr) {
                // 读取文件原来的 packet 数量
                self.aqData->mCurrentPacket = 0;
                UInt32 propertySizeDataPacketCount;
                UInt32 writabilityDataPacketCount;
                UInt32 numberOfPackets;
                
                err = AudioFileGetPropertyInfo(_mAudioFile,
                                               kAudioFilePropertyAudioDataPacketCount,
                                               &propertySizeDataPacketCount,
                                               &writabilityDataPacketCount);
                
                err = AudioFileGetProperty(_mAudioFile,
                                           kAudioFilePropertyAudioDataPacketCount,
                                           &propertySizeDataPacketCount,
                                           &numberOfPackets);
                
                if (err != noErr) {
                    self.aqData->mCurrentPacket = numberOfPackets;
                }
            }
            
            CFRelease(url);
            if (err != noErr) {
                NSLog(@"AudioFileOpenURL failed, err: %@", @(err));
                return;
            }
            
        } else {
            // create the audio file
            err = AudioFileCreateWithURL(url, self.audioFileType, self.mDataFormat, kAudioFileFlags_EraseFile, &_mAudioFile);
            
            CFRelease(url);
            if (err == noErr) {
                self.aqData->mCurrentPacket = 0;
            } else {
                NSLog(@"AudioFileCreateWithURL failed, err: %@", @(err));
                return;
            }
        }
        
        // copy the cookie first to give the file object as much info as we can about the data going in
        // not necessary for pcm, but required for some compressed audio
        [self CopyEncoderCookieToFile];
        
        // allocate and enqueue buffers
        int bufferByteSize = [self ComputeRecordBufferSizeWithformat:*(self.mDataFormat)
                                                             seconds:0.5];	// enough bytes for half a second
        for (int i = 0; i < kNumberBuffers; ++i) {
            err = AudioQueueAllocateBuffer(self.mQueue, bufferByteSize, &self.aqData->mBuffers[i]);
            if (err != noErr) {
                NSLog(@"AudioQueueAllocateBuffer failed, err: %@", @(err));
            }
            
            err = AudioQueueEnqueueBuffer(self.mQueue, self.aqData->mBuffers[i], 0, NULL);
            if (err != noErr) {
                NSLog(@"AudioQueueEnqueueBuffer failed, err: %@", @(err));
            }
        }
        
        // start the queue
        
        self.status = RAQRecorderStatusRecording;
        
        err = AudioQueueStart(self.mQueue, NULL);
        if (err != noErr) {
            
            self.status = RAQRecorderStatusStopped;
            
            NSLog(@"AudioQueueStart failed, err: %@", @(err));
            
            return;
        }
    }
}

/**
 暂停录音
 */
- (void)pause
{
    // pause recording
    OSStatus err = AudioQueuePause(self.mQueue);
    if (err != noErr) {
        NSLog(@"AudioQueueStop failed, err: %@", @(err));
        return;
    }
    
    self.status = RAQRecorderStatusPaused;
}

/**
 停止录音
 */
- (void)stop
{
    // end recording
    OSStatus err = AudioQueueStop(self.mQueue, true);
    if (err != noErr) {
        NSLog(@"AudioQueueStop failed, err: %@", @(err));
        return;
    }
    
    // a codec may update its cookie at the end of an encoding session, so reapply it to the file now
    [self CopyEncoderCookieToFile];
    
    AudioQueueDispose(self.mQueue, true);
    AudioFileClose(self.mAudioFile);
    
    self.aqData->mCurrentPacket = 0;
    self.status = RAQRecorderStatusStopped;
}

@end
