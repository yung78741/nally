//
//  YLTerminal.m
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/9/10.
//  Copyright 2006 yllan. All rights reserved.
//

#import "YLTerminal.h"
#import "YLLGlobalConfig.h"


BOOL isC0Control(unsigned char c) { return (c <= 0x1F); }
BOOL isSPACE(unsigned char c) { return (c == 0x20 || c == 0xA0); }
BOOL isIntermediate(unsigned char c) { return (c >= 0x20 && c <= 0x2F); }
BOOL isParameter(unsigned char c) { return (c >= 0x30 && c <= 0x3F); }
BOOL isUppercase(unsigned char c) { return (c >= 0x40 && c <= 0x5F); }
BOOL isLowercase(unsigned char c) { return (c >= 0x60 && c <= 0x7E); }
BOOL isDelete(unsigned char c) { return (c == 0x7F); }
BOOL isC1Control(unsigned char c) { return(c >= 0x80 && c <= 0x9F); }
BOOL isG1Displayable(unsigned char c) { return(c >= 0xA1 && c <= 0xFE); }
BOOL isSpecial(unsigned char c) { return(c == 0xA0 || c == 0xFF); }
BOOL isAlphabetic(unsigned char c) { return(c >= 0x40 && c <= 0x7E); }

ASCII_CODE asciiCodeFamily(unsigned char c) {
	if (isC0Control(c)) return C0;
	if (isIntermediate(c)) return INTERMEDIATE;
	if (isAlphabetic(c)) return ALPHABETIC;
	if (isDelete(c)) return DELETE;
	if (isC1Control(c)) return C1;
	if (isG1Displayable(c)) return G1;
	if (isSpecial(c)) return SPECIAL;
	return ERROR;
}

static SEL normal_table[256];

@implementation YLTerminal

+ (void) initialize {
	int i;
	/* C0 control character */
	for (i = 0x00; i <= 0x1F; i++)
		normal_table[i] = NULL;
	normal_table[0x07] = @selector(beep);
	normal_table[0x08] = @selector(backspace);
	normal_table[0x0A] = @selector(lf);
	normal_table[0x0D] = @selector(cr);
	normal_table[0x1B] = @selector(beginESC);
	
	/* C1 control character */
	for (i = 0x80; i <=0x9F; i++)
		normal_table[i] = NULL;
	normal_table[0x85] = @selector(newline);
	normal_table[0x9B] = @selector(beginControl);
	
}

- (id) init {
	if (self = [super init]) {
		int i;
		row = [[YLLGlobalConfig sharedInstance] row];
		column = [[YLLGlobalConfig sharedInstance] column];
		x = 0;
		y = 0;
		grid = malloc(sizeof(cell *) * row);
		for (i = 0; i < row; i++) 
			grid[i] = malloc(sizeof(cell) * column);
	}
	return self;
}

- (void) dealloc {
	int i;
	for (i = 0; i < row; i++) 
		free(grid[i]);
	free(grid);
	[super dealloc];
}

# pragma mark -
# pragma mark Cursor Movement


# pragma mark -
# pragma mark Input Interface
- (void) feedData: (NSData *) data {
	[self feedBytes: [data bytes] length: [data length]];
}

- (void) feedBytes: (const unsigned char *) bytes length: (int) len {
	int i;
	char c;
	for (i = 0; i < len; i++) {
		c = bytes[i];
		if (_state == TP_NORMAL) {
			if (normal_table[c])
				[self performSelector: normal_table[c]];
		} else if (_state == TP_ESCAPE) {
			
		} else if (_state == TP_CONTROL) {
			
		}
	}
}

# pragma mark -
# pragma mark Parsing Command

- (void) C0ControlCharacter: (unsigned char) c {
	
}

- (void) C1ControlCharacter: (unsigned char) c {
	
}


- (void) setDelegate: (id) d {
	_delegate = d; // Yes, this is delegation. It shouldn't own the delegation object.
}

- (id) delegate {
	return _delegate;
}

@end
