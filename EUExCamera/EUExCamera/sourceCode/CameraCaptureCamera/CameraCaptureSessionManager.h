//
//  CameraCaptureSessionManager.h
//  EUExCamera
//
//  Created by zywx on 16/1/22.
//  Copyright © 2016年 zywx. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "CameraDefines.h"
#import <UIKit/UIKit.h>
#import "EUExCamera.h"
#define MAX_PINCH_SCALE_NUM   3.f
#define MIN_PINCH_SCALE_NUM   1.f
@protocol CameraCaptureSessionManager;
typedef void(^DidCapturePhotoBlock)(UIImage *stillImage);
@interface CameraCaptureSessionManager : NSObject
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) AVCaptureDeviceInput *inputDevice;
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;
//pinch
@property (nonatomic, assign) CGFloat preScaleNum;
@property (nonatomic, assign) CGFloat scaleNum;
@property (nonatomic, assign) id <CameraCaptureSessionManager> delegate;
- (void)configureWithParentLayer:(UIView *)parent previewRect:(CGRect)preivewRect;
- (void)takePicture:(DidCapturePhotoBlock)block;
- (NSString *)switchCamera:(NSString *)cameraPosition;
- (void)pinchCameraViewWithScalNum:(CGFloat)scale;
- (void)pinchCameraView:(UIPinchGestureRecognizer *)gesture;
- (NSString *)switchFlashMode:(NSString *)flashMode;
- (void)switchFlashButton:(UIButton*)sender;
- (void)focusInPoint:(CGPoint)devicePoint;
- (void)switchGrid:(BOOL)toShow;
@end
@protocol CameraCaptureSessionManager <NSObject>
@optional
- (void)didCapturePhoto:(UIImage*)stillImage;
@end
