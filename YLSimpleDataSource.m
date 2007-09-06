//
//  YLSimpleDataSource.m
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 9/1/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import "YLSimpleDataSource.h"

static char *templateString = "我達達的馬蹄是美麗的錯誤。我不是歸人，是個澳客。";

@implementation YLSimpleDataSource
- (int) row {
	return 24;
}
- (int) column {
	return 80;
}

- (NSColor *) fgColorAtRow: (int) r column: (int) c {
	if (r == 5) {
		if (c == 2 || c== 3) 
			return [NSColor greenColor];
	}
	
	if (r == 3) {
		if (c == 2 || c== 4 || c == 7 || c == 10) 
			return [NSColor yellowColor];
		if (c == 3)
			return [NSColor purpleColor];
	}
	return nil;
}

- (NSColor *) bgColorAtRow: (int) r column: (int) c {
	if (r == 6) {
		if (c >= 2 && c <= 10) 
			return [NSColor redColor];
	}
	return nil;
}

- (BOOL) isDirtyAtRow: (int) r column:(int) c {
	return YES;
}

- (unichar) charAtRow: (int) r column: (int) c {
	NSString *s = [NSString stringWithUTF8String: templateString];
	if (c/2 >= [s length]) return 0;
	
	if (c & 1) return 0;
	return [s characterAtIndex: (c / 2)];
}

- (int) isDoubleByteAtRow: (int) r column:(int) c {
	NSString *s = [NSString stringWithUTF8String: templateString];
	if (c/2 >= [s length]) return 0;
	if (c & 1) return 2;
	return 1;
}

@end
