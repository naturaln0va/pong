
#import "RALaunchScreen.h"
#import "RAMenuScene.h"

CGFloat DegreesToRadians(CGFloat degrees) {
    return M_PI * degrees / 180.0;
}

@implementation RALaunchScreen

-(instancetype) initWithSize: (CGSize)size
{
    if (self = [super initWithSize: size]) {
        [self setBackgroundColor: [UIColor blackColor]];
        
        SKSpriteNode *bigLogo = [SKSpriteNode spriteNodeWithImageNamed: @"TreehouseBigIcon"];
        bigLogo.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame) + 45);
        bigLogo.xScale = 0.0f;
        bigLogo.yScale = 0.0f;
        [self addChild: bigLogo];
        
        SKSpriteNode *logoText = [SKSpriteNode spriteNodeWithImageNamed: @"Made-For-A-Treehouse-Contest"];
        logoText.position = CGPointMake(CGRectGetMidX(self.frame), -120.0);
        [self addChild:logoText];
        
        [bigLogo runAction:[SKAction rotateToAngle: DegreesToRadians(360 * 3) duration: 0.8921]];
        [bigLogo runAction:[SKAction scaleTo: 1.0f duration: 0.8921]];
        [logoText runAction:[SKAction sequence: @[[SKAction moveTo: CGPointMake(CGRectGetMidX(self.frame), 45.0) duration: 0.8921]]]];
    }
    
    return self;
}

@end
