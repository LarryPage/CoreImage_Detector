//
//  ViewController.m
//  EYE_Image_ Collect
//
//  Created by Dennis Gao on 16/9/7.
//  Copyright © 2016年 Dennis Gao. All rights reserved.
//

#import "ViewController.h"
#import "InfoTools.h"



#import <AudioToolbox/AudioToolbox.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>
#import <CoreMotion/CoreMotion.h>// 陀螺仪
typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);

#define kMusicBtn @"7142.wav"

@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    CGFloat x;
    CGFloat y;
    CGFloat z;
    
    int CambtnX ;
    int CambtnY ;
    
    BOOL isClick;// 判断按钮是否被点击
}
@property (assign,nonatomic) AVCaptureDevicePosition cameraPosition;//摄像头位置
@property (nonatomic,strong) CMMotionManager *motionManager;// 陀螺仪
@property (nonatomic,strong) AVCaptureVideoDataOutput *captureVideoDataOutput;
@property (strong,nonatomic) AVCaptureSession *captureSession;//负责输入和输出设备之间的数据传递
@property (strong,nonatomic) AVCaptureDeviceInput *captureDeviceInput;//负责从AVCaptureDevice获得输入数据
@property (strong,nonatomic) AVCaptureStillImageOutput *captureStillImageOutput;//照片输出流
@property (strong,nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;//相机拍摄预览图层
@property (nonatomic,strong)UIView *videoMainView;// 映射图层
@property (nonatomic,strong)UIImageView *focusCursor;// 聚焦光圈
@property (nonatomic,strong)UIButton *camBtn;// 拍照按钮
@property (nonatomic,strong)UIButton *toggleCameraBtn;// 摄像头位置切换按钮
@property (nonatomic,strong)UIImageView *imageView;// 转换
@property (nonatomic,strong)NSTimer *timer;// 控制拍照按钮
@property (nonatomic,strong)UILabel *label;// 扫描到标记
@property (nonatomic,strong)NSMutableArray *labelData;
@end

@implementation ViewController
#pragma mark - 懒加载
- (NSMutableArray *)labelData
{
    if (_labelData == nil) {
        _labelData = [NSMutableArray array];
    }
    return _labelData;
}

- (UIImageView *)imageView
{
    if (_imageView == nil) {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, SCR_WIDTH, SCR_HEIGHT)];
        _imageView.backgroundColor = [UIColor clearColor];
    }
    return _imageView;
}
- (UIView *)videoMainView
{
    if (_videoMainView == nil) {
        _videoMainView = [[UIView alloc] init];
        _videoMainView.frame = CGRectMake(0, 0, SCR_WIDTH ,SCR_HEIGHT);
        _videoMainView.backgroundColor = [UIColor clearColor];
    }
    return _videoMainView;
}

