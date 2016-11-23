//
//  CameraPickerController.m
//  EUExCamera
//
//  Created by zywx on 16/1/25.
//  Copyright © 2016年 zywx. All rights reserved.
//
#import "CameraPickerController.h"
#import "CameraSlider.h"
#import "CameraCommon.h"
#import "EUtility.h"
#import "EUExCamera.h"
#import "EUExBaseDefine.h"
#import "CameraDefines.h"
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
#define SC_CAMERA_WIDTH  SC_DEVICE_SIZE.width
#define SC_CAMERA_HEIGHT  SC_DEVICE_SIZE.height
@interface CameraPickerController () {
    int alphaTimes;
    CGPoint currTouchPoint;
    BOOL isFrontCamera;
    BOOL isFlashLight;
    UIButton *switchFlashBtn;
    UIButton *switchCameraBtn;
    CGFloat cameraHeight;
    CGFloat cameraWidth;
}
@property (nonatomic, strong) CameraCaptureSessionManager *captureManager;
@property (nonatomic, strong) UIView *topContainerView;//顶部view
@property (nonatomic, strong) UIView *middleContainerView;//中部view
@property (nonatomic, strong) UILabel *middleLbl;//中部的地址信息
@property (nonatomic, strong) UIView *cameraMenuView;//网格、闪光灯、前后摄像头等按钮
//对焦
@property (nonatomic, strong) UIImageView *focusImageView;
@property (nonatomic, strong) CameraSlider *cameraSlider;
@end
@implementation CameraPickerController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        alphaTimes = -1;
        currTouchPoint = CGPointZero;
        isFrontCamera = NO;
        isFlashLight = NO;
        self.isAction = NO;
        cameraHeight = SC_CAMERA_HEIGHT > SC_CAMERA_WIDTH?SC_CAMERA_HEIGHT:SC_CAMERA_WIDTH;
        cameraWidth = SC_CAMERA_HEIGHT > SC_CAMERA_WIDTH?SC_CAMERA_WIDTH:SC_CAMERA_HEIGHT;
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
//    self.closeCameraDelegate = self.uexObj;
    //notification
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationOrientationChange object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange:) name:kNotificationOrientationChange object:nil];
    CameraCaptureSessionManager *manager = [[CameraCaptureSessionManager alloc] init];
    //AvcaptureManager此处修改拍照预览区域的大小//
    if (CGRectEqualToRect(_previewRect, CGRectZero)) {
        self.previewRect = CGRectMake(0, 22, cameraWidth, cameraHeight / 4 * 3);
    }
    [manager configureWithParentLayer:self.view previewRect:_previewRect];
    self.captureManager = manager;
    [self addCameraMenuView];
    [self addTopViewWithText:kInternationalization(@"takePhotos")];
    //伸缩手势
    [self addPinchGesture];
    [_captureManager.session startRunning];
#if SWITCH_SHOW_DEFAULT_IMAGE_FOR_NONE_CAMERA
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        //        [SVProgressHUD showErrorWithStatus:@"设备不支持拍照功能T_T"];
    }
