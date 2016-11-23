//
//  CameraCommon.h
//  EUExCamera
//
//  Created by zywx on 16/1/22.
//  Copyright © 2016年 zywx. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface CameraCommon : NSObject
+ (UIImage*)createImageWithColor:(UIColor*)color size:(CGSize)imageSize;
+ (void)drawALineWithFrame:(CGRect)frame andColor:(UIColor*)color inLayer:(CALayer*)parentLayer;
+ (void)saveImageToPhotoAlbum:(UIImage*)image;
@end
