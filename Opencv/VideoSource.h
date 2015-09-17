//
//  VideoSource.h
//  Opencv
//
//  Created by 周涛 on 15/8/27.
//  Copyright (c) 2015年 net.huiyutech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>

struct BGRAVideoFrame
{
    size_t width;
    size_t height;
    size_t stride;
    
    unsigned char *data;
};

typedef struct BGRAVideoFrame BGRAVideoFrame;

@protocol VideoSourceDelegate <NSObject>

- (void)frameReady:(struct BGRAVideoFrame)frame;

@end

@interface VideoSource : NSObject<AVCaptureVideoDataOutputSampleBufferDelegate> 

@property (nonatomic,retain) AVCaptureSession *captureSession;
@property (nonatomic,retain) AVCaptureDeviceInput *deviceInput;
@property (nonatomic,weak) id <VideoSourceDelegate> delegate;

- (bool) startWithDevicePosition:(AVCaptureDevicePosition)
devicePosition;

- (void)addRawViewOutput;

@end
