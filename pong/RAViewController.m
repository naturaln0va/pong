
#import "RAViewController.h"
#import "RALaunchScreen.h"
#import "RAMenuScene.h"
#import "RAGameKitHelper.h"


@interface RAViewController()
@property (nonatomic, strong) SKView *skView;
@property (nonatomic, strong) RALaunchScreen *launchScene;
@property (nonatomic, strong) RAMenuScene *menuScene;
@end


@implementation RAViewController

-(void) viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(showAuthenticationViewController)
                                                 name: PresentAuthenticationViewController
                                               object: nil];
    
    [[RAGameKitHelper sharedGameKitHelper] authenticateLocalPlayer];
    
    self.skView = [[SKView alloc] initWithFrame: self.view.bounds];
    self.skView.multipleTouchEnabled = YES;
    
    self.launchScene = [RALaunchScreen sceneWithSize: self.skView.bounds.size];
    self.launchScene.scaleMode = SKSceneScaleModeAspectFill;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        RAMenuScene *menuScene = [RAMenuScene sceneWithSize: self.skView.bounds.size];
        menuScene.scaleMode = SKSceneScaleModeAspectFill;
        
        SKTransition *transition = [SKTransition crossFadeWithDuration: 1];
        transition.pausesOutgoingScene = YES;
        
        [self.launchScene removeFromParent];
        [self.skView presentScene: menuScene transition: transition];
    });
    
    [self.view addSubview: self.skView];
    [self.skView presentScene: self.launchScene];
}


-(void) showAuthenticationViewController
{
    RAGameKitHelper *gameKitHelper = [RAGameKitHelper sharedGameKitHelper];
    
    [self.view.window.rootViewController presentViewController: gameKitHelper.authenticationViewController animated: YES completion: nil];
}


-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}


-(BOOL) shouldAutorotate
{
    return YES;
}


-(BOOL) prefersStatusBarHidden
{
    return YES;
}


-(UIInterfaceOrientationMask) supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}

@end