- (UIButton *)camBtn
{
    if (_camBtn == nil) {
        _camBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _camBtn.backgroundColor = [InfoTools shareInfoTools].getArcColor;
        
        CambtnX = [InfoTools getRandomNumber:kNum*2 to:SCR_WIDTH - (kNum*2)];
        CambtnY = [InfoTools getRandomNumber:kNum*2 to:SCR_HEIGHT - (kNum*2)];
        
        _camBtn.frame = CGRectMake(CambtnX, CambtnY, kNum*2, kNum*2);
        // 设置元角度
        _camBtn.layer.cornerRadius = 20.0;
        _camBtn.layer.borderWidth = 1.0;
        _camBtn.layer.borderColor = [UIColor clearColor].CGColor;
        _camBtn.clipsToBounds = TRUE;//去除边界
        
        [_camBtn setTitle:@"抓" forState:UIControlStateNormal];
        [_camBtn addTarget:self action:@selector(takeButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _camBtn;
}

- (UIButton *)toggleCameraBtn
{
    if (_toggleCameraBtn == nil) {
        _toggleCameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _toggleCameraBtn.backgroundColor = [InfoTools shareInfoTools].getArcColor;
        
        _toggleCameraBtn.frame = CGRectMake(10, 20, kNum*2, kNum*2);
        // 设置元角度
        _toggleCameraBtn.layer.cornerRadius = 20.0;
        _toggleCameraBtn.layer.borderWidth = 1.0;
        _toggleCameraBtn.layer.borderColor = [UIColor clearColor].CGColor;
        _toggleCameraBtn.clipsToBounds = TRUE;//去除边界
        
        [_toggleCameraBtn setTitle:@"前" forState:UIControlStateNormal];
        [_toggleCameraBtn addTarget:self action:@selector(toggleCameraClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _toggleCameraBtn;
}


#pragma mark - VC周期
- (void)viewDidLoad {
    [super viewDidLoad];

    [[InfoTools shareInfoTools] zxMotionManager];
    
    [self.view addSubview:self.videoMainView];

    [self.videoMainView addSubview:self.camBtn];
    
    self.cameraPosition=AVCaptureDevicePositionFront;
    [self.view addSubview:self.toggleCameraBtn];
    
    self.label.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self createTimeBtn];
    // 初始化一次陀螺仪
    [self useGyroPush];
    // 初始化相机
    [self getCameraSession];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.captureSession startRunning];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self.captureSession stopRunning];
}

/**
 *  初始化定时器
 */
- (void)createTimeBtn
{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(hiddenBtn) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop]addTimer:self.timer forMode:NSDefaultRunLoopMode];
    
    [self.timer fire];
}
- (void)hiddenBtn
{
    
    CambtnX = [InfoTools getRandomNumber:kNum*2 to:SCR_WIDTH - (kNum*2)];
    CambtnY = [InfoTools getRandomNumber:kNum*2 to:SCR_HEIGHT - (kNum*2)];
    
    self.camBtn.frame = CGRectMake( CambtnX, CambtnY, kNum*2, kNum*2);
}
#pragma mark - 初始化相机
- (void)getCameraSession
{
    //初始化会话
    _captureSession=[[AVCaptureSession alloc]init];
    if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {//设置分辨率
        _captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
    }
    //获得输入设备AVCaptureDevicePositionFront,AVCaptureDevicePositionBack
    AVCaptureDevice *captureDevice=[self getCameraDeviceWithPosition:self.cameraPosition];//取得前置摄像头
    if (!captureDevice) {
        NSLog(@"取得前置摄像头时出现问题.");
        return;
    }
    
    NSError *error=nil;
    //根据输入设备初始化设备输入对象，用于获得输入数据
    _captureDeviceInput=[[AVCaptureDeviceInput alloc]initWithDevice:captureDevice error:&error];
    if (error) {
        NSLog(@"取得设备输入对象时出错，错误原因：%@",error.localizedDescription);
        return;
    }
    //将设备输入添加到会话中
    if ([_captureSession canAddInput:_captureDeviceInput]) {
        [_captureSession addInput:_captureDeviceInput];
    }
    
    //初始化设备输出对象，用于获得输出数据
    _captureStillImageOutput=[[AVCaptureStillImageOutput alloc]init];
    NSDictionary *outputSettings = @{AVVideoCodecKey:AVVideoCodecJPEG};
    [_captureStillImageOutput setOutputSettings:outputSettings];//输出设置
    
    //将设备输出添加到会话中
    if ([_captureSession canAddOutput:_captureStillImageOutput]) {
        [_captureSession addOutput:_captureStillImageOutput];
    }
    
    //创建视频预览层，用于实时展示摄像头状态
    _captureVideoPreviewLayer=[[AVCaptureVideoPreviewLayer alloc]initWithSession:self.captureSession];
    
    CALayer *layer=self.videoMainView.layer;
    layer.masksToBounds=YES;
    _captureVideoPreviewLayer.frame=layer.bounds;
    _captureVideoPreviewLayer.videoGravity=AVLayerVideoGravityResizeAspectFill;//填充模式
    
    //将视频预览层添加到界面中
    [layer addSublayer:_captureVideoPreviewLayer];
    [layer insertSublayer:_captureVideoPreviewLayer below:self.focusCursor.layer];// 没啥用的东西

    // 初始化数据流
    [self addVidelDataOutput];
}
/**
 *  AVCaptureVideoDataOutput 获取数据流
 */
- (void)addVidelDataOutput
{
    AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    captureOutput.alwaysDiscardsLateVideoFrames = YES;
    
    dispatch_queue_t queue;
    queue = dispatch_queue_create("myQueue", DISPATCH_QUEUE_SERIAL);
    [captureOutput setSampleBufferDelegate:self queue:queue];
    
    NSString *key = (NSString *)kCVPixelBufferPixelFormatTypeKey;
    NSNumber *value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary *settings = @{key:value};
    [captureOutput setVideoSettings:settings];
    
    [self.captureSession addOutput:captureOutput];
    
}

#pragma mark 拍照
- (IBAction)takeButtonClick:(UIButton *)sender {
    // 启动陀螺仪
    [self useGyroPush];
    [[InfoTools shareInfoTools] playSoundEffect:kMusicBtn];
    isClick = 1;
}

- (IBAction)toggleCameraClick:(UIButton *)sender {
    if (self.cameraPosition==AVCaptureDevicePositionFront) {
        self.cameraPosition=AVCaptureDevicePositionBack;
        [_toggleCameraBtn setTitle:@"后" forState:UIControlStateNormal];
    }
    else{
        self.cameraPosition=AVCaptureDevicePositionFront;
        [_toggleCameraBtn setTitle:@"前" forState:UIControlStateNormal];
    }
    
    //获得输入设备AVCaptureDevicePositionFront,AVCaptureDevicePositionBack
    AVCaptureDevice *captureDevice=[self getCameraDeviceWithPosition:self.cameraPosition];//取得前置摄像头
    if (!captureDevice) {
        NSLog(@"取得前置摄像头时出现问题.");
        return;
    }
    
    [_captureSession beginConfiguration];
    
    [_captureSession removeInput:_captureDeviceInput];
    
    NSError *error=nil;
    //根据输入设备初始化设备输入对象，用于获得输入数据
    _captureDeviceInput=[[AVCaptureDeviceInput alloc]initWithDevice:captureDevice error:&error];
    if (error) {
        NSLog(@"取得设备输入对象时出错，错误原因：%@",error.localizedDescription);
        return;
    }
    
    //将设备输入添加到会话中
    if ([_captureSession canAddInput:_captureDeviceInput]) {
        [_captureSession addInput:_captureDeviceInput];
    }
    
    [_captureSession commitConfiguration];
}

#pragma mark - 私有方法

/**
 *  取得指定位置的摄像头
 *
 *  @param position 摄像头位置
 *
 *  @return 摄像头设备
 */
-(AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position{
    NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position] == position) {
            return camera;
        }
    }
    return nil;
}

