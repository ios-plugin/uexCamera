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
#import "JSON.h"

@class CameraPostViewController;

@interface EUExCamera() <CameraPostViewControllerDelegate, CameraPickerControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>{

    BOOL isCompress;//是否压缩
    
    float scale;//缩放比例
    
}

@property (nonatomic, strong) CameraCaptureCamera *captureCameraView;

@property (nonatomic, strong) UIImagePickerController * imagePickerController;

@property (nonatomic, strong) CameraPickerController * cameraPickerController;


@end

@implementation EUExCamera

#define IsIOS6OrLower ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0)



#pragma mark - super

- (id)initWithBrwView:(EBrowserView *)eInBrwView {
    
	if (self = [super initWithBrwView:eInBrwView]) {
        
        self.imagePickerController = [[UIImagePickerController alloc] init];
        
	}
    
	return self;
}

- (void)clean {
    
    [self closeAllCamera];
}

#pragma mark - 相机权限判断
- (BOOL)judgeCamera
{
    self.isJudgeCamera = NO;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (authStatus) {
        case AVAuthorizationStatusNotDetermined://没有询问是否开启照片
        {
            //            __weak EUExImage *weakSelf = self;
            //            //第一次询问用户是否进行授权
            //            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            //                // CALL YOUR METHOD HERE - as this assumes being called only once from user interacting with permission alert!
            //                if (status == PHAuthorizationStatusAuthorized) {
            //                    // Photo enabled code
            //                    weakSelf.isJudgePic = YES;
            //                }
            //                else {
            //                    // Photo disabled code
            //                    weakSelf.isJudgePic = NO;
            //                }
            //            }];
            self.isJudgeCamera = YES;
        }
            break;
        case AVAuthorizationStatusRestricted:
            //未授权，家长限制
            self.isJudgeCamera = NO;
            break;
        case AVAuthorizationStatusDenied:
            //用户未授权
            self.isJudgeCamera = NO;
            break;
        case AVAuthorizationStatusAuthorized:
            //用户授权
            self.isJudgeCamera = YES;
            break;
        default:
            break;
    }
    
    return self.isJudgeCamera;
}

#pragma mark - CallBack

-(void)uexSuccessWithOpId:(int)inOpId dataType:(int)inDataType data:(NSString *)inData {
    if (inData) {
        
        [self jsSuccessWithName:@"uexCamera.cbOpen" opId:inOpId dataType:inDataType strData:inData];
        
    }
}


#pragma mark - open

- (void)open:(NSMutableArray *)inArguments {
    
    //相机权限检测
    BOOL isPicOK = [self judgeCamera];
    if (!isPicOK) {
        NSDictionary *dicResult = [NSDictionary dictionaryWithObjectsAndKeys:@"1",@"errCode",@"相机打开失败，请在 设置-隐私-相机 中开启权限",@"info", nil];
        NSString *dataStr = [dicResult JSONFragment];
        NSString *jsStr = [NSString stringWithFormat:@"if(uexCamera.onPermissionDenied){uexCamera.onPermissionDenied(%@)}",dataStr];
        //回调给当前网页
        [EUtility brwView:self.meBrwView evaluateScript:jsStr];
        return;
    }
    
    //为避免冲突先关闭其他自定义相机
    [self closeAllCamera];
    
    [self setCompressAndScale:inArguments];
    
    [self showCamera];

}

-(void)showCamera {
    
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        
        [super jsFailedWithOpId:0 errorCode:1030108 errorDes:UEX_ERROR_DESCRIBE_DEVICE_SUPPORT];
        
    } else {
        
        [self.imagePickerController setDelegate:self];
        
        [self.imagePickerController setSourceType:UIImagePickerControllerSourceTypeCamera];
        
        [self.imagePickerController setVideoQuality:UIImagePickerControllerQualityTypeMedium];
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0) {
            
            [EUtility brwView:meBrwView presentModalViewController:self.imagePickerController animated:YES];
            
        } else {
            
            [EUtility brwView:meBrwView navigationPresentModalViewController:self.imagePickerController animated:YES];
            
        }
        
        if (!IsIOS6OrLower) {
            
            UIViewController *controller = [EUtility brwCtrl:meBrwView];
            
            [controller setNeedsStatusBarAppearanceUpdate];
            
        }
    }
}


#pragma mark - UIImagePickerControllerDelegate

