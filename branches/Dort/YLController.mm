//
//  YLController.m
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 9/11/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import "YLController.h"
#import "YLTelnet.h"
#import "YLTerminal.h"
#import "YLLGlobalConfig.h"
#import "DBPrefsWindowController.h"
#import "YLEmoticon.h"

static NSString *gMyToolbarIdentifier = @"YLLAN TOOLBAR IDENTIFIER";
static NSString *gSitesToolbarItemIdentifier = @"SITES TOOLBARITEM IDENTIFIER";
static NSString *gReconnectToolbarItemIdentifier = @"RECONNECT TOOLBARITEM IDENTIFIER";
static NSString *gAddToolbarItemIdentifier = @"ADD TOOLBARITEM IDENTIFIER";
static NSString *gAddressToolbarItemIdentifier = @"ADDRESS TOOLBARITEM IDENTIFIER";
static NSString *gEmoticonsToolbarItemIdentifier = @"EMOTICONS TOOLBARITEM IDENTIFIER";
static NSString *gAntiIdleToolbarItemIdentifier = @"ANTIIDLE TOOLBARITEM IDENTIFIER";
static NSString *gShowHiddenTextToolbarItemIdentifier = @"SHOWHIDDENTEXT TOOLBARITEM IDENTIFIER";
static NSString *gDetectDoubleByteToolbarItemIdentifier = @"DETECTDOUBLEBYTE TOOLBARITEM IDENTIFIER";

@implementation YLController

- (void) awakeFromNib {
    [[YLLGlobalConfig sharedInstance] addObserver: self
                                       forKeyPath: @"showHiddenText"
                                          options: (NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) 
                                          context: NULL];
    
    [[YLLGlobalConfig sharedInstance] addObserver: self
                                       forKeyPath: @"antiIdle"
                                          options: (NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) 
                                          context: NULL];
    [[YLLGlobalConfig sharedInstance] addObserver: self
                                       forKeyPath: @"detectDoubleByte"
                                          options: (NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) 
                                          context: NULL];
    
    [[YLLGlobalConfig sharedInstance] setAntiIdle: [[NSUserDefaults standardUserDefaults] boolForKey: @"AntiIdle"]];
    [[YLLGlobalConfig sharedInstance] setShowHiddenText: [[NSUserDefaults standardUserDefaults] boolForKey: @"ShowHiddenText"]];
    [[YLLGlobalConfig sharedInstance] setDetectDoubleByte: [[NSUserDefaults standardUserDefaults] boolForKey: @"DetectDoubleByte"]];
    
//    [_tab setStyleNamed: @"Adium"];
    [_tab setCanCloseOnlyTab: YES];
//	[_tab setNeedsDisplay: YES];
        
    [self loadSites];
    [self updateSitesMenu];
    [self loadEmoticons];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey: @"RestoreConnection"]) 
        [self loadLastConnections];
    
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier: gMyToolbarIdentifier] autorelease];
    
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
    [toolbar setShowsBaselineSeparator: NO];
    [toolbar setDelegate: self];
    [_mainWindow setToolbar: toolbar];
    
    [NSTimer scheduledTimerWithTimeInterval: 120 target: self selector: @selector(antiIdle:) userInfo: nil repeats: YES];
    [NSTimer scheduledTimerWithTimeInterval: 1 target: self selector: @selector(updateBlinkTicker:) userInfo: nil repeats: YES];
            
}

- (void) updateSitesMenu {
    int total = [[_sitesMenu submenu] numberOfItems] ;
    int i;
    for (i = 3; i < total; i++) {
        [[_sitesMenu submenu] removeItemAtIndex: 3];
    }
    
    for (i = 0; i < [_sites count]; i++) {
        YLSite *s = [_sites objectAtIndex: i];
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle: [s name] action: @selector(openSiteMenu:) keyEquivalent: @""];
        [menuItem setRepresentedObject: s];
        [[_sitesMenu submenu] addItem: menuItem];
        [menuItem release];        
    }
}

