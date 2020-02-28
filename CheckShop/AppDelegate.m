//
//  AppDelegate.m
//  CheckShop
//
//  Created by INTAEK HAN on 2020/01/24.
//  Copyright © 2020 INTAEK HAN. All rights reserved.
//

#import "AppDelegate.h"

//이슈들 기록
//*OpenCV
//C++ 옵션 조정 필요 -> GNU++17, C++11 support...어쩌구로...

//*Tesseract
//TESSDATA_PREFIX 어쩌구 이슈
//===> ~/.profile에 TESSDATA_PREFIX="/usr/local/Celler/tessract/.../share" 설정하면됨
//TESSDATA_NUM_ENTRIES:Error:Assert failed:in file ../../ccutil/tessdatamanager.cpp, line 53
//===> https://github.com/gali8/Tesseract-OCR-iOS/issues/392

//
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    return YES;
}

@end
