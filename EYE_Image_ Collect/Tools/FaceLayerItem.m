//
//  FaceLayerItem.m
//  EYE_Image_ Collect
//
//  Created by xl on 16/9/10.
//  Copyright © 2016年 Dennis Gao. All rights reserved.
//

#import "FaceLayerItem.h"

@implementation FaceLayerItem


- (FaceLabel *)label {
    if (!_label) {
        _label = [[FaceLabel alloc]init];
    }
    return _label;
}

- (instancetype)initWithRect:(NSValue *)layerRect {
    if (self = [super init]) {
        self.layerRect = layerRect;
    }
    return self;
}
+ (instancetype)faceItemWithRect:(NSValue *)layerRect {
    FaceLayerItem *item = [[FaceLayerItem alloc]initWithRect:layerRect];
    return item;
}
@end