- (void) updateEncodingMenu {
    // Update encoding menu status
    NSMenu *m = [_encodingMenuItem submenu];
    int i;
    for (i = 0; i < [m numberOfItems]; i++) {
        NSMenuItem *item = [m itemAtIndex: i];
        [item setState: NSOffState];
        if ([_telnetView dataSource] && i == [[_telnetView dataSource] encoding])
            [item setState: NSOnState];
    }
    
}

- (void) updateBlinkTicker: (NSTimer *) t {
    [[YLLGlobalConfig sharedInstance] updateBlinkTicker];
    if ([_telnetView hasBlinkCell])
        [_telnetView setNeedsDisplay: YES];
}

- (void) antiIdle: (NSTimer *) t {
    if (![[NSUserDefaults standardUserDefaults] boolForKey: @"AntiIdle"]) return;
    NSArray *a = [_telnetView tabViewItems];
    int i;
    for (i = 0; i < [a count]; i++) {
        NSTabViewItem *item = [a objectAtIndex: i];
        id telnet = [item identifier];
        if ([telnet connected] && [telnet lastTouchDate] && [[NSDate date] timeIntervalSinceDate: [telnet lastTouchDate]] >= 119) {
//            unsigned char msg[] = {0x1B, 'O', 'A', 0x1B, 'O', 'B'};
            unsigned char msg[] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
            [telnet sendBytes:msg length:6];
        }
    }
}

- (void) newConnectionWithSite: (YLSite *) s {
    [self newConnectionWithDictionary: [s dictionaryOfSite]];
}

- (void) newConnectionWithDictionary: (NSDictionary *) d {
    [self newConnectionToAddress: [d valueForKey: @"address"] 
                            name: [d valueForKey: @"name"]
                        encoding: (YLEncoding) [[d valueForKey: @"encoding"] unsignedIntValue]];
}

- (void) newConnectionToAddress: (NSString *) addr name: (NSString *) name encoding: (YLEncoding) encoding {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
	id terminal = [YLTerminal new];
    id telnet;

    BOOL emptyTab = [_telnetView telnet] && ([[_telnetView telnet] terminal] == nil);

    if (emptyTab) 
        telnet = [_telnetView telnet];
    else 
        telnet = [[YLTelnet new] autorelease];

    [terminal setEncoding: encoding];
	[telnet setTerminal: terminal];
    [telnet setConnectionName: name];
    [telnet setConnectionAddress: addr];
	[terminal setDelegate: _telnetView];
    
    NSTabViewItem *tabItem;
    
    if (emptyTab) {
        tabItem = [_telnetView selectedTabViewItem];
    } else {
        tabItem = [[[NSTabViewItem alloc] initWithIdentifier: telnet] autorelease];
        [_telnetView addTabViewItem: tabItem];
    }
    
    [tabItem setLabel: name];
	
	[telnet connectToAddress: addr];
    [_telnetView selectTabViewItem: tabItem];
    [terminal release];
    [self refreshTabLabelNumber: _telnetView];
    [self updateEncodingMenu];
    [pool release];
}

