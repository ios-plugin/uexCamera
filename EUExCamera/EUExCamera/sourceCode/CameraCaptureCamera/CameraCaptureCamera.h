//
//  CameraCaptureCamera.h
//  EUExCamera
//
//  Created by zywx on 16/1/22.
//  Copyright © 2016年 zywx. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "CameraCaptureSessionManager.h"
#import "CameraPostViewController.h"
@class EUExCamera;
@class EBrowserView;
@interface CameraCaptureCamera : UIView
@property (nonatomic, assign) CGRect previewRect;
@property (nonatomic, assign) BOOL isStatusBarHiddenBeforeShowCamera;
@property (nonatomic, copy) NSString *address;
@property (nonatomic, weak) id<AppCanWebViewEngineObject> webViewEngine;
@property (nonatomic, weak) EUExCamera *uexObj;
@property (nonatomic, assign) CGFloat quality;
@property (nonatomic, strong) CameraPostViewController *cameraPostViewController;
@property(nonatomic,strong)ACJSFunctionRef *funcOpenViewCamera;
- (void)setUpUI;
- (NSString*)switchCamera:(NSString *)cameraPosition;
- (NSString*)switchFlashMode:(NSString *)flashMode;
- (void)clean;
@end
