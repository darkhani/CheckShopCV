//
//  UIScreen+Utils.h
//  Hanpass
//
//  Created by INTAEK HAN on 2018. 2. 5..
//  Copyright © 2018년 hanpass. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIScreen (Utils)

+ (BOOL) isIphone5size;
+ (BOOL) isIphone6OrMoreSize;
+ (BOOL) isIphone6PlusSize;
+ (BOOL) isIphone8;
+ (BOOL) isIphoneX;
+ (BOOL) isIphoneXsMax;
+ (BOOL) beforeiPhoneX;
+ (NSInteger) ratioWidth;

@end
