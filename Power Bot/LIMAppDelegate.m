//
//  LIMAppDelegate.m
//  Power Bot
//
//  Created by limbero on 13/10/13.
//  Copyright (c) 2013 Limbero. All rights reserved.
//

#import "LIMAppDelegate.h"

#include <IOKit/IOKitLib.h>
#include <IOKit/ps/IOPSKeys.h>
#include <IOKit/ps/IOPowerSources.h>

@implementation LIMAppDelegate
NSStatusItem *statusItem;
NSMenu *theMenu;
NSString *rawBatteryString;
NSMutableAttributedString *percentageString;
NSInteger _stringLength;
NSTimer *updateTimer;
NSString *tooltip;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
    statusItem = [statusBar statusItemWithLength:NSVariableStatusItemLength];
    
    rawBatteryString = @"?%";
    percentageString=[[NSMutableAttributedString alloc] initWithString:rawBatteryString];
    _stringLength=[percentageString length];
    [percentageString addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:12.0f] range:NSMakeRange(0, _stringLength)];
    
    theMenu = [[NSMenu alloc] initWithTitle:@""];
    [theMenu setAutoenablesItems:NO];
    /*NSMenuItem *preferencesItem = nil;
    preferencesItem = [theMenu addItemWithTitle:@"Preferences..." action:nil keyEquivalent:@""];
    [theMenu addItem:[NSMenuItem separatorItem]];*/
    NSMenuItem *quitItem = nil;
    quitItem = [theMenu addItemWithTitle:@"Quit Power Bot" action:@selector(terminate:) keyEquivalent:@"q"];
    [quitItem setKeyEquivalentModifierMask:NSCommandKeyMask];
    
    /*NSString *tooltip;
    if(IOPSCopyExternalPowerAdapterDetails() != NULL)
    {
        tooltip = @"Power Bot 0.1\nAC Power";
    }
    else
    {
        tooltip = @"Power Bot 0.1\nBattery";
    }*/
    tooltip = @"Power Bot 0.1";
    
    [statusItem setAttributedTitle:percentageString];
    [statusItem setImage:[NSImage imageNamed:@"powerbot_charged.png"]];
    [statusItem setAlternateImage:[NSImage imageNamed:@"powerbot_charged_reverse.png"]];
    [statusItem setToolTip:tooltip];
    [statusItem setHighlightMode:YES];
    [statusItem setMenu:theMenu];
    
    [self updater];
    
    updateTimer = [NSTimer timerWithTimeInterval:2 target:self selector:@selector(updater) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:updateTimer forMode:NSRunLoopCommonModes];
}

- (void)updater
{
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: @"/usr/bin/pmset"];
    
    NSArray *arguments;
    arguments = [NSArray arrayWithObjects: @"-g", @"batt", nil];
    [task setArguments: arguments];
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    
    [task launch];
    
    NSData *data;
    data = [file readDataToEndOfFile];
    
    NSString *string;
    string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    NSLog (@"pmset -g batt\n%@", string);
    
    rawBatteryString = [NSString stringWithFormat:@"%@", [string substringWithRange:[string rangeOfString:@"[0-9]+\%" options:NSRegularExpressionSearch]]];
    
    NSLog(@"%@", rawBatteryString);
    if ([string rangeOfString:@"'Battery Power'"].location == NSNotFound) {
        if([[rawBatteryString substringToIndex:[rawBatteryString length]-1] intValue] >= 80)
        {
            [statusItem setImage:[NSImage imageNamed:@"powerbot_charged.png"]];
            [statusItem setAlternateImage:[NSImage imageNamed:@"powerbot_charged_reverse.png"]];
            NSLog(@"stop charging");
            tooltip = @"Stop charging\nPower Bot 0.1";
        } else {
            [statusItem setImage:[NSImage imageNamed:@"powerbot_charging.png"]];
            [statusItem setAlternateImage:[NSImage imageNamed:@"powerbot_charging_reverse.png"]];
            NSLog(@"keep charging");
            tooltip = @"Keep charging\nPower Bot 0.1";
        }
    } else {
        if([[rawBatteryString substringToIndex:[rawBatteryString length]-1] intValue] <= 20)
        {
            [statusItem setImage:[NSImage imageNamed:@"powerbot_discharged.png"]];
            [statusItem setAlternateImage:[NSImage imageNamed:@"powerbot_discharged_reverse.png"]];
            NSLog(@"start charging");
            tooltip = @"Start charging\nPower Bot 0.1";
        } else {
            [statusItem setImage:[NSImage imageNamed:@"powerbot_charged.png"]];
            [statusItem setAlternateImage:[NSImage imageNamed:@"powerbot_charged_reverse.png"]];
            NSLog(@"keep discharging");
            tooltip = @"Keep discharging\nPower Bot 0.1";
        }
    }
    
    [statusItem setToolTip:tooltip];
    
    percentageString=[[NSMutableAttributedString alloc] initWithString:rawBatteryString];
    _stringLength=[percentageString length];
    [percentageString addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:12.0f] range:NSMakeRange(0, _stringLength)];
    [statusItem setAttributedTitle:percentageString];
}

@end
