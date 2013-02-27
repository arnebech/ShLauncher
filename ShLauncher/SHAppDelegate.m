//
//  SHAppDelegate.m
//  ShLauncher
//
//  Created by Arne Bech on 2/25/13.
//  Copyright (c) 2013 Arne Bech. All rights reserved.
//

#import "SHAppDelegate.h"

@implementation SHAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{

    _log = [NSMutableString stringWithCapacity:5000];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserverForName:NSFileHandleDataAvailableNotification object:nil queue:nil
        usingBlock:^(NSNotification *note) {
                        
            NSString* newStr = [[NSString alloc] initWithData:[[note object] availableData] encoding:NSUTF8StringEncoding];
            
            if ([newStr length] > 0) {
                [[note object] waitForDataInBackgroundAndNotify];
                [_log appendString:newStr];
                [_logField setString:_log];
            }
    }];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *defaults = @{
        @"cwd": @"/Users/bech/Projects/arnebech/SenchaDesigner/web/build-scripts",
        @"script": @"launch.sh",
        @"extraPath": @"/Users/bech/Projects/ionjsNew/chrion/"
    };
    
    [userDefaults registerDefaults:defaults];
    
}

- (IBAction)onLaunch:(id)sender {
    
    if (_myTask != nil) {
        [self onKill:self];
    }
    
    //construct PATH variable
    NSString* pathVar = [[[NSUserDefaults standardUserDefaults] stringForKey:@"extraPath"] stringByAppendingString:@":/usr/bin:/bin:/usr/sbin:/sbin"];
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/sh"];
    [task setCurrentDirectoryPath:[[NSUserDefaults standardUserDefaults] stringForKey:@"cwd"]];
    [task setArguments:@[[[NSUserDefaults standardUserDefaults] stringForKey:@"script"]]];
    [task setEnvironment:@{@"PATH": pathVar}];
    
    NSPipe *stdPipe = [NSPipe pipe];
    NSPipe *errPipe = [NSPipe pipe];
    [task setStandardOutput:stdPipe];
    [task setStandardError:errPipe];
    
    [[stdPipe fileHandleForReading] waitForDataInBackgroundAndNotify];
    [[errPipe fileHandleForReading] waitForDataInBackgroundAndNotify];

    [task launch];
    
    _myTask = task;

}

- (IBAction)onKill:(id)sender {
    
    [_myTask terminate];
    
    _myTask = nil;
}

- (IBAction)selectScript:(id)sender {
    NSOpenPanel* selectDialog = [NSOpenPanel openPanel];
    [selectDialog setCanChooseFiles:YES];
    [selectDialog setPrompt:@"Select Script"];
    [selectDialog setAllowsMultipleSelection:NO];
    
    if ( [selectDialog runModal] == NSFileHandlingPanelOKButton ) {

        NSArray* urls = [selectDialog URLs];
        NSURL *url = [urls objectAtIndex:0];
        NSString *file = [url lastPathComponent];
        NSString *dir = [[url path] stringByDeletingLastPathComponent];
        
        [[NSUserDefaults standardUserDefaults] setObject:file forKey:@"script"];
        [[NSUserDefaults standardUserDefaults] setObject:dir forKey:@"cwd"];
                
    }
}

- (IBAction)selectPathDir:(id)sender {
    NSOpenPanel* selectDialog = [NSOpenPanel openPanel];
    [selectDialog setCanChooseFiles:NO];
    [selectDialog setCanChooseDirectories:YES];
    [selectDialog setPrompt:@"Select Dir"];
    [selectDialog setAllowsMultipleSelection:NO];
    
    if ( [selectDialog runModal] == NSFileHandlingPanelOKButton ) {
        
        NSArray* urls = [selectDialog URLs];
        NSURL *url = [urls objectAtIndex:0];
        
        [[NSUserDefaults standardUserDefaults] setObject:[url path] forKey:@"extraPath"];
        
    }
}
@end
