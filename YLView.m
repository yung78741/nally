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
	id ds = [YLSimpleDataSource new];
	if (!gConfig) gConfig = [YLLGlobalConfig sharedInstance];

	frame.size = NSMakeSize([ds column] * [gConfig cellWidth], [ds row] * [gConfig cellHeight]);
    self = [super initWithFrame: frame];
    if (self) {
		_bgColor = [[NSColor colorWithCalibratedRed: 0.0 green: 0.0470588 blue: 0.2431372 alpha: 1.0] retain];
		_fgColor = [[NSColor colorWithCalibratedRed: 0.75 green: 0.75 blue: 0.75 alpha: 1.0] retain];

		_dataSource = ds;
		_fontWidth = [gConfig cellWidth];
		_fontHeight = [gConfig cellHeight];
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

/*
	for (x = 0; x < [gConfig column]; x++) {
		NSBezierPath *bp = [NSBezierPath new];
		[bp moveToPoint: NSMakePoint(x * _fontWidth, 0)];
		[bp lineToPoint: NSMakePoint(x * _fontWidth, [gConfig row] * _fontHeight)];
		[[NSColor greenColor] set];
		[bp stroke];
		[bp release];
	}

	for (y = 0; y < [gConfig row]; y++) {
		NSBezierPath *bp = [NSBezierPath new];
		[bp moveToPoint: NSMakePoint(0, y * _fontHeight)];
		[bp lineToPoint: NSMakePoint([gConfig column] * _fontWidth,  y * _fontHeight)];
		[[NSColor greenColor] set];
		[bp stroke];
		[bp release];
	}

/**/
}

- (void) drawCellAtRow: (int) r column: (int) c {
	NSRect rect;
	int doubleByte = [_dataSource isDoubleByteAtRow: r column: c];
	unichar ch = [_dataSource charAtRow: r column:c ];

	if (!doubleByte) {
		rect = NSMakeRect(c * _fontWidth, r * _fontHeight, _fontWidth, _fontHeight);
		NSColor *b = [_dataSource bgColorAtRow: r column: c];
		[b set];
		[NSBezierPath fillRect: rect];
		
		NSString *s = [NSString stringWithCharacters: &ch length: 1];
		int fgIndex = [_dataSource fgColorIndexAtRow: r column: c];
		BOOL hilite = [_dataSource boldAtRow: r column: c];


		[self drawString: s atPoint: NSMakePoint(c * _fontWidth, r * _fontHeight)
		  withAttributes: [gConfig eFontAttributeForColorIndex: fgIndex hilite: hilite]
				 unichar: ch color: [gConfig colorAtIndex: fgIndex hilite: hilite]];
	} else if (doubleByte == 1) {
		int bgIndex1 = [_dataSource bgColorIndexAtRow: r column: c];
		int bgIndex2 = [_dataSource bgColorIndexAtRow: r column: c + 1];
		
		NSString *s = [NSString stringWithCharacters: &ch length: 1];
		int fgIndex1 = [_dataSource fgColorIndexAtRow: r column: c];
		int fgIndex2 = [_dataSource fgColorIndexAtRow: r column: c + 1];
		BOOL hilite1 = [_dataSource boldAtRow: r column: c];
		BOOL hilite2 = [_dataSource boldAtRow: r column: c + 1];

		if (fgIndex1 == fgIndex2 && hilite1 == hilite2) {
			rect = NSMakeRect(c * _fontWidth, r * _fontHeight, _fontWidth, _fontHeight);
			[[gConfig colorAtIndex: bgIndex1 hilite: NO] set];
			[NSBezierPath fillRect: rect];
			rect = NSMakeRect((c+1) * _fontWidth, r * _fontHeight, _fontWidth, _fontHeight);
			[[gConfig colorAtIndex: bgIndex1 hilite: NO] set];
			[NSBezierPath fillRect: rect];

			NSPoint p = NSMakePoint(c * _fontWidth, r * _fontHeight);
			[self drawString: s atPoint: p withAttributes: [gConfig cFontAttributeForColorIndex: fgIndex2 hilite: hilite2]
					 unichar: ch color: [gConfig colorAtIndex: fgIndex2 hilite: hilite2]];
		} else {
			rect = NSMakeRect((c+1) * _fontWidth, r * _fontHeight, _fontWidth, _fontHeight);
			[[gConfig colorAtIndex: bgIndex2 hilite: NO] set];
			[NSBezierPath fillRect: rect];

			NSPoint p = NSMakePoint(c * _fontWidth, r * _fontHeight);
			[self drawString: s atPoint: p withAttributes: [gConfig cFontAttributeForColorIndex: fgIndex2 hilite: hilite2]
					 unichar: ch color: [gConfig colorAtIndex: fgIndex2 hilite: hilite2]];
			
			NSImage *limg = [[NSImage alloc] initWithSize: NSMakeSize(_fontWidth, _fontHeight)];
			[limg setFlipped: YES];
			[limg lockFocus];
			[[gConfig colorAtIndex: bgIndex1 hilite: NO] set];
			[NSBezierPath fillRect: NSMakeRect(0, 0, _fontWidth, _fontHeight)];
	
			[self drawString: s atPoint: NSMakePoint(0, 0) withAttributes: [gConfig cFontAttributeForColorIndex: fgIndex1 hilite: hilite1]
					 unichar: ch color: [gConfig colorAtIndex: fgIndex1 hilite: hilite1]];

			[limg unlockFocus];
			
			[limg compositeToPoint: NSMakePoint(c * _fontWidth, (r+1) * _fontHeight) operation: NSCompositeSourceOver];
			[limg dealloc];
		}

	} else {
//		NSLog(@"%d %d %d", r, c, doubleByte);
	}
}

