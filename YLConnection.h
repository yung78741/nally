//
//  YLConnection.h
//  MacBlueTelnet
//
//  Created by Wentao Han on 11/25/08.
//  Copyright 2008 net9.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "YLTerminal.h"

@interface YLConnection : NSObject {
    YLTerminal      * _terminal;
    NSString        * _connectionName;
    NSString        * _connectionAddress;
    NSImage         * _icon;
    BOOL              _processing;
    BOOL              _connected;
    NSDate          * _lastTouchDate;
}

+ (YLConnection *) connectionWithAddress: (NSString *) addr;

- (YLTerminal *) terminal ;
- (void) setTerminal: (YLTerminal *) term;
- (BOOL)connected;
- (void)setConnected:(BOOL)value;
- (NSString *)connectionName;
- (void)setConnectionName:(NSString *)value;
- (NSImage *)icon;
- (void)setIcon:(NSImage *)value;
- (NSString *)connectionAddress;
- (void)setConnectionAddress:(NSString *)value;
- (BOOL)isProcessing;
- (void)setIsProcessing:(BOOL)value;
- (NSDate *) lastTouchDate;
- (void) close ;
- (void) reconnect ;
- (void) connectWithDictionary: (NSDictionary *) d ;
- (BOOL) connectToAddress: (NSString *) addr;
- (BOOL) connectToAddress: (NSString *) addr port: (unsigned int) port ;
- (void) receiveBytes: (unsigned char *) bytes length: (unsigned long int) length ;
- (void) sendBytes: (unsigned char *) msg length: (long int) length ;
- (void) sendMessage: (NSData *) msg;

@end
