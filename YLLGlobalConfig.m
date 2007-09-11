//
//  YLLGlobalConfig.m
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/11/12.
//  Copyright 2006 Yllan.org. All rights reserved.
//

#import "YLLGlobalConfig.h"

static YLLGlobalConfig *sSharedInstance;

@implementation YLLGlobalConfig
+ (YLLGlobalConfig*) sharedInstance {
	return sSharedInstance ?: [[YLLGlobalConfig new] autorelease];
}

- (id) init {
	if(sSharedInstance) {
		[self release];
	} else if(self = sSharedInstance = [[super init] retain]) {
		/* init code */
		_row = 24;
		_column = 80;
		_cellWidth = 12;
		_cellHeight = 24;
		[self setEFont: [NSFont fontWithName: @"Monaco" size: 18]];
		[self setCFont: [NSFont fontWithName: @"LiHei Pro" size: 22]];
		_colorTable[0][0] = [[NSColor colorWithDeviceRed: 0.00 green: 0.00 blue: 0.00 alpha: 1.0] retain];
		_colorTable[1][0] = [[NSColor colorWithDeviceRed: 0.25 green: 0.25 blue: 0.25 alpha: 1.0] retain];
		_colorTable[0][1] = [[NSColor colorWithDeviceRed: 0.50 green: 0.00 blue: 0.00 alpha: 1.0] retain];
		_colorTable[1][1] = [[NSColor colorWithDeviceRed: 1.00 green: 0.00 blue: 0.00 alpha: 1.0] retain];
		_colorTable[0][2] = [[NSColor colorWithDeviceRed: 0.00 green: 0.50 blue: 0.00 alpha: 1.0] retain];
		_colorTable[1][2] = [[NSColor colorWithDeviceRed: 0.00 green: 1.00 blue: 0.00 alpha: 1.0] retain];
		_colorTable[0][3] = [[NSColor colorWithDeviceRed: 0.50 green: 0.50 blue: 0.00 alpha: 1.0] retain];
		_colorTable[1][3] = [[NSColor colorWithDeviceRed: 1.00 green: 1.00 blue: 0.00 alpha: 1.0] retain];
		_colorTable[0][4] = [[NSColor colorWithDeviceRed: 0.00 green: 0.00 blue: 0.50 alpha: 1.0] retain];
		_colorTable[1][4] = [[NSColor colorWithDeviceRed: 0.00 green: 0.00 blue: 1.00 alpha: 1.0] retain];
		_colorTable[0][5] = [[NSColor colorWithDeviceRed: 0.50 green: 0.00 blue: 0.50 alpha: 1.0] retain];
		_colorTable[1][5] = [[NSColor colorWithDeviceRed: 1.00 green: 0.00 blue: 1.00 alpha: 1.0] retain];
		_colorTable[0][6] = [[NSColor colorWithDeviceRed: 0.00 green: 0.50 blue: 0.50 alpha: 1.0] retain];
		_colorTable[1][6] = [[NSColor colorWithDeviceRed: 0.00 green: 1.00 blue: 1.00 alpha: 1.0] retain];
		_colorTable[0][7] = [[NSColor colorWithDeviceRed: 0.50 green: 0.50 blue: 0.50 alpha: 1.0] retain];
		_colorTable[1][7] = [[NSColor colorWithDeviceRed: 1.00 green: 1.00 blue: 1.00 alpha: 1.0] retain];
		_colorTable[0][8] = [[NSColor colorWithDeviceRed: 0.75 green: 0.75 blue: 0.75 alpha: 1.0] retain];
		_colorTable[1][8] = [[NSColor colorWithDeviceRed: 1.00 green: 1.00 blue: 1.00 alpha: 1.0] retain];
		_colorTable[0][9] = [[NSColor colorWithDeviceRed: 0.00 green: 0.00 blue: 0.00 alpha: 1.0] retain];
		_colorTable[1][9] = [[NSColor colorWithDeviceRed: 0.00 green: 0.00 blue: 0.00 alpha: 1.0] retain];
		
		int i, j;
		for (i = 0; i < NUM_COLOR; i++) 
			for (j = 0; j < 2; j++) {
				_cDictTable[j][i] = [[NSDictionary dictionaryWithObjectsAndKeys: _colorTable[j][i], NSForegroundColorAttributeName,
									  _cFont, NSFontAttributeName, nil] retain];
				_eDictTable[j][i] = [[NSDictionary dictionaryWithObjectsAndKeys: _colorTable[j][i], NSForegroundColorAttributeName,
									  _eFont, NSFontAttributeName, nil] retain];
			}
		
	}
	return sSharedInstance;
}

- (void) dealloc {
	[_eFont release];
	[_cFont release];
	
	[super dealloc];
}

- (int)row {
    return _row;
}

- (void)setRow:(int)value {
	_row = value;
}

- (int)column {
    return _column;
}

- (void)setColumn:(int)value {
    _column = value;
}

- (int)cellWidth {
    return _cellWidth;
}

- (void)setCellWidth:(int)value {
    _cellWidth = value;
}

- (int)cellHeight {
    return _cellHeight;
}

- (void)setCellHeight:(int)value {
    _cellHeight = value;
}

- (NSFont *)eFont {
    return [[_eFont retain] autorelease];
}

- (void)setEFont:(NSFont *)value {
    if (_eFont != value) {
        [_eFont release];
        _eFont = [value copy];
    }
}

- (NSFont *)cFont {
    return [[_cFont retain] autorelease];
}

- (void)setCFont:(NSFont *)value {
    if (_cFont != value) {
        [_cFont release];
        _cFont = [value copy];
    }
}

- (NSColor *) colorAtIndex: (int) i hilite: (BOOL) h {
	if (i >= 0 && i < NUM_COLOR) 
		return _colorTable[h][i];
	return _colorTable[0][NUM_COLOR - 1];
}

- (void) setColor: (NSColor *) c hilite: (BOOL) h atIndex: (int) i {
	if (i >= 0 && i < NUM_COLOR) {
		[_colorTable[h][i] autorelease];
		_colorTable[h][i] = [c retain];
	}
}

- (NSDictionary *) cFontAttributeForColorIndex: (int) i hilite: (BOOL) h {
	return _cDictTable[h][i];
}

- (NSDictionary *) eFontAttributeForColorIndex: (int) i hilite: (BOOL) h {
	return _eDictTable[h][i];
}

@end
