//
//  YLView.m
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/6/9.
//  Copyright 2006 yllan. All rights reserved.
//

#import "YLView.h"
#import "YLTerminal.h"
#import "YLTelnet.h"
#import "YLLGLobalConfig.h"

@implementation YLView

static id gConfig;
static int gRow;
static int gColumn;
static NSImage *gLeftImage;

- (id)initWithFrame:(NSRect)frame {
	if (!gConfig) gConfig = [YLLGlobalConfig sharedInstance];
	gColumn = [gConfig column];
	gRow = [gConfig row];
	
	frame.size = NSMakeSize(gColumn * [gConfig cellWidth], gRow * [gConfig cellHeight]);
    self = [super initWithFrame: frame];
    if (self) {
		_bgColor = [[NSColor colorWithCalibratedRed: 0.0 green: 0.0470588 blue: 0.2431372 alpha: 1.0] retain];
		_fgColor = [[NSColor colorWithCalibratedRed: 0.75 green: 0.75 blue: 0.75 alpha: 1.0] retain];

		_fontWidth = [gConfig cellWidth];
		_fontHeight = [gConfig cellHeight];
		
		
		_backedImage = [[NSImage alloc] initWithSize: frame.size];
//		_backedImage = [[NSImage alloc] initWithContentsOfFile: @"~/Desktop/Picture 1.png"];
		[_backedImage setFlipped: YES];
		[_backedImage lockFocus];
		[[gConfig colorAtIndex: 9 hilite: NO] set];
		[NSBezierPath fillRect: NSMakeRect(0, 0, frame.size.width, frame.size.height)];
		[_backedImage unlockFocus];

		if (!gLeftImage) {
			gLeftImage = [[NSImage alloc] initWithSize: NSMakeSize(_fontWidth, _fontHeight)];
			[gLeftImage setFlipped: YES];			
		}
    }
    return self;
}

- (void) dealloc {
	[_backedImage release];
	[super dealloc];
}

- (void) mouseDown: (NSEvent *) e {
	NSLog(@"%X %d %d", [_dataSource charAtRow: 1 column: 78], [_dataSource isDoubleByteAtRow: 1 column: 78], [_dataSource isDoubleByteAtRow: 1 column: 79]);
}

- (void) keyDown: (NSEvent *) e {
	unichar c = [[e charactersIgnoringModifiers] characterAtIndex: 0];
	unsigned char arrow[3] = {0x1B, 0x4F, 0x00};
	
	if (c == NSUpArrowFunctionKey) arrow[2] = 'A';
	if (c == NSDownArrowFunctionKey) arrow[2] = 'B';
	if (c == NSRightArrowFunctionKey) arrow[2] = 'C';
	if (c == NSLeftArrowFunctionKey) arrow[2] = 'D';
	if (c == NSUpArrowFunctionKey || c == NSDownArrowFunctionKey || c == NSRightArrowFunctionKey || c == NSLeftArrowFunctionKey) {
		[_telnet sendBytes: arrow length: 3];
		return;
	}
	
	unsigned char ch = (unsigned char) c;
	[_telnet sendBytes: &ch length: 1];		
}

- (NSRect) cellRectForRect: (NSRect) r {
	int originx = r.origin.x / _fontWidth;
	int originy = r.origin.y / _fontHeight;
	int width = ((r.size.width + r.origin.x) / _fontWidth) - originx + 1;
	int height = ((r.size.height + r.origin.y) / _fontHeight) - originy + 1;
	return NSMakeRect(originx, originy, width, height);
}

