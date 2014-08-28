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
    EntityCategoryBall = 1 << 1,
    EntityCategoryBorder = 1 << 2
};

#define IPAD_MULT_FACTOR    2.0
#define IPAD_BALL_SPEED     385.0

#define PADDLE_PADDING      45
#define ARC4RANDOM_MAX      0x100000000
#define PADDLE_SPEED        0.13245
#define COMPUTER_SPEED      0.04321
#define BALL_INITIAL_SPEED  189.0
#define BALL_SPEED          150.0

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
    SKAction *_bongSound;
    
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
        
        [self createBorder];
        [self createPlayerPaddle];
        [self createComputerPaddle];
        [self createBall];
        [self createSounds];
        
        [self addChild:_worldNode];
        
        [self runAction:[SKAction sequence:@[
                                             [SKAction waitForDuration:1.5],
                                             [SKAction runBlock:^{
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                _ball.physicsBody.velocity = CGVectorMake(IPAD_BALL_SPEED,
                                                          IPAD_BALL_SPEED);
            } else {
                _ball.physicsBody.velocity = CGVectorMake(BALL_INITIAL_SPEED,
                                                          BALL_INITIAL_SPEED);
            }
        }]]]];
    }
    return self;
}

#pragma mark - Init

-(void)createBorder {
    self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
    self.physicsBody.categoryBitMask = EntityCategoryBorder;
    self.physicsBody.collisionBitMask = 0;
    self.physicsBody.contactTestBitMask = EntityCategoryBall | EntityCategoryPaddle;
    self.physicsBody.friction = 0.0f;
    self.physicsBody.restitution = 1.0f;
    self.physicsBody.dynamic = NO;
    self.physicsBody.usesPreciseCollisionDetection = YES;
}

-(void)createSounds {
    _bounceSound = [SKAction playSoundFileNamed:@"bounce.wav" waitForCompletion:NO];
    _bongSound = [SKAction playSoundFileNamed:@"bong.wav" waitForCompletion:NO];
}

-(void)createBall {
    _ball = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor]
                                         size:CGSizeMake(11, 11)];
    _ball.position = CGPointMake(CGRectGetMidX(self.frame),
                                 ScalarRandomRange(PADDLE_PADDING, CGRectGetMaxY(self.frame) - PADDLE_PADDING));
    _ball.anchorPoint = CGPointMake(0.5, 0.5);
    _ball.zPosition = LayerBall;
    
    _ball.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:_ball.size];
    _ball.physicsBody.linearDamping = 0.0f;
    _ball.physicsBody.friction = 0.0f;
    _ball.physicsBody.restitution = 1.0f;
    _ball.physicsBody.allowsRotation = NO;
    _ball.physicsBody.categoryBitMask = EntityCategoryBall;
    _ball.physicsBody.collisionBitMask = 0;
    _ball.physicsBody.contactTestBitMask = EntityCategoryPaddle;
    _ball.physicsBody.usesPreciseCollisionDetection = YES;
    
    [_worldNode addChild:_ball];
}

-(void)createComputerPaddle {
    _computerPaddle = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor]
                                                   size:CGSizeMake(12.0f, 80.0f)];
    _computerPaddle.position = CGPointMake(PADDLE_PADDING,
                                           CGRectGetMidY(self.frame));
    _computerPaddle.anchorPoint = CGPointMake(0.5, 0.5);
    _computerPaddle.zPosition = LayerPaddle;
    
    _computerPaddle.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:_computerPaddle.size];
    _computerPaddle.physicsBody.categoryBitMask = EntityCategoryPaddle;
    _computerPaddle.physicsBody.collisionBitMask = 0;
    _computerPaddle.physicsBody.contactTestBitMask = EntityCategoryBall;
    _computerPaddle.physicsBody.usesPreciseCollisionDetection = YES;
    
    [_worldNode addChild:_computerPaddle];
}

-(void)createPlayerPaddle {
    _playerPaddle = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor]
                                                 size:CGSizeMake(12.0f, 80.0f)];
    _playerPaddle.position = CGPointMake(CGRectGetWidth(self.frame) - PADDLE_PADDING,
                                         CGRectGetMidY(self.frame));
    _playerPaddle.anchorPoint = CGPointMake(0.5, 0.5);
    _playerPaddle.zPosition = LayerPaddle;
    
    _playerPaddle.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:_playerPaddle.size];
    _playerPaddle.physicsBody.categoryBitMask = EntityCategoryPaddle;
    _playerPaddle.physicsBody.collisionBitMask = 0;
    _playerPaddle.physicsBody.contactTestBitMask = EntityCategoryBall;;
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

-(void)moveComputerPaddle {
    if (_ball.position.x <= (CGRectGetWidth(self.frame) / 4)) {
        [_computerPaddle runAction:[SKAction moveToY:_ball.position.y duration:COMPUTER_SPEED]];
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
    [self moveComputerPaddle];
}

#pragma mark - Collision Detection

- (void)didBeginContact:(SKPhysicsContact *)contact {
    SKPhysicsBody *other = (contact.bodyA.categoryBitMask == EntityCategoryBall ? contact.bodyB : contact.bodyA);
    if (other.categoryBitMask == EntityCategoryPaddle) {
        _ball.physicsBody.velocity = CGVectorMake(-_ball.physicsBody.velocity.dx,
                                                  _ball.physicsBody.velocity.dy);
        [self runAction:_bounceSound];
        return;
    } else if (other.categoryBitMask == EntityCategoryBorder) {
        _ball.physicsBody.velocity = CGVectorMake(_ball.physicsBody.velocity.dx,
                                                  -_ball.physicsBody.velocity.dy);
        [self runAction:_bongSound];
    }
}

@end
