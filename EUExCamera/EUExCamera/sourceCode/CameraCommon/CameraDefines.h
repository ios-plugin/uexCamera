//
//  CameraDefines.h
//  EUExCamera
//
//  Created by zywx on 16/1/22.
//  Copyright © 2016年 zywx. All rights reserved.
//
#ifndef CameraCaptureCameraDemo_SCDefines_h
#define CameraCaptureCameraDemo_SCDefines_h
/**
 *  相机：CameraCaptureCamera needs four frameworks:
 *  1、CoreMedia.framework
 *  2、QuartzCore.framework
 *  3、AVFoundation.framework
 *  4、ImmageIO.framework
 *
 */
// Debug Logging
#if 1 // Set to 1 to enable debug logging
#define SCDLog(x, ...) NSLog(x, ## __VA_ARGS__);
#else
#define SCDLog(x, ...)
#endif
//Position
#define ADDRESS_FONT 20
#define POSITION_TOP 50
#define POSITION_BOTTOM 40
#define POSITION_LEFT 25
#define BUTTON_WIDTH 80
#define BUTTON_HEIGHT 30
#define BUTTON_X 10
//notification
#define kCapturedPhotoSuccessfully              @"caputuredPhotoSuccessfully"
#define kNotificationOrientationChange          @"kNotificationOrientationChange"
#define kNotificationTakePicture                @"kNotificationTakePicture"
//weakself
#define WEAKSELF_SC __weak __typeof(&*self)weakSelf_SC = self;
//cort text里的空格要转一下
#define REPLACE_SPACE_STR(content) [content stringByReplacingOccurrencesOfString:@" " withString:@" "]
//color
#define rgba_SC(r, g, b, a) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]
//frame and size
#define SC_DEVICE_BOUNDS        [[UIScreen mainScreen] bounds]
#define SC_DEVICE_SIZE          [[UIScreen mainScreen] bounds].size
#define SC_DEVICE_WIDTH         [[UIScreen mainScreen] bounds].size.width
#define SC_DEVICE_HEIGHT        [[UIScreen mainScreen] bounds].size.height
#define SC_APP_FRAME            [[UIScreen mainScreen] applicationFrame]
#define SC_APP_SIZE             [[UIScreen mainScreen] applicationFrame].size
#define SELF_CON_FRAME          self.view.frame
#define SELF_CON_SIZE           self.view.frame.size
#define SELF_VIEW_FRAME         self.frame
#define SELF_VIEW_SIZE          self.frame.size
// 是否iPad
#define isPad_SC (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)//设备类型改为Universal才能生效
#define isPad_AllTargetMode_SC ([[UIDevice currentDevice].model rangeOfString:@"iPad"].location != NSNotFound)//设备类型为任何类型都能生效
//iPhone5及以上设备，按钮的位置放在下面。iPhone5以下的按钮放上面。
#define isHigherThaniPhone4_SC ((isPad_AllTargetMode_SC && [[UIScreen mainScreen] applicationFrame].size.height <= 960 ? NO : ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? ([[UIScreen mainScreen] currentMode].size.height > 960 ? YES : NO) : NO)))
//#define isHigherThaniPhone4_SC (isPad_SC ? YES : ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? ([[UIScreen mainScreen] currentMode].size.height > 960 ? YES : NO) : NO))
#define kCameraBtnWH 70
#define kSpacing 10
//json,text,int
#define UEX_CALLBACK_DATATYPE_TEXT	0
#define UEX_CALLBACK_DATATYPE_JSON	1
#define UEX_CALLBACK_DATATYPE_INT	2
#if __IPHONE_6_0 // iOS6 and later
#   define kTextAlignmentCenter_Camera    NSTextAlignmentCenter
#   define kTextAlignmentLeft_Camera      NSTextAlignmentLeft
#   define kTextAlignmentRight_Camera     NSTextAlignmentRight
#   define kTextLineBreakByWordWrapping_Camera      NSLineBreakByWordWrapping
#   define kTextLineBreakByCharWrapping_Camera      NSLineBreakByCharWrapping
#   define kTextLineBreakByClipping_Camera          NSLineBreakByClipping
#   define kTextLineBreakByTruncatingHead_Camera    NSLineBreakByTruncatingHead
#   define kTextLineBreakByTruncatingTail_Camera    NSLineBreakByTruncatingTail
#   define kTextLineBreakByTruncatingMiddle_Camera  NSLineBreakByTruncatingMiddle
#else // older versions
#   define kTextAlignmentCenter_Camera    UITextAlignmentCenter
#   define kTextAlignmentLeft_Camera      UITextAlignmentLeft
#   define kTextAlignmentRight_Camera     UITextAlignmentRight
#   define kTextLineBreakByWordWrapping_Camera       UILineBreakModeWordWrap
#   define kTextLineBreakByCharWrapping_Camera       UILineBreakModeCharacterWrap
#   define kTextLineBreakByClipping_Camera           UILineBreakModeClip
#   define kTextLineBreakByTruncatingHead_Camera     UILineBreakModeHeadTruncation
#   define kTextLineBreakByTruncatingTail_Camera     UILineBreakModeTailTruncation
#   define kTextLineBreakByTruncatingMiddle_Camera   UILineBreakModeMiddleTruncation
#endif
#endif