#pragma mark -
#pragma mark Toolbar

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted {
    // Required delegate method:  Given an item identifier, this method returns an item 
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself 
    NSToolbarItem *toolbarItem = nil;
    
    if ([itemIdent isEqual: gSitesToolbarItemIdentifier]) {
        toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
        
        [toolbarItem setLabel: NSLocalizedString(@"Sites", @"")];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Sites", @"")];
        
        [toolbarItem setToolTip: NSLocalizedString(@"Sites", @"")];
        [toolbarItem setView: _sitesButton];
		[toolbarItem setMinSize: NSMakeSize(30, 23)];
		[toolbarItem setMaxSize: NSMakeSize(30, 23)];
        
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(editSites:)];
    } else if ([itemIdent isEqual: gReconnectToolbarItemIdentifier]) {
        toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
        
        [toolbarItem setLabel: NSLocalizedString(@"Reconnect", @"")];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Reconnect", @"")];
        
        [toolbarItem setToolTip: NSLocalizedString(@"Reconnect", @"")];
        [toolbarItem setView: _reconnectButton];
		[toolbarItem setMinSize: NSMakeSize(30, 23)];
		[toolbarItem setMaxSize: NSMakeSize(30, 23)];
        
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(reconnect:)];
    } else if ([itemIdent isEqual: gAddToolbarItemIdentifier]) {
        toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
        
        [toolbarItem setLabel: NSLocalizedString(@"Add This Site",@"")];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Add This Site", @"")];
        
        [toolbarItem setToolTip: NSLocalizedString(@"Add This Site", @"")];
        [toolbarItem setView: _addButton];
		[toolbarItem setMinSize: NSMakeSize(30, 23)];
		[toolbarItem setMaxSize: NSMakeSize(30, 23)];
        
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(addSites:)];
    } else if ([itemIdent isEqual: gAddressToolbarItemIdentifier]) {
        toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
        
        [toolbarItem setLabel: NSLocalizedString(@"Address", @"")];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Address", @"")];
        
        [toolbarItem setToolTip: NSLocalizedString(@"Address", @"")];
        [toolbarItem setView: _addressButton];
		[toolbarItem setMinSize: NSMakeSize(208, 23)];
		[toolbarItem setMaxSize: NSMakeSize(210, 23)];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(connect:)];
    } else if ([itemIdent isEqual: gEmoticonsToolbarItemIdentifier]) {
        toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
        
        [toolbarItem setLabel: NSLocalizedString(@"Emoticons", @"")];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Emoticons", @"")];

        [toolbarItem setToolTip: NSLocalizedString(@"Emoticons", @"")];
        [toolbarItem setView: _emoticonsButton];
		[toolbarItem setMinSize: NSMakeSize(30, 23)];
		[toolbarItem setMaxSize: NSMakeSize(30, 23)];

        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(openEmoticonsWindow:)];
    } else if ([itemIdent isEqual: gAntiIdleToolbarItemIdentifier]) {
        toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
        
        [toolbarItem setLabel: NSLocalizedString(@"Anti-Idle", @"")];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Anti-Idle", @"")];
        
        [toolbarItem setToolTip: NSLocalizedString(@"Anti-Idle", @"")];
        [toolbarItem setView: _antiIdleButton];
		[toolbarItem setMinSize: NSMakeSize(30, 23)];
		[toolbarItem setMaxSize: NSMakeSize(30, 23)];

    } else if ([itemIdent isEqual: gShowHiddenTextToolbarItemIdentifier]) {
        toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
        
        [toolbarItem setLabel: NSLocalizedString(@"Show Hidden Text", @"")];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Show Hidden Text", @"")];
        
        [toolbarItem setToolTip: NSLocalizedString(@"Show Hidden Text", @"")];
        [toolbarItem setView: _showHiddenTextButton];
		[toolbarItem setMinSize: NSMakeSize(30, 23)];
		[toolbarItem setMaxSize: NSMakeSize(30, 23)];

    } else if ([itemIdent isEqual: gDetectDoubleByteToolbarItemIdentifier]) {
        toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
        
        [toolbarItem setLabel: NSLocalizedString(@"Detect Double Bytes", @"")];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Detect Double Bytes", @"")];
        
        [toolbarItem setToolTip: NSLocalizedString(@"Detect Double Bytes", @"")];
        [toolbarItem setView: _detectDoubleByteButton];
		[toolbarItem setMinSize: NSMakeSize(30, 23)];
		[toolbarItem setMaxSize: NSMakeSize(30, 23)];

    }
    return toolbarItem;
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {

    return [NSArray arrayWithObjects:	gSitesToolbarItemIdentifier, gReconnectToolbarItemIdentifier, 
            gAddToolbarItemIdentifier, gAddressToolbarItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, 
            gEmoticonsToolbarItemIdentifier, gAntiIdleToolbarItemIdentifier, gShowHiddenTextToolbarItemIdentifier, gDetectDoubleByteToolbarItemIdentifier, nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    return [NSArray arrayWithObjects:	gSitesToolbarItemIdentifier, gReconnectToolbarItemIdentifier, 
            gAddToolbarItemIdentifier, gAddressToolbarItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, 
            gEmoticonsToolbarItemIdentifier, gAntiIdleToolbarItemIdentifier, gShowHiddenTextToolbarItemIdentifier, gDetectDoubleByteToolbarItemIdentifier, nil];
}

- (void) toolbarWillAddItem: (NSNotification *) notif {

}  

- (void) toolbarDidRemoveItem: (NSNotification *) notif {

}

- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem {
    return YES;
}

#pragma mark -
#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([[YLLGlobalConfig sharedInstance] showHiddenText]) 
        [_showHiddenTextMenuItem setState: NSOnState];
    else
        [_showHiddenTextMenuItem setState: NSOffState];

    if ([[YLLGlobalConfig sharedInstance] antiIdle]) 
        [_antiIdleMenuItem setState: NSOnState];
    else
        [_antiIdleMenuItem setState: NSOffState];
    
    if ([[YLLGlobalConfig sharedInstance] detectDoubleByte]) 
        [_detectDoubleByteMenuItem setState: NSOnState];
    else
        [_detectDoubleByteMenuItem setState: NSOffState];

}

