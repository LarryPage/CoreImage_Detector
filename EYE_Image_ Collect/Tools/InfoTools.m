//
//  InfoTools.m
//  EYE_Image_ Collect
//
//  Created by Dennis Gao on 16/9/7.
//  Copyright © 2016年 Dennis Gao. All rights reserved.
//

#import "InfoTools.h"
#import "NSString+GZDDevice.h"
#import <AudioToolbox/AudioToolbox.h>
#import <CoreImage/CoreImage.h>
#import <CoreMotion/CoreMotion.h>// 陀螺仪

@interface InfoTools()

@property (nonatomic,strong)CMMotionManager *motionManager;// 陀螺仪
@property (nonatomic,assign)NSInteger deveiceDirection;// 陀螺仪

@end
@implementation InfoTools
static InfoTools *_instance;
+ (instancetype)shareInfoTools
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[InfoTools alloc] init];
    });
    return _instance;
}

#pragma mark - 保存图片至沙盒
- (void)saveImage:(UIImage *)currentImage withName:(NSString *)imageName{
    
    NSData *imageData = UIImageJPEGRepresentation(currentImage, 1.0);
    
    // 获取沙盒目录
    NSString *fullPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:imageName];
    
//    NSLog(@"%@",fullPath);
    
    // 将图片写入文件
    [imageData writeToFile:fullPath atomically:NO];
}



#pragma mark - 获取一个随机值
// 获取一个随机整数，范围在[from,to），包括from，不包括to
+ (int)getRandomNumber:(int)from to:(int)to
{
    return (int)(from + (arc4random() % (to - from + 1)));
}
#pragma mark - 获取系统时间
+ (NSString *)GetDateTime
{
    NSDate *senddate=[NSDate date];
    NSDateFormatter *dateformatter=[[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:@"YYYYMMddHHmmss"];
    NSString *morelocationString = [dateformatter stringFromDate:senddate];
    
    return morelocationString;
}

/**
 *  用来处理图片翻转90度
 *
 *  @param aImage
 *
 *  @return
 */
- (UIImage *)fixOrientation:(UIImage *)aImage
{
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}


#pragma mark - 给按钮点击增加音效
-(void)playSoundEffect:(NSString *)name
{
    NSString *audioFile=[[NSBundle mainBundle] pathForResource:name ofType:nil];
    NSURL *fileUrl=[NSURL fileURLWithPath:audioFile];
    //1.获得系统声音ID
    SystemSoundID soundID=0;
    /**
     * inFileUrl:音频文件url
     * outSystemSoundID:声音id（此函数会将音效文件加入到系统音频服务中并返回一个长整形ID）
     */
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)(fileUrl), &soundID);
    //如果需要在播放完之后执行某些操作，可以调用如下方法注册一个播放完成回调函数
    AudioServicesAddSystemSoundCompletion(soundID, NULL, NULL, soundCompleteCallback, NULL);
    //2.播放音频
    AudioServicesPlaySystemSound(soundID);//播放音效
    //    AudioServicesPlayAlertSound(soundID);//播放音效并震动
}
void soundCompleteCallback(SystemSoundID soundID, void * clientData){
    NSLog(@"播放完成...");
}


// 图片压缩(递归)
+ (NSData *)reSetMuImage:(UIImage *)image size:(int)size andCompressionQuality:(CGFloat)quality
{
    // 先检测quality的值。如果quality比0.001还要小，就直接返回数值.否则在进行压缩！
    NSData *tpData = UIImageJPEGRepresentation(image, quality);
    if (quality <= 0.001) {
        return tpData;
    }
    else{
        if (tpData.length > size *1024) {
            CGFloat qut = 0.0;
            qut = size/(tpData.length/1024.0);
            return [self reSetMuImage:image size:size andCompressionQuality:quality];
        }
        else{
            if (tpData == nil || tpData.length == 0) {
                tpData = UIImageJPEGRepresentation(image, 0.7);
            }
            return tpData;
        }
    }
}

/**
 *  获取设备分辨率
 *
 *  @return 倍数
 */
+ (double)getSCRScale
{
    CGFloat scale_screen = [UIScreen mainScreen].scale;
    return scale_screen;
}
/**
 *  获取iPone尺寸物理宽高
 *
 *  @return 返回宽高
 */
+ (CGSize)getSCRWith_Height
{
    NSString *device = [NSString GZDDevicePlatform];
    
    if ([device isEqualToString:@"iPhone 3GS"]) {
        
        return CGSizeMake(62.1, 115.5);
        
    }else if ([device isEqualToString:@"iPhone 4"]||[device isEqualToString:@"iPone 4s"]){
        
        return CGSizeMake(58.6, 115.2);
        
    }else if ([device isEqualToString:@"iPhone 5c"]){
        
        return CGSizeMake(59.2, 1124.4);
        
    }else if ([device isEqualToString:@"iPhone 5"] || [device isEqualToString:@"iPhone 5S"]){
        
        return CGSizeMake(58.6, 123.8);
        
    }else if ([device isEqualToString:@"iPhone 6"]){
        
        return CGSizeMake(67.0, 138.1);
        
    }else if ([device isEqualToString:@"iPhone 6s"]){
        
        return CGSizeMake(77.8, 158.1);
        
    }else
    {
        return CGSizeMake(0, 0);
    }
}


