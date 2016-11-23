//
//  CameraCaptureCamera.m
//  EUExCamera
//
//  Created by zywx on 16/1/22.
//  Copyright © 2016年 zywx. All rights reserved.
//
#import "CameraCaptureCamera.h"
#import "CameraSlider.h"
#import "CameraCommon.h"
#import "EUtility.h"
#import "EUExCamera.h"
#import "CameraInternationalization.h"
#define SWITCH_SHOW_FOCUSVIEW_UNTIL_FOCUS_DONE      0   //对焦框是否一直闪到对焦完成
#define SWITCH_SHOW_DEFAULT_IMAGE_FOR_NONE_CAMERA   1   //没有拍照功能的设备，是否给一张默认图片体验一下
//height
#define CAMERA_TOPVIEW_HEIGHT   44  //title
#define CAMERA_MEDDLEVIEW_HEIGHT   44  //title
#define CAMERA_MENU_VIEW_HEIGH  44  //menu
//对焦
#define ADJUSTINT_FOCUS @"adjustingFocus"
#define LOW_ALPHA   0.7f
#define HIGH_ALPHA  1.0f
@interface CameraCaptureCamera () {
    int alphaTimes;
    CGPoint currTouchPoint;
}
@property (nonatomic, strong) CameraCaptureSessionManager *captureManager;
@property (nonatomic, strong) UIView *middleContainerView;//中部view
@property (nonatomic, strong) UILabel *middleLbl;//中部的地址信息
@property (nonatomic, strong) UIView *cameraMenuView;//网格、闪光灯、前后摄像头等按钮
//对焦
@property (nonatomic, strong) UIImageView *focusImageView;
@property (nonatomic, strong) CameraSlider *cameraSlider;
@end
@implementation CameraCaptureCamera
-(instancetype)initWithFrame:(CGRect)frame{
    if (self=[super initWithFrame:frame]) {
        // Custom initialization
        alphaTimes = -1;
        currTouchPoint = CGPointZero;
    }
    return self;
}
#pragma mark - 懒加载
- (CameraPostViewController *)cameraPostViewController {
    if (!_cameraPostViewController) {
        _cameraPostViewController = [[CameraPostViewController alloc] init];
    }
    return _cameraPostViewController;
}
#pragma mark -------------UI---------------
-(void)setUpUI {
    CameraCaptureSessionManager *manager = [[CameraCaptureSessionManager alloc] init];
    //AvcaptureManager此处修改拍照预览区域的大小//
    if (CGRectEqualToRect(_previewRect, CGRectZero)) {
        self.previewRect = self.frame;
    }
    [manager configureWithParentLayer:self previewRect:_previewRect];
    self.captureManager = manager;
    [self addAddressViewWithText:_address];
    [self addCameraMenuView];
    //伸缩手势
    [self addPinchGesture];
    [_captureManager.session startRunning];
#if SWITCH_SHOW_DEFAULT_IMAGE_FOR_NONE_CAMERA
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, CAMERA_TOPVIEW_HEIGHT, self.frame.size.width, self.frame.size.width)];
        imgView.clipsToBounds = YES;
        imgView.contentMode = UIViewContentModeScaleAspectFill;
        imgView.image = [CameraInternationalization getImageFromLocalFile:@"Default" type:@"png"];
        [self addSubview:imgView];
    }