#pragma mark -
#pragma mark User Defaults

- (void) loadSites {
    NSArray *array = [[NSUserDefaults standardUserDefaults] arrayForKey: @"Sites"];
    int i;
    for (i = 0; i < [array count]; i++) {
        NSDictionary *d = [array objectAtIndex: i];
        [self insertObject: [YLSite siteWithDictionary: d] inSitesAtIndex: [self countOfSites]];
    }
        
}

- (void) saveSites {
    NSMutableArray *a = [NSMutableArray array];
    int i;
    for (i = 0; i < [_sites count]; i++) {
        YLSite *s = [_sites objectAtIndex: i];
        [a addObject: [s dictionaryOfSite]];
    }
    [[NSUserDefaults standardUserDefaults] setObject: a forKey: @"Sites"];
    [self updateSitesMenu];
}

- (void) loadEmoticons {
    NSArray *a = [[NSUserDefaults standardUserDefaults] arrayForKey: @"Emoticons"];
    int i;
    for (i = 0; i < [a count]; i++) {
        NSDictionary *d = [a objectAtIndex: i];
        [self insertObject: [YLEmoticon emoticonWithDictionary: d] inEmoticonsAtIndex: [self countOfEmoticons]];
    }
}

- (void) saveEmoticons {
    NSMutableArray *a = [NSMutableArray array];
    int i;
    for (i = 0; i < [_emoticons count]; i++) {
        YLEmoticon *e = [_emoticons objectAtIndex: i];
        [a addObject: [e dictionaryOfEmoticon]];
    } 
    [[NSUserDefaults standardUserDefaults] setObject: a forKey: @"Emoticons"];    
}

- (void) loadLastConnections {
    NSArray *a = [[NSUserDefaults standardUserDefaults] arrayForKey: @"LastConnections"];
    int i;
    for (i = 0; i < [a count]; i++) {
        NSDictionary *d = [a objectAtIndex: i];
        [self newConnectionWithDictionary: d];
    }    
}

- (void) saveLastConnections {
    int tabNumber = [_telnetView numberOfTabViewItems];
    int i;
    NSMutableArray *a = [NSMutableArray array];
    for (i = 0; i < tabNumber; i++) {
        id connection = [[_telnetView tabViewItemAtIndex: i] identifier];
        if ([connection terminal]) // not empty tab
            [a addObject: [NSDictionary dictionaryWithObjectsAndKeys: [connection connectionName], @"name", 
                           [connection connectionAddress], @"address", 
                           [NSNumber numberWithUnsignedInt: [[connection terminal] encoding]], @"encoding", nil]];
    }
    [[NSUserDefaults standardUserDefaults] setObject: a forKey: @"LastConnections"];
}

