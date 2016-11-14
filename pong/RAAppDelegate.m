
#import "RAAppDelegate.h"
#import "RAViewController.h"


@implementation RAAppDelegate

-(BOOL) application: (UIApplication *)application didFinishLaunchingWithOptions: (NSDictionary *)launchOptions
{
    RAViewController *vc = [RAViewController new];
    
    self.window = [[UIWindow alloc] initWithFrame: [UIScreen mainScreen].bounds];
    self.window.rootViewController = vc;
    
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
