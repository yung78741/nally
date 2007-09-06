//
//  YLView.h
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/6/9.
//  Copyright 2006 yllan. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface YLView : NSView {
	NSColor *bgColor;
	NSColor *fgColor;
	
	int fontWidth;
	int fontHeight;
	
	id _dataSource;
}

@end