#pragma mark -
#pragma mark Actions
- (IBAction) setEncoding: (id) sender {
    int index = [[_encodingMenuItem submenu] indexOfItem: sender];
    if ([_telnetView dataSource]) {
        [[_telnetView dataSource] setEncoding: (YLEncoding)index];
        [[_telnetView dataSource] setAllDirty];
        [_telnetView update];
        [_telnetView setNeedsDisplay: YES];
        [self updateEncodingMenu];
    }
}

- (IBAction) newTab: (id) sender {
    YLTelnet *telnet = [YLTelnet new];
    [telnet setConnectionAddress: @""];
    [telnet setConnectionName: @""];
    NSTabViewItem *tabItem = [[[NSTabViewItem alloc] initWithIdentifier: telnet] autorelease];
    [_telnetView addTabViewItem: tabItem];
    [_telnetView selectTabViewItem: tabItem];
    
    [_mainWindow makeKeyAndOrderFront: self];
	[_telnetView resignFirstResponder];
	[_addressBar becomeFirstResponder];
    [telnet release];
}

- (IBAction) connect: (id) sender {
	[sender abortEditing];
	[[_telnetView window] makeFirstResponder: _telnetView];

	[self newConnectionToAddress: [sender stringValue] 
                            name: [sender stringValue] 
                        encoding: (YLEncoding) [(NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey: @"DefaultEncoding"] unsignedShortValue]];
}

- (IBAction) openLocation: (id) sender {
    [_mainWindow makeKeyAndOrderFront: self];
	[_telnetView resignFirstResponder];
	[_addressBar becomeFirstResponder];
}

- (IBAction) reconnect: (id) sender {
    [[_telnetView telnet] reconnect];
}

- (IBAction) selectNextTab: (id) sender {
    if ([_telnetView indexOfTabViewItem: [_telnetView selectedTabViewItem]] == [_telnetView numberOfTabViewItems] - 1)
        [_telnetView selectFirstTabViewItem: self];
    else
        [_telnetView selectNextTabViewItem: self];
}

- (IBAction) selectPrevTab: (id) sender {
    if ([_telnetView indexOfTabViewItem: [_telnetView selectedTabViewItem]] == 0)
        [_telnetView selectLastTabViewItem: self];
    else
        [_telnetView selectPreviousTabViewItem: self];
}

- (IBAction) selectTabNumber: (int) index {
    if (index <= [_telnetView numberOfTabViewItems]) {
        [_telnetView selectTabViewItemAtIndex: index - 1];
    }
}

- (IBAction) closeTab: (id) sender {
    if ([_telnetView numberOfTabViewItems] == 0) return;
    
    NSTabViewItem *tabItem = [_telnetView selectedTabViewItem];
    
    [_telnetView removeTabViewItem: tabItem];
}

- (IBAction) editSites: (id) sender {
    [NSApp beginSheet: _sitesWindow
       modalForWindow: _mainWindow
        modalDelegate: nil
       didEndSelector: NULL
          contextInfo: nil];
}

- (IBAction) openSites: (id) sender {
    NSArray *a = [_sitesController selectedObjects];
    [self closeSites: sender];
    
    if ([a count] == 1) {
        YLSite *s = [a objectAtIndex: 0];
        [self newConnectionWithSite: s];
    }
}

- (IBAction) openSiteMenu: (id) sender {
    YLSite *s = [sender representedObject];
    [self newConnectionWithSite: s];
}

- (IBAction) closeSites: (id) sender {
    [_sitesWindow endEditingFor: nil];
    [NSApp endSheet: _sitesWindow];
    [_sitesWindow orderOut: self];
    [self saveSites];
}

