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

#define IPAD_MULT_FACTOR    2.0
#define IPAD_BALL_SPEED     385.0

#define PADDLE_PADDING      45.0
#define PADDLE_WIDTH        12.0
#define PADDLE_HEIGHT       80.0
#define ARC4RANDOM_MAX      0x100000000
#define PADDLE_SPEED        0.13245
#define COMPUTER_SPEED      278.0
#define COMPUTER_DEACCEL    122.0

#define BALL_INITIAL_SPEED  189.0
#define BALL_SPEED          150.0
#define BALL_SIZE           11.0
#define BALL_SCORE_CHECK    47.0

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
    SKAction *_spawnBall;
    
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
        
        _spawnBall = [SKAction sequence:@[
                                             [SKAction waitForDuration:1.5],
                                             [SKAction runBlock:^{
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                _ball.physicsBody.velocity = CGVectorMake(IPAD_BALL_SPEED,
                                                          IPAD_BALL_SPEED);
            } else {
                _ball.physicsBody.velocity = CGVectorMake(BALL_INITIAL_SPEED,
                                                          BALL_INITIAL_SPEED);
            }
        }]]];
        [self runAction:_spawnBall];
    }
    return self;
}

#pragma mark - Init

-(void)createSounds {
    _bounceSound = [SKAction playSoundFileNamed:@"bounce.wav" waitForCompletion:NO];
    _bongSound = [SKAction playSoundFileNamed:@"bong.wav" waitForCompletion:NO];
}

-(void)createBall {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        _ball = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor]
                                             size:CGSizeMake(BALL_SIZE * IPAD_MULT_FACTOR,
                                                             BALL_SIZE * IPAD_MULT_FACTOR)];
        _ball.position = CGPointMake(CGRectGetMidX(self.frame),
                                     ScalarRandomRange(PADDLE_PADDING * IPAD_MULT_FACTOR, CGRectGetMaxY(self.frame) - PADDLE_PADDING * IPAD_MULT_FACTOR));
    } else {
        _ball = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor]
                                             size:CGSizeMake(BALL_SIZE,
                                                             BALL_SIZE)];
        _ball.position = CGPointMake(CGRectGetMidX(self.frame),
                                     ScalarRandomRange(PADDLE_PADDING, CGRectGetMaxY(self.frame) - PADDLE_PADDING));
    }
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
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        _computerPaddle = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor]
                                                       size:CGSizeMake(PADDLE_WIDTH * IPAD_MULT_FACTOR,
                                                                       PADDLE_HEIGHT * IPAD_MULT_FACTOR)];
        _computerPaddle.position = CGPointMake(PADDLE_PADDING * IPAD_MULT_FACTOR,
                                               CGRectGetMidY(self.frame));
    } else {
        _computerPaddle = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor]
                                                       size:CGSizeMake(PADDLE_WIDTH,
                                                                       PADDLE_HEIGHT)];
        _computerPaddle.position = CGPointMake(PADDLE_PADDING,
                                               CGRectGetMidY(self.frame));
    }
    
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
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        _playerPaddle = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor]
                                                     size:CGSizeMake(PADDLE_WIDTH * IPAD_MULT_FACTOR,
                                                                     PADDLE_HEIGHT * IPAD_MULT_FACTOR)];
        _playerPaddle.position = CGPointMake(CGRectGetWidth(self.frame) - PADDLE_PADDING * IPAD_MULT_FACTOR, CGRectGetMidY(self.frame));
    } else {
        _playerPaddle = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor]
                                                     size:CGSizeMake(PADDLE_WIDTH,
                                                                     PADDLE_HEIGHT)];
        _playerPaddle.position = CGPointMake(CGRectGetWidth(self.frame) - PADDLE_PADDING,
                                             CGRectGetMidY(self.frame));
    }
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
    if (_ball.position.x <= (CGRectGetWidth(self.frame) / 2.8)) {
        
        if (_ball.position.y > _computerPaddle.position.y) {
            _computerPaddle.physicsBody.velocity = CGVectorMake(_computerPaddle.physicsBody.velocity.dx, _computerPaddle.physicsBody.velocity.dy + _dt * COMPUTER_SPEED);
        } else if (_ball.position.y < _computerPaddle.position.y) {
            _computerPaddle.physicsBody.velocity = CGVectorMake(_computerPaddle.physicsBody.velocity.dx, _computerPaddle.physicsBody.velocity.dy - _dt * COMPUTER_SPEED);
        }
    } else {
        if (_computerPaddle.physicsBody.velocity.dy > 0.0f) {
            _computerPaddle.physicsBody.velocity = CGVectorMake(_computerPaddle.physicsBody.velocity.dx, _computerPaddle.physicsBody.velocity.dy - _dt * COMPUTER_DEACCEL);
        } else if (_computerPaddle.physicsBody.velocity.dy < 0.0f) {
            _computerPaddle.physicsBody.velocity = CGVectorMake(_computerPaddle.physicsBody.velocity.dx, _computerPaddle.physicsBody.velocity.dy + _dt * COMPUTER_DEACCEL);
        }
    }
}

- (void)checkBoundryForBall {
    if ((_ball.position.y + _ball.size.height / 2) >= self.frame.size.height ||
        (_ball.position.y - _ball.size.height / 2) <= 0.0f) {
        _ball.physicsBody.velocity = CGVectorMake(_ball.physicsBody.velocity.dx,
                                                  -_ball.physicsBody.velocity.dy);
        [self runAction:_bongSound];
    } else if (_ball.position.x >= (self.frame.size.width - BALL_SCORE_CHECK) ||
               _ball.position.x <= BALL_SCORE_CHECK) {
        [_ball runAction:[SKAction sequence:@[[SKAction fadeAlphaTo:0.0f duration:0.073],
                                  [SKAction removeFromParent]]]];
        [self createBall];
        [self runAction:_spawnBall];
    }
}
-(void)update:(CFTimeInterval)currentTime {
    if (_lastUpdateTime) {
        _dt = currentTime - _lastUpdateTime;
    } else {
        _dt = 0;
    }
    _lastUpdateTime = currentTime;
    [self checkBoundryForBall];
    [self moveComputerPaddle];
    NSLog(@"%f", _computerPaddle.physicsBody.velocity.dy);
}

#pragma mark - Collision Detection

- (void)didBeginContact:(SKPhysicsContact *)contact {
    SKPhysicsBody *other = (contact.bodyA.categoryBitMask == EntityCategoryBall ? contact.bodyB : contact.bodyA);
    if (other.categoryBitMask == EntityCategoryPaddle) {
        if (other.velocity.dy > 0.0f) {
            CGFloat difference = fabs(_ball.physicsBody.velocity.dy - other.velocity.dy);
            _ball.physicsBody.velocity = CGVectorMake(-_ball.physicsBody.velocity.dx,
                                                      _ball.physicsBody.velocity.dy + difference);
        } else {
            _ball.physicsBody.velocity = CGVectorMake(-_ball.physicsBody.velocity.dx,
                                                      _ball.physicsBody.velocity.dy);
        }
        
        [self runAction:_bongSound];
        return;
    }
}

@end
