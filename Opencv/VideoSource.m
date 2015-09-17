//
//  VideoSource.m
//  Opencv
//
//  Created by 周涛 on 15/8/27.
//  Copyright (c) 2015年 net.huiyutech. All rights reserved.
//

#import "VideoSource.h"

@implementation VideoSource

- (void)dealloc
{
    _captureSession = nil;
    _deviceInput = nil;
    self.delegate = nil;
}

- (id)init
{
    if (self = [super init])
    {
        _captureSession = [[AVCaptureSession alloc] init];
        if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset640x480])
        {
            [_captureSession setSessionPreset:AVCaptureSessionPreset640x480];
            NSLog(@"Set capture session preset AVCaptureSessionPreset640x480");
        }else if ([_captureSession canSetSessionPreset:AVCaptureSessionPresetLow])
        {
            [_captureSession setSessionPreset:AVCaptureSessionPresetLow];
            NSLog(@"Set capture session preset AVCaptureSessionPresetLow");
        }
    }
    return self;
}

//外部调用，启动相机
- (bool) startWithDevicePosition:(AVCaptureDevicePosition)devicePosition
{
    AVCaptureDevice *device = [self cameraWithPosition:devicePosition];
    if (!device) return FALSE;
    
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    self.deviceInput = input;
    
    if (!error)//初始化没有发生错误
    {
        if ([[self captureSession] canAddInput:self.deviceInput])
        {
            [[self captureSession] addInput:self.deviceInput];
        }else
        {
            NSLog(@"Couldn't add video input");
            return FALSE;
        }
    }else
    {
        NSLog(@"Couldn't create video input");
        return FALSE;
    }
    //添加输出
    [self addRawViewOutput];
    //开始视频捕捉
    [_captureSession startRunning];
    return TRUE;
}

//获取相机
- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition) position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == position)
        {
            return device;
        }
    }
    return nil;
}

//添加输出
- (void)addRawViewOutput
{
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    //同一时间只处理一帧，否则no
    output.alwaysDiscardsLateVideoFrames = YES;
    
    //创建操作队列
    dispatch_queue_t queue;
    queue = dispatch_queue_create("com.lanhaijiye", nil);
    
    [output setSampleBufferDelegate:self queue:queue];
    
    NSString *keyString = (NSString *)kCVPixelBufferPixelFormatTypeKey;
    NSNumber *value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    
    NSDictionary *setting = [NSDictionary dictionaryWithObject:value forKey:keyString];
    [output setVideoSettings:setting];
    
    if ([self.captureSession canAddOutput:output])
    {
        [self.captureSession addOutput:output];
    }
}

#pragma -mark AVCaptureOutput delegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    //给图像加把锁
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    size_t stride = CVPixelBufferGetBytesPerRow(imageBuffer);
    
    BGRAVideoFrame frame = {width,height,stride,baseAddress};
    if (_delegate && [_delegate respondsToSelector:@selector(frameReady:)])
    {
        [_delegate frameReady:frame];
    }
    //解锁
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
}

@end
