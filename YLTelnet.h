//
//  YLTelnet.h
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/9/10.
//  Copyright 2006 yllan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class YLTerminal;

@interface YLTelnet : NSObject {
	NSString		* _serverAddress;
	NSFileHandle	* _server;
	YLTerminal		* _delegate;
}

/* return YES if successful, NO otherwise. */
- (BOOL) connectToAddress: (NSString *) addr;

/* return the last error message. */
- (NSString *) lastError;

- (void) setDelegate: (YLTerminal *) _terminal;

@end
