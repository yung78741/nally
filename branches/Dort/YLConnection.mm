//
//  YLConnection.mm
//  MacBlueTelnet
//
//  Created by Wentao Han on 11/25/08.
//  Copyright 2008 net9.org. All rights reserved.
//

#import "YLConnection.h"
#import "YLTerminal.h"

@implementation YLConnection

+ (YLConnection *) connectionWithAddress: (NSString *) addr {
    Class c; 
    if ([addr hasPrefix: @"ssh://"])
        c = NSClassFromString(@"YLSSH");
    else
        c = NSClassFromString(@"YLTelnet");
    NSLog(@"CONNECTION wih addr: %@ %@", addr, c);
    return (YLConnection *)[[[c alloc] init] autorelease];
}

- (YLTerminal *) terminal {
    return _terminal;
}

- (void) setTerminal: (YLTerminal *) term {
    if (term != _terminal) {
        [_terminal release];
        _terminal = [term retain];
    }
}

- (BOOL)connected {
    return _connected;
}

- (void)setConnected:(BOOL)value {
    _connected = value;
    if (_connected) 
        [self setIcon: [NSImage imageNamed: @"connect.pdf"]];
    else
        [self setIcon: [NSImage imageNamed: @"offline.pdf"]];
}

- (NSString *)connectionName {
    return _connectionName;
}

- (void)setConnectionName:(NSString *)value {
    if (_connectionName != value) {
        [_connectionName release];
        _connectionName = [value retain];
    }
}

- (NSImage *)icon {
    return _icon;
}

- (void)setIcon:(NSImage *)value {
    if (_icon != value) {
        [_icon release];
        _icon = [value retain];
    }
}

- (NSString *)connectionAddress {
    return _connectionAddress;
}

- (void)setConnectionAddress:(NSString *)value {
    if (_connectionAddress != value) {
        [_connectionAddress release];
        _connectionAddress = [value retain];
    }
}

- (BOOL)isProcessing {
    return _processing;
}

- (void)setIsProcessing:(BOOL)value {
    _processing = value;
}

- (NSDate *) lastTouchDate {
    return _lastTouchDate;
}

- (void) close {
}

- (void) reconnect {
}

- (void) connectWithDictionary: (NSDictionary *) d {
}

- (BOOL) connectToAddress: (NSString *) addr {
    return YES;
}

- (BOOL) connectToAddress: (NSString *) addr port: (unsigned int) port {
    return YES;
}

- (void) receiveBytes: (unsigned char *) bytes length: (unsigned long int) length {
}

- (void) sendBytes: (unsigned char *) msg length: (long int) length {
}

- (void) sendMessage: (NSData *) msg {
}

@end
