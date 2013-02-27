//
//  SHAppDelegate.h
//  ShLauncher
//
//  Created by Arne Bech on 2/25/13.
//  Copyright (c) 2013 Arne Bech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SHAppDelegate : NSObject <NSApplicationDelegate>

@property (unsafe_unretained) IBOutlet NSTextView *logField;


@property (assign) IBOutlet NSWindow *window;
@property NSTask * myTask;
@property NSMutableString *log;
- (IBAction)onLaunch:(id)sender;
- (IBAction)onKill:(id)sender;
- (IBAction)selectScript:(id)sender;
- (IBAction)selectPathDir:(id)sender;


@end