#endif
}
//地理位置
- (void)addAddressViewWithText:(NSString*)text {
    if (!_middleContainerView) {
        _middleLbl = [[UILabel alloc] init];
        _middleLbl.font = [UIFont systemFontOfSize:ADDRESS_FONT];
        CGFloat maxW = self.frame.size.width - POSITION_LEFT;
        CGSize lblSize = [text sizeWithFont:_middleLbl.font constrainedToSize:CGSizeMake(maxW, MAXFLOAT)];
        CGRect middleFrame = CGRectMake(0, CGRectGetMaxY(self.frame) - kSpacing * 2 - kCameraBtnWH - lblSize.height, self.frame.size.width, lblSize.height);
        UIView *mView = [[UIView alloc] initWithFrame:middleFrame];
        mView.backgroundColor = [UIColor clearColor];
        [self addSubview:mView];
        self.middleContainerView = mView;
        _middleLbl.numberOfLines = 0;
        _middleLbl.frame = CGRectMake((self.frame.size.width - lblSize.width) / 2, 0, lblSize.width, lblSize.height);
        _middleLbl.backgroundColor = [UIColor clearColor];
        _middleLbl.textColor = [UIColor blackColor];
        _middleLbl.text = text;
        [_middleContainerView addSubview:_middleLbl];
    }
}
//拍照菜单栏
- (void)addCameraMenuView {
    //拍照按钮
    CGFloat cameraBtnLength = kCameraBtnWH;
    [self buildButton:CGRectMake((self.frame.size.width - cameraBtnLength) / 2 + self.frame.origin.x, CGRectGetMaxY(self.frame) - kSpacing - cameraBtnLength , cameraBtnLength, cameraBtnLength)
         normalImgStr:@"plugin_camera_bt_takepic_normal"
      highlightImgStr:@"plugin_camera_bt_takepic_on"
       selectedImgStr:@""
               action:@selector(takePictureBtnPressed:)
           parentView:self];
}
- (UIButton*)buildButton:(CGRect)frame
            normalImgStr:(NSString*)normalImgStr
         highlightImgStr:(NSString*)highlightImgStr
          selectedImgStr:(NSString*)selectedImgStr
                  action:(SEL)action
              parentView:(UIView*)parentView {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = frame;
    if (normalImgStr.length > 0) {
        [btn setImage:[CameraInternationalization getImageFromLocalFile:normalImgStr type:@"png"] forState:UIControlStateNormal];
    }
    if (highlightImgStr.length > 0) {
        [btn setImage:[CameraInternationalization getImageFromLocalFile:highlightImgStr type:@"png"] forState:UIControlStateHighlighted];
    }
    if (selectedImgStr.length > 0) {
        [btn setImage:[CameraInternationalization getImageFromLocalFile:selectedImgStr type:@"png"] forState:UIControlStateSelected];
    }
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [parentView addSubview:btn];
    return btn;
}
//对焦的框
- (void)addFocusView {
    UIImageView *imgView = [[UIImageView alloc] initWithImage:[CameraInternationalization getImageFromLocalFile:@"touch_focus_x" type:@"png"]];
    imgView.alpha = 0;
    [self addSubview:imgView];
    self.focusImageView = imgView;
#if SWITCH_SHOW_FOCUSVIEW_UNTIL_FOCUS_DONE
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device && [device isFocusPointOfInterestSupported]) {
        [device addObserver:self forKeyPath:ADJUSTINT_FOCUS options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    }
#endif
}
//伸缩镜头的手势
- (void)addPinchGesture {
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    [self addGestureRecognizer:pinch];
    //横向
    //    CGFloat width = _previewRect.size.width - 100;
    //    CGFloat height = 40;
    //    SCSlider *slider = [[SCSlider alloc] initWithFrame:CGRectMake((SC_APP_SIZE.width - width) / 2, SC_APP_SIZE.width + CAMERA_MENU_VIEW_HEIGH - height, width, height)];
    //竖向
    CGFloat width = 40;
    CGFloat height = _previewRect.size.height - 100;
    CameraSlider *slider = [[CameraSlider alloc] initWithFrame:CGRectMake(_previewRect.size.width - width, (_previewRect.size.height + CAMERA_MENU_VIEW_HEIGH - height) / 2, width, height) direction:CameraSliderDirectionVertical];
    slider.alpha = 0.f;
    slider.minValue = MIN_PINCH_SCALE_NUM;
    slider.maxValue = MAX_PINCH_SCALE_NUM;
    WEAKSELF_SC
    [slider buildDidChangeValueBlock:^(CGFloat value) {
        [weakSelf_SC.captureManager pinchCameraViewWithScalNum:value];
    }];
    [slider buildTouchEndBlock:^(CGFloat value, BOOL isTouchEnd) {
        [weakSelf_SC setSliderAlpha:isTouchEnd];
    }];
    [self addSubview:slider];
    self.cameraSlider = slider;
}
- (void)setSliderAlpha:(BOOL)isTouchEnd {
    if (_cameraSlider) {
        _cameraSlider.isSliding = !isTouchEnd;
        if (_cameraSlider.alpha != 0.f && !_cameraSlider.isSliding) {
            double delayInSeconds = 3.88;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                if (_cameraSlider.alpha != 0.f && !_cameraSlider.isSliding) {
                    [UIView animateWithDuration:0.3f animations:^{
                        _cameraSlider.alpha = 0.f;
                    }];
                }
            });
        }
    }
}
#pragma mark -------------touch to focus---------------
#if SWITCH_SHOW_FOCUSVIEW_UNTIL_FOCUS_DONE
//监听对焦是否完成
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:ADJUSTINT_FOCUS]) {
        BOOL isAdjustingFocus = [[change objectForKey:NSKeyValueChangeNewKey] isEqualToNumber:[NSNumber numberWithInt:1] ];
        if (!isAdjustingFocus) {
            alphaTimes = -1;
        }
    }
}
- (void)showFocusInPoint:(CGPoint)touchPoint {
    [UIView animateWithDuration:0.1f delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        int alphaNum = (alphaTimes % 2 == 0 ? HIGH_ALPHA : LOW_ALPHA);
        self.focusImageView.alpha = alphaNum;
        alphaTimes++;
    } completion:^(BOOL finished) {
        if (alphaTimes != -1) {
            [self showFocusInPoint:currTouchPoint];
        } else {
            self.focusImageView.alpha = 0.0f;
        }
    }];
}
#endif
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    //    [super touchesBegan:touches withEvent:event];
    alphaTimes = -1;
    UITouch *touch = [touches anyObject];
    currTouchPoint = [touch locationInView:self];
    if (CGRectContainsPoint(_captureManager.previewLayer.frame, currTouchPoint) == NO) {
        return;
    }
    [_captureManager focusInPoint:currTouchPoint];
    //对焦框
    [_focusImageView setCenter:currTouchPoint];
    _focusImageView.transform = CGAffineTransformMakeScale(2.0, 2.0);
