//
//  RAMyScene.m
//  pong
//
//  Created by Ryan Ackermann on 8/26/14.
//  Copyright (c) 2014 Ryan Ackermann. All rights reserved.
//

#import "RAGameScene.h"

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
#define PADDLE_ACCEL        1.25
#define PADDLE_DEACCEL      2.85232
#define COMPUTER_ACCEL      423.0
#define COMPUTER_DEACCEL    389.0

#define BALL_INITIAL_SPEED  189.0
#define BALL_SPEED          150.0
#define BALL_SIZE           11.0
#define BALL_SCORE_CHECK    47.0

static inline CGFloat ScalarRandomRange(CGFloat min, CGFloat max){
    return floorf(((double)arc4random() / ARC4RANDOM_MAX) * (max - min) + min);
}

@interface RAGameScene() <SKPhysicsContactDelegate>
@end

@implementation RAGameScene {
    SKNode *_worldNode;
    SKSpriteNode *_leftPaddle;
    SKSpriteNode *_rightPaddle;
    SKSpriteNode *_ball;
    
    SKAction *_bounceSound;
    SKAction *_bongSound;
    SKAction *_spawnBall;
    
    UITouch *_leftTouch;
    UITouch *_rightTouch;
    
    NSTimeInterval _lastUpdateTime;
    NSTimeInterval _dt;
    
    SKLabelNode *_leftScoreLabel;
    SKLabelNode *_rightScoreLabel;
    
    CGFloat _leftDifference;
    CGFloat _rightDifference;
    
    BOOL _isTwoPlayer;
    int _leftScore;
    int _rightScore;
}

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        self.backgroundColor = [SKColor blackColor];
        _worldNode = [SKNode node];
        
        // TESTING
        _isTwoPlayer = false;
        
        self.physicsWorld.gravity = CGVectorMake(0.0f, 0.0f);
        self.physicsWorld.contactDelegate = self;
        
        [self createLabels];
        [self createLeftPaddle];
        [self createRightPaddle];
        [self createBall];
        [self createCenterLine];
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

-(void)addParticleToNode:(SKNode *)node withName:(NSString *)name {
    SKEmitterNode *engine = [NSKeyedUnarchiver
                             unarchiveObjectWithFile:
                             [[NSBundle mainBundle]
                              pathForResource:name
                              ofType:@"sks"]];
    engine.targetNode = node;
    [self addChild:engine];
    /*[engine runAction:[SKAction sequence:@[[SKAction waitForDuration:0.79],
                                          [SKAction removeFromParent]]]];*/
}

-(void)createCenterLine {
    //middle line
    CGFloat middleLineWidth = 4.0;
    CGFloat middleLineHeight = 20.0;
    NSInteger numberOfLines = self.frame.size.height / (2*middleLineHeight);
    CGPoint linePosition = CGPointMake(self.frame.size.width / 2.0, middleLineHeight * 1.5);
    for (NSInteger i = 0; i < numberOfLines; i++)
    {
        SKSpriteNode *lineNode = [SKSpriteNode spriteNodeWithColor:[SKColor colorWithWhite:1.0 alpha:0.5] size:CGSizeMake(middleLineWidth, middleLineHeight)];
        lineNode.position = linePosition;
        linePosition.y += 2*middleLineHeight;
        [_worldNode addChild:lineNode];
    }
}

-(void)createLabels {
    _rightScoreLabel = [SKLabelNode labelNodeWithFontNamed:@"enhanced_dot_digital-7"];
}

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
    
    //[self addParticleToNode:_ball withName:@"BallTrail"];
    
    [_worldNode addChild:_ball];
}

-(void)createRightPaddle {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        _rightPaddle = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor]
                                                       size:CGSizeMake(PADDLE_WIDTH * IPAD_MULT_FACTOR,
                                                                       PADDLE_HEIGHT * IPAD_MULT_FACTOR)];
        _rightPaddle.position = CGPointMake(PADDLE_PADDING * IPAD_MULT_FACTOR,
                                               CGRectGetMidY(self.frame));
    } else {
        _rightPaddle = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor]
                                                       size:CGSizeMake(PADDLE_WIDTH,
                                                                       PADDLE_HEIGHT)];
        _rightPaddle.position = CGPointMake(PADDLE_PADDING,
                                               CGRectGetMidY(self.frame));
    }
    
    _rightPaddle.anchorPoint = CGPointMake(0.5, 0.5);
    _rightPaddle.zPosition = LayerPaddle;
    
    _rightPaddle.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:_rightPaddle.size];
    _rightPaddle.physicsBody.categoryBitMask = EntityCategoryPaddle;
    _rightPaddle.physicsBody.collisionBitMask = 0;
    _rightPaddle.physicsBody.contactTestBitMask = EntityCategoryBall;
    _rightPaddle.physicsBody.usesPreciseCollisionDetection = YES;
    
    [_worldNode addChild:_rightPaddle];
}

