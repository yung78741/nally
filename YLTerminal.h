//
//  YLTerminal.h
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/9/10.
//  Copyright 2006 yllan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef struct {
	unsigned char byte;
	unsigned int fgColor	: 4;
	unsigned int bgColor	: 4;
	unsigned int clear		: 1;
	unsigned int bold		: 1;
	unsigned int underline	: 1;
	unsigned int blink		: 1;
	unsigned int reverse	: 1;
} cell;

typedef enum {C0, INTERMEDIATE, ALPHABETIC, DELETE, C1, G1, SPECIAL, ERROR} ASCII_CODE;

@interface YLTerminal : NSObject {	
	unsigned int row;
	unsigned int column;
	unsigned int x;
	unsigned int y;
	
	cell **grid;
	
	enum { TP_NORMAL, TP_ESCAPE, TP_CONTROL } _state;

	id _delegate;
}

- (void) feedData: (NSData *) data ;
- (void) feedBytes: (const unsigned char *) bytes length: (int) len ;

- (void) setDelegate: (id) d;
- (id) delegate;

@end
