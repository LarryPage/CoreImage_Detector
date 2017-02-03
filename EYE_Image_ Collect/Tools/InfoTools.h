//
//  InfoTools.h
//  EYE_Image_ Collect
//
//  Created by Dennis Gao on 16/9/7.
//  Copyright © 2016年 Dennis Gao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FaceLayerItem.h"

@interface InfoTools : NSObject
+ (instancetype)shareInfoTools;

/**
 *  生成随机颜色
 *
 *  @return 颜色
 */
- (UIColor *)getArcColor;
// 获取设备
+ (double)getSCRScale;
/**
 *  获取设备物理宽高
 *
 *  @return 宽高
 */
+ (CGSize)getSCRWith_Height;

/**
 *  获取一个随机整数，范围在[from,to），包括from，不包括to
 *
 *  @param from 开始(包括)
 *  @param to   结束(不包括)
 *
 *  @return 一个随机数
 */
+ (int)getRandomNumber:(int)from to:(int)to;


/**
 *  保存图片到本地
 *
 *  @param currentImage 图片
 *  @param imageName    图片名称
 */
- (void)saveImage:(UIImage *)currentImage withName:(NSString *)imageName;


/**
 *  用来处理图片翻转90度
 *
 *  @param aImage
 *
 *  @return
 */
- (UIImage *)fixOrientation:(UIImage *)aImage;

/**
 *  添加音效
 *
 *  @param name 音效文件的名称
 */
-(void)playSoundEffect:(NSString *)name;


/**
 *  人脸识别
 *
 *  @param image 图片
 *
 *  @return Bool
 */
-(NSArray *)judgeFac:(UIImage *)image;





- (NSArray *)leftEyePositionsWithImage:(UIImage *)sImage;

//开启重力
- (void)zxMotionManager;
@end