- (IBAction) addSites: (id) sender {
    if ([_telnetView numberOfTabViewItems] == 0) return;
    NSString *address = [[_telnetView telnet] connectionAddress];
    int i;
    for (i = 0; i < [_sites count]; i++) {
        YLSite *s = [_sites objectAtIndex: i];
        if ([[s address] isEqualToString: address]) 
            return;        
    }
    
    YLSite *s = [[YLSite new] autorelease];
    [s setName: address];
    [s setAddress: address];
    [s setEncoding: [[_telnetView dataSource] encoding]];
    [_sitesController addObject: s];
    [_sitesController setSelectedObjects: [NSArray arrayWithObject: s]];
    [self performSelector: @selector(editSites:) withObject: sender afterDelay: 0.1];
    [_sitesTableView editColumn: 0 row: [_sitesTableView selectedRow] withEvent: nil select: YES];
}



- (IBAction) showHiddenTextAction: (id) sender {
    BOOL show = ([sender state] == NSOnState);
    if ([sender isKindOfClass: [NSMenuItem class]]) {
        show = !show;
    }

    [[YLLGlobalConfig sharedInstance] setShowHiddenText: show];
    [_telnetView refreshHiddenRegion];
    [_telnetView update];
    [_telnetView setNeedsDisplay: YES];
}

- (IBAction) detectDoubleByteAction: (id) sender {
    BOOL value = ([sender state] == NSOnState);
    if ([sender isKindOfClass: [NSMenuItem class]]) {
        value = !value;
    }
    
    [[YLLGlobalConfig sharedInstance] setDetectDoubleByte: value];
}

- (IBAction) antiIdleAction: (id) sender {
    BOOL value = ([sender state] == NSOnState);
    if ([sender isKindOfClass: [NSMenuItem class]]) {
        value = !value;
    }
    
    [[YLLGlobalConfig sharedInstance] setAntiIdle: value];
}
- (IBAction) openPreferencesWindow: (id) sender {
    [[DBPrefsWindowController sharedPrefsWindowController] showWindow:nil];
}

- (IBAction) openEmoticonsWindow: (id) sender {
    [_emoticonsWindow makeKeyAndOrderFront: self];
}

- (IBAction) closeEmoticons: (id) sender {
    [_emoticonsWindow endEditingFor: nil];
    [_emoticonsWindow makeFirstResponder: _emoticonsWindow];
    [_emoticonsWindow orderOut: self];
    [self saveEmoticons];
}

- (IBAction) inputEmoticons: (id) sender {
    [self closeEmoticons: sender];
    
    if ([[_telnetView telnet] connected]) {
        NSArray *a = [_emoticonsController selectedObjects];
        
        if ([a count] == 1) {
            YLEmoticon *e = [a objectAtIndex: 0];
            [_telnetView insertText: [e content]];
        }
    }
}

#pragma mark -
#pragma mark Accessor

- (NSArray *)sites {
    if (!_sites) {
        _sites = [[NSMutableArray alloc] init];
    }
    return [[_sites retain] autorelease];
}

- (unsigned)countOfSites {
    if (!_sites) {
        _sites = [[NSMutableArray alloc] init];
    }
    return [_sites count];
}

- (id)objectInSitesAtIndex:(unsigned)theIndex {
    if (!_sites) {
        _sites = [[NSMutableArray alloc] init];
    }
    return [_sites objectAtIndex:theIndex];
}

- (void)getSites:(id *)objsPtr range:(NSRange)range {
    if (!_sites) {
        _sites = [[NSMutableArray alloc] init];
    }
    [_sites getObjects:objsPtr range:range];
}

- (void)insertObject:(id)obj inSitesAtIndex:(unsigned)theIndex {
    if (!_sites) {
        _sites = [[NSMutableArray alloc] init];
    }
    [_sites insertObject:obj atIndex:theIndex];
}