- (void)drawRect:(NSRect)rect {
	NSRect imgRect = rect;
	imgRect.origin.y = (_fontHeight * gRow) - rect.origin.y - rect.size.height;
//	NSLog(@"%f %f %f %f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
//	NSLog(@"%f %f", imgRect.origin.y, rect.origin.y);
	[_backedImage compositeToPoint: NSMakePoint(rect.origin.x, rect.origin.y + rect.size.height)
						  fromRect: imgRect
						 operation: NSCompositeCopy];
//	[[NSColor redColor] set];
//	[NSBezierPath strokeRect: rect];
/*
	int x, y;
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

- (void) update {
	int x, y;
	[_backedImage lockFocus];
	for (y = 0; y < gRow; y++) {
		for (x = 0; x < gColumn; x++) {
			if ([_dataSource isDirtyAtRow: y column: x]) {
				int startx = x;
				for (; x < gColumn && [_dataSource isDirtyAtRow:y column:x]; x++) ;
				[self updateRow: y from: startx to: x];
				for(x--; x >= startx; x--) 
					[_dataSource setDirty: NO atRow: y column: x];
			}
		}
	}
	[_backedImage unlockFocus];
}

- (void) updateRow: (int) r from: (int) start to: (int) end {
	int c;
	NSRect rowRect = NSMakeRect(start * _fontWidth, r * _fontHeight, (end - start) * _fontWidth, _fontHeight);
//	[[NSColor colorWithCalibratedRed: (float)rand() / RAND_MAX green: (float)rand() / RAND_MAX blue: (float)rand() / RAND_MAX alpha: 1.0] set];
//	[NSBezierPath fillRect: rowRect];
//	NSLog(@"%d (%d ~ %d)", r, start, end);

	attribute currAttr, lastAttr = [_dataSource attrAtRow: r column: start];
	int length = 0;

	for (c = start; c <= end; c++) {
		if (c < end)
			currAttr = [_dataSource attrAtRow: r column: c];
		if (currAttr.v != lastAttr.v || c == end) {
			/* Draw Background */
			NSRect rect = NSMakeRect((c - length) * _fontWidth, r * _fontHeight,
								  _fontWidth * length, _fontHeight);
			if (lastAttr.f.reverse)
				[[gConfig colorAtIndex: lastAttr.f.fgColor hilite: NO] set];
			else
				[[gConfig colorAtIndex: lastAttr.f.bgColor hilite: NO] set];
			[NSBezierPath fillRect: rect];
			
			/* Draw Foreground */
			int x;
			for (x = c - length; x < c; x++) {
				int db = [_dataSource isDoubleByteAtRow: r column: x];
				
				int colorIndex = lastAttr.f.reverse?lastAttr.f.bgColor:lastAttr.f.fgColor;
				
				/* Draw Underline */
				if (lastAttr.f.underline) {
					[[gConfig colorAtIndex: colorIndex hilite: lastAttr.f.bold] set];
					[NSBezierPath strokeLineFromPoint: NSMakePoint(x * _fontWidth, (r+1) * _fontHeight - 0.5) 
											  toPoint: NSMakePoint((x+1) * _fontWidth, (r+1) * _fontHeight - 0.5) ];
				}
				
				/* Draw Character */
				if (db == 1) continue;
				
				unichar ch;
				
				if (db == 0) { // English
					ch = [_dataSource charAtRow: r column: x];
					NSString *s = [NSString stringWithCharacters: &ch length: 1];
					[self drawString: s atPoint: NSMakePoint(x * _fontWidth, r * _fontHeight) 
					  withAttribute: lastAttr
							 unichar: ch];
				} else if (db == 2) { // Chinese
					if (x == start) {
						rowRect.origin.x -= _fontWidth;
						rowRect.size.width += _fontWidth;							
					}
					
					ch = [_dataSource charAtRow: r column: x - 1];
					NSString *s = [NSString stringWithCharacters: &ch length: 1];
					[self drawString: s atPoint: NSMakePoint((x-1) * _fontWidth, r * _fontHeight) 
					   withAttribute: lastAttr
							 unichar: ch];
					
					if (x == c - length) { // double color
						attribute prevAttr = [_dataSource attrAtRow: r column: x - 1];
						
						[gLeftImage lockFocus];
						int bgColorIndex = prevAttr.f.reverse ? prevAttr.f.fgColor : prevAttr.f.bgColor;
						[[gConfig colorAtIndex: bgColorIndex hilite: NO] set];
						[NSBezierPath fillRect: NSMakeRect(0, 0, _fontWidth, _fontHeight)];
						[self drawString: s atPoint: NSMakePoint(0, 0)
						   withAttribute: prevAttr unichar: ch];
						[gLeftImage unlockFocus];
						[gLeftImage compositeToPoint: NSMakePoint((x-1) * _fontWidth, (r+1) * _fontHeight) operation: NSCompositeCopy];
					}
				}
			}
			
			/* finish this segment */
			length = 1;
			lastAttr.v = currAttr.v;
		} else {
			length++;
		}
	}
	
	[self setNeedsDisplayInRect: rowRect];
}

