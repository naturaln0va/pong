//
//  RAMyScene.m
//  pong
//
//  Created by Ryan Ackermann on 8/26/14.
//  Copyright (c) 2014 Ryan Ackermann. All rights reserved.
//

#import "RAMyScene.h"

typedef NS_ENUM(int, Layer) {
    LayerBackground,
    LayerBall,
    LayerPaddle,
    LayerEffects,
    LayerMenu
};

typedef NS_OPTIONS(int, EntityCategory) {
    EntityCategoryPaddle = 1 << 0,
    EntityCategoryBall = 1 << 1
};

#define PADDLE_PADDING      85
#define ARC4RANDOM_MAX      0x100000000
#define PADDLE_SPEED        0.13245
#define BALL_INITIAL_SPEED  189.0

static inline CGFloat ScalarRandomRange(CGFloat min, CGFloat max){
    return floorf(((double)arc4random() / ARC4RANDOM_MAX) * (max - min) + min);
}

@interface RAMyScene() <SKPhysicsContactDelegate>
@end

@implementation RAMyScene {
    SKNode *_worldNode;
    SKSpriteNode *_playerPaddle;
    SKSpriteNode *_computerPaddle;
    SKSpriteNode *_ball;
    
    SKAction *_bounceSound;
    
    NSTimeInterval _lastUpdateTime;
    NSTimeInterval _dt;
    
    int _score;
}

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        self.backgroundColor = [SKColor blackColor];
        _worldNode = [SKNode node];
        
        self.physicsWorld.gravity = CGVectorMake(0.0f, 0.0f);
        self.physicsWorld.contactDelegate = self;
        
        [self createPlayerPaddle];
        [self createComputerPaddle];
        [self createBall];
        [self createSounds];
        
        [self addChild:_worldNode];
        
        [self runAction:[SKAction sequence:@[
                                             [SKAction waitForDuration:1.5],
                                             [SKAction runBlock:^{
            _ball.physicsBody.velocity = CGVectorMake(BALL_INITIAL_SPEED,
                                                      BALL_INITIAL_SPEED);
        }]]]];
    }
    return self;
}

#pragma mark - Init

-(void)createSounds {
    _bounceSound = [SKAction playSoundFileNamed:@"bounce.wav" waitForCompletion:NO];
}

-(void)createBall {
    _ball = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor]
                                         size:CGSizeMake(11, 11)];
    _ball.position = CGPointMake(CGRectGetMidX(self.frame),
                                 ScalarRandomRange(PADDLE_PADDING, CGRectGetMaxY(self.frame) - PADDLE_PADDING));
    _ball.anchorPoint = CGPointMake(0.5, 0.5);
    _ball.zPosition = LayerBall;
    
    _ball.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:_ball.size];
    _ball.physicsBody.categoryBitMask = EntityCategoryBall;
    _ball.physicsBody.collisionBitMask = 0;
    _ball.physicsBody.contactTestBitMask = EntityCategoryPaddle;
    _ball.physicsBody.affectedByGravity = NO;
    _ball.physicsBody.usesPreciseCollisionDetection = YES;
    
    [_worldNode addChild:_ball];
}

-(void)createComputerPaddle {
    _computerPaddle = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor]
                                                   size:CGSizeMake(16.0f, 80.0f)];
    _computerPaddle.position = CGPointMake(PADDLE_PADDING,
                                           CGRectGetMidY(self.frame));
    _computerPaddle.anchorPoint = CGPointMake(0.5, 0.5);
    _computerPaddle.zPosition = LayerPaddle;
    
    _computerPaddle.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:_computerPaddle.size];
    _computerPaddle.physicsBody.categoryBitMask = EntityCategoryPaddle;
    _computerPaddle.physicsBody.collisionBitMask = 0;
    _computerPaddle.physicsBody.contactTestBitMask = EntityCategoryBall;
    _computerPaddle.physicsBody.affectedByGravity = NO;
    _computerPaddle.physicsBody.usesPreciseCollisionDetection = YES;
    
    [_worldNode addChild:_computerPaddle];
}

-(void)createPlayerPaddle {
    _playerPaddle = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor]
                                                 size:CGSizeMake(16.0f, 80.0f)];
    _playerPaddle.position = CGPointMake(CGRectGetWidth(self.frame) - PADDLE_PADDING,
                                         CGRectGetMidY(self.frame));
    _playerPaddle.anchorPoint = CGPointMake(0.5, 0.5);
    _playerPaddle.zPosition = LayerPaddle;
    
    _playerPaddle.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:_playerPaddle.size];
    _playerPaddle.physicsBody.categoryBitMask = EntityCategoryPaddle;
    _playerPaddle.physicsBody.collisionBitMask = 0;
    _playerPaddle.physicsBody.contactTestBitMask = EntityCategoryBall;
    _playerPaddle.physicsBody.affectedByGravity = NO;
    _playerPaddle.physicsBody.usesPreciseCollisionDetection = YES;
    
    [_worldNode addChild:_playerPaddle];
}

#pragma mark - Touches

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        
        if (location.y != _playerPaddle.position.y) {
            [_playerPaddle runAction:[SKAction moveTo:CGPointMake(_playerPaddle.position.x, location.y) duration:PADDLE_SPEED]];
        } else {
            _playerPaddle.position = CGPointMake(_playerPaddle.position.x, location.y);
        }
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        
        if (location.y != _playerPaddle.position.y) {
            [_playerPaddle runAction:[SKAction moveTo:CGPointMake(_playerPaddle.position.x, location.y) duration:PADDLE_SPEED]];
        } else {
            _playerPaddle.position = CGPointMake(_playerPaddle.position.x, location.y);
        }
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
}

#pragma mark - Update

-(void)moveBall {
    if (_ball.position.y > self.frame.size.height || _ball.position.y < 0) {
        _ball.physicsBody.velocity = CGVectorMake(_ball.physicsBody.velocity.dx,
                                                  -_ball.physicsBody.velocity.dy);
        [self runAction:_bounceSound];
    }
}

-(void)moveComputerPaddle {
    if (_ball.position.x <= (CGRectGetWidth(self.frame) / 2)) {
        
    }
}

-(void)update:(CFTimeInterval)currentTime {
    if (_lastUpdateTime) {
        _dt = currentTime - _lastUpdateTime;
    } else {
        _dt = 0;
    }
    _lastUpdateTime = currentTime;
}

-(void)didSimulatePhysics {
    [self moveBall];
    [self moveComputerPaddle];
}

#pragma mark - Collision Detection

- (void)didBeginContact:(SKPhysicsContact *)contact {
    SKPhysicsBody *other = (contact.bodyA.categoryBitMask == EntityCategoryPaddle ? contact.bodyB : contact.bodyA);
    if (other.categoryBitMask == EntityCategoryBall) {
        _ball.physicsBody.velocity = CGVectorMake(-_ball.physicsBody.velocity.dx,
                                                  _ball.physicsBody.velocity.dy);
        [self runAction:_bounceSound];
        return;
    }
}

@end