#endif
}
#pragma mark -------------UI---------------
//顶部标题
- (void)addTopViewWithText:(NSString*)text {
    if (!_topContainerView) {
        CGRect topFrame = CGRectMake(0, 0, cameraWidth, CAMERA_TOPVIEW_HEIGHT * 1.5);
        self.topContainerView = [[UIView alloc] initWithFrame:topFrame];
        self.topContainerView.backgroundColor = [UIColor clearColor];
        [self.view addSubview:self.topContainerView];
        UIView *emptyView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, topFrame.size.width, topFrame.size.height)];
        emptyView.backgroundColor = [UIColor blackColor];
        emptyView.alpha = 1.0f;
        [_topContainerView addSubview:emptyView];
        topFrame.origin.x += 10;
        switchCameraBtn = [[UIButton alloc] initWithFrame:CGRectMake(cameraWidth - 62, 0, 44, topFrame.size.height)];
        [switchCameraBtn setImage:[CameraInternationalization getImageFromLocalFile:@"switch_camera" type:@"png"] forState:UIControlStateNormal];
        [switchCameraBtn addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
        [_topContainerView addSubview:switchCameraBtn];
        //默认设置关闭闪光灯
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        [device lockForConfiguration:nil];
        device.flashMode = AVCaptureFlashModeOff;
        switchFlashBtn = [[UIButton alloc] initWithFrame:CGRectMake(22, 0, 44, topFrame.size.height)];
        [switchFlashBtn setImage:[CameraInternationalization getImageFromLocalFile:@"flashing_off" type:@"png"] forState:UIControlStateNormal];
        [switchFlashBtn addTarget:self action:@selector(switchFlashButton:) forControlEvents:UIControlEventTouchUpInside];
        [_topContainerView addSubview:switchFlashBtn];
    }
}
//拍照菜单栏
- (void)addCameraMenuView {
    CGFloat cameraBtnLength = kCameraBtnWH;
    CGRect cameraBtnFrame = CGRectMake((cameraWidth - cameraBtnLength) / 2, cameraHeight - kSpacing * 2 - cameraBtnLength , cameraBtnLength, cameraBtnLength);
    _cameraMenuView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_previewRect), cameraWidth, cameraHeight - CGRectGetMaxY(_previewRect))];
    _cameraMenuView.backgroundColor = [UIColor blackColor];
    UIButton *backBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 30)];
    CGPoint backCenterPoint = backBtn.center;
    backCenterPoint.x = 40;
    backCenterPoint.y = _cameraMenuView.center.y - _cameraMenuView.frame.origin.y;
    backBtn.center = backCenterPoint;
    backBtn.backgroundColor = [UIColor blackColor];
    [backBtn setTitle:kInternationalization(@"back") forState:UIControlStateNormal];
    backBtn.titleLabel.textColor = [UIColor whiteColor];
    [backBtn addTarget:self action:@selector(closeCamera) forControlEvents:UIControlEventTouchUpInside];
    [_cameraMenuView addSubview:backBtn];
    [self.view addSubview:_cameraMenuView];
    //拍照按钮
    [self buildButton:cameraBtnFrame
         normalImgStr:@"plugin_camera_bt_takepic_normal"
      highlightImgStr:@"plugin_camera_bt_takepic_on"
       selectedImgStr:@""
               action:@selector(takePictureBtnPressed:)
           parentView:self.view];
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
-(void)closeCamera{
    if (self.isAction) {
        return;
    }
    self.isAction = YES;
    [self dismissViewControllerAnimated:NO completion:^{
        [self performSelector:@selector(changeIsAction) withObject:nil afterDelay:0.5f];
        if (self.delegate) {
            [self.delegate closeCameraPickerController:self];
        }
    }];
}
//对焦的框
- (void)addFocusView {
    UIImageView *imgView = [[UIImageView alloc] initWithImage:[CameraInternationalization getImageFromLocalFile:@"touch_focus_x" type:@"png"]];
    imgView.alpha = 0;
    [self.view addSubview:imgView];
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
    [self.view addGestureRecognizer:pinch];
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
    [self.view addSubview:slider];
    self.cameraSlider = slider;
}
- (void)setSliderAlpha:(BOOL)isTouchEnd {
    if (_cameraSlider) {
        _cameraSlider.isSliding = !isTouchEnd;
        if (_cameraSlider.alpha != 0.f && !_cameraSlider.isSliding) {
            double delayInSeconds = 3.88;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
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
//监听对焦是否完成了
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:ADJUSTINT_FOCUS]) {
        BOOL isAdjustingFocus = [[change objectForKey:NSKeyValueChangeNewKey] isEqualToNumber:[NSNumber numberWithInt:1]];
        //        SCDLog(@"Is adjusting focus? %@", isAdjustingFocus ? @"YES" : @"NO" );
        //        SCDLog(@"Change dictionary: %@", change);
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
    currTouchPoint = [touch locationInView:self.view];
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
    if (self.isAction) {
        return;
    }
    self.isAction = YES;
#if SWITCH_SHOW_DEFAULT_IMAGE_FOR_NONE_CAMERA
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        //        [SVProgressHUD showErrorWithStatus:@"设备不支持拍照功能"];
        return;
    }
#endif
    sender.userInteractionEnabled = NO;
    //    [self showCameraCover:YES];
    __block UIActivityIndicatorView *actiView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    actiView.center = CGPointMake(self.view.center.x, self.view.center.y - CAMERA_TOPVIEW_HEIGHT);
    [actiView startAnimating];
    [self.view addSubview:actiView];
    [_captureManager takePicture:^(UIImage *stillImage) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //[SCCommon saveImageToPhotoAlbum:stillImage];//存至本机
        });
        [actiView stopAnimating];
        [actiView removeFromSuperview];
        actiView = nil;
        double delayInSeconds = 2.f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            sender.userInteractionEnabled = YES;
        });
        if (stillImage) {
            CameraPostViewController *pc = [[CameraPostViewController alloc] init];
            pc.postImage = stillImage;
            pc.uexObj = _uexObj;
            pc.quality = self.scale;
            pc.isByOpenInternal = YES;
            pc.isCompress = self.isCompress;
            pc.delegate = self;
            pc.funcOpenView = self.funcOpenInternal;
            [self presentViewController:pc animated:YES completion:nil];
        }
        [self performSelector:@selector(changeIsAction) withObject:nil afterDelay:0.5f];
    }];
}
//拍照页面，切换前后摄像头按钮按钮
- (void)switchCamera:(UIButton*)sender {
    if (self.isAction) {
        return;
    }
    self.isAction = YES;
    isFrontCamera = !isFrontCamera;
    NSString * result = [_captureManager switchCamera:[NSString stringWithFormat:@"%d",isFrontCamera]];
    NSString *imgStr = @"";
    if (isFrontCamera) {
        imgStr = @"switch_camera_h";
    } else{
        imgStr = @"switch_camera";
    }
    if (sender) {
        [sender setImage:[CameraInternationalization getImageFromLocalFile:imgStr type:@"png"] forState:UIControlStateNormal];
    }
    if (_uexObj) {
        [_uexObj.webViewEngine callbackWithFunctionKeyPath:@"uexCamera.cbChangeCameraPosition" arguments:ACArgsPack(@0,@(UEX_CALLBACK_DATATYPE_JSON),result)];
        [self performSelector:@selector(changeIsAction) withObject:nil afterDelay:0.5f];
    }
}
//拍照页面，闪光灯按钮
- (void)switchFlashButton:(UIButton*)sender {
    if (self.isAction) {
        return;
    }
    self.isAction = YES;
    [_captureManager switchFlashButton:sender];
    [self performSelector:@selector(changeIsAction) withObject:nil afterDelay:0.5f];
}
- (void)changeIsAction{
    self.isAction = NO;
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
#pragma mark ------------notification-------------
- (void)orientationDidChange:(NSNotification*)noti {
    switchCameraBtn.layer.anchorPoint = CGPointMake(0.5, 0.5);
    switchFlashBtn.layer.anchorPoint = CGPointMake(0.5, 0.5);
    CGAffineTransform transform = CGAffineTransformMakeRotation(0);
    switch ([UIDevice currentDevice].orientation) {
        case UIDeviceOrientationPortrait: {
            transform = CGAffineTransformMakeRotation(0);
            break;
        }
        case UIDeviceOrientationPortraitUpsideDown: {
            transform = CGAffineTransformMakeRotation(M_PI);
            break;
        }
        case UIDeviceOrientationLandscapeLeft: {
            transform = CGAffineTransformMakeRotation(M_PI_2);
            break;
        }
        case UIDeviceOrientationLandscapeRight: {
            transform = CGAffineTransformMakeRotation(-M_PI_2);
            break;
        }
        default:
            break;
    }
    [UIView animateWithDuration:0.3f animations:^{
        switchCameraBtn.transform = transform;
        switchFlashBtn.transform = transform;
    }];
}
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
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    //    return [UIApplication sharedApplication].statusBarOrientation;
    return UIInterfaceOrientationPortrait;
}
#endif
#pragma mark - CameraPostViewControllerDelegate
- (void)closeCameraInCameraPostViewController:(CameraPostViewController *)cameraPostViewController {
    [self dismissViewControllerAnimated:NO completion:^{
        if (self.delegate) {
            [self.delegate closeCameraPickerController:self];
        }
    }];
}
@end
