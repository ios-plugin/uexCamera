//
//  CameraPostViewController.m
//  CameraCaptureCameraDemo
//
//  Created by zywx on 15/11/26.
//  Copyright (c) 2015年 zywx. All rights reserved.
//
#import "CameraPostViewController.h"
#import "EUExBaseDefine.h"
#import "CameraDefines.h"
#import "CameraUtility.h"
#import "CameraInternationalization.h"
#import "EUExCamera.h"
@interface CameraPostViewController (){
    CGSize lblSize;
}
@end
@implementation CameraPostViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self addAddressViewWithText:_address];
    [self setUpUI];
    if (!self.isByOpenInternal) {
    }
}
- (void) setUpUI {
    self.view.backgroundColor = [UIColor lightGrayColor];
    CGFloat imgViewWidth = self.view.frame.size.width - POSITION_LEFT * 2;
    CGFloat imgViewX = POSITION_LEFT;
    if (self.isByOpenInternal) {
        self.view.backgroundColor = [UIColor blackColor];
        imgViewWidth = self.view.frame.size.width;
        imgViewX = 0;
    }
    if (_postImage) {
        UIImageView *imgView = [[UIImageView alloc] initWithImage:_postImage];
        imgView.clipsToBounds = YES;
        imgView.contentMode = UIViewContentModeScaleAspectFill;
        imgView.frame = CGRectMake(imgViewX, POSITION_TOP, imgViewWidth, self.view.frame.size.height - lblSize.height - POSITION_BOTTOM * 3);
        [self.view addSubview:imgView];
    }
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.frame = CGRectMake(BUTTON_X, self.view.frame.size.height - POSITION_TOP, BUTTON_WIDTH, BUTTON_HEIGHT);
    [backBtn setTitle:kInternationalization(@"remake") forState:UIControlStateNormal];
    backBtn.backgroundColor = [UIColor whiteColor];
    [backBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(backBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backBtn];
    UIButton *submitBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    submitBtn.frame = CGRectMake(self.view.frame.size.width - BUTTON_X - BUTTON_WIDTH, self.view.frame.size.height - POSITION_TOP, BUTTON_WIDTH, BUTTON_HEIGHT);
    [submitBtn setTitle:kInternationalization(@"submit") forState:UIControlStateNormal];
    submitBtn.backgroundColor = [UIColor whiteColor];
    [submitBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [submitBtn addTarget:self action:@selector(submitBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:submitBtn];
    if (self.isByOpenInternal) {
        backBtn.backgroundColor = [UIColor blackColor];
        [backBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [submitBtn setTitle:kInternationalization(@"usePhoto") forState:UIControlStateNormal];
        submitBtn.backgroundColor = [UIColor blackColor];
        [submitBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
}
//地理位置
- (void)addAddressViewWithText:(NSString*)text {
    if (!_middleContainerView) {
        _middleLbl = [[UILabel alloc] init];
        _middleLbl.font = [UIFont systemFontOfSize:ADDRESS_FONT];
        CGFloat maxW = self.view.frame.size.width - POSITION_LEFT;
        lblSize = [text sizeWithFont:_middleLbl.font constrainedToSize:CGSizeMake(maxW, MAXFLOAT)];
        CGRect middleFrame = CGRectMake(0, self.view.frame.size.height - kSpacing * 2 - lblSize.height - POSITION_BOTTOM, self.view.frame.size.width, lblSize.height);
        UIView *mView = [[UIView alloc] initWithFrame:middleFrame];
        mView.backgroundColor = [UIColor clearColor];
        [self.view addSubview:mView];
        self.middleContainerView = mView;
        _middleLbl.numberOfLines = 0;
        _middleLbl.frame = CGRectMake((self.view.frame.size.width - lblSize.width) / 2, 0, lblSize.width, middleFrame.size.height);
        _middleLbl.backgroundColor = [UIColor clearColor];
        _middleLbl.textColor = [UIColor blackColor];
        _middleLbl.text = text;
        [_middleContainerView addSubview:_middleLbl];
    }
}
- (void)backBtnPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
-(void)submitBtnPressed:(id)sender {
    if (self.isByOpenInternal) { //如果是通过OpenInternal打开的相机
        [self savaImg:_postImage];
        [self dismissViewControllerAnimated:NO completion:^{
            if (self.delegate) {
                //关闭OpenInternal相机
                [self.delegate closeCameraInCameraPostViewController:self];
            }
        }];
        return;
    }
    NSString *filePath = [self saveImageWith:_postImage];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setValue:filePath forKey:@"photoPath"];
    [dict setValue:_address forKey:@"location"];
    [dict setValue:_address forKey:@"label"];
    NSString *jsonString = [dict ac_JSONFragment];
    if (_uexObj) {
        //[_uexObj jsSuccessWithName:@"uexCamera.cbOpenViewCamera" opId:0 dataType:UEX_CALLBACK_DATATYPE_JSON strData:jsonString];
        [_uexObj.webViewEngine callbackWithFunctionKeyPath:@"uexCamera.cbOpenViewCamera" arguments:ACArgsPack(@(0),@(UEX_CALLBACK_DATATYPE_JSON),jsonString)];
        [self.funcOpenView executeWithArguments:ACArgsPack(dict)];
        self.funcOpenView = nil;
    }
    [self dismissViewControllerAnimated:NO completion:^{
        if (self.delegate) {
            //关闭openViewCamera相机
            [self.delegate closeCameraInCameraPostViewController:self];
        }
    }];
}
-(NSString *)saveImageWith:(UIImage *)image {
    NSDateFormatter *formatter =[[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *timeString = [formatter stringFromDate:[NSDate date]];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSString *pathDocuments = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *createPath = [NSString stringWithFormat:@"%@/EUExCamera", pathDocuments];
    // 判断文件夹是否存在，如果不存在，则创建
    if (![[NSFileManager defaultManager] fileExistsAtPath:createPath]) {
        [fileManager createDirectoryAtPath:createPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *filePath = [createPath stringByAppendingPathComponent:[NSString stringWithFormat:@"EUExCamera_%@.png", timeString]];
//    [UIImagePNGRepresentation(_postImage) writeToFile: filePath atomically:YES];
    [UIImageJPEGRepresentation(image, self.quality) writeToFile:filePath atomically:YES];
    return filePath;
}
-(UIImage *)getImageWith:(NSString *)filePath {
    UIImage *img = [UIImage imageWithContentsOfFile:filePath];
    return img;
}
-(void)savaImg:(UIImage *)image {
    //保存到一个指定目录
    NSError * error;
    NSFileManager * fmanager = [NSFileManager defaultManager];
    NSString * wgtPath = [self.uexObj absPath:@"wgt://"];
    NSString * imagePath = [CameraUtility getSavename:@"image" wgtPath:wgtPath];
    if([fmanager fileExistsAtPath:imagePath]) {
        [fmanager removeItemAtPath:imagePath error:&error];
    }
    UIImage * newImage = [EUtility rotateImage:image];
    //压缩
    UIImage * needSaveImg = [CameraUtility imageByScalingAndCroppingForSize:newImage width:640];
    //压缩比率，0：压缩后的图片最小，1：压缩后的图片最大
    NSData * imageData = nil;
    if (self.isCompress) {
        imageData = UIImageJPEGRepresentation(needSaveImg, self.quality);
    } else {
        imageData = UIImageJPEGRepresentation(needSaveImg, 1);
    }
    BOOL success = [imageData writeToFile:imagePath atomically:YES];
    if (success) {
        //[self.uexObj jsSuccessWithName:@"uexCamera.cbOpenInternal" opId:0 dataType:UEX_CALLBACK_DATATYPE_TEXT strData:imagePath];
        [self.uexObj.webViewEngine callbackWithFunctionKeyPath:@"uexCamera.cbOpenInternal" arguments:ACArgsPack(@(0),@(UEX_CALLBACK_DATATYPE_TEXT),imagePath)];
        [self.funcOpenView executeWithArguments:ACArgsPack(imagePath)];
        self.funcOpenView = nil;
//        [self.uexObj uexSuccessWithOpId:0 dataType:UEX_CALLBACK_DATATYPE_TEXT data:imagePath];
    } else {
        //[self.uexObj jsFailedWithOpId:0 errorCode:1030105 errorDes:UEX_ERROR_DESCRIBE_FILE_SAVE];
    }
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}
- (BOOL)shouldAutorotate {
    return NO;
}
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;//只支持这一个方向(正常的方向)
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
@end
