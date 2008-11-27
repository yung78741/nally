//
//  YLSSH.h
//  MacBlueTelnet
//
//  Created by Wentao Han on 11/25/08.
//  Copyright 2008 net9.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "YLConnection.h"

@interface YLSSH : YLConnection {
    pid_t _pid;
    int _fileDescriptor;
}

@end