/**
 *  改变设备属性的统一操作方法
 *
 *  @param propertyChange 属性改变操作
 */
-(void)changeDeviceProperty:(PropertyChangeBlock)propertyChange
{
    AVCaptureDevice *captureDevice= [self.captureDeviceInput device];
    NSError *error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error])
    {
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
    }else
    {
        NSLog(@"设置设备属性过程发生错误，错误信息：%@",error.localizedDescription);
    }
}
#pragma mark - 获取陀螺仪的值
- (void)useGyroPush
{
    //初始化全局管理对象
    CMMotionManager *manager = [[CMMotionManager alloc] init];
    self.motionManager = manager;
    //判断陀螺仪可不可以，判断陀螺仪是不是开启
    //    BOOL m = [manager isGyroActive];
    if ([manager isGyroAvailable]){
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        //告诉manager，更新频率是100Hz
        manager.gyroUpdateInterval = 0.01;
        //Push方式获取和处理数据
        [manager startGyroUpdatesToQueue:queue
                             withHandler:^(CMGyroData *gyroData, NSError *error)
         {
              x = gyroData.rotationRate.x;
              y = gyroData.rotationRate.y;
              z = gyroData.rotationRate.z;
             [manager stopGyroUpdates];
         }];
        
    }
}
#pragma mark - Samle Buffer Delegate
// 抽样缓存写入时所调用的委托程序
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    UIImage *img = [self imageFromSampleBuffer:sampleBuffer];
    UIImage *image = [[InfoTools shareInfoTools] fixOrientation:img];
    // 人脸检测
    NSArray *features = [[InfoTools shareInfoTools]leftEyePositionsWithImage:image];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.videoMainView.subviews.count -1 <features.count) {
            FaceLabel *label =[[FaceLabel alloc]init];
            label.hidden = YES;
            [self.videoMainView addSubview:label];
        }
        for (UIView *label in self.videoMainView.subviews) {
            if ([label isMemberOfClass:[FaceLabel class]]) {
                label.hidden = YES;
            }
        }
        if (features.count >0) {
            for (int i=0;i<features.count; i++) {
                NSValue *layerRect = features[i];
                FaceLabel *label = self.videoMainView.subviews[i+1];
               
                CGRect originalRect = [layerRect CGRectValue];
                
                CGRect getRect = [self getUIImageViewRectFromCIImageRect:originalRect];
                
                label.frame = getRect;
                label.hidden = NO;
                
            }
        }
        else{
            for (UIView *label in self.videoMainView.subviews) {
                if ([label isMemberOfClass:[FaceLabel class]]) {
                    label.hidden = YES;
                }
            }
        }
    });
