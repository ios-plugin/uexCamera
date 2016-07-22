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

@property (nonatomic, assign) EBrowserView *meBrwView;

@property (nonatomic, weak) EUExCamera *uexObj;

@property (nonatomic, assign) CGFloat quality;

@property (nonatomic, strong) CameraPostViewController *cameraPostViewController;


- (void)setUpUI;

- (void)switchCamera:(NSString *)cameraPosition;

- (void)switchFlashMode:(NSString *)flashMode;

- (void)clean;

@end
