//
//  CameraPickerController.h
//  EUExCamera
//
//  Created by zywx on 16/1/25.
//  Copyright © 2016年 zywx. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "CameraCaptureSessionManager.h" 
#import "CameraPostViewController.h"
@class EUExCamera;
@class EBrowserView;
@class CameraPickerController;
@protocol CameraPickerControllerDelegate <NSObject>
@optional
- (void)closeCameraPickerController:(CameraPickerController *)CameraPickerController;
@end
@interface CameraPickerController : UIViewController<CameraPostViewControllerDelegate>
@property (nonatomic, assign) CGRect previewRect;
@property (nonatomic, assign) BOOL isStatusBarHiddenBeforeShowCamera;
@property (nonatomic, weak) id<AppCanWebViewEngineObject> webViewEngine;
@property (nonatomic, assign) EUExCamera *uexObj;
@property (nonatomic, assign) CGFloat scale;
@property (nonatomic, assign) BOOL isCompress;
@property (nonatomic, assign) BOOL isAction;
@property (nonatomic, assign) id<CameraPickerControllerDelegate> delegate;
@property(nonatomic,strong)ACJSFunctionRef *funcOpenInternal;
@end
