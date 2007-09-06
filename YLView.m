//
//  YLView.m
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/6/9.
//  Copyright 2006 yllan. All rights reserved.
//

#import "YLView.h"
#import "YLSimpleDataSource.h"

@implementation YLView

- (id)initWithFrame:(NSRect)frame {
	id ds = [YLSimpleDataSource new];
	frame.size = NSMakeSize([ds column] * 12, [ds row] * 24);
    self = [super initWithFrame: frame];
    if (self) {
		bgColor = [[NSColor colorWithCalibratedRed: 0.0 green: 0.0470588 blue: 0.2431372 alpha: 1.0] retain];
//		bgColor = [[NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 0.0 alpha: 1.0] retain];
		fgColor = [[NSColor colorWithCalibratedRed: 0.75 green: 0.75 blue: 0.75 alpha: 1.0] retain];
//		fgColor = [[NSColor colorWithCalibratedRed: 1.0 green: 1.0 blue: 1.0 alpha: 1.0] retain];
		_dataSource = ds;
		fontWidth = 12;
		fontHeight = 24;
    }
    return self;
}

- (NSRect) cellRectForRect: (NSRect) r {
	int originx = r.origin.x / fontWidth;
	int originy = r.origin.y / fontHeight;
	int width = ((r.size.width + r.origin.x) / fontWidth) - originx + 1;
	int height = ((r.size.height + r.origin.y) / fontHeight) - originy + 1;
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
	
	if (!doubleByte) {
		rect = NSMakeRect(c * fontWidth, r * fontHeight, fontWidth, fontHeight);
		NSColor *b = [_dataSource bgColorAtRow: r column: c];
		if (!b) b = bgColor;
		[b set];
		[NSBezierPath fillRect: rect];
		
		NSString *s = [NSString stringWithCharacters: &ch length: 1];
		NSColor *f = [_dataSource fgColorAtRow: r column: c];
		if (!f) f = fgColor;
		[f set];
		[s drawAtPoint: NSMakePoint(c * fontWidth, (r + 1) * fontHeight - 1) withAttributes: [NSDictionary dictionary]];
	} else if (doubleByte == 1) {
		NSColor *b1 = [_dataSource bgColorAtRow: r column: c];
		if (!b1) b1 = bgColor;
		NSColor *b2 = [_dataSource bgColorAtRow: r column: c + 1];
		if (!b2) b2 = bgColor;
		
		NSString *s = [NSString stringWithCharacters: &ch length: 1];
		NSColor *f1 = [_dataSource fgColorAtRow: r column: c];
		if (!f1) f1 = fgColor;
		NSColor *f2 = [_dataSource fgColorAtRow: r column: c + 1];
		if (!f2) f2 = fgColor;

		if ([f1 isEqualTo: f2]) {
			rect = NSMakeRect(c * fontWidth, r * fontHeight, fontWidth, fontHeight);
			[b1 set];
			[NSBezierPath fillRect: rect];
			rect = NSMakeRect((c+1) * fontWidth, r * fontHeight, fontWidth, fontHeight);		
			[b2 set];
			[NSBezierPath fillRect: rect];

			NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys: 
				f1, NSForegroundColorAttributeName,
				[NSFont fontWithName: @"LiSong Pro" size: 20], NSFontAttributeName, nil];

			NSPoint p = NSMakePoint(c * fontWidth, r * fontHeight);
			[s drawAtPoint: p withAttributes: d];
		} else {
			NSDictionary *d;
			NSImage *limg = [[NSImage alloc] initWithSize: NSMakeSize(fontWidth, fontHeight)];
			NSImage *rimg = [[NSImage alloc] initWithSize: NSMakeSize(fontWidth, fontHeight)];
			[limg lockFocus];
			[b1 set];
			[NSBezierPath fillRect: NSMakeRect(0, 0, fontWidth, fontHeight)];
			d = [NSDictionary dictionaryWithObjectsAndKeys: 
				f1, NSForegroundColorAttributeName,
				[NSFont fontWithName: @"LiSong Pro" size: 20], NSFontAttributeName, nil];
			
			[s drawAtPoint: NSMakePoint(0, 0) withAttributes: d];
			[limg unlockFocus];
			
			[rimg lockFocus];
			[b2 set];
			[NSBezierPath fillRect: NSMakeRect(0, 0, fontWidth, fontHeight)];
			d = [NSDictionary dictionaryWithObjectsAndKeys: 
				f2, NSForegroundColorAttributeName,
				[NSFont fontWithName: @"LiSong Pro" size: 20], NSFontAttributeName, nil];
			[s drawAtPoint: NSMakePoint(-fontWidth, 0) withAttributes: d];
			[rimg unlockFocus];
			
			[limg compositeToPoint: NSMakePoint(c * fontWidth, (r+1) * fontHeight) operation: NSCompositeSourceOver];
			[rimg compositeToPoint: NSMakePoint((c+1) * fontWidth, (r+1) * fontHeight) operation: NSCompositeSourceOver];
			[limg dealloc];
			[rimg dealloc];
		}

	} else {
//		NSLog(@"%d %d %d", r, c, doubleByte);
	}
}

- (BOOL) isFlipped {
	return YES;
}

@end
