//
//  CameraUtility.h
//  EUExCamera
//
//  Created by zywx on 16/2/2.
//  Copyright © 2016年 xll. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CameraUtility : NSObject

+ (NSString *)getSavename:(NSString *)type wgtPath:(NSString *)wgtPath;
+ (UIImage *)imageByScalingAndCroppingForSize:(UIImage *)sourceImage width:(float)destWith;
@end
