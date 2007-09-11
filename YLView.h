//
//  YLView.h
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/6/9.
//  Copyright 2006 yllan. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface YLView : NSView {
	NSColor *_bgColor;
	NSColor *_fgColor;
	
	int _fontWidth;
	int _fontHeight;
	
	id _dataSource;
}

- (void) drawCellAtRow: (int) r column: (int) c;

@end
