//
//  YLController.h
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 9/11/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "YLView.h"
#import <PSMTabBarControl/PSMTabBarControl.h>
#import "YLSite.h"

@class YLTerminal;

@interface YLController : NSObject {
    IBOutlet NSPanel *_sitesWindow;
    IBOutlet NSPanel *_emoticonsWindow;
    IBOutlet NSWindow *_mainWindow;
    IBOutlet id _telnetView;
    IBOutlet id _addressBar;
    IBOutlet PSMTabBarControl *_tab;
    IBOutlet NSMenuItem *_closeWindowMenuItem;
    IBOutlet NSMenuItem *_closeTabMenuItem;
    NSMutableArray *_sites;
    NSMutableArray *_emoticons;
    IBOutlet NSArrayController *_sitesController;
    IBOutlet NSArrayController *_emoticonsController;
    IBOutlet NSMenuItem *_sitesMenu;
    IBOutlet NSTableView *_sitesTableView;
    IBOutlet NSMenuItem *_showHiddenTextMenuItem;
    IBOutlet NSMenuItem *_antiIdleMenuItem;
    IBOutlet NSMenuItem *_detectDoubleByteMenuItem;
    IBOutlet NSMenuItem *_encodingMenuItem;

    IBOutlet id _sitesButton;
    IBOutlet id _reconnectButton;
    IBOutlet id _addButton;
    IBOutlet id _addressButton;
    IBOutlet id _emoticonsButton;
    IBOutlet id _antiIdleButton;
    IBOutlet id _showHiddenTextButton;
    IBOutlet id _detectDoubleByteButton;
}

- (void) updateSitesMenu ;
- (void) loadSites ;
- (void) loadEmoticons ;
- (void) loadLastConnections;

- (IBAction) setEncoding: (id) sender ;

- (IBAction) newTab: (id) sender ;
- (IBAction) connect: (id) sender;
- (IBAction) openLocation: (id) sender;
- (IBAction) selectNextTab: (id) sender;
- (IBAction) selectPrevTab: (id) sender;
- (void) selectTabNumber: (int) index ;
- (IBAction) closeTab: (id) sender;
- (IBAction) reconnect: (id) sender;
- (IBAction) openSites: (id) sender;
- (IBAction) editSites: (id) sender;
- (IBAction) closeSites: (id) sender;
- (IBAction) addSites: (id) sender;
- (IBAction) openPreferencesWindow: (id) sender ;
- (void) newConnectionToAddress: (NSString *) addr name: (NSString *) name encoding: (YLEncoding) encoding;
- (void) newConnectionWithDictionary: (NSDictionary *) d ;
- (void) newConnectionWithSite: (YLSite *) s ;

- (IBAction) showHiddenTextAction: (id) sender;
- (IBAction) detectDoubleByteAction: (id) sender;
- (IBAction) antiIdleAction: (id) sender;

- (IBAction) closeEmoticons: (id) sender;
- (IBAction) inputEmoticons: (id) sender;
- (IBAction) openEmoticonsWindow: (id) sender;

- (NSArray *)sites;
- (unsigned)countOfSites;
- (id)objectInSitesAtIndex:(unsigned)theIndex;
- (void)getSites:(id *)objsPtr range:(NSRange)range;
- (void)insertObject:(id)obj inSitesAtIndex:(unsigned)theIndex;
- (void)removeObjectFromSitesAtIndex:(unsigned)theIndex;
- (void)replaceObjectInSitesAtIndex:(unsigned)theIndex withObject:(id)obj;

- (void) refreshTabLabelNumber: (NSTabView *) tabView ;

- (NSArray *)emoticons;
- (unsigned)countOfEmoticons;
- (id)objectInEmoticonsAtIndex:(unsigned)theIndex;
- (void)getEmoticons:(id *)objsPtr range:(NSRange)range;
- (void)insertObject:(id)obj inEmoticonsAtIndex:(unsigned)theIndex;
- (void)removeObjectFromEmoticonsAtIndex:(unsigned)theIndex;
- (void)replaceObjectInEmoticonsAtIndex:(unsigned)theIndex withObject:(id)obj;

@end
