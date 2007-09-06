//
//  YLLGlobalConfig.h
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/11/12.
//  Copyright 2006 Yllan.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface YLLGlobalConfig : NSObject {

}

+ (YLLGlobalConfig *) sharedInstance;

- (int) row ;
- (int) column ;
@end
