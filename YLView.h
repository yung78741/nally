//
//  YLView.h
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/6/9.
//  Copyright 2006 yllan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CommonType.h"

@class YLTerminal;
@class YLTelnet;

@interface YLView : NSView {
	NSColor *_bgColor;
	NSColor *_fgColor;
	
	int _fontWidth;
	int _fontHeight;
	
	NSImage *_backedImage;
	
	YLTerminal *_dataSource;
	YLTelnet *_telnet;
}

- (void) updateRow: (int) r from: (int) start to: (int) end ;
//- (void) drawCellAtRow: (int) r column: (int) c;
- (void) drawString: (NSString *) str atPoint: (NSPoint) origin withAttribute: (attribute) attr unichar: (unichar) ch ;
- (id)dataSource;
- (void)setDataSource:(id)value;
- (YLTelnet *)telnet;
- (void)setTelnet:(YLTelnet *)value;


@end