-(void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    
	if (error != NULL) {
        
		[super jsFailedWithOpId:0 errorCode:1030105 errorDes:UEX_ERROR_DESCRIBE_FILE_SAVE];
        
	}
    
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
	if (picker) {
        
		[picker dismissViewControllerAnimated:YES completion:^{
            //
        }];
        
	}
    
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
	NSString * mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
	if ([mediaType isEqualToString:@"public.image"]) {
        
        UIImage * image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
        
        //同时有模态视图的时候需要 模态视图关闭动画之后再保存图片
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 5.0) {
            
            [picker dismissViewControllerAnimated:YES completion:^ {
                
                [self performSelector:@selector(savaImg:) withObject:image afterDelay:0];
                
            }];
            
        } else {
            
            [picker dismissViewControllerAnimated:NO completion:^{
                //
            }];
            
            [self performSelector:@selector(savaImg:) withObject:image afterDelay:0];
            
        }
        
	}
    
}

-(void)savaImg:(UIImage *)image {
    
	//保存到一个指定目录
	NSError * error;
    
    NSFileManager * fmanager = [NSFileManager defaultManager];

    NSString *createPath = [self creatSaveImgPath];
    
    NSLog(@"EUExCamera==>>savaImg==>>保存路径createPath=%@",createPath);
    
    NSString * imagePath = [CameraUtility getSavename:@"image" wgtPath:createPath];
    
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

#pragma mark - openInternal

-(void)openInternal:(NSMutableArray *)inArguments {
    
    NSLog(@"uexCamera==>>openInternal");
    
    //相机权限检测
    BOOL isPicOK = [self judgeCamera];
    if (!isPicOK) {
        NSDictionary *dicResult = [NSDictionary dictionaryWithObjectsAndKeys:@"1",@"errCode",@"相机打开失败，请在 设置-隐私-相机 中开启权限",@"info", nil];
        //NSString *dataStr = [dicResult JSONFragment];
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dicResult options:NSJSONWritingPrettyPrinted error:&error];
        NSString *jsStr = [NSString stringWithFormat:@"if(uexCamera.onPermissionDenied){uexCamera.onPermissionDenied(%@)}",[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
        //回调给当前网页
        [EUtility brwView:self.meBrwView evaluateScript:jsStr];
        return;
    }
    
    //为避免冲突先关闭其他自定义相机
    if (_captureCameraView) {
        
        [_captureCameraView removeFromSuperview];
        
        _captureCameraView = nil;
        
    }
    
    if (_cameraPickerController) {
        
        [_cameraPickerController dismissViewControllerAnimated:NO completion:^{
            //
        }];
        
        _cameraPickerController = nil;
        
    }
    
    [self setCompressAndScale:inArguments];
    
    if (!self.cameraPickerController) {
        
        self.cameraPickerController = [[CameraPickerController alloc] init];
    }
    
    self.cameraPickerController.meBrwView = meBrwView;
    
    self.cameraPickerController.uexObj = self;
    
    self.cameraPickerController.scale = scale;
    
    self.cameraPickerController.isCompress = isCompress;
    
    self.cameraPickerController.delegate = self;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0) {
        
        [EUtility brwView:meBrwView presentModalViewController:self.cameraPickerController animated:YES];
        
    } else {
        
        [EUtility brwView:meBrwView navigationPresentModalViewController:self.cameraPickerController animated:YES];
        
    }
    
}


#pragma mark - openViewCamera
- (void)openViewCamera:(NSMutableArray *)array {
    
    NSLog(@"uexCamera==>>openViewCamera");
    
    //相机权限检测
    BOOL isPicOK = [self judgeCamera];
    if (!isPicOK) {
        NSDictionary *dicResult = [NSDictionary dictionaryWithObjectsAndKeys:@"1",@"errCode",@"相机打开失败，请在 设置-隐私-相机 中开启权限",@"info", nil];
        //NSString *dataStr = [dicResult JSONFragment];
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dicResult options:NSJSONWritingPrettyPrinted error:&error];
        NSString *jsStr = [NSString stringWithFormat:@"if(uexCamera.onPermissionDenied){uexCamera.onPermissionDenied(%@)}",[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
        //回调给当前网页
        [EUtility brwView:self.meBrwView evaluateScript:jsStr];
        return;
    }
    
    //为避免冲突先关闭其他自定义相机
    [self closeAllCamera];
    
    CGFloat x = [array objectAtIndex:0] ? [[array objectAtIndex:0] floatValue] : 0.0;
    
    CGFloat y = [array objectAtIndex:1] ? [[array objectAtIndex:1] floatValue] : 0.0;
    
    CGFloat w = [array objectAtIndex:2] ? [[array objectAtIndex:2] floatValue] : SC_DEVICE_WIDTH;
    
    CGFloat h = [array objectAtIndex:3] ? [[array objectAtIndex:3] floatValue] : SC_DEVICE_HEIGHT;
    
    NSString * address = [array objectAtIndex:4] ? [array objectAtIndex:4] : kInternationalization(@"noAddress");
    
    self.captureCameraView = [[CameraCaptureCamera alloc] initWithFrame:CGRectMake(x, y, w, h)];
    
    self.captureCameraView.address = address;
    
    self.captureCameraView.meBrwView = meBrwView;
    
    self.captureCameraView.uexObj = self;
    
    self.captureCameraView.cameraPostViewController.delegate = self;
    
    if (array.count > 5) {
        
        self.captureCameraView.quality = [[array objectAtIndex:5] floatValue] / 100.0;
        
    }
    
    [self.captureCameraView setUpUI];
    
    [EUtility brwView:meBrwView addSubview:self.captureCameraView];
    
}

//0代表自动，1代表打开闪光灯，2代表关闭闪光灯
-(void)changeFlashMode:(NSMutableArray *)array {
    
    //uexCamera.cbChangeFlashMode
    NSString *flashMode = [array objectAtIndex:0]?[array objectAtIndex:0]:@"0";
    
    if (_captureCameraView) {
        
        [_captureCameraView switchFlashMode:flashMode];
        
    }else{
        
        [self jsSuccessWithName:@"uexCamera.cbChangeFlashMode" opId:0 dataType:UEX_CALLBACK_DATATYPE_JSON strData:@"-1"];
    }
}

//1代表前置，0代表后置
- (void)changeCameraPosition:(NSMutableArray *)array {
    
    NSString * cameraPosition = @"0";
    
    if (array.count > 0) {
        
        cameraPosition = [array objectAtIndex:0];
        
    }
    if (_captureCameraView) {
        
        [_captureCameraView switchCamera:cameraPosition];
        
    } else {
        
        [self jsSuccessWithName:@"uexCamera.cbChangeCameraPosition" opId:0 dataType:UEX_CALLBACK_DATATYPE_JSON strData:@"-1"];
        
    }
    
}

- (void)removeViewCameraFromWindow:(NSMutableArray *)array {
    
    [self closeAllCamera];
    
}

#pragma mark - CameraPickerControllerDelegate

- (void)closeCameraPickerController:(CameraPickerController *)CameraPickerController{
    
    [self closeAllCamera];
    
}

#pragma mark - CameraPostViewControllerDelegate

- (void)closeCameraInCameraPostViewController:(CameraPostViewController *)cameraPostViewController{

    [self closeAllCamera];
}

#pragma mark - privte

//关闭所有自定义相机
- (void)closeAllCamera{

    NSLog(@"EUExCamera==>>closeAllCamera==>>关闭所有自定义相机");
    
    if (_captureCameraView) {
        
        [_captureCameraView removeFromSuperview];
        
        [_captureCameraView clean];
        
        _captureCameraView = nil;
        
    }
    
    if (_cameraPickerController) {
        
        [_cameraPickerController dismissViewControllerAnimated:NO completion:^{
            //
        }];

        _cameraPickerController = nil;
        
    }
    
}

//设置压缩参数
- (void)setCompressAndScale:(NSMutableArray *)inArguments{

    isCompress = NO;
    
    scale = 0;
    
    if ([inArguments isKindOfClass:[NSMutableArray class]] && [inArguments count] > 0) {
        
        NSString * compress = [inArguments objectAtIndex:0];
        
        if ([compress isKindOfClass:[NSString class]] && compress.length > 0) {
            
            if (0 == [compress intValue]) {
                
                isCompress = YES;
                
                scale = 0.5;
                
                if ([inArguments count] == 2) {
                    
                    NSString * scaleStr = [inArguments objectAtIndex:1];
                    
                    float scalefloat = [scaleStr floatValue] / 100;
                    
                    if (scalefloat <= 100 && scalefloat >= 0 ) {
                        
                        scale = scalefloat;
                        
                    }
                    
                }
                
            }
            
        }
        
    }

}

//创建存储路径
- (NSString *)creatSaveImgPath {

    NSString *pathDocuments = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSString *createPath = [NSString stringWithFormat:@"%@/EUExCamera/", pathDocuments];
    
    return createPath;
}

@end
