//
//  UIScreen+Utils.m
//  Hanpass
//
//  Created by INTAEK HAN on 2018. 2. 5..
//  Copyright © 2018년 hanpass. All rights reserved.
//

#import "UIScreen+Utils.h"
#import <UIKit/UIKit.h>

/*
 switch ((int)[[UIScreen mainScreen] nativeBounds].size.height) {
 
 case 1136:
 printf("iPhone 5 or 5S or 5C");
 break;
 case 1334:
 printf("iPhone 6/6S/7/8");
 break;
 case 2208:
 printf("iPhone 6+/6S+/7+/8+");
 break;
 case 2436:
 printf("iPhone X");
 break;
 default:
 printf("unknown");
 }
 */

//iPhoneX , CGSize sz = [UIScreen mainScreen].bounds.size;, (width = 375, height = 812)

@implementation UIScreen(Utils)
+ (BOOL) isIphone5size {
    CGSize sz = [UIScreen mainScreen].bounds.size;
    if (sz.width == 320 && sz.height <= 568) { // = 빠져서 수정 2018-02-07 한인택
        return YES;
    } else {
        return NO;
    }
}

+ (BOOL) isIphone6OrMoreSize {
    CGSize sz = [UIScreen mainScreen].bounds.size;
//    if (sz.width == 375 && sz.height <= 813) { // = 빠져서 수정 2018-02-07 한인택
    if (sz.width == 375) {
        return YES;
    } else {
        return NO;
    }
}

+ (BOOL) isIphone6PlusSize {
    CGSize sz = [UIScreen mainScreen].bounds.size;
    if (sz.width == 414) { // = 빠져서 수정 2018-02-07 한인택
        return YES;
    } else {
        return NO;
    }
}

+ (BOOL) isIphone8 { // Ten 기기 대응건으로 추가 (하단 버튼 공간 줄때 써야지.)
    NSInteger height = (int)[[UIScreen mainScreen] nativeBounds].size.height;
    if ( height == 1334 ) {
        return YES;
    }
    return NO;
}

+ (BOOL) beforeiPhoneX {
    BOOL retVal;
    if ([self isIphone5size]) {
        retVal = YES;
    } else if ([self isIphone6OrMoreSize]) {
        retVal = YES;
    } else if ([self isIphone6PlusSize]) {
        retVal = YES;
    } else if ([self isIphone8]) {
        retVal = YES;
    } else {
        retVal = NO;
    }
    return retVal;
}

+ (BOOL) isIphoneX { // Ten 기기 대응건으로 추가 (하단 버튼 공간 줄때 써야지.)
    //CGSize sz = [UIScreen mainScreen].bounds.size;
    //sz.width == 375임.
    NSInteger width = (int)[[UIScreen mainScreen] nativeBounds].size.width;
    NSInteger height = (int)[[UIScreen mainScreen] nativeBounds].size.height;
    if ( width == 1125 && height == 2436 ) {
        return YES;
    }
    return NO;
}

+ (BOOL) isIphoneXsMax { //iPhone Xs Max ==> 2688 이것도 적용하자.
    NSInteger height = (int)[[UIScreen mainScreen] nativeBounds].size.height;
    if ( height == 2688 ) {
        return YES;
    }
    return NO;
}

+ (NSInteger) ratioWidth {
    CGFloat width = [[UIScreen mainScreen] nativeBounds].size.width; //width == 1125 라면
    CGSize sz = [UIScreen mainScreen].bounds.size; //sz.width == 375 라면
    NSInteger ratio = (int)round(width / sz.width);
//    NSLog(@"width : %f , CGSize : %f , ratio : %d",width,sz.width,ratio);
    return ratio;
}

@end
