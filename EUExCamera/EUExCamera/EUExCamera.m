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
#import <MobileCoreServices/MobileCoreServices.h>
@class CameraPostViewController;
@interface EUExCamera() <CameraPostViewControllerDelegate, CameraPickerControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>{
    BOOL isCompress;//是否压缩
    float scale;//缩放比例
    
}
@property (nonatomic, strong) CameraCaptureCamera *captureCameraView;
@property (nonatomic, strong) UIImagePickerController * imagePickerController;
@property (nonatomic, strong) CameraPickerController * cameraPickerController;
@property(nonatomic,strong)ACJSFunctionRef *funcOpen;

@property(nonatomic,assign)BOOL isJudgeCamera;//是否拥有相机权限

@end

@implementation EUExCamera


#pragma mark - super

- (instancetype)initWithWebViewEngine:(id<AppCanWebViewEngineObject>)engine{
    self = [super initWithWebViewEngine:engine];
    if (self) {
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
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexCamera.cbOpen" arguments:ACArgsPack(@(inOpId),@(inDataType),inData)];
        [self.funcOpen executeWithArguments:ACArgsPack(inData)];
        self.funcOpen = nil;
    }
}
#pragma mark - open
- (void)open:(NSMutableArray *)inArguments {
    
    //相机权限检测
    BOOL isPicOK = [self judgeCamera];
    if (!isPicOK) {
        NSDictionary *dicResult = [NSDictionary dictionaryWithObjectsAndKeys:@"1",@"errCode",@"相机打开失败，请在 设置-隐私-相机 中开启权限",@"info", nil];
        NSString *dataStr = [dicResult ac_JSONFragment];
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexCamera.onPermissionDenied" arguments:ACArgsPack(dataStr)];
        return;
    }
    
    ACJSFunctionRef *func = JSFunctionArg(inArguments.lastObject);
    self.funcOpen = func;
    //为避免冲突先关闭其他自定义相机
    [self closeAllCamera];
    
    [self setCompressAndScale:inArguments];
    
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        return;
    }
    
    [self.imagePickerController setDelegate:self];
    [self.imagePickerController setSourceType:UIImagePickerControllerSourceTypeCamera];
    [self.imagePickerController setVideoQuality:UIImagePickerControllerQualityTypeMedium];
    [[self.webViewEngine viewController] presentViewController:self.imagePickerController animated:YES completion:nil];
    
    [[self.webViewEngine viewController] setNeedsStatusBarAppearanceUpdate];
}


