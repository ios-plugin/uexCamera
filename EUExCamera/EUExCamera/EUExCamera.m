//
//  EUExCamera.m
//  AppCan
//
//  Created by AppCan on 11-8-26.
//  Copyright 2011 AppCan. All rights reserved.
//

#import "EUExCamera.h"
#import "EUtility.h"
#import "EUExBaseDefine.h"

@implementation EUExCamera

#define IsIOS6OrLower ([[[UIDevice currentDevice] systemVersion] floatValue]<7.0)

-(id)initWithBrwView:(EBrowserView *) eInBrwView{
	if (self = [super initWithBrwView:eInBrwView]) {
	}
	return self;
}

#pragma mark -
#pragma mark - dealloc

-(void)dealloc{
    [super dealloc];
}

-(void)clean{
    
}

#pragma mark -
#pragma mark - Plugin Method

-(void)open:(NSMutableArray *)inArguments {
    isCompress = NO;
    if ([inArguments isKindOfClass:[NSMutableArray class]] && [inArguments count] > 0) {
        NSString * compress = [inArguments objectAtIndex:0];
        if ([compress isKindOfClass:[NSString class]] && compress.length > 0) {
            if (0 == [compress intValue]) {
                isCompress = YES;
                if ([inArguments count] == 2) {
                    NSString * scaleStr = [inArguments objectAtIndex:1];
                    if ([scaleStr isKindOfClass:[NSString class]] && scaleStr.length>0) {
                        scale = [scaleStr floatValue]/100;
                        if (scale > 100) {
                            scale = 0.5;
                        } else if(scale < 0){
                            scale = 0.5;
                        }
                    } else {
                        scale = 0.5;
                    }
                } else {
                    scale = 0.5;
                }
            }
        }
    }
	[self showCamera];
}

-(void)showCamera {
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [super jsFailedWithOpId:0 errorCode:1030108 errorDes:UEX_ERROR_DESCRIBE_DEVICE_SUPPORT];
    } else {
        UIImagePickerController * imagePickerController = [[UIImagePickerController alloc] init];
        [imagePickerController setDelegate:self];
        //        [imagePickerController setAllowsEditing:YES];
        [imagePickerController setSourceType:UIImagePickerControllerSourceTypeCamera];
        [imagePickerController setVideoQuality:UIImagePickerControllerQualityTypeMedium];
		if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0) {
			[EUtility brwView:meBrwView presentModalViewController:imagePickerController animated:YES];
		} else {
			[EUtility brwView:meBrwView navigationPresentModalViewController:imagePickerController animated:YES];
		}
        if (IsIOS6OrLower) {
            
        } else {
            UIViewController *controller = [EUtility brwCtrl:meBrwView];
            [controller setNeedsStatusBarAppearanceUpdate];
        }
        [imagePickerController release];
    }
}

#pragma mark -
#pragma mark - CallBack

-(void)uexSuccessWithOpId:(int)inOpId dataType:(int)inDataType data:(NSString *)inData {
	if (inData) {
		[self jsSuccessWithName:@"uexCamera.cbOpen" opId:inOpId dataType:inDataType strData:inData];
	}
}

#pragma mark -
#pragma mark - UIImagePickerControllerDelegate

-(void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error
  contextInfo:(void *)contextInfo {
	if (error != NULL) {
		[super jsFailedWithOpId:0 errorCode:1030105 errorDes:UEX_ERROR_DESCRIBE_FILE_SAVE];
	}
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	if (picker) {
		[picker dismissModalViewControllerAnimated:YES];
	}
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	NSString * mediaType = [info objectForKey:UIImagePickerControllerMediaType];
	if ([mediaType isEqualToString:@"public.image"]){
        UIImage * image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
        //同时有模态视图的时候需要 模态视图关闭动画之后再保存图片
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 5.0) {
            [picker dismissViewControllerAnimated:YES completion:^{
                [self performSelector:@selector(savaImg:) withObject:image afterDelay:0];
            }];
        }else{
            [picker dismissModalViewControllerAnimated:NO];
            [self performSelector:@selector(savaImg:) withObject:image afterDelay:0];
        }
	}
}

#pragma mark -
#pragma mark - 获得保存图片的名字 处理图片根据图片宽度 保存图片

-(NSString *)getSavename:(NSString *)type {
    NSString * wgtPath = [super absPath:@"wgts://"];//暂时改为用wgts协议路径来保证一定是在Documents目录下
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
	
	if (max < 10 & max >= 0) {
        if ([fileType isEqualToString:@"JPG"]) {
            fileType = @"jpg";
        }
		saveName = [NSString stringWithFormat:@"IMG000%d.%@", max, fileType];
	} else if (max < 100 & max >= 10) {
		saveName = [NSString stringWithFormat:@"IMG00%d.%@", max, fileType];
	} else if (max < 1000 & max >= 100) {
		saveName = [NSString stringWithFormat:@"IMG0%d.%@", max, fileType];
	} else if (max < 10000 & max >= 1000) {
		saveName = [NSString stringWithFormat:@"IMG%d.%@", max, fileType];
	} else {
		saveName = [NSString stringWithFormat:@"IMG0000.%@", fileType];
	}
	return [photoPath stringByAppendingPathComponent:saveName];
}

-(UIImage *)imageByScalingAndCroppingForSize:(UIImage *)sourceImage width:(float)destWith {
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

-(void)savaImg:(UIImage *)image {
	//保存到一个指定目录
	NSError * error;
    NSFileManager * fmanager = [NSFileManager defaultManager];
    NSString * imagePath = [self getSavename:@"image"];
 	if([fmanager fileExistsAtPath:imagePath]) {
        [fmanager removeItemAtPath:imagePath error:&error];
	}
	UIImage * newImage = [EUtility rotateImage:image];
    //压缩
    UIImage * needSaveImg = [self imageByScalingAndCroppingForSize:newImage width:640];
    //压缩比率，0：压缩后的图片最小，1：压缩后的图片最大
    NSData * imageData = nil;
    if (isCompress) {
        imageData = UIImageJPEGRepresentation(needSaveImg, scale);
    } else {
        imageData = UIImageJPEGRepresentation(needSaveImg, 1);
    }
	BOOL success = [imageData writeToFile:imagePath atomically:YES];
	if (success) {
		[self uexSuccessWithOpId:0 dataType:UEX_CALLBACK_DATATYPE_TEXT data:imagePath];
	} else {
		[super jsFailedWithOpId:0 errorCode:1030105 errorDes:UEX_ERROR_DESCRIBE_FILE_SAVE];
	}
}

@end
