//
//  Constants.h
//  NIDCamera
//
//  Created by INTAEK HAN on 2020/01/15.
//  Copyright © 2020 INTAEK HAN. All rights reserved.
//

#ifndef Constants_h
#define Constants_h

//앱버전 관련 정의
#define APP_VER @"1.0"
#define APP_BUILD_NUM @"6"
#define APP_BUILD_DATE @"2020.02.18"


//은행정보 정의


#define BANKS_JSON @"[{\"BANK\":\"기업은행\",\"CODE\":\"003\",\"ID\":\"KIB\"},{\"BANK\":\"국민은행\",\"CODE\":\"004\",\"ID\":\"KBB\"},{\"BANK\":\"외환은행\",\"CODE\":\"005\",\"ID\":\"KEB\"},{\"BANK\":\"수협\",\"CODE\":\"007\",\"ID\":\"SUB\"},{\"BANK\":\"농협\",\"CODE\":\"011\",\"ID\":\"NHB\"},{\"BANK\":\"우리은행\",\"CODE\":\"020\",\"ID\":\"WRB\"},{\"BANK\":\"제일은행\",\"CODE\":\"023\",\"ID\":\"JIB\"},{\"BANK\":\"씨티은행\",\"CODE\":\"027\",\"ID\":\"CTB\"},{\"BANK\":\"부산은행\",\"CODE\":\"032\",\"ID\":\"PSB\"},{\"BANK\":\"광주은행\",\"CODE\":\"034\",\"ID\":\"KJB\"},{\"BANK\":\"제주은행\",\"CODE\":\"035\",\"ID\":\"JJB\"},{\"BANK\":\"전북은행\",\"CODE\":\"037\",\"ID\":\"JBB\"},{\"BANK\":\"경남은행\",\"CODE\":\"039\",\"ID\":\"KNB\"},{\"BANK\":\"새마을금고\",\"CODE\":\"045\",\"ID\":\"SMB\"},{\"BANK\":\"신협\",\"CODE\":\"048\",\"ID\":\"SIN\"},{\"BANK\":\"우체국\",\"CODE\":\"071\",\"ID\":\"WCG\"},{\"BANK\":\"하나은행\",\"CODE\":\"081\",\"ID\":\"HNB\"},{\"BANK\":\"신한은행\",\"CODE\":\"088\",\"ID\":\"SHB\"},{\"BANK\":\"카카오뱅크\",\"CODE\":\"090\",\"ID\":\"KKB\"}]"

#define KEY_BANK @"BANK"
#define KEY_CODE @"CODE"
#define KEY_ID @"ID"

//====== 실서버 ====
#define BASE_URL @"http://211.170.66.178" //처음부터 했던 서버 - 우분투... 클라이언트
//====== 테스트 서버 ==== : 속도 이슈 있음.
//#define BASE_URL @"http://211.170.66.193" //새로 생긴 서버 , GPU 성능이 이 조금 부족한 서버
//                          211.170.66.193:5048
//====== 사용 포트 =====
#define BASE_PORT @"5048"

#define REQUEST_TIME_OUT 15.0
 
#define MIN_LIMIT_AREA_3X 480000
#define MAX_LIMIT_AREA_3X 650000

#define MIN_LIMIT_AREA_2X 280000
#define MAX_LIMIT_AREA_2X 350000

#endif /* Constants_h */
