//
//  YLMarkedTextView.m
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 9/29/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import "YLMarkedTextView.h"


@implementation YLMarkedTextView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[self setDefaultFont: [NSFont fontWithName: @"Lucida Grande" size: 20]];
        _layoutManager = [[NSLayoutManager alloc] init];
        _textContainer = [[NSTextContainer alloc] initWithContainerSize: NSMakeSize(999999, 999999)];
        [_layoutManager addTextContainer: _textContainer];
    }
    return self;
}

- (void) dealloc {
    [_layoutManager release];
    [_textContainer release];
    [_string release];
    [_defaultFont release];
    [super dealloc];
}

- (void)drawRect:(NSRect)rect {
	CGContextRef context = (CGContextRef) [[NSGraphicsContext currentContext] graphicsPort];
	CGContextSaveGState(context);
	
	float half = ([self frame].size.height / 2.0);
	BOOL fromTop = _destination.y > half;
	
	CGContextTranslateCTM(context, 1.0,  1.0);
	if (!fromTop) 
		CGContextTranslateCTM(context, 0.0,  5.0);

	CGPoint dest = (*(CGPoint *)&(_destination));
	dest.x -= 1.0;
	dest.y -= 1.0;
	if (!fromTop)
		dest.y -= 5.0;
	
	CGContextSaveGState(context);
	float ovalSize = 6.0;
	CGContextTranslateCTM(context, 1.0,  1.0);

    float fw = ([self bounds].size.width - 3);
    float fh = ([self bounds].size.height - 3 - 5);

	CGContextBeginPath(context);
    CGContextMoveToPoint(context, 0, fh - ovalSize); 
    CGContextAddArcToPoint(context, 0, fh, ovalSize, fh, ovalSize);
	if (fromTop) {
		float left, right;
		left = dest.x - 2.5;
		right = left + 5.0;
		if (left < ovalSize) {
			left = ovalSize;
			right = left + 5.0;
		} else if (right > fw - ovalSize) {
			right = fw - ovalSize;
			left = right - 5.0;
		}
		CGContextAddLineToPoint(context, left, fh);
		CGContextAddLineToPoint(context, dest.x, dest.y);
		CGContextAddLineToPoint(context, right, fh);
	}
//    CGContextMoveToPoint(context, fw - ovalSize, fh); 
    CGContextAddArcToPoint(context, fw, fh, fw, fh - ovalSize, ovalSize);

//	CGContextMoveToPoint(context, fw, ovalSize); 
	CGContextAddArcToPoint(context, fw, 0, fw - ovalSize, 0, ovalSize);
	if (!fromTop) {
		float left, right;
		left = dest.x - 2.5;
		right = left + 5.0;
		if (left < ovalSize) {
			left = ovalSize;
			right = left + 5.0;
		} else if (right > fw - ovalSize) {
			right = fw - ovalSize;
			left = right - 5.0;
		}
		CGContextAddLineToPoint(context, right, 0);
		CGContextAddLineToPoint(context, dest.x, dest.y);
		CGContextAddLineToPoint(context, left, 0);		
	}
//	CGContextMoveToPoint(context, ovalSize, 0); 
    CGContextAddArcToPoint(context, 0, 0, 0, ovalSize, ovalSize); 
    CGContextClosePath(context);	

	CGContextSetRGBFillColor(context, 0.15, 0.15, 0.15, 1.0);
	CGContextSetLineWidth(context, 2.0);
	CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);

	CGContextDrawPath(context, kCGPathFillStroke);

	CGContextRestoreGState(context);

	CGContextTranslateCTM(context, 4.0,  3.0);
    
    
	[_string drawAtPoint: NSZeroPoint];
	

    float offset;
    
    if (_selectedRange.location == 0) {
        offset = 0;
    } else {
        NSTextStorage *textStorage = [[[NSTextStorage alloc] initWithString: [_string string]] autorelease];
        
        [textStorage addLayoutManager: _layoutManager];
        [textStorage addAttributes:[_string attributesAtIndex: 0 effectiveRange: NULL] range: NSMakeRange(0, [_string length])];
        [_layoutManager glyphRangeForTextContainer: _textContainer];
        
        NSRect r = [_layoutManager boundingRectForGlyphRange: NSMakeRange(0, _selectedRange.location) inTextContainer: _textContainer];
        offset = r.size.width;
    }

	[[NSColor whiteColor] set];
	[NSBezierPath strokeLineFromPoint: NSMakePoint(offset, 0) toPoint: NSMakePoint(offset, _lineHeight)];
	CGContextRestoreGState(context);
}



- (NSAttributedString *)string {
    return [[_string retain] autorelease];
}

- (void)setString:(NSAttributedString *)value {
	NSMutableAttributedString *as = [[NSMutableAttributedString alloc] initWithAttributedString: value];
	[as addAttribute: NSFontAttributeName 
			   value: _defaultFont
			   range: NSMakeRange(0, [value length])];
	[as addAttribute: NSForegroundColorAttributeName 
			   value: [NSColor whiteColor]
			   range: NSMakeRange(0, [value length])];
	[_string release];
	_string = as;
	[self setNeedsDisplay: YES];

    NSTextStorage *textStorage = [[[NSTextStorage alloc] initWithString: [_string string]] autorelease];    
    [textStorage addLayoutManager: _layoutManager];
    [textStorage addAttributes:[_string attributesAtIndex: 0 effectiveRange: NULL] range: NSMakeRange(0, [_string length])];
    [_layoutManager glyphRangeForTextContainer: _textContainer];
    
    NSRect r = [_layoutManager boundingRectForGlyphRange: NSMakeRange(0, [_string length]) inTextContainer: _textContainer];
    
    double w = r.size.width;
	NSSize size = [self frame].size;
	size.width = w + 12;
	size.height = _lineHeight + 8 + 5;
	[self setFrameSize: size];
//	CFRelease(line);
}

- (NSRange)markedRange {
    return _markedRange;
}

- (void)setMarkedRange:(NSRange)value {
	_markedRange = value;
	[self setNeedsDisplay: YES];
}

- (NSRange)selectedRange {
    return _selectedRange;
}

- (void)setSelectedRange:(NSRange)value {
	_selectedRange = value;
	[self setNeedsDisplay: YES];
}

- (NSFont *)defaultFont {
    return [[_defaultFont retain] autorelease];
}

- (void)setDefaultFont:(NSFont *)value {
    if (_defaultFont != value) {
        [_defaultFont release];
        _defaultFont = [value copy];
		_lineHeight = [[[NSLayoutManager new] autorelease] defaultLineHeightForFont: _defaultFont];
    }
	[self setNeedsDisplay: YES];
}

- (NSPoint)destination {
    return _destination;
}

- (void)setDestination:(NSPoint)value {
        _destination = value;
}


- (BOOL) isOpaque {
	return NO;
}

@end
