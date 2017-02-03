//
//  FaceLayerItem.h
//  EYE_Image_ Collect
//
//  Created by xl on 16/9/10.
//  Copyright © 2016年 Dennis Gao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FaceLabel.h"

@interface FaceLayerItem : NSObject


@property(nonatomic,strong) NSValue *layerRect;
@property(nonatomic,strong) FaceLabel *label;

+ (instancetype)faceItemWithRect:(NSValue *)layerRect;
@end
