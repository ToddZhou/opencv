//
//  ViewController.m
//  Opencv
//
//  Created by 周涛 on 15/8/25.
//  Copyright (c) 2015年 net.huiyutech. All rights reserved.
//

#import "ViewController.h"
#import "UIImage+OpenCV.h"
#import <opencv2/imgproc/types_c.h>

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *cardView;
@property (weak, nonatomic) IBOutlet UIButton *imagePicker;

@property (strong, nonatomic) VideoSource *source;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self.imagePicker addTarget:self action:@selector(openPicker:) forControlEvents:UIControlEventTouchUpInside];
    
    _cardView.image = [UIImage imageNamed:@"card.JPG"];

//    VideoSource *source = [[VideoSource alloc] init];
//    if([source startWithDevicePosition:AVCaptureDevicePositionFront])
//    {
//        NSLog(@"启动相机成功");
//        source.delegate = self;
//    }
//    
//    self.source = source;
}

- (void)frameReady:(BGRAVideoFrame)frame
{
    NSLog(@"width:%f,heigh:%f, method:%@",(float)frame.width,(float)frame.height,NSStringFromSelector(_cmd));
    
}

- (void)openPicker:(id)sender
{
//    [self.source addRawViewOutput];
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:picker animated:YES completion:^{
        ;
    }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    if (image) {
        _cardView.image = image;
    }
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)processHead
{
    cv::Mat grayFrame,_lastFrame, mask,bgModel,fgModel;
    UIImageToMat(_cardView.image, _lastFrame, false);
    cv::cvtColor(_lastFrame, grayFrame,cv::COLOR_RGBA2BGR);//转换成三通道bgr
    
    cv::Rect rectangle(1,1,grayFrame.cols-2,grayFrame.rows -2);//检测的范围
    //分割图像
    cv::grabCut(grayFrame, mask, rectangle, bgModel, fgModel, 3,cv::GC_INIT_WITH_RECT);//openCv强大的扣图功能
    
    int nrow = grayFrame.rows;
    int ncol = grayFrame.cols * grayFrame.channels();
    for(int j=0; j<nrow; j++){
        for(int i=0; i<ncol; i++){
            uchar val = mask.at<uchar>(j,i);
            if(val==cv::GC_PR_BGD){
                grayFrame.at<cv::Vec3b>(j,i)[0]= '\255';
                grayFrame.at<cv::Vec3b>(j,i)[1]= '\255';
                grayFrame.at<cv::Vec3b>(j,i)[2]= '\255';
            }
        }
    }
    cv::cvtColor(grayFrame, grayFrame,cv::COLOR_BGR2RGB); //转换成彩色图片
    _cardView.image = [[UIImage alloc] initWithCVMat:grayFrame];//显示结果
}

- (void)processSkin
{
    UIImage* image = self.cardView.image;
    // Convert UIImage* to cv::Mat
    cv::Mat cvImage;
    UIImageToMat(image, cvImage,false);
    IplImage* src = new IplImage(cvImage);
    IplImage* processed = NULL;
    
    [self skinDetectionYCrCb:src low:100 upper:150 imgProcessed:processed];
    
    _cardView.image = [UIImage convertToUIImage:processed];
    
}

//灰度图
- (cv::Mat)RBG2GRAY:(cv::Mat)mat
{
    cv::Mat gray_bi;
    cvtColor(mat, gray_bi, CV_BGR2GRAY);
    return gray_bi;
}

//轮廓提取
- (void)FindContours:(cv::Mat)mat
{
    IplImage* src = new IplImage(mat);
    CvScalar hole_color;
    CvScalar external_color;//绘制轮廓线的颜色
    
    CvMemStorage *storage = cvCreateMemStorage(0);
    CvSeq *contours =0;//外轮廓
    CvSeq *conInner =0;//内轮廓
    // 查找所有轮廓
    cvFindContours(src, storage, &contours,
                   sizeof(CvContour),
                   CV_RETR_LIST,
                   CV_CHAIN_APPROX_NONE,
                   cvPoint(0,0));
    
    // 填充所有轮廓
    cvDrawContours(src, contours, CV_RGB(255, 255, 255), CV_RGB(255, 255, 255), 2, CV_FILLED, 8, cvPoint(0, 0));
    
//    for (;contours!=0;contours=contours->h_next)
//    {
//        hole_color=CV_RGB(rand()&255,rand()&255,rand()&255);
//        external_color = CV_RGB(rand()&255,rand()&255,rand()&255);
//        cvDrawContours(src,contours,external_color,hole_color,1,2,8);
//    }
    
    int wai = 0;
    int nei = 0;
    double dConArea;
    for (; contours != NULL; contours = contours->h_next)
    {
        wai++;
        // 内轮廓循环
        for (conInner = contours->v_next; conInner != NULL; conInner = conInner->h_next)
        {
            nei++;
            // 内轮廓面积
            dConArea = fabs(cvContourArea(conInner, CV_WHOLE_SEQ));
        }
        CvRect rect = cvBoundingRect(contours,0);
        cvRectangle(src, cvPoint(rect.x, rect.y), cvPoint(rect.x + rect.width, rect.y + rect.height),CV_RGB(255,255, 255), 1, 8, 0);
    }

    cvReleaseMemStorage(&storage);
    storage = NULL;
}

