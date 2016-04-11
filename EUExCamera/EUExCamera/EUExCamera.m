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
#import "CameraUtility.h"
#import "CameraCaptureCamera.h"
#import "CameraPickerController.h"
#import "CameraInternationalization.h"

@interface EUExCamera(){

}

@end

@implementation EUExCamera

#define IsIOS6OrLower ([[[UIDevice currentDevice] systemVersion] floatValue]<7.0)

-(id)initWithBrwView:(EBrowserView *) eInBrwView{
	if (self = [super initWithBrwView:eInBrwView]) {
	}
    self.imagePickerController = [[UIImagePickerController alloc] init];
	return self;
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
                scale = 0.5;
                if ([inArguments count] == 2) {
                    NSString * scaleStr = [inArguments objectAtIndex:1];
                    float scalefloat = [scaleStr floatValue]/100;
                    if (scalefloat <= 100 && scalefloat >= 0 ) {
                        scale = scalefloat;
                    }
                }
            }
        }
    }
    [self showCamera];

}

-(void)openInternal:(NSMutableArray *)inArguments {
   
    NSLog(@"uexCamera==>>openInternal");
    isCompress = NO;
    if ([inArguments isKindOfClass:[NSMutableArray class]] && [inArguments count] > 0) {
        NSString * compress = [inArguments objectAtIndex:0];
        if ([compress isKindOfClass:[NSString class]] && compress.length > 0) {
            if (0 == [compress intValue]) {
                isCompress = YES;
                scale = 0.5;
                if ([inArguments count] == 2) {
                    NSString * scaleStr = [inArguments objectAtIndex:1];
                    float scalefloat = [scaleStr floatValue]/100;
                    if (scalefloat <= 100 && scalefloat >= 0 ) {
                        scale = scalefloat;
                    }
                }
            }
        }
    }
    if (!self.cameraPickerController) {
        
        self.cameraPickerController = [[CameraPickerController alloc] init];
    }
    
    self.cameraPickerController.meBrwView = meBrwView;
    self.cameraPickerController.uexObj = self;
    self.cameraPickerController.scale = scale;
    self.cameraPickerController.isCompress = isCompress;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0) {
        [EUtility brwView:meBrwView presentModalViewController:self.cameraPickerController animated:YES];
    } else {
        [EUtility brwView:meBrwView navigationPresentModalViewController:self.cameraPickerController animated:YES];
    }
    
}


-(void)showCamera {
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [super jsFailedWithOpId:0 errorCode:1030108 errorDes:UEX_ERROR_DESCRIBE_DEVICE_SUPPORT];
    } else {
        
        [self.imagePickerController setDelegate:self];
        //        [imagePickerController setAllowsEditing:YES];
        [self.imagePickerController setSourceType:UIImagePickerControllerSourceTypeCamera];
        [self.imagePickerController setVideoQuality:UIImagePickerControllerQualityTypeMedium];
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0) {
            [EUtility brwView:meBrwView presentModalViewController:self.imagePickerController animated:YES];
        } else {
            [EUtility brwView:meBrwView navigationPresentModalViewController:self.imagePickerController animated:YES];
        }
        if (IsIOS6OrLower) {
            
        } else {
            UIViewController *controller = [EUtility brwCtrl:meBrwView];
            [controller setNeedsStatusBarAppearanceUpdate];
        }
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

-(void)savaImg:(UIImage *)image {
	//保存到一个指定目录
	NSError * error;
    NSFileManager * fmanager = [NSFileManager defaultManager];
    NSString * wgtPath = [super absPath:@"wgt://"];
    NSString * imagePath = [CameraUtility getSavename:@"image" wgtPath:wgtPath];
 	if([fmanager fileExistsAtPath:imagePath]) {
        [fmanager removeItemAtPath:imagePath error:&error];
	}
	UIImage * newImage = [EUtility rotateImage:image];
    //压缩
    UIImage * needSaveImg = [CameraUtility imageByScalingAndCroppingForSize:newImage width:640];
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


#pragma mark -
#pragma mark - 自定义相机
- (void)openViewCamera:(NSMutableArray *)array {
    
    @try {
        
        float x = [array objectAtIndex:0]?[[array objectAtIndex:0] floatValue]:0.0;
        float y = [array objectAtIndex:1]?[[array objectAtIndex:1] floatValue]:0.0;
        float w = [array objectAtIndex:2]?[[array objectAtIndex:2] floatValue]:SC_DEVICE_SIZE.width;
        float h = [array objectAtIndex:3]?[[array objectAtIndex:3] floatValue]:SC_DEVICE_SIZE.height;
        NSString *address = [array objectAtIndex:4]?[array objectAtIndex:4]:kInternationalization(@"noAddress");
        
        _captureCameraView = [[CameraCaptureCamera alloc] initWithFrame:CGRectMake(x, y, w, h)];
        _captureCameraView.address = address;
        _captureCameraView.meBrwView = meBrwView;
        _captureCameraView.uexObj = self;
        if (array.count > 5) {
            _captureCameraView.quality = [[array objectAtIndex:5] floatValue] / 100.0;
        }
        [_captureCameraView setUpUI];
        [EUtility brwView:meBrwView addSubview:_captureCameraView];
    }
    @catch (NSException *exception) {
        
        NSLog(@"EUExCamera==>>openViewCamera==>>catch==>>%@\n%@\n%@",exception.name,exception.reason,exception.userInfo);
        
    }
    @finally {
        //
    }
    
}

//0代表自动，1代表打开闪光灯，2代表关闭闪光灯
-(void)changeFlashMode:(NSMutableArray *)array{
    //uexCamera.cbChangeFlashMode
    NSString *flashMode = [array objectAtIndex:0]?[array objectAtIndex:0]:@"0";
    if (_captureCameraView) {
        [_captureCameraView switchFlashMode:flashMode];
    }else{
        NSLog(@"EUExCamera==>>changeFlashMode==>>相机初始化失败");
        [self jsSuccessWithName:@"uexCamera.cbChangeFlashMode" opId:0 dataType:UEX_CALLBACK_DATATYPE_JSON strData:@"-1"];
        NSLog(@"EUExCamera==>>changeFlashMode==>>回调完成");
        
    }
    
}

//1代表前置，0代表后置
-(void)changeCameraPosition:(NSMutableArray *)array{
    
    NSString *cameraPosition = @"0";
    
    if (array.count > 0) {
        cameraPosition = [array objectAtIndex:0];
    }
    
    if (_captureCameraView) {
        [_captureCameraView switchCamera:cameraPosition];
    }else{
        NSLog(@"EUExCamera==>>changeCameraPosition==>>相机初始化失败");
        [self jsSuccessWithName:@"uexCamera.cbChangeCameraPosition" opId:0 dataType:UEX_CALLBACK_DATATYPE_JSON strData:@"-1"];
        NSLog(@"EUExCamera==>>changeCameraPosition==>>回调完成");
    }
    
}

- (void)removeViewCameraFromWindow{
    
    if (_captureCameraView) {
        NSLog(@"EUExCamera==>>removeViewCameraFromWindow==>>delegate关闭openViewCamera相机");
        [_captureCameraView removeFromSuperview];
    }
    
}

- (void)CloseCamera{
    
    [self removeViewCameraFromWindow];
}

@end
