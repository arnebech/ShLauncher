//
//  SHAppDelegate.m
//  ShLauncher
//
//  Created by Arne Bech on 2/25/13.
//  Copyright (c) 2013 Arne Bech. All rights reserved.
//

#import "SHAppDelegate.h"
#include <errno.h>

@implementation SHAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{

    _log = [NSMutableString stringWithCapacity:5000];
    
    //subscribe to notification center, so we know when we get new updates through our pipes
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserverForName:NSFileHandleDataAvailableNotification object:nil queue:nil
        usingBlock:^(NSNotification *note) {
                        
            NSString* newStr = [[NSString alloc] initWithData:[[note object] availableData] encoding:NSUTF8StringEncoding];
            
            if ([newStr length] > 0) {
                
                //continue listening
                [[note object] waitForDataInBackgroundAndNotify];
                
                //update log string and log field
                [_log appendString:newStr];
                [_logField setString:_log];
            }
    }];
    
    //set up basic user defaults, only works for me out of the box
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
        //kill the current task if running
        [self onKill:self];
    }
    

    //update environemnt
    NSMutableDictionary *env = [[NSMutableDictionary alloc] init];
    [env addEntriesFromDictionary:[[NSProcessInfo processInfo]environment]];
    
    NSString *extraPath = [[NSUserDefaults standardUserDefaults] stringForKey:@"extraPath"];
    NSString *updatedPath = [NSString stringWithFormat:@"%@:%@", extraPath, [env objectForKey:@"PATH"]];
    
    [env setObject:updatedPath forKey:@"PATH"];
    
    //create task
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/sh"];
    [task setCurrentDirectoryPath:[[NSUserDefaults standardUserDefaults] stringForKey:@"cwd"]];
    [task setArguments:@[[[NSUserDefaults standardUserDefaults] stringForKey:@"script"]]];
    [task setEnvironment:env];
    
    //set up pipes for the task
    NSPipe *stdPipe = [NSPipe pipe];
    NSPipe *errPipe = [NSPipe pipe];
    [task setStandardOutput:stdPipe];
    [task setStandardError:errPipe];
    
    //set up async handling
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
        NSString *file = [url lastPathComponent]; //gets filename
        NSString *dir = [[url path] stringByDeletingLastPathComponent]; //gets the parent dir of the file
        
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
