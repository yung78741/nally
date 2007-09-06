//
//  YLLGlobalConfig.m
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/11/12.
//  Copyright 2006 Yllan.org. All rights reserved.
//

#import "YLLGlobalConfig.h"

static YLLGlobalConfig* SharedInstance;

@implementation YLLGlobalConfig
+ (YLLGlobalConfig*) sharedInstance {
	return SharedInstance ?: [[YLLGlobalConfig new] autorelease];
}

- (id) init {
	if(SharedInstance) {
		[self release];
	} else if(self = SharedInstance = [[super init] retain]) {
		/* init code */
	}
	return SharedInstance;
}

- (int) row {
	return 24;
}

- (int) column {
	return 80;
}

@end
