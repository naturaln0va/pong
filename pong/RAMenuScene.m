//
//  RAMenuScene.m
//  pong
//
//  Created by Ryan Ackermann on 8/30/14.
//  Copyright (c) 2014 Ryan Ackermann. All rights reserved.
//

#import "RAMenuScene.h"
#import "RAGameScene.h"

#define FRAME_PADDING       12.0
#define MENU_ITEM_PADDING   54.0
#define MENU_ITEM_SIZE      37.0

NSString *const twitterURL = @"https://twitter.com/naturaln0va";

@implementation RAMenuScene {
    SKLabelNode *_mainLabel;
    SKLabelNode *_onePlayer;
    SKLabelNode *_twoPlayer;
    
    SKNode *_layerPlayersPick;
    SKNode *_layerDifficultySelect;
    
    SKSpriteNode *_twitterIcon;
}


-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        self.backgroundColor = [SKColor blackColor];
        
        _mainLabel = [SKLabelNode labelNodeWithFontNamed:@"Enhanced Dot Digital-7"];
        _mainLabel.position = CGPointMake(CGRectGetMidX(self.frame),
                                          CGRectGetMidY(self.frame) + 45.0f);
        _mainLabel.fontColor = [SKColor whiteColor];
        _mainLabel.fontSize = 120.0f;
        _mainLabel.text = @"PONG";
        [self addChild:_mainLabel];
        [_mainLabel runAction:[SKAction repeatActionForever:[SKAction sequence:@[[SKAction scaleBy:1.145f duration:0.231], [SKAction scaleTo:1.0f duration:0.231]]]]];
        
        _layerPlayersPick = [SKNode node];
        
        _onePlayer = [SKLabelNode labelNodeWithFontNamed:@"Enhanced Dot Digital-7"];
        _onePlayer.position = CGPointMake(CGRectGetMidX(self.frame),
                                          CGRectGetMidY(self.frame) - (MENU_ITEM_PADDING / 2.0));
        _onePlayer.fontColor = [SKColor whiteColor];
        _onePlayer.fontSize = MENU_ITEM_SIZE;
        _onePlayer.text = @"ONE PLAYER";
        _onePlayer.name = @"playerSelect";
        [_layerPlayersPick addChild:_onePlayer];
        
        _twoPlayer = [SKLabelNode labelNodeWithFontNamed:@"Enhanced Dot Digital-7"];
        _twoPlayer.position = CGPointMake(CGRectGetMidX(self.frame),
                                          CGRectGetMidY(self.frame) - (MENU_ITEM_PADDING * 2.0));
        _twoPlayer.fontColor = [SKColor whiteColor];
        _twoPlayer.fontSize = MENU_ITEM_SIZE;
        _twoPlayer.text = @"TWO PLAYER";
        _twoPlayer.name = @"playerSelect";
        [_layerPlayersPick addChild:_twoPlayer];
        
        _twitterIcon = [SKSpriteNode spriteNodeWithImageNamed:@"TwitterIcon"];
        [_twitterIcon runAction:[SKAction scaleXBy:0.75f y:0.75f duration:0.0001]];
        _twitterIcon.position = CGPointMake(CGRectGetWidth(self.frame) - (_twitterIcon.size.width / 2.0 + FRAME_PADDING), (_twitterIcon.size.height / 2.0) + FRAME_PADDING);
        [self addChild:_twitterIcon];
        
        [self addChild:_layerPlayersPick];
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        
        if (CGRectContainsPoint(_onePlayer.frame, location)) {
            SKAction *fade = [SKAction fadeAlphaTo:0.0f duration:0.53];
            SKAction *scaleDown = [SKAction scaleTo:0.0f duration:0.53];
            
            [_layerPlayersPick enumerateChildNodesWithName:@"playerSelect" usingBlock:^(SKNode *node, BOOL *stop) {
                [node runAction:fade];
                [node runAction:scaleDown];
                
                [node runAction:[SKAction sequence:@[[SKAction waitForDuration:0.6],
                                                     [SKAction removeFromParent]]]];
            }];
            
        } else if (CGRectContainsPoint(_twoPlayer.frame, location)) {
            [self presentGame]; // pass information along
        } else if (CGRectContainsPoint(_twitterIcon.frame, location)) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:twitterURL]];
        }
    }
}

- (void)presentGame {
    RAGameScene *gameScene = [RAGameScene sceneWithSize:self.frame.size];
    SKTransition *transition = [SKTransition fadeWithDuration:1.12];
    [self.view presentScene:gameScene transition:transition];
}

@end
