//
//  RAGameKitHelper.h
//  pong
//
//  Created by Ryan Ackermann on 9/15/14.
//  Copyright (c) 2014 Ryan Ackermann. All rights reserved.
//

#import <Foundation/Foundation.h>

@import GameKit;

extern NSString *const PresentAuthenticationViewController;

@interface RAGameKitHelper : NSObject <GKGameCenterControllerDelegate>

@property (nonatomic, readonly) UIViewController *authenticationViewController;
@property (nonatomic, readonly) NSError *lastError;

+(instancetype)sharedGameKitHelper;

-(void)authenticateLocalPlayer;
-(void)reportScore:(int64_t)score forLeaderboardID:(NSString *)leaderboardID;
-(void)showGKGameCenterViewController: (UIViewController *)viewController;

@end
