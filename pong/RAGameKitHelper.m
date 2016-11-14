
#import "RAGameKitHelper.h"

NSString *const PresentAuthenticationViewController =
        @"present_authentication_view_controller";

@implementation RAGameKitHelper {
    BOOL _enableGameCenter;
}

+(instancetype)sharedGameKitHelper {
    static RAGameKitHelper *sharedGameKitHelper;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedGameKitHelper = [[RAGameKitHelper alloc] init];
    });
    return sharedGameKitHelper;
}

-(id)init {
    self = [super init];
    if (self) {
        _enableGameCenter = YES;
    }
    return self;
}

-(void)authenticateLocalPlayer {
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    
    localPlayer.authenticateHandler = ^(UIViewController *view, NSError *error) {
        [self setLastError:error];
        
        if (view != nil) {
            [self setAuthenticationViewController:view];
        } else if ([GKLocalPlayer localPlayer].isAuthenticated) {
            _enableGameCenter = YES;
        } else {
            _enableGameCenter = NO;
        }
    };
}

-(void)setAuthenticationViewController:(UIViewController *)authenticationViewController {
    if (authenticationViewController != nil) {
        _authenticationViewController = authenticationViewController;
        [[NSNotificationCenter defaultCenter]
         postNotificationName:PresentAuthenticationViewController
                       object:self];
    }
}

-(void)setLastError:(NSError *)lastError {
    _lastError = [lastError copy];
    if (_lastError) {
        NSLog(@"RAGameKitHelper ERROR:   %@",
              [[_lastError userInfo] description]);
    }
}

-(void)reportScore:(int64_t)score forLeaderboardID:(NSString *)leaderboardID {
    if (!_enableGameCenter) {
        NSLog(@"Local player is not authenticated! :[");
    }
    
    GKScore *scoreReporter = [[GKScore alloc]
                              initWithLeaderboardIdentifier:leaderboardID];
    scoreReporter.value = score;
    scoreReporter.context = 0;
    
    NSArray *scores = @[scoreReporter];
    
    [GKScore reportScores:scores withCompletionHandler:^(NSError *error) {
        [self setLastError:error];
    }];
}

-(void)showGKGameCenterViewController: (UIViewController *)viewController {
    if (!_enableGameCenter) {
        NSLog(@"Local play is not authenticated");
        return;
    }
    GKGameCenterViewController *gameCenterViewController = [[GKGameCenterViewController alloc] init];
    gameCenterViewController.gameCenterDelegate = self;
    
    gameCenterViewController.viewState = GKGameCenterViewControllerStateLeaderboards;
    [viewController presentViewController:gameCenterViewController animated:YES
                               completion:nil];
}

-(void)gameCenterViewControllerDidFinish: (GKGameCenterViewController *)gameCenterViewController {
    [gameCenterViewController dismissViewControllerAnimated:YES
                                                 completion:nil];
}

@end