//高斯滤波器滤波去噪（可选）
- (cv::Mat)Gaussian:(cv::Mat)mat
{
    int ksize = 3;
    cv::Mat g_gray;
    cv::Mat G_kernel = cv::getGaussianKernel(ksize,0.3*((ksize-1)*0.5-1)+0.8);
    filter2D(mat,g_gray,-1,G_kernel);
    //Sobel算子（x方向和y方向）
    cv::Mat sobel_x,sobel_y;
    Sobel(g_gray,sobel_x,CV_16S,1,0,3);
    Sobel(g_gray,sobel_y,CV_16S,0,1,3);
    cv::Mat abs_x,abs_y;
    convertScaleAbs(sobel_x,abs_x);
    convertScaleAbs(sobel_y,abs_y);
    cv::Mat grad;
    addWeighted(abs_x,0.5,abs_y,0.5,0,grad);
    cv::Mat img_bin;
    threshold(grad,img_bin,0,255,CV_THRESH_BINARY |CV_THRESH_OTSU);
    
    return img_bin;
}

//二值化
- (cv::Mat)Threshold:(cv::Mat)mat
{
    cv::Mat gray_bi;
    threshold(mat,gray_bi,0,255,CV_THRESH_OTSU);
    return gray_bi;
}

//边缘增强
- (cv::Mat)Canny:(cv::Mat)mat
{
    //灰度拉伸
    float num[256], p[256],p1[256];
    memset(num,0,sizeof(num));// 清空三个数组
    memset(p,0,sizeof(p));
    memset(p1,0,sizeof(p1));
    long wMulh = mat.cols * mat.rows;
    for (int i = 0; i < mat.cols; i++)
    {
        for (int j = 0; j < mat.rows; j++)
        {
            int v = mat.at<uchar>(j,i);
            num[v]++;
        }
    }
    for (int i = 0; i < 256; i++)//存放图像各个灰度级的出现概率
    {
        p[i] = num[i] / wMulh;
    }
    for (int i = 0; i < 256; i++)//求存放各个灰度级之前的概率和
    {
        for (int k = 0; k <= i; k++)
        {
            p1[i]+=p[k];
        }
    }
    for (int x = 0; x < mat.cols; x++)
    {
        for (int y = 0; y < mat.rows; y++)
        {
            int v = mat.at<uchar>(y,x);
            mat.at<uchar>(y,x) = p1[v]*255 + 0.5;
        }
    }
    //边缘增强
    cv::Mat gray_c;
    Canny(mat,gray_c,50,150,3);
    
    return gray_c;
}

//YCrCb空间的肤色提取
-(void)skinDetectionYCrCb:(IplImage*) imageRGB low:(int)lower upper:(int)upper imgProcessed:(IplImage*)imgProcessed
{
    assert(imageRGB->nChannels==3);
    IplImage* imageYCrCb = NULL;
    IplImage* imageCb = NULL;
    imageYCrCb = cvCreateImage(cvGetSize(imageRGB),8,3);
    imageCb = cvCreateImage(cvGetSize(imageRGB),8,1);
    
    cvCvtColor(imageRGB,imageYCrCb,CV_BGR2YCrCb);
    cvSplit(imageYCrCb,0,0,imageCb,0);//Cb
    for (int h=0;h<imageCb->height;h++)
    {
        for (int w=0;w<imageCb->width;w++)
        {
            unsigned char* p =(unsigned char*)(imageCb->imageData+h*imageCb->widthStep+w);
            if (*p<=upper&&*p>=lower)
            {
                *p=255;
            }
            else
            {
                *p=0;
            }
        }
    }
    cvCopy(imageCb,imgProcessed,NULL);
}

#pragma mark - action
- (IBAction)grayAction:(id)sender {

    UIImage* image = self.cardView.image;
    cv::Mat cvImage;
    UIImageToMat(image, cvImage,false);
    if (cvImage.empty()) {
        return;
    }
    
    cv::Mat result;
    result = [self RBG2GRAY:cvImage];

    self.cardView.image = MatToUIImage(result);
    
    cvImage = NULL;
    result = NULL;
}

- (IBAction)twoValue:(id)sender {
    UIImage* image = self.cardView.image;
    cv::Mat cvImage;
    UIImageToMat(image, cvImage,false);
    if (cvImage.empty()) {
        return;
    }
    
    cv::Mat result;
    result = [self Threshold:cvImage];
    
    self.cardView.image = MatToUIImage(result);
    
    cvImage = NULL;
    result = NULL;
}
- (IBAction)Contours:(id)sender {
    UIImage* image = self.cardView.image;
    cv::Mat cvImage;
    UIImageToMat(image, cvImage,false);
    if (cvImage.empty()) {
        return;
    }

    [self FindContours:cvImage];
    
    self.cardView.image = MatToUIImage(cvImage);
    
    cvImage = NULL;
}
- (IBAction)gas:(id)sender {
    UIImage* image = self.cardView.image;
    cv::Mat cvImage;
    UIImageToMat(image, cvImage,false);
    if (cvImage.empty()) {
        return;
    }
    
    [self Gaussian:cvImage];
    
    self.cardView.image = MatToUIImage(cvImage);
    
    cvImage = NULL;
}
- (IBAction)save:(id)sender {
    UIImageWriteToSavedPhotosAlbum(_cardView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

// 功能：显示图片保存结果
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo
{
    if (!error){
        
        [self showAlert:NSLocalizedString(@"保存成功", nil)];
    }else {
        [self showAlert:NSLocalizedString(@"保存失败", nil)];
    }
}

- (void) showAlert: (NSString *) message
{
    if (message != nil) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [av show];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
