//
//  CameraInternationalization.h
//
//
//  Created by sdk-suit on 15/10/10.
//  Copyright (c) 2015年 xll. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "EUtility.h"
#define kInternationalization(str) [CameraInternationalization localizedString:str,nil]
@interface CameraInternationalization : NSObject
+ (NSBundle *)pluginBundle;
+ (NSString*)localizedString:(NSString *)key, ...;
+ (UIImage *)getImageFromLocalFile:(NSString*)imageName type:(NSString *)type;
@end
