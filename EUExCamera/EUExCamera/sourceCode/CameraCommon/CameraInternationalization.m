//
//  CameraInternationalization.m
//
//
//  Created by sdk-suit on 15/10/10.
//  Copyright (c) 2015年 xll. All rights reserved.
//
#import "CameraInternationalization.h"
@implementation CameraInternationalization
+ (NSBundle *)pluginBundle {
    NSString * bundleName = [NSString stringWithFormat:@"uexCamera.bundle"];
    NSString * bundlePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:bundleName];
    return [NSBundle bundleWithPath:bundlePath];
}
+ (NSString*)localizedString:(NSString *)key,... {
    NSString *defaultValue=@"";
    va_list argList;
    va_start(argList,key);
    id arg=va_arg(argList,id);
    //if(arg && [arg isKindOfClass:[NSString class]]){
    if(arg) {
        defaultValue=arg;
    }
    va_end(argList);
    return [EUtility uexPlugin:@"uexCamera" localizedString:key,defaultValue];
}
+ (UIImage *)getImageFromLocalFile:(NSString*)imageName type:(NSString *)type {
    //动态库要用[EUtility bundleForPlugin:@"uexCamera"]获取bundle，静态库可以用[self pluginBundle]
    NSBundle *_mBundle = [EUtility bundleForPlugin:@"uexCamera"];
    NSString *path = [[_mBundle resourcePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@",imageName,type]];
    return [UIImage imageWithContentsOfFile:path];
}
@end