- (void) drawString: (NSString *) str atPoint: (NSPoint) origin withAttributes: (NSDictionary *) attribute unichar: (unichar) ch color: (NSColor *) color {
	if (ch <= 0x0020) {
		return;
	} else if (ch == 0x25FC) { // ◼ BLACK SQUARE
		
	} else if (ch >= 0x2581 && ch <= 0x2588) { // BLOCK ▁▂▃▄▅▆▇█
		NSRect r = NSMakeRect(origin.x, origin.y + _fontHeight * (0x2588 - ch) / 8, 2 * _fontWidth, _fontHeight * (ch - 0x2580) / 8);
		[color set];
		[NSBezierPath fillRect: r];
	} else if (ch >= 0x2589 && ch <= 0x258F) { // BLOCK ▉▊▋▌▍▎▏
		NSRect r = NSMakeRect(origin.x, origin.y, 2 * _fontWidth * (0x2590 - ch) / 8, _fontHeight);
		[color set];
		[NSBezierPath fillRect: r];		
	} else if (ch >= 0x25E2 && ch <= 0x25E5) { // TRIANGLE ◢◣◤◥
		NSPoint pts[4] = {	NSMakePoint(origin.x + 2 * _fontWidth, origin.y), 
							NSMakePoint(origin.x + 2 * _fontWidth, origin.y + _fontHeight), 
							NSMakePoint(origin.x, origin.y + _fontHeight), 
							NSMakePoint(origin.x, origin.y) };
		int base = ch - 0x25E2;
		NSBezierPath *bp = [[NSBezierPath alloc] init];
		[bp moveToPoint: pts[base]];
		int i;
		for (i = 1; i < 3; i++)	
			[bp lineToPoint: pts[(base + i) % 4]];
		[bp closePath];
		[color set];
		[bp fill];
		[bp release];
	} else if (ch == 0x0) {
	} else if (ch == 0x0) {
	} else if (ch == 0x0) {
		
	} else if (ch > 0x0080) {
		origin.y -= 2;
		[str drawAtPoint: origin withAttributes: attribute];
	} else
		[str drawAtPoint: origin withAttributes: attribute];
}

- (BOOL) isFlipped {
	return YES;
}

- (id)dataSource {
    return [[_dataSource retain] autorelease];
}

- (void)setDataSource:(id)value {
    if (_dataSource != value) {
        [_dataSource release];
        _dataSource = [value retain];
    }
}

@end