#if SWITCH_SHOW_FOCUSVIEW_UNTIL_FOCUS_DONE
    [UIView animateWithDuration:0.1f animations:^{
        _focusImageView.alpha = HIGH_ALPHA;
        _focusImageView.transform = CGAffineTransformMakeScale(1.0, 1.0);
    } completion:^(BOOL finished) {
        [self showFocusInPoint:currTouchPoint];
    }];
#else
    [UIView animateWithDuration:0.3f delay:0.f options:UIViewAnimationOptionAllowUserInteraction animations:^{
        _focusImageView.alpha = 1.f;
        _focusImageView.transform = CGAffineTransformMakeScale(1.0, 1.0);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.5f delay:0.5f options:UIViewAnimationOptionAllowUserInteraction animations:^{
            _focusImageView.alpha = 0.f;
        } completion:nil];
    }];
#endif
}
#pragma mark -------------button actions---------------
//拍照页面，拍照按钮
- (void)takePictureBtnPressed:(UIButton*)sender {
#if SWITCH_SHOW_DEFAULT_IMAGE_FOR_NONE_CAMERA
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        //        [SVProgressHUD showErrorWithStatus:@"设备不支持拍照功能T_T"];
        return;
    }
#endif
    sender.userInteractionEnabled = NO;
    __block UIActivityIndicatorView *actiView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    actiView.center = CGPointMake(self.center.x, self.center.y - CAMERA_TOPVIEW_HEIGHT);
    [actiView startAnimating];
    [self addSubview:actiView];
    [_captureManager takePicture:^(UIImage *stillImage) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //[SCCommon saveImageToPhotoAlbum:stillImage];//存至本机
        });
        [actiView stopAnimating];
        [actiView removeFromSuperview];
        actiView = nil;
        double delayInSeconds = 2.f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
            sender.userInteractionEnabled = YES;
        });
        self.cameraPostViewController.postImage = stillImage;
        self.cameraPostViewController.funcOpenView = self.funcOpenViewCamera;
        self.cameraPostViewController.address = _address;
        self.cameraPostViewController.uexObj = _uexObj;
        self.cameraPostViewController.quality = self.quality;
        self.cameraPostViewController.isCompress = NO;
        //[EUtility brwView:_meBrwView presentModalViewController:self.cameraPostViewController animated:YES];
        [[self.webViewEngine viewController] presentViewController:self.cameraPostViewController animated:YES completion:nil];
    }];
}
//拍照页面，切换前后摄像头按钮按钮
- (NSString*)switchCamera:(NSString *)cameraPosition {
    NSString * result = [_captureManager switchCamera:cameraPosition];
    if (_uexObj) {
       // [_uexObj jsSuccessWithName:@"uexCamera.cbChangeCameraPosition" opId:0 dataType:UEX_CALLBACK_DATATYPE_JSON strData:result];
        [_uexObj.webViewEngine callbackWithFunctionKeyPath:@"uexCamera.cbChangeCameraPosition" arguments:ACArgsPack(@(0),@(UEX_CALLBACK_DATATYPE_JSON),result)];

    }
    return result;
}
//拍照页面，闪光灯按钮
- (NSString*)switchFlashMode:(NSString *)flashMode {
    NSString * result = [_captureManager switchFlashMode:flashMode];
    if (_uexObj) {
        //[_uexObj jsSuccessWithName:@"uexCamera.cbChangeFlashMode" opId:0 dataType:UEX_CALLBACK_DATATYPE_JSON strData:result];
        [_uexObj.webViewEngine callbackWithFunctionKeyPath:@"uexCamera.cbChangeFlashMode" arguments:ACArgsPack(@(0),@(UEX_CALLBACK_DATATYPE_JSON),result)];

    }
    return result;
}
#pragma mark -------------pinch camera---------------
//伸缩镜头
- (void)handlePinch:(UIPinchGestureRecognizer*)gesture {
    [_captureManager pinchCameraView:gesture];
    if (_cameraSlider) {
        if (_cameraSlider.alpha != 1.f) {
            [UIView animateWithDuration:0.3f animations:^{
                _cameraSlider.alpha = 1.f;
            }];
        }
        [_cameraSlider setValue:_captureManager.scaleNum shouldCallBack:NO];
        if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
            [self setSliderAlpha:YES];
        } else {
            [self setSliderAlpha:NO];
        }
    }
}
//#pragma mark -------------save image to local---------------
////保存照片至本机
//- (void)saveImageToPhotoAlbum:(UIImage*)image {
//    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
//}
//
//- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
//    if (error != NULL) {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"出错了!" message:@"存不了T_T" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
//        [alert show];
//    } else {
//        SCDLog(@"保存成功");
//    }
//}
#pragma mark ------------notification-------------
#pragma mark ---------rotate(only when this controller is presented, the code below effect)-------------
//<iOS6
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationOrientationChange object:nil];
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_6_0
//iOS6+
- (BOOL)shouldAutorotate {
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationOrientationChange object:nil];
    return NO;
}
- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}
#endif
- (void)clean {
    _captureManager = nil;
    _cameraSlider = nil;
    _cameraPostViewController = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