- (void)removeObjectFromSitesAtIndex:(unsigned)theIndex {
    if (!_sites) {
        _sites = [[NSMutableArray alloc] init];
    }
    [_sites removeObjectAtIndex:theIndex];
}

- (void)replaceObjectInSitesAtIndex:(unsigned)theIndex withObject:(id)obj {
    if (!_sites) {
        _sites = [[NSMutableArray alloc] init];
    }
}

- (NSArray *)emoticons {
    if (!_emoticons) {
        _emoticons = [[NSMutableArray alloc] init];
    }
    return [[_emoticons retain] autorelease];
}

- (unsigned)countOfEmoticons {
    if (!_emoticons) {
        _emoticons = [[NSMutableArray alloc] init];
    }
    return [_emoticons count];
}

- (id)objectInEmoticonsAtIndex:(unsigned)theIndex {
    if (!_emoticons) {
        _emoticons = [[NSMutableArray alloc] init];
    }
    return [_emoticons objectAtIndex:theIndex];
}

- (void)getEmoticons:(id *)objsPtr range:(NSRange)range {
    if (!_emoticons) {
        _emoticons = [[NSMutableArray alloc] init];
    }
    [_emoticons getObjects:objsPtr range:range];
}

- (void)insertObject:(id)obj inEmoticonsAtIndex:(unsigned)theIndex {
    if (!_emoticons) {
        _emoticons = [[NSMutableArray alloc] init];
    }
    [_emoticons insertObject:obj atIndex:theIndex];
}

- (void)removeObjectFromEmoticonsAtIndex:(unsigned)theIndex {
    if (!_emoticons) {
        _emoticons = [[NSMutableArray alloc] init];
    }
    [_emoticons removeObjectAtIndex:theIndex];
}

- (void)replaceObjectInEmoticonsAtIndex:(unsigned)theIndex withObject:(id)obj {
    if (!_emoticons) {
        _emoticons = [[NSMutableArray alloc] init];
    }
    [_emoticons replaceObjectAtIndex:theIndex withObject:obj];
}



#pragma mark -
#pragma mark Application Delegation
- (BOOL) validateMenuItem: (NSMenuItem *) item {
    SEL action = [item action];
    if ((action == @selector(addSites:) ||
         action == @selector(reconnect:) ||
         action == @selector(selectNextTab:) ||
         action == @selector(selectPrevTab:) )
        && [_telnetView numberOfTabViewItems] == 0) {
        return NO;
    } else if (action == @selector(setEncoding:) && [_telnetView numberOfTabViewItems] == 0) {
        return NO;
    }
    return YES;
}

- (BOOL) applicationShouldHandleReopen: (id) s hasVisibleWindows: (BOOL) b {
    [_mainWindow makeKeyAndOrderFront: self];
    return NO;
} 

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    int tabNumber = [_telnetView numberOfTabViewItems];
    int i;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey: @"RestoreConnection"]) 
        [self saveLastConnections];
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey: @"ConfirmOnQuit"]) 
        return NSTerminateNow;
    
    BOOL hasConnectedConnetion = NO;
    for (i = 0; i < tabNumber; i++) {
        id connection = [[_telnetView tabViewItemAtIndex: i] identifier];
        if ([connection connected]) 
            hasConnectedConnetion = YES;
    }
    if (!hasConnectedConnetion) return NSTerminateNow;
    NSBeginAlertSheet(NSLocalizedString(@"Are you sure you want to quit Dort?", @"Sheet Title"), 
                      NSLocalizedString(@"Quit", @"Default Button"), 
                      NSLocalizedString(@"Cancel", @"Cancel Button"), 
                      nil, 
                      _mainWindow, self, 
                      @selector(confirmSheetDidEnd:returnCode:contextInfo:), 
                      @selector(confirmSheetDidDismiss:returnCode:contextInfo:), nil, 
                      [NSString stringWithFormat: NSLocalizedString(@"There are %d tabs open in Dort. Do you want to quit anyway?", @"Sheet Message"),
                                tabNumber]);
    return NSTerminateLater;
}

