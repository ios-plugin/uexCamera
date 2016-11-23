//
//  CameraUtility.m
//  EUExCamera
//
//  Created by zywx on 16/2/2.
//  Copyright © 2016年 xll. All rights reserved.
//

#import "CameraUtility.h"

@implementation CameraUtility

#pragma mark - 获得保存图片的名字 处理图片根据图片宽度 保存图片

+ (NSString *)getSavename:(NSString *)type wgtPath:(NSString *)wgtPath {
    NSString * photoPath = [wgtPath stringByAppendingPathComponent:@"photo"];
    NSFileManager * filemag = [NSFileManager defaultManager];
    if (![filemag fileExistsAtPath:photoPath]) {
        [filemag createDirectoryAtPath:photoPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString * filepath_cfg = [photoPath stringByAppendingPathComponent:@"photoCfg.cfg"];
    NSString * maxNum = [NSString stringWithContentsOfFile:filepath_cfg encoding:NSUTF8StringEncoding error:nil];
    int max = 0;
    NSString * saveName;
    if (maxNum) {
        max = [maxNum intValue];
        if (max == 9999) {
            max = 0;
        } else {
            max ++;
        }
        NSString * currentMax = [NSString stringWithFormat:@"%d",max];
        [currentMax writeToFile:filepath_cfg atomically:YES encoding:NSUTF8StringEncoding error:nil];
    } else {
        NSString * currentMax = @"0";
        [currentMax writeToFile:filepath_cfg atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
    NSString * fileType;
    if ([type isEqualToString:@"image"]) {
        fileType = @"JPG";
    } else {
        fileType = @"MOV";
    }
    if (max < 10 && max >= 0) {
        if ([fileType isEqualToString:@"JPG"]) {
            fileType = @"jpg";
        }
        saveName = [NSString stringWithFormat:@"IMG000%d.%@", max, fileType];
    } else if (max < 100 && max >= 10) {
        saveName = [NSString stringWithFormat:@"IMG00%d.%@", max, fileType];
    } else if (max < 1000 && max >= 100) {
        saveName = [NSString stringWithFormat:@"IMG0%d.%@", max, fileType];
    } else if (max < 10000 && max >= 1000) {
        saveName = [NSString stringWithFormat:@"IMG%d.%@", max, fileType];
    } else {
        saveName = [NSString stringWithFormat:@"IMG0000.%@", fileType];
    }
    return [photoPath stringByAppendingPathComponent:saveName];
}

+ (UIImage *)imageByScalingAndCroppingForSize:(UIImage *)sourceImage width:(float)destWith {
    UIImage * newImage = nil;
    CGFloat srcWidth = sourceImage.size.width;
    CGFloat srcHeight = sourceImage.size.height;
    CGFloat targetWidth;
    CGFloat targetHeight;
    if (srcWidth <= destWith) {
        targetWidth = srcWidth;
        targetHeight = srcHeight;
    } else {
        targetWidth = destWith;
        targetHeight = (srcHeight * destWith)/(srcWidth * 1.0);
    }
    
    CGSize targetSize = CGSizeMake(targetWidth, targetHeight);
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    if (CGSizeEqualToSize(sourceImage.size, targetSize) == NO) {
        CGFloat widthFactor = targetWidth / srcWidth;
        CGFloat heightFactor = targetHeight / srcHeight;
        if (widthFactor > heightFactor){
            scaleFactor = widthFactor; // scale to fit height
        } else {
            scaleFactor = heightFactor; // scale to fit width
        }
        scaledWidth  = srcWidth * scaleFactor;
        scaledHeight = srcHeight * scaleFactor;
        // center the image
        if (widthFactor > heightFactor) {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        } else if (widthFactor < heightFactor) {
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    UIGraphicsBeginImageContext(targetSize); // this will crop
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    [sourceImage drawInRect:thumbnailRect];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if(newImage == nil) {
        UIGraphicsEndImageContext();
    }
    return newImage;
}

@end
