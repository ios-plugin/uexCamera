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

@class CameraPostViewController;
@interface EUExCamera() <CameraPostViewControllerDelegate, CameraPickerControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, assign) CGFloat scale;//缩放比例
@property (nonatomic, assign) BOOL isCompress;//是否压缩
@property (nonatomic, strong) CameraCaptureCamera *captureCameraView;
@property (nonatomic, strong) UIImagePickerController * imagePickerController;
@property (nonatomic, strong) CameraPickerController * cameraPickerController;

@end
@implementation EUExCamera
#define IsIOS6OrLower

#pragma mark - super
- (id)initWithBrwView:(EBrowserView *)eInBrwView {
	if (self = [super initWithBrwView:eInBrwView]) {
        
	}
	return self;
}
- (void)clean {
    [self closeAllCamera];
}
#pragma mark - CallBack
-(void)uexSuccessWithOpId:(int)inOpId dataType:(int)inDataType data:(NSString *)inData {
    if (inData) {
        [self jsSuccessWithName:@"uexCamera.cbOpen" opId:inOpId dataType:inDataType strData:inData];
    }
}

#pragma mark - open
- (void)open:(NSMutableArray *)inArguments {
    //为避免冲突先关闭其他自定义相机
    self.imagePickerController = [[UIImagePickerController alloc] init];
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
        [EUtility brwView:meBrwView presentModalViewController:self.imagePickerController animated:YES];
        [[EUtility brwCtrl:meBrwView] setNeedsStatusBarAppearanceUpdate];
    }
}

#pragma mark - UIImagePickerControllerDelegate
-(void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
	if (error != NULL) {
		[self jsFailedWithOpId:0 errorCode:1030105 errorDes:UEX_ERROR_DESCRIBE_FILE_SAVE];
	}
}
-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	if (picker) {
        [picker dismissViewControllerAnimated:YES completion:^{
            self.imagePickerController = nil;
        }];
	}
}
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	NSString * mediaType = [info objectForKey:UIImagePickerControllerMediaType];
	if ([mediaType isEqualToString:@"public.image"]) {
        UIImage * image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
        //同时有模态视图的时候需要 模态视图关闭动画之后再保存图片
        [picker dismissViewControllerAnimated:YES completion:^ {
            [self savaImg:image];
            self.imagePickerController = nil;
        }];
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
    if (self.isCompress) {
        imageData = UIImageJPEGRepresentation(needSaveImg, self.scale);
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
    self.cameraPickerController.scale = self.scale;
    self.cameraPickerController.isCompress = self.isCompress;
    self.cameraPickerController.delegate = self;
    [EUtility brwView:meBrwView presentModalViewController:self.cameraPickerController animated:YES];

}

#pragma mark - openViewCamera
- (void)openViewCamera:(NSMutableArray *)inArguments {
    if (inArguments.count < 4) {
        return;
    }
    
    //为避免冲突先关闭其他自定义相机
    [self closeAllCamera];
    CGFloat x = inArguments[0] ? [inArguments[0] floatValue] : 0.0;
    CGFloat y = inArguments[1] ? [inArguments[1] floatValue] : 0.0;
    CGFloat w = inArguments[2] ? [inArguments[2] floatValue] : SC_DEVICE_WIDTH;
    CGFloat h = inArguments[3] ? [inArguments[3] floatValue] : SC_DEVICE_HEIGHT;
    
    NSString * address = kInternationalization(@"noAddress");
    if (inArguments.count > 4) {
        address = inArguments[4];
    }
    
    self.captureCameraView = [[CameraCaptureCamera alloc] initWithFrame:CGRectMake(x, y, w, h)];
    self.captureCameraView.address = address;
    self.captureCameraView.meBrwView = meBrwView;
    self.captureCameraView.uexObj = self;
    self.captureCameraView.cameraPostViewController.delegate = self;
    if (inArguments.count > 5) {
        self.captureCameraView.quality = [inArguments[5] floatValue] / 100.0;
    }
    [self.captureCameraView setUpUI];
    [EUtility brwView:meBrwView addSubview:self.captureCameraView];
}
//0代表自动，1代表打开闪光灯，2代表关闭闪光灯
-(void)changeFlashMode:(NSMutableArray *)inArguments {
    if (inArguments.count == 0) {
        return;
    }
    //uexCamera.cbChangeFlashMode
    NSString *flashMode = inArguments[0];
    if (_captureCameraView) {
        [_captureCameraView switchFlashMode:flashMode];
    }else{
        [self jsSuccessWithName:@"uexCamera.cbChangeFlashMode" opId:0 dataType:UEX_CALLBACK_DATATYPE_JSON strData:@"-1"];
    }
}
//1代表前置，0代表后置
- (void)changeCameraPosition:(NSMutableArray *)inArguments {
    NSString * cameraPosition = @"0";
    if (inArguments.count > 0) {
        cameraPosition = [inArguments objectAtIndex:0];
    }
    if (_captureCameraView) {
        [_captureCameraView switchCamera:cameraPosition];
    } else {
        [self jsSuccessWithName:@"uexCamera.cbChangeCameraPosition" opId:0 dataType:UEX_CALLBACK_DATATYPE_JSON strData:@"-1"];
    }
}
- (void)removeViewCameraFromWindow:(NSMutableArray *)inArguments {
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
    if (self.imagePickerController.isBeingPresented) {
        [self.imagePickerController dismissViewControllerAnimated:YES completion:nil];
    }
    self.imagePickerController = nil;
    [_captureCameraView removeFromSuperview];
    [_captureCameraView clean];
    _captureCameraView = nil;
    [_cameraPickerController dismissViewControllerAnimated:NO completion:nil];
    _cameraPickerController = nil;
    
}
//设置压缩参数
- (void)setCompressAndScale:(NSMutableArray *)inArguments{
    self.isCompress = NO;
    self.scale = 0;
    if (inArguments.count == 0) {
        return;
    }
    if (![inArguments[0] boolValue]) {
        return;
    }
    self.isCompress = YES;
    self.scale = 0.5;
    if (inArguments.count > 1) {
        CGFloat percent = [inArguments[1] floatValue];
        if (percent > 0 && percent <= 100) {
            self.scale = percent/100;
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
