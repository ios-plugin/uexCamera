//
//  UIImage+CameraResize.h
//  EUExCamera
//
//  Created by zywx on 16/1/22.
//  Copyright © 2016年 zywx. All rights reserved.
//
#import <UIKit/UIKit.h>
@interface UIImage (CameraResize)
- (UIImage *)croppedImage:(CGRect)bounds;
- (UIImage *)resizedImage:(CGSize)newSize
     interpolationQuality:(CGInterpolationQuality)quality;
- (UIImage *)resizedImageWithContentMode:(UIViewContentMode)contentMode
                                  bounds:(CGSize)bounds
                    interpolationQuality:(CGInterpolationQuality)quality;
- (UIImage *)resizedImage:(CGSize)newSize
                transform:(CGAffineTransform)transform
           drawTransposed:(BOOL)transpose
     interpolationQuality:(CGInterpolationQuality)quality;
- (CGAffineTransform)transformForOrientation:(CGSize)newSize;
- (UIImage *)fixOrientation;
- (UIImage *)rotatedByDegrees:(CGFloat)degrees;
@end