//- (void) updateCellAtRow: (int) r column: (int) c {
//	NSRect rect;
//	int doubleByte = [_dataSource isDoubleByteAtRow: r column: c];
//	unichar ch = [_dataSource charAtRow: r column:c ];
//
//	if (!doubleByte) {
//		rect = NSMakeRect(c * _fontWidth, r * _fontHeight, _fontWidth, _fontHeight);
//		NSColor *b = [_dataSource bgColorAtRow: r column: c];
//		[b set];
//		[NSBezierPath fillRect: rect];
//		
//		NSString *s = [NSString stringWithCharacters: &ch length: 1];
//		int fgIndex = [_dataSource fgColorIndexAtRow: r column: c];
//		BOOL hilite = [_dataSource boldAtRow: r column: c];
//
//
//		[self drawString: s atPoint: NSMakePoint(c * _fontWidth, r * _fontHeight)
//		  withAttributes: [gConfig eFontAttributeForColorIndex: fgIndex hilite: hilite]
//				 unichar: ch color: [gConfig colorAtIndex: fgIndex hilite: hilite]];
//	} else if (doubleByte == 1) {
//		int bgIndex1 = [_dataSource bgColorIndexAtRow: r column: c];
//		int bgIndex2 = [_dataSource bgColorIndexAtRow: r column: c + 1];
//		
//		NSString *s = [NSString stringWithCharacters: &ch length: 1];
//		int fgIndex1 = [_dataSource fgColorIndexAtRow: r column: c];
//		int fgIndex2 = [_dataSource fgColorIndexAtRow: r column: c + 1];
//		BOOL hilite1 = [_dataSource boldAtRow: r column: c];
//		BOOL hilite2 = [_dataSource boldAtRow: r column: c + 1];
//
//		if (fgIndex1 == fgIndex2 && hilite1 == hilite2) {
//			rect = NSMakeRect(c * _fontWidth, r * _fontHeight, _fontWidth, _fontHeight);
//			[[gConfig colorAtIndex: bgIndex1 hilite: NO] set];
//			[NSBezierPath fillRect: rect];
//			rect = NSMakeRect((c+1) * _fontWidth, r * _fontHeight, _fontWidth, _fontHeight);
//			[[gConfig colorAtIndex: bgIndex1 hilite: NO] set];
//			[NSBezierPath fillRect: rect];
//
//			NSPoint p = NSMakePoint(c * _fontWidth, r * _fontHeight);
//			[self drawString: s atPoint: p withAttributes: [gConfig cFontAttributeForColorIndex: fgIndex2 hilite: hilite2]
//					 unichar: ch color: [gConfig colorAtIndex: fgIndex2 hilite: hilite2]];
//		} else {
//			rect = NSMakeRect((c+1) * _fontWidth, r * _fontHeight, _fontWidth, _fontHeight);
//			[[gConfig colorAtIndex: bgIndex2 hilite: NO] set];
//			[NSBezierPath fillRect: rect];
//
//			NSPoint p = NSMakePoint(c * _fontWidth, r * _fontHeight);
//			[self drawString: s atPoint: p withAttributes: [gConfig cFontAttributeForColorIndex: fgIndex2 hilite: hilite2]
//					 unichar: ch color: [gConfig colorAtIndex: fgIndex2 hilite: hilite2]];
//			
//			NSImage *limg = [[NSImage alloc] initWithSize: NSMakeSize(_fontWidth, _fontHeight)];
//			[limg setFlipped: YES];
//			[limg lockFocus];
//			[[gConfig colorAtIndex: bgIndex1 hilite: NO] set];
//			[NSBezierPath fillRect: NSMakeRect(0, 0, _fontWidth, _fontHeight)];
//	
//			[self drawString: s atPoint: NSMakePoint(0, 0) withAttributes: [gConfig cFontAttributeForColorIndex: fgIndex1 hilite: hilite1]
//					 unichar: ch color: [gConfig colorAtIndex: fgIndex1 hilite: hilite1]];
//
//			[limg unlockFocus];
//			
//			[limg compositeToPoint: NSMakePoint(c * _fontWidth, (r+1) * _fontHeight) operation: NSCompositeSourceOver];
//			[limg dealloc];
//		}
//
//	} else {
////		NSLog(@"%d %d %d", r, c, doubleByte);
//	}
//}

- (void) drawString: (NSString *) str atPoint: (NSPoint) origin withAttribute: (attribute) attr unichar: (unichar) ch {
	int colorIndex = attr.f.reverse ? attr.f.bgColor : attr.f.fgColor;
	NSColor *color = [gConfig colorAtIndex: colorIndex hilite: attr.f.bold];
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
		[str drawAtPoint: origin withAttributes: [gConfig cFontAttributeForColorIndex: colorIndex hilite: attr.f.bold]];
	} else
		[str drawAtPoint: origin withAttributes: [gConfig eFontAttributeForColorIndex: colorIndex hilite: attr.f.bold]];
}

- (BOOL) isFlipped {
	return YES;
}

- (BOOL) isOpaque {
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

- (YLTelnet *)telnet {
    return [[_telnet retain] autorelease];
}

- (void)setTelnet:(YLTelnet *)value {
    if (_telnet != value) {
        [_telnet release];
        _telnet = [value retain];
    }
}

- (BOOL) acceptsFirstResponder {
	return YES;
}

@end
