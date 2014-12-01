//
//  RAViewController.m
//  pong
//
//  Created by Ryan Ackermann on 8/26/14.
//  Copyright (c) 2014 Ryan Ackermann. All rights reserved.
//

#import "RAViewController.h"
#import "RALaunchScreen.h"
#import "RAGameKitHelper.h"

@implementation RAViewController {
    SKView *_skView;
    RALaunchScreen *_scene;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showAuthenticationViewController)
                                                 name:PresentAuthenticationViewController
                                               object:nil];
    [[RAGameKitHelper sharedGameKitHelper] authenticateLocalPlayer];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    if (!_skView) {
        _skView =
        [[SKView alloc] initWithFrame:self.view.bounds];
        
        _scene = [RALaunchScreen sceneWithSize:_skView.bounds.size];
        _scene.scaleMode = SKSceneScaleModeAspectFill;
        
        [_skView presentScene:_scene];
        [self.view addSubview:_skView];
    }
}

-(void)showAuthenticationViewController {
    RAGameKitHelper *gameKitHelper =
            [RAGameKitHelper sharedGameKitHelper];
    
    [self.view.window.rootViewController presentViewController:gameKitHelper.authenticationViewController
                                                      animated:YES
                                                    completion:nil];
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

@end
