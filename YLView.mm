//
//  YLView.m
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/6/9.
//  Copyright 2006 yllan. All rights reserved.
//

#import "YLView.h"
#import "YLTerminal.h"
#import "encoding.h"
#import "YLTelnet.h"
#import "YLLGLobalConfig.h"

static YLLGlobalConfig *gConfig;
static int gRow;
static int gColumn;
static NSImage *gLeftImage;

@implementation YLView

- (id)initWithFrame:(NSRect)frame {
	if (!gConfig) gConfig = [YLLGlobalConfig sharedInstance];
	gColumn = [gConfig column];
	gRow = [gConfig row];
	
	frame.size = NSMakeSize(gColumn * [gConfig cellWidth], gRow * [gConfig cellHeight]);
    self = [super initWithFrame: frame];
    if (self) {
		_fontWidth = [gConfig cellWidth];
		_fontHeight = [gConfig cellHeight];
		
		
		_backedImage = [[NSImage alloc] initWithSize: frame.size];
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

#pragma mark -
#pragma mark Event Handling
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

#pragma mark -
#pragma mark Drawing

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
	[_backedImage compositeToPoint: NSMakePoint(rect.origin.x, rect.origin.y + rect.size.height)
						  fromRect: imgRect
						 operation: NSCompositeCopy];
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

- (void) clearScreen: (int) opt atRow: (int) r column: (int) c {
	
}

- (void) extendBottom {
	[_backedImage lockFocus];
	[_backedImage compositeToPoint: NSMakePoint(0, (gRow - 1) * _fontHeight) 
						  fromRect: NSMakeRect(0, 0, gColumn * _fontWidth, (gRow - 1) * _fontHeight) 
						 operation: NSCompositeCopy];

	[gConfig->_colorTable[0][NUM_COLOR - 1] set];
	[NSBezierPath fillRect: NSMakeRect(0, (gRow - 1) * _fontHeight, gColumn * _fontWidth, _fontHeight)];
	[_backedImage unlockFocus];
	
	[self setNeedsDisplay: YES];
}

- (void) extendTop {
	[_backedImage lockFocus];
	[_backedImage compositeToPoint: NSMakePoint(0, gRow * _fontHeight) 
						  fromRect: NSMakeRect(0, _fontHeight, gColumn * _fontWidth, (gRow - 1) * _fontHeight) 
						 operation: NSCompositeCopy];
	
	[gConfig->_colorTable[0][NUM_COLOR - 1] set];
	[NSBezierPath fillRect: NSMakeRect(0, (gRow - 1) * _fontHeight, gColumn * _fontWidth, _fontHeight)];
	[_backedImage unlockFocus];
	
	[self setNeedsDisplay: YES];
}

- (void) update {
	int x, y;
	[_backedImage lockFocus];
	CGContextRef myCGContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
	
	/* Draw Background */
	for (y = 0; y < gRow; y++) {
		for (x = 0; x < gColumn; x++) {
			if ([_dataSource isDirtyAtRow: y column: x]) {
				int startx = x;
				for (; x < gColumn && [_dataSource isDirtyAtRow:y column:x]; x++) ;
				[self updateBackgroundForRow: y from: startx to: x];
			}
		}
	}

	CGContextSaveGState(myCGContext);
	CGAffineTransform ctm = CGContextGetCTM(myCGContext);
	ctm = CGAffineTransformInvert(ctm);
	CGContextConcatCTM(myCGContext, ctm); // cancel the flip
	CGContextSetShouldSmoothFonts(myCGContext, NO);

	/* Draw String row by row */
	for (y = 0; y < gRow; y++) {
		[_dataSource updateDoubleByteStateForRow: y];
		[self drawStringForRow: y context: myCGContext];
	}		
	CGContextRestoreGState(myCGContext);
	
//	[[NSColor whiteColor] set];
//	for (y = 0; y < gRow; y++) 
//		[NSBezierPath strokeLineFromPoint: NSMakePoint(0, y * _fontHeight + 0.5) toPoint: NSMakePoint(gColumn * _fontWidth, y * _fontHeight + 0.5)];
//	for (x = 0; x < gColumn; x++) 
//		[NSBezierPath strokeLineFromPoint: NSMakePoint(x * _fontWidth + 0.5, 0) toPoint: NSMakePoint(x * _fontWidth + 0.5, gRow * _fontHeight)];
		
	
	for (y = 0; y < gRow; y++) {
		for (x = 0; x < gColumn; x++) {
			[_dataSource setDirty: NO atRow: y column: x];
		}
	}

	[_backedImage unlockFocus];
}

- (void) drawStringForRow: (int) r context: (CGContextRef) myCGContext {
	int i, c, x;
	int start, end;
	unichar textBuf[gColumn];
	BOOL isDoubleByte[gColumn];
	ATSUAttributeTag tags[2];
	ByteCount sizes[2];
	ATSUAttributeValuePtr values[2];
	cell *currRow = [_dataSource cellsOfRow: r];

	for (i = 0; i < gColumn; i++) 
		isDoubleByte[i] = textBuf[i] = 0x0020;

	for (x = 0; x < gColumn && ![_dataSource isDirtyAtRow: r column: x]; x++) ;
	start = x;
	if (start == gColumn) return;
	
	for (x = start; x < gColumn; x++) {
		if (![_dataSource isDirtyAtRow: r column: x]) continue;
		end = x;
		int db = (currRow + x)->attr.f.doubleByte;
		
		if (db == 0) {
			textBuf[x] = 0x0000 + (currRow + x)->byte;
			isDoubleByte[x] = NO;
		} else if (db == 1) {
			isDoubleByte[x] = YES;
			continue;
		} else if (db == 2) {
			isDoubleByte[x] = YES;
			textBuf[x] = B2U[(((currRow + x - 1)->byte) << 8) + ((currRow + x)->byte) - 0x8000];
			if (x == start) start--;
		}
	}

	ATSUTextLayout layout;
	ATSUCreateTextLayout(&layout);
	tags[0] = kATSUCGContextTag;
	sizes[0] = sizeof (CGContextRef);
	values[0] = &myCGContext;
	ATSUSetLayoutControls (layout, 1, tags, sizes, values);

	ATSUSetTextPointerLocation(layout, textBuf, start, end - start + 1, gColumn);
	
	/* Run-length of the style */
	c = start;
	while (c <= end) {
		int location = c;
		int length = 0;
		BOOL db = isDoubleByte[c];
		
		attribute currAttr, lastAttr = (currRow + location)->attr;
		for (; c <= end; c++) {
			currAttr = (currRow + c)->attr;
			if (currAttr.v != lastAttr.v || isDoubleByte[c] != db) break;
		}
		length = c - location;
		
		ATSUStyle style = gConfig->_eATSUStyle[lastAttr.f.bold][lastAttr.f.reverse ? lastAttr.f.bgColor : lastAttr.f.fgColor];
		if (db)
			style = gConfig->_cATSUStyle[lastAttr.f.bold][lastAttr.f.reverse ? lastAttr.f.bgColor : lastAttr.f.fgColor];

		ATSUSetRunStyle(layout, style, location, length);
	}
	
	ATSUDrawText(layout, start, end - start + 1, X2Fix(_fontWidth * start), X2Fix((gRow - r - 1) * _fontHeight + 5));	
		
	ATSUDisposeTextLayout(layout);
}

- (void) updateBackgroundForRow: (int) r from: (int) start to: (int) end {
	int c;
	cell *currRow = [_dataSource cellsOfRow: r];
	NSRect rowRect = NSMakeRect(start * _fontWidth, r * _fontHeight, (end - start) * _fontWidth, _fontHeight);

	attribute currAttr, lastAttr = (currRow + start)->attr;
	int length = 0;
	unsigned int currentBackgroundColor;
	unsigned int lastBackgroundColor = lastAttr.f.reverse ? lastAttr.f.fgColor : lastAttr.f.bgColor;
	
	/* TODO: optimize the number of fillRect method. */
	/* 
		for example: 
		
		  BBBBBBBBBBBWWWWWWWWWWBBBBBBBBBBB
		
		currently, we draw each color segment one by one, like this:
		
		1. BBBBBBBBBBB
		2. BBBBBBBBBBBWWWWWWWWWW
		3. BBBBBBBBBBBWWWWWWWWWWBBBBBBBBBBB
		
		but we can use only two fillRect:
	 
		1. BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
		2. BBBBBBBBBBBWWWWWWWWWWBBBBBBBBBBB
	 
		If further optimization of background drawing is needed, consider the 2D reduction.
	 */
	for (c = start; c <= end; c++) {
		if (c < end) {
			currAttr = (currRow + c)->attr;
			currentBackgroundColor = currAttr.f.reverse ? currAttr.f.fgColor : currAttr.f.bgColor;
		}
		
		if (currentBackgroundColor != lastBackgroundColor || c == end) {
			/* Draw Background */
			NSRect rect = NSMakeRect((c - length) * _fontWidth, r * _fontHeight,
								  _fontWidth * length, _fontHeight);
			[[gConfig colorAtIndex: lastBackgroundColor hilite: NO] set];
			[NSBezierPath fillRect: rect];
			
			/* finish this segment */
			length = 1;
			lastAttr.v = currAttr.v;
			lastBackgroundColor = currentBackgroundColor;
		} else {
			length++;
		}
	}
	
	[self setNeedsDisplayInRect: rowRect];
}

- (void) drawChar: (unichar) ch atPoint: (NSPoint) origin withAttribute: (attribute) attr  {
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
//#define DRAWFONTBOUNDARYONLY
		
#ifdef DRAWFONTBOUNDARYONLY
		NSRect r = NSMakeRect(origin.x + 0.5, origin.y + 2.5, _fontWidth * 2 - 1, _fontHeight - 1);
		[[NSColor whiteColor] set];
		[NSBezierPath strokeRect: r];
#else
		NSString *str = [NSString stringWithCharacters: &ch length: 1];
		[str drawAtPoint: origin withAttributes: [gConfig cFontAttributeForColorIndex: colorIndex hilite: attr.f.bold]];
#endif
	} else {
#ifdef DRAWFONTBOUNDARYONLY		
		NSRect r = NSMakeRect(origin.x + 0.5, origin.y + 0.5, _fontWidth - 1, _fontHeight - 1);
		[[NSColor yellowColor] set];
		[NSBezierPath strokeRect: r];
#else
		NSString *str = [NSString stringWithCharacters: &ch length: 1];
		[str drawAtPoint: origin withAttributes: [gConfig eFontAttributeForColorIndex: colorIndex hilite: attr.f.bold]];
#endif
	}
}


#pragma mark -
#pragma mark Override

- (BOOL) isFlipped {
	return YES;
}

- (BOOL) isOpaque {
	return YES;
}

- (BOOL) acceptsFirstResponder {
	return YES;
}

#pragma mark -
#pragma mark Accessor

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

@end