/**
 *  生成随机颜色
 *
 *  @return 颜色
 */
- (UIColor *)getArcColor
{
    int R = (arc4random() % 256) ;
    int G = (arc4random() % 256) ;
    int B = (arc4random() % 256) ;
    UIColor *color = [UIColor colorWithRed:R/255.0 green:G/255.0 blue:B/255.0 alpha:1];
    return color;
}




#pragma mark - 判断人脸
- (NSArray *)leftEyePositionsWithImage:(UIImage *)sImage
{
    if (![self hasFace:sImage]) {
        return nil;
    }
    
    NSArray *features = [self detectFaceWithImage:sImage];
    NSMutableArray *arrM = [NSMutableArray arrayWithCapacity:features.count];
    for (CIFaceFeature *f in features) {
        [arrM addObject:[NSValue valueWithCGRect:f.bounds]];
    }
    return arrM;
}


- (BOOL)hasFace:(UIImage *)sImage
{
    NSArray *features = [self detectFaceWithImage:sImage];
    return features.count?YES:NO;
}

-(NSArray *)judgeFac:(UIImage *)image
{
    NSArray *results = [self detectFaceWithImage:image];
    return results;
}
#pragma mark - faceDetectorMethods
/**识别脸部*/
-(NSArray *)detectFaceWithImage:(UIImage *)faceImag
{
    // 识别特征: 这里添加了眨眼和微笑
    //1,代表垂直,摄像头朝上 2,表示的效果和1相同 3,代表垂直,摄像头朝上 4,表示效果同3
    //5,代表水平,摄像头朝右 6,表示的效果和5相同 7,代表水平,摄像头朝左 8,表示效果同7
    NSDictionary *featuresParam = @{CIDetectorSmile: @YES,
                                    CIDetectorEyeBlink: @YES,
                                    CIDetectorImageOrientation:@(self.deveiceDirection),
                                    CIDetectorAccuracy: CIDetectorAccuracyLow};
    
    //此处是CIDetectorAccuracyHigh，若用于real-time的人脸检测，则用CIDetectorAccuracyLow，更快
    CIDetector *faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace
                                                  context:nil
                                                  options:featuresParam];
    
    CIImage *ciimg = [CIImage imageWithCGImage:faceImag.CGImage];
    NSArray *features = [faceDetector featuresInImage:ciimg options:featuresParam];
    for (CIFaceFeature *feature in features) {
        if (feature.hasSmile) {
            NSLog(@"微笑：%d", feature.hasSmile);
        }
        if (feature.rightEyeClosed) {
            NSLog(@"右眼：%d", feature.rightEyeClosed);
        }
        if (feature.leftEyeClosed) {
            NSLog(@"左眼：%d", feature.leftEyeClosed);
        }
        if (feature.hasFaceAngle) {
            NSLog(@"脸框：%d", feature.hasFaceAngle);
        }
        if (feature.hasMouthPosition) {
            NSLog(@"嘴：%d", feature.hasMouthPosition);
        }
    }
    return features;
}

- (void)zxMotionManager
{
    if (_motionManager == nil) {
        _motionManager = [[CMMotionManager alloc] init];
    }
    if ([_motionManager isGyroAvailable])
    {
        // deviceMotion 加速器和陀螺仪的复合型数据
        _motionManager.deviceMotionUpdateInterval = 1.0f;
        [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
            [self performSelectorOnMainThread:@selector(handleDeviceMotion:) withObject:motion waitUntilDone:YES];
        }];
    }
    else
    {
        NSLog(@"陀螺仪/加速器不可用");
        [self setMotionManager:nil];
    }
}


- (void)handleDeviceMotion:(CMDeviceMotion *)deviceMotion{
    double x = deviceMotion.gravity.x;
    double y = deviceMotion.gravity.y;
    if (fabs(y) >= fabs(x))
    {
        if (y >= 0){
            self.deveiceDirection = 3;
            // NSLog(@"屏幕直立，上下顛倒");
        }
        else{
            self.deveiceDirection = 1;
            // NSLog(@"屏幕直立");
        }
    }
    else
    {
        if (x >= 0){
            self.deveiceDirection = 5;
            // NSLog(@"屏幕向右橫置");
        }
        else{
            self.deveiceDirection = 7;
            // NSLog(@"屏幕向左横置");
        }
    }
}
@end
