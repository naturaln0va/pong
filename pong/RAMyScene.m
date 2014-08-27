//
//  RAMyScene.m
//  pong
//
//  Created by Ryan Ackermann on 8/26/14.
//  Copyright (c) 2014 Ryan Ackermann. All rights reserved.
//

#import "RAMyScene.h"
#import "RAPaddle.h"

typedef NS_ENUM(int, Layer) {
    LayerBackground,
    LayerBall,
    LayerPaddle,
    LayerEffects,
    LayerMenu
};

typedef NS_OPTIONS(int, EntityCategory) {
    EntityCategoryPaddle = 1 << 0,
    EntityCategoryBall = 1 << 1,
};

#define PADDLE_PADDING      42
#define ARC4RANDOM_MAX      0x100000000
#define BALLSPEED

static inline CGFloat ScalarRandomRange(CGFloat min, CGFloat max){
    return floorf(((double)arc4random() / ARC4RANDOM_MAX) * (max - min) + min);
}

@implementation RAMyScene {
    SKNode *_worldNode;
    SKSpriteNode *_playerPaddle;
    
    NSTimeInterval _lastUpdateTime;
    NSTimeInterval _dt;
    
    int _score;
}

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        _worldNode = [SKNode node];
        
        [self createPlayerPaddle];
        
        [self addChild:_worldNode];
    }
    return self;
}

#pragma mark - Init

- (void)createPlayerPaddle {
    self.backgroundColor = [SKColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
    
    _playerPaddle = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor] size:CGSizeMake(16.0f, 80.0f)];
    _playerPaddle.position = CGPointMake(CGRectGetWidth(self.frame) - PADDLE_PADDING,
                                         CGRectGetMidY(self.frame));
    _playerPaddle.anchorPoint = CGPointMake(0.5, 0.5);
    _playerPaddle.zPosition = LayerPaddle;
    
    _playerPaddle.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:_playerPaddle.size];
    _playerPaddle.physicsBody.categoryBitMask = EntityCategoryPaddle;
    _playerPaddle.physicsBody.collisionBitMask = 0;
    _playerPaddle.physicsBody.contactTestBitMask = EntityCategoryBall;
    _playerPaddle.physicsBody.affectedByGravity = NO;
    
    [_worldNode addChild:_playerPaddle];
}

#pragma mark - Touches

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    
    /*for (UITouch *touch in touches) {
     CGPoint location = [touch locationInNode:self];
     
     }*/
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
}

#pragma mark - Update

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

@end