//    if (features.count >0) {
//        for (int i=0;i<features.count; i++) {
//            
//            
//            NSValue *layerRect = features[i];
//            FaceLabel *label = self.videoMainView.subviews[i+1];
//            dispatch_async(dispatch_get_main_queue(), ^{
//                CGRect originalRect = [layerRect CGRectValue];
//                
//                CGRect getRect = [self getUIImageViewRectFromCIImageRect:originalRect];
//                
//                label.frame = getRect;
////                self.label.hidden = NO;
////                [UIView animateWithDuration:0.1 animations:^{
////                    self.label.frame = getRect;
////                    
////                }];
//                
//            });
//        }
//    }
//    else{
//        dispatch_async(dispatch_get_main_queue(), ^{
////            self.label.hidden = YES;
//            [self.videoMainView.subviews makeObjectsPerformSelector:@selector(setHidden:) withObject:@(1)];
//        });
//    }

//    NSArray *features = [[InfoTools shareInfoTools]leftEyePositionsWithImage:image];
//    NSLog(@"features >>>>>>>> %ld",(unsigned long)features.count);
//    if (features.count >0) {
//        for (NSValue *rectValue in features) {
//            
//            CGRect originalRect = [rectValue CGRectValue];
//            
//            CGRect getRect = [self getUIImageViewRectFromCIImageRect:originalRect];
//            
//            dispatch_async(dispatch_get_main_queue(), ^{
//                self.label.hidden = NO;
//                [UIView animateWithDuration:0.1 animations:^{
//                    self.label.frame = getRect;
//                    
//                }];
//                
//            });
//        }
//    }
//    else{
//        dispatch_async(dispatch_get_main_queue(), ^{
//            self.label.hidden = YES;
//        });
//    }
    
    
    if (isClick) {
        // 保存图片至本地
        NSString *strPicName = [NSString stringWithFormat:@"Image"];
        
        CGFloat SCRW = [InfoTools getSCRWith_Height].width;
        CGFloat SCRH = [InfoTools getSCRWith_Height].height;
         CGFloat scale = [InfoTools getSCRScale];
        NSString *indexStr = [NSString stringWithFormat:@"%@_(%d,%d)_(%0.1f,%0.1f)_(720,1280)_(%0.1f,%0.1f)_(%f,%f,%f).png",strPicName,CambtnX,CambtnY,SCRW,SCRH,SCR_WIDTH*scale,SCR_HEIGHT*scale,x,y,z];
        NSLog(@"%@",indexStr);
        [InfoTools.shareInfoTools saveImage:image withName:indexStr];
        [self.captureSession startRunning];
        isClick = 0;
    }
}
//在该代理方法中，sampleBuffer是一个Core Media对象，可以引入Core Video供使用
// 通过抽样缓存数据创建一个UIImage对象
- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
    CIContext *temporaryContext = [CIContext contextWithOptions:nil];
    CGImageRef videoImage = [temporaryContext createCGImage:ciImage fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(imageBuffer), CVPixelBufferGetHeight(imageBuffer))];
    UIImage *result = [[UIImage alloc] initWithCGImage:videoImage scale:1.0 orientation:UIImageOrientationLeftMirrored];
    CGImageRelease(videoImage);
    return result;
}
- (void)dealloc
{
    [self.timer invalidate];
    self.timer = nil;
}
/**
 *  图片GIImage转换
 *
 *  @param originAllRect
 *
 *  @return
 */
- (CGRect)getUIImageViewRectFromCIImageRect:(CGRect)originAllRect
{
    CGRect getRect = originAllRect;

    float scrSalImageW = 720/SCR_WIDTH;
    float scrSalImageH = 1280/SCR_HEIGHT;
    
    getRect.size.width = originAllRect.size.width/scrSalImageW;
    getRect.size.height = originAllRect.size.height/scrSalImageH;
    
    float hx = self.videoMainView.frame.size.width/720;
    float hy = self.videoMainView.frame.size.height/1280;
    
    if (self.cameraPosition==AVCaptureDevicePositionFront) {
        getRect.origin.x = originAllRect.origin.x*hx;//*hx
    }
    else{
        getRect.origin.x = (self.videoMainView.frame.size.width - originAllRect.origin.x*hx) - getRect.size.width;
    }
    getRect.origin.y = (self.videoMainView.frame.size.height - originAllRect.origin.y*hy) - getRect.size.height;
    

    return getRect;
}

@end
