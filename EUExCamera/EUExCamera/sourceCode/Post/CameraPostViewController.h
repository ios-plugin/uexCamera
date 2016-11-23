//
//  CameraPostViewController.h
//  CameraCaptureCameraDemo
//
//  Created by zywx on 15/11/26.
//  Copyright (c) 2015年 zywx. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "EUtility.h"
#import "CameraDefines.h"
#import "CameraCommon.h"
@class EUExCamera;
@class CameraCaptureCamera;
@class CameraPostViewController;
@class CameraPickerController;
@protocol CameraPostViewControllerDelegate <NSObject>
@optional
- (void)closeCameraInCameraPostViewController:(CameraPostViewController *)cameraPostViewController;
@end
@interface CameraPostViewController : UIViewController
@property (nonatomic, strong) UIImage *postImage;
@property (nonatomic, assign) EBrowserView *meBrwView;
@property (nonatomic, copy) NSString *address;
@property (nonatomic, strong) UIView *middleContainerView;//中部view
@property (nonatomic, strong) UILabel *middleLbl;//中部的地址信息
@property (nonatomic, weak) EUExCamera *uexObj;
@property (nonatomic, assign) CGFloat quality;
@property (nonatomic, weak) id<CameraPostViewControllerDelegate> delegate;
@property (nonatomic, assign) BOOL isByOpenInternal;
@property (nonatomic, assign) BOOL isCompress;
@property(nonatomic,strong)ACJSFunctionRef *funcOpenView;
@end
