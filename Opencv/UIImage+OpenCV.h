//
//  UIImage+OpenCV.h
//  Opencv
//
//  Created by 周涛 on 15/8/26.
//  Copyright (c) 2015年 net.huiyutech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/opencv.hpp>

@interface UIImage (UIImage_OpenCV)

+(UIImage *)imageWithCVMat:(const cv::Mat&)cvMat;
-(id)initWithCVMat:(const cv::Mat&)cvMat;

void UIImageToMat(const UIImage* image, cv::Mat& m,
                  bool alphaExist);
UIImage* MatToUIImage(const cv::Mat& image);

// UIImage类型转换为IPlImage类型
-(IplImage *)convertToIplImage;
/// IplImage类型转换为UIImage类型
+(UIImage *)convertToUIImage:(IplImage *)image;

@property(nonatomic, readonly) cv::Mat CVMat;
@property(nonatomic, readonly) cv::Mat CVGrayscaleMat;

@end
