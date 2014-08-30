//
//  RAMenuScene.m
//  pong
//
//  Created by Ryan Ackermann on 8/30/14.
//  Copyright (c) 2014 Ryan Ackermann. All rights reserved.
//

#import "RAMenuScene.h"
#import "RAGameScene.h"

@implementation RAMenuScene {
    SKLabelNode *_mainLabel;
}


-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        self.backgroundColor = [SKColor blackColor];
        
        _mainLabel = [SKLabelNode labelNodeWithFontNamed:@"enhanced_dot_digital-7"];
        _mainLabel.position = CGPointMake(CGRectGetMidX(self.frame),
                                          CGRectGetMidY(self.frame));
        _mainLabel.fontColor = [SKColor whiteColor];
        _mainLabel.fontSize = 120.0f;
        _mainLabel.text = @"PONG";
        [self addChild:_mainLabel];
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        
        if (CGRectContainsPoint(_mainLabel.frame, location)) {
            [self presentGame];
        }
    }
}

- (void)presentGame {
    RAGameScene *gameScene = [RAGameScene sceneWithSize:self.frame.size];
    SKTransition *transition = [SKTransition fadeWithDuration:1.12];
    [self.view presentScene:gameScene transition:transition];
}

@end