#pragma mark - UIImagePickerControllerDelegate
-(void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    
	if (error != NULL) {
        
		//[super jsFailedWithOpId:0 errorCode:1030105 errorDes:UEX_ERROR_DESCRIBE_FILE_SAVE];
        
	}
    
}
-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	NSString * mediaType = [info objectForKey:UIImagePickerControllerMediaType];
	if ([mediaType isEqualToString:(__bridge NSString *)kUTTypeImage]) {
        UIImage * image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
            [picker dismissViewControllerAnimated:YES completion:^{
                [self savaImg:image];
                
            }];

        
	}
    
}
-(void)savaImg:(UIImage *)image {
    
	//保存到一个指定目录
	NSError * error;
    NSFileManager * fmanager = [NSFileManager defaultManager];
    NSString *createPath = [self creatSaveImgPath];
    NSString * imagePath = [CameraUtility getSavename:@"image" wgtPath:createPath];
    
 	if([fmanager fileExistsAtPath:imagePath]) {
        [fmanager removeItemAtPath:imagePath error:&error];
	}
    
    //压缩比率，0：压缩后的图片最小，1：压缩后的图片最大
    NSData * imageData = nil;
    CGFloat quality = isCompress ? scale : 1;
    
//	UIImage * newImage = [EUtility rotateImage:image];
//    //压缩
//    UIImage * needSaveImg = [CameraUtility imageByScalingAndCroppingForSize:newImage width:640];
//    imageData = UIImageJPEGRepresentation(needSaveImg, quality);
    
    
    //有开发者有需要原图的需求
    imageData = UIImageJPEGRepresentation(image, quality);
    
	if ([imageData writeToFile:imagePath atomically:YES]) {
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexCamera.cbOpen" arguments:ACArgsPack(@0,@(UEX_CALLBACK_DATATYPE_TEXT),imagePath)];
        [self.funcOpen executeWithArguments:ACArgsPack(imagePath)];
        self.funcOpen = nil;
	}
}
#pragma mark - openInternal
-(void)openInternal:(NSMutableArray *)inArguments {
    
    //相机权限检测
    BOOL isPicOK = [self judgeCamera];
    if (!isPicOK) {
        NSDictionary *dicResult = [NSDictionary dictionaryWithObjectsAndKeys:@"1",@"errCode",@"相机打开失败，请在 设置-隐私-相机 中开启权限",@"info", nil];
        NSString *dataStr = [dicResult ac_JSONFragment];
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexCamera.onPermissionDenied" arguments:ACArgsPack(dataStr)];
        return;
    }
    
    ACJSFunctionRef *func = JSFunctionArg(inArguments.lastObject);
    //为避免冲突先关闭其他自定义相机
    if (_captureCameraView) {
        [_captureCameraView removeFromSuperview];
        _captureCameraView = nil;
    }
    
    if (_cameraPickerController) {
        [_cameraPickerController dismissViewControllerAnimated:NO completion:nil];
        _cameraPickerController = nil;
    }
    [self setCompressAndScale:inArguments];
    if (!self.cameraPickerController) {
        self.cameraPickerController = [[CameraPickerController alloc] init];
    }
    self.cameraPickerController.webViewEngine = self.webViewEngine;
    self.cameraPickerController.funcOpenInternal = func;
    self.cameraPickerController.uexObj = self;
    self.cameraPickerController.scale = scale;
    self.cameraPickerController.isCompress = isCompress;
    self.cameraPickerController.delegate = self;

    [[self.webViewEngine viewController] presentViewController:self.cameraPickerController animated:YES completion:nil];

    
}
#pragma mark - openViewCamera
- (void)openViewCamera:(NSMutableArray *)inArguments {
    
    //相机权限检测
    BOOL isPicOK = [self judgeCamera];
    if (!isPicOK) {
        NSDictionary *dicResult = [NSDictionary dictionaryWithObjectsAndKeys:@"1",@"errCode",@"相机打开失败，请在 设置-隐私-相机 中开启权限",@"info", nil];
        NSString *dataStr = [dicResult ac_JSONFragment];
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexCamera.onPermissionDenied" arguments:ACArgsPack(dataStr)];
        return;
    }
    
    ACArgsUnpack(NSNumber *xNum,NSNumber *yNum,NSNumber *wNum,NSNumber *hNum,NSString *hint,NSNumber *qualityNum) = inArguments;
    NSDictionary *info = dictionaryArg(inArguments.firstObject);
    NSNumber *options = nil;
    if (info) {
        xNum = numberArg(info[@"x"]);
        yNum = numberArg(info[@"y"]);
        wNum = numberArg(info[@"width"]);
        hNum = numberArg(info[@"height"]);
        hint = stringArg(info[@"hint"]);
        qualityNum = numberArg(info[@"quality"]);
        options = numberArg(info[@"options"]);
    }
    ACJSFunctionRef *func = JSFunctionArg(inArguments.lastObject);
    //为避免冲突先关闭其他自定义相机
    [self closeAllCamera];
    CGFloat x = xNum ? xNum.floatValue : 0;
    CGFloat y = yNum ? yNum.floatValue : 0;
    CGFloat w = wNum ? wNum.floatValue : SC_DEVICE_WIDTH;
    CGFloat h = hNum ? hNum.floatValue : SC_DEVICE_HEIGHT;
    hint = hint ?: kInternationalization(@"noAddress");
    self.captureCameraView = [[CameraCaptureCamera alloc] initWithFrame:CGRectMake(x, y, w, h)];
    self.captureCameraView.funcOpenViewCamera = func;
    self.captureCameraView.address = hint;
    self.captureCameraView.webViewEngine = self.webViewEngine;
    self.captureCameraView.uexObj = self;
    self.captureCameraView.cameraPostViewController.delegate = self;
    if (qualityNum) {
        self.captureCameraView.quality = qualityNum.floatValue / 100.0;
    }
    [self.captureCameraView setUpUI];
    if (options) {
        self.captureCameraView.captureManager.options = options.unsignedIntegerValue;
    }
    [[self.webViewEngine webView] addSubview:self.captureCameraView];
    
}
//0代表自动，1代表打开闪光灯，2代表关闭闪光灯
-(NSNumber*)changeFlashMode:(NSMutableArray *)array {
    
    //uexCamera.cbChangeFlashMode
    //NSString *flashMode = [array objectAtIndex:0]?[array objectAtIndex:0]:@"0";
    ACArgsUnpack(NSString *flashMode) = array;
    if (flashMode == nil) {
        flashMode = @"0";
    }
    if (_captureCameraView) {
       NSString *mode = [_captureCameraView switchFlashMode:flashMode];
        return @([mode intValue]);
    }else{
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexCamera.cbChangeFlashMode" arguments:ACArgsPack(@(0),@(UEX_CALLBACK_DATATYPE_JSON),@"-1")];
        return @(-1);
    }
}
//1代表前置，0代表后置
- (NSNumber*)changeCameraPosition:(NSMutableArray *)array {

    ACArgsUnpack(NSString *cameraPosition) = array;
    if (cameraPosition == nil) {
        cameraPosition = @"0";
    }
    if (_captureCameraView) {
       NSString *position = [_captureCameraView switchCamera:cameraPosition];
        return @([position intValue]);
        
    } else {
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexCamera.cbChangeCameraPosition" arguments:ACArgsPack(@(0),@(UEX_CALLBACK_DATATYPE_JSON),@"-1")];
        return @(-1);
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

    if (_captureCameraView) {
        [_captureCameraView removeFromSuperview];
        [_captureCameraView clean];
        _captureCameraView = nil;
    }
    
    if (_cameraPickerController) {
        [_cameraPickerController dismissViewControllerAnimated:NO completion:nil];
        _cameraPickerController = nil;
    }
    
}
//设置压缩参数
- (void)setCompressAndScale:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSNumber *compressFlag,NSNumber *scaleNum) = inArguments;
    if(compressFlag == nil){
        isCompress = NO;
        return;
    }
    if([compressFlag integerValue] == 0){
        isCompress = YES;
    }
    else{
        isCompress = NO;
    }
    scale = scaleNum.floatValue / 100;
    if (scale <= 0 || scale > 1) {
        scale = 0.5;
    }

}
//创建存储路径
- (NSString *)creatSaveImgPath {
    NSString *pathDocuments = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *createPath = [NSString stringWithFormat:@"%@/EUExCamera/", pathDocuments];
    return createPath;
}
@end
