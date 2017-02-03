//
//  FaceLabel.m
//  EYE_Image_ Collect
//
//  Created by xl on 16/9/10.
//  Copyright © 2016年 Dennis Gao. All rights reserved.
//

#import "FaceLabel.h"

@implementation FaceLabel


- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self setupUI];
    }
    return self;
}
- (void)setupUI {
    self.backgroundColor = [UIColor clearColor];
    self.layer.borderColor = [[UIColor redColor] CGColor];
    self.layer.borderWidth = 5;
}
@end
