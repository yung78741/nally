//
//  YLView.m
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/6/9.
//  Copyright 2006 yllan. All rights reserved.
//

#import "YLView.h"
#import "YLSimpleDataSource.h"
#import "YLLGLobalConfig.h"

@implementation YLView

static id gConfig;

- (id)initWithFrame:(NSRect)frame {
	frame.size = NSMakeSize([ds column] * 12, [ds row] * 24);
    self = [super initWithFrame: frame];
    if (self) {
		_bgColor = [[NSColor colorWithCalibratedRed: 0.0 green: 0.0470588 blue: 0.2431372 alpha: 1.0] retain];
//		bgColor = [[NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 0.0 alpha: 1.0] retain];
		_fgColor = [[NSColor colorWithCalibratedRed: 0.75 green: 0.75 blue: 0.75 alpha: 1.0] retain];
//		fgColor = [[NSColor colorWithCalibratedRed: 1.0 green: 1.0 blue: 1.0 alpha: 1.0] retain];
		_dataSource = ds;
		_fontWidth = 12;
		_fontHeight = 24;
		if (!gConfig) gConfig = [YLLGlobalConfig sharedInstance];
    }
    return self;
}

- (NSRect) cellRectForRect: (NSRect) r {
	int originx = r.origin.x / _fontWidth;
	int originy = r.origin.y / _fontHeight;
	int width = ((r.size.width + r.origin.x) / _fontWidth) - originx + 1;
	int height = ((r.size.height + r.origin.y) / _fontHeight) - originy + 1;
	return NSMakeRect(originx, originy, width, height);
}

- (void)drawRect:(NSRect)rect {
	NSRect cRect = [self cellRectForRect: rect];
	
	int x, y;
	for (y = cRect.origin.y; y < (cRect.origin.y + cRect.size.height); y++) 
		 for (x = cRect.origin.x; x < (cRect.origin.x + cRect.size.width); x++)
			  if ([_dataSource isDirtyAtRow: y column: x]) {
				  [self drawCellAtRow: y column: x];
			  }
}

- (void) drawCellAtRow: (int) r column: (int) c {
	NSRect rect;
	int doubleByte = [_dataSource isDoubleByteAtRow: r column: c];
	unichar ch = [_dataSource charAtRow: r column:c ];
//	if (ch == 0x0020 || ch == 0x0000) 
	if (!doubleByte) {
		rect = NSMakeRect(c * _fontWidth, r * _fontHeight, _fontWidth, _fontHeight);
		NSColor *b = [_dataSource bgColorAtRow: r column: c];
		[b set];
		[NSBezierPath fillRect: rect];
		
		NSString *s = [NSString stringWithCharacters: &ch length: 1];
		int fgIndex = [_dataSource fgColorIndexAtRow: r column: c];

		[s drawAtPoint: NSMakePoint(c * _fontWidth, (r + 1) * _fontHeight - 1) withAttributes: 
			[gConfig eFontAttributeForColorIndex: fgIndex hilite: NO]];
	} else if (doubleByte == 1) {
		int bgIndex1 = [_dataSource bgColorIndexAtRow: r column: c];
		int bgIndex2 = [_dataSource bgColorIndexAtRow: r column: c + 1];
		
		NSString *s = [NSString stringWithCharacters: &ch length: 1];
		int fgIndex1 = [_dataSource fgColorIndexAtRow: r column: c];
		int fgIndex2 = [_dataSource fgColorIndexAtRow: r column: c + 1];

		if (fgIndex1 == fgIndex2) {
			rect = NSMakeRect(c * _fontWidth, r * _fontHeight, _fontWidth, _fontHeight);
			[[gConfig colorAtIndex: bgIndex1 hilite: NO] set];
			[NSBezierPath fillRect: rect];
			rect = NSMakeRect((c+1) * _fontWidth, r * _fontHeight, _fontWidth, _fontHeight);
			[[gConfig colorAtIndex: bgIndex1 hilite: NO] set];
			[NSBezierPath fillRect: rect];

			NSPoint p = NSMakePoint(c * _fontWidth, r * _fontHeight);
			[s drawAtPoint: p withAttributes: [gConfig cFontAttributeForColorIndex: fgIndex1 hilite: NO]];
		} else {
			rect = NSMakeRect((c+1) * _fontWidth, r * _fontHeight, _fontWidth, _fontHeight);
			[[gConfig colorAtIndex: bgIndex2 hilite: NO] set];
			[NSBezierPath fillRect: rect];

			NSPoint p = NSMakePoint(c * _fontWidth, r * _fontHeight);
			[s drawAtPoint: p withAttributes: [gConfig cFontAttributeForColorIndex: fgIndex2 hilite: NO]];
			
			NSImage *limg = [[NSImage alloc] initWithSize: NSMakeSize(_fontWidth, _fontHeight)];
			[limg lockFocus];
			[[gConfig colorAtIndex: bgIndex1 hilite: NO] set];
			[NSBezierPath fillRect: NSMakeRect(0, 0, _fontWidth, _fontHeight)];
			
			[s drawAtPoint: NSMakePoint(0, 0) withAttributes: [gConfig cFontAttributeForColorIndex: fgIndex1 hilite: NO]];
			[limg unlockFocus];
			
			[limg compositeToPoint: NSMakePoint(c * _fontWidth, (r+1) * _fontHeight) operation: NSCompositeSourceOver];
			[limg dealloc];
		}

	} else {
//		NSLog(@"%d %d %d", r, c, doubleByte);
	}
}

- (BOOL) isFlipped {
	return YES;
}

@end
