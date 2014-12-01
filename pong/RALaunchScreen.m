//
//  RALaunchScreen.m
//  pong
//
//  Created by Ryan Ackermann on 9/16/14.
//  Copyright (c) 2014 Ryan Ackermann. All rights reserved.
//

#import "RALaunchScreen.h"
#import "RAMenuScene.h"

CGFloat DegreesToRadians(CGFloat degrees) {
    return M_PI * degrees / 180.0;
}

@implementation RALaunchScreen

-(instancetype)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        [self setBackgroundColor:[UIColor colorWithRed:48.0/255.0f
                                                 green:47.0/255.0f
                                                  blue:48.0/255.0f
                                                 alpha:1.0f]];
        
        SKSpriteNode *bigLogo = [SKSpriteNode spriteNodeWithImageNamed:@"TreehouseBigIcon"];
        bigLogo.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame) + 45);
        bigLogo.xScale = 0.0f;
        bigLogo.yScale = 0.0f;
        [self addChild:bigLogo];
        SKSpriteNode *logoText = [SKSpriteNode spriteNodeWithImageNamed:@"Made-For-A-Treehouse-Contest"];
        logoText.position = CGPointMake(CGRectGetMidX(self.frame), -120.0);
        [self addChild:logoText];
        
        [bigLogo runAction:[SKAction rotateToAngle:DegreesToRadians(360 * 3) duration:0.8921]];
        [bigLogo runAction:[SKAction scaleTo:1.0f duration:0.8921]];
        [logoText runAction:[SKAction sequence:@[[SKAction moveTo:CGPointMake(CGRectGetMidX(self.frame), 45.0) duration:0.8921]]]];
        
        [self runAction:[SKAction sequence:@[[SKAction waitForDuration:2.22],
                                             [SKAction runBlock:^{
            [self goToMainMenu];
        }]]]];
    }
    return self;
}

-(void)goToMainMenu {
    RAMenuScene *menuScene = [RAMenuScene sceneWithSize:self.frame.size];
    SKTransition *transition = [SKTransition fadeWithDuration:1.12];
    [self.view presentScene:menuScene transition:transition];
}

@end