-(void)createLeftPaddle {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        _leftPaddle = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor]
                                                     size:CGSizeMake(PADDLE_WIDTH * IPAD_MULT_FACTOR,
                                                                     PADDLE_HEIGHT * IPAD_MULT_FACTOR)];
        _leftPaddle.position = CGPointMake(CGRectGetWidth(self.frame) - PADDLE_PADDING * IPAD_MULT_FACTOR, CGRectGetMidY(self.frame));
    } else {
        _leftPaddle = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor]
                                                     size:CGSizeMake(PADDLE_WIDTH,
                                                                     PADDLE_HEIGHT)];
        _leftPaddle.position = CGPointMake(CGRectGetWidth(self.frame) - PADDLE_PADDING,
                                             CGRectGetMidY(self.frame));
    }
    _leftPaddle.anchorPoint = CGPointMake(0.5, 0.5);
    _leftPaddle.zPosition = LayerPaddle;
    
    _leftPaddle.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:_leftPaddle.size];
    _leftPaddle.physicsBody.categoryBitMask = EntityCategoryPaddle;
    _leftPaddle.physicsBody.collisionBitMask = 0;
    _leftPaddle.physicsBody.contactTestBitMask = EntityCategoryBall;;
    _leftPaddle.physicsBody.usesPreciseCollisionDetection = YES;
    
    [_worldNode addChild:_leftPaddle];
}

#pragma mark - Touches

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        
        // TODO: add check for menu button
        
        if(_isTwoPlayer) {
            if (_leftTouch == nil) {
                if (location.x < self.frame.size.width / 2.0) {
                    _leftTouch = touch;
                }
            }
            if (_rightTouch == nil) {
                if (location.x > self.frame.size.width / 2.0) {
                    _rightTouch = touch;
                }
            }
        } else {
            _leftTouch = touch;
        }
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        if (touch == _leftTouch) {
            [self moveLeftPaddle];
        } else if (touch == _rightTouch) {
            [self moveRightPaddle];
        }
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        if (touch == _leftTouch) {
            _leftTouch = nil;
            [self easeLeftToStop];
        }
        else if (touch == _rightTouch) {
            _rightTouch = nil;
        }
    }
}

#pragma mark - Update

-(void)moveLeftPaddle {
    CGPoint previousLocation = [_leftTouch previousLocationInNode:self];
    CGPoint newLocation = [_leftTouch locationInNode:self];
    _leftDifference = newLocation.y - previousLocation.y; // use this as change in y velocity for the ball
    
    if (newLocation.x > self.frame.size.width / 2.0) {
        if (_isTwoPlayer) {
            return; // touch is on wrong side
        }
    }
    
    CGFloat xPos = _leftPaddle.position.x;
    CGFloat yPos = _leftPaddle.position.y + _leftDifference * PADDLE_ACCEL;
    
    CGFloat yMax = self.frame.size.height - _leftPaddle.size.height/2.0;
    CGFloat yMin = _leftPaddle.size.height/2.0;
    if (yPos > yMax) {
        yPos = yMax;
    } else if (yPos < yMin) {
        yPos = yMin;
    }
    _leftPaddle.position = CGPointMake(xPos, yPos);
}

-(void)easeLeftToStop {
    if (_leftPaddle.physicsBody.velocity.dy > 0.0f) {
        _leftPaddle.physicsBody.velocity = CGVectorMake(_leftPaddle.physicsBody.velocity.dx,
                                                        _leftPaddle.physicsBody.velocity.dy - (_dt * PADDLE_DEACCEL));
    } else if (_leftPaddle.physicsBody.velocity.dy < 0.0f) {
        _leftPaddle.physicsBody.velocity = CGVectorMake(_leftPaddle.physicsBody.velocity.dx,
                                                        _leftPaddle.physicsBody.velocity.dy + (_dt * PADDLE_DEACCEL));
    }
}

-(void)moveRightPaddle {
    
}

-(void)moveComputerPaddle {
    if (_ball.position.x <= (CGRectGetWidth(self.frame) * 0.4)) {
        
        if (_ball.position.y > _rightPaddle.position.y) {
            _rightPaddle.physicsBody.velocity = CGVectorMake(_rightPaddle.physicsBody.velocity.dx, _rightPaddle.physicsBody.velocity.dy + _dt * COMPUTER_ACCEL);
        } else if (_ball.position.y < _rightPaddle.position.y) {
            _rightPaddle.physicsBody.velocity = CGVectorMake(_rightPaddle.physicsBody.velocity.dx, _rightPaddle.physicsBody.velocity.dy - _dt * COMPUTER_ACCEL);
        }
    } else {
        if (_rightPaddle.physicsBody.velocity.dy > 0.0f) {
            _rightPaddle.physicsBody.velocity = CGVectorMake(_rightPaddle.physicsBody.velocity.dx, _rightPaddle.physicsBody.velocity.dy - _dt * COMPUTER_DEACCEL);
        } else if (_rightPaddle.physicsBody.velocity.dy < 0.0f) {
            _rightPaddle.physicsBody.velocity = CGVectorMake(_rightPaddle.physicsBody.velocity.dx, _rightPaddle.physicsBody.velocity.dy + _dt * COMPUTER_DEACCEL);
        }
    }
    
    CGFloat yMax = self.frame.size.height - _rightPaddle.size.height/2.0;
    CGFloat yMin = _rightPaddle.size.height/2.0;
    
    if (_rightPaddle.position.y > yMax) {
        _rightPaddle.position = CGPointMake(_rightPaddle.position.x,
                                            yMax);
    }
    if (_rightPaddle.position.y < yMin) {
        _rightPaddle.position = CGPointMake(_rightPaddle.position.x,
                                            yMin);
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
        [_ball runAction:[SKAction sequence:@[[SKAction fadeAlphaTo:0.0f duration:0.023],
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
    
    if (!_isTwoPlayer) [self moveComputerPaddle];
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
                                                      _ball.physicsBody.velocity.dy + _leftDifference);
        }
        
        [self runAction:_bongSound];
        //[self addParticleToNode:other.node withName:@"PaddleParticle"];
        return;
    }
}

@end