- (void) confirmSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo {
    [NSApp replyToApplicationShouldTerminate: (returnCode == NSAlertDefaultReturn)];
}

- (void) confirmSheetDidDismiss:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo {
    [NSApp replyToApplicationShouldTerminate: (returnCode == NSAlertDefaultReturn)];
}

#pragma mark -
#pragma mark Window Delegation

- (BOOL) windowShouldClose: (id) window {
    [_mainWindow orderOut: self];
    return NO;
}

- (BOOL) windowWillClose: (id) window {
//    [NSApp terminate: self];
//    NSLog(@"WILL");
    return NO;
}

- (void) windowDidBecomeKey: (NSNotification *) notification {
    [_closeWindowMenuItem setKeyEquivalentModifierMask: NSCommandKeyMask | NSShiftKeyMask];
    [_closeTabMenuItem setKeyEquivalent: @"w"];
}

- (void) windowDidResignKey: (NSNotification *) notification {
    [_closeWindowMenuItem setKeyEquivalentModifierMask: NSCommandKeyMask];
    [_closeTabMenuItem setKeyEquivalent: @""];
}

#pragma mark -
#pragma mark Tab Delegation

- (BOOL)tabView:(NSTabView *)tabView shouldCloseTabViewItem:(NSTabViewItem *)tabViewItem {
    return YES;
}

- (void)tabView:(NSTabView *)tabView willCloseTabViewItem:(NSTabViewItem *)tabViewItem {

}

- (void)tabView:(NSTabView *)tabView didCloseTabViewItem:(NSTabViewItem *)tabViewItem {

}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
    id identifier = [tabViewItem identifier];
    [_telnetView update];
    [_addressBar setStringValue: [identifier connectionAddress]];
    [_telnetView setNeedsDisplay: YES];
    [_mainWindow makeFirstResponder: _telnetView];
    if ([[tabViewItem identifier] connected]) {
        [[tabViewItem identifier] setIcon: [NSImage imageNamed: @"connect.pdf"]];
    }
    [self updateEncodingMenu];
}

- (BOOL)tabView:(NSTabView *)tabView shouldSelectTabViewItem:(NSTabViewItem *)tabViewItem {
    return YES;
}

- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem {
    id identifier = [tabViewItem identifier];
    [[identifier terminal] setAllDirty];
}

- (BOOL)tabView:(NSTabView*)aTabView shouldDragTabViewItem:(NSTabViewItem *)tabViewItem fromTabBar:(PSMTabBarControl *)tabBarControl {
	return NO;
}

- (BOOL)tabView:(NSTabView*)aTabView shouldDropTabViewItem:(NSTabViewItem *)tabViewItem inTabBar:(PSMTabBarControl *)tabBarControl {
	return YES;
}

- (void)tabView:(NSTabView*)aTabView didDropTabViewItem:(NSTabViewItem *)tabViewItem inTabBar:(PSMTabBarControl *)tabBarControl {
//    [self refreshTabLabelNumber: _telnetView];
}

- (NSImage *)tabView:(NSTabView *)aTabView imageForTabViewItem:(NSTabViewItem *)tabViewItem offset:(NSSize *)offset styleMask:(unsigned int *)styleMask {
    return nil;
}

- (void)tabViewDidChangeNumberOfTabViewItems:(NSTabView *)tabView {
    [self refreshTabLabelNumber: tabView];
}

- (void) refreshTabLabelNumber: (NSTabView *) tabView {
    int i, tabNumber;
    tabNumber = [tabView numberOfTabViewItems];
    for (i = 0; i < tabNumber; i++) {
        NSTabViewItem *item = [tabView tabViewItemAtIndex: i];
        [item setLabel: [NSString stringWithFormat: @"%d. %@", i + 1, [[item identifier] connectionName]]];
    }
    
}
@end
