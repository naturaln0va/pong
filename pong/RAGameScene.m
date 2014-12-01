//
//  RAMyScene.m
//  pong
//
//  Created by Ryan Ackermann on 8/26/14.
//  Copyright (c) 2014 Ryan Ackermann. All rights reserved.
//

#import "RAGameScene.h"
#import "RAMenuScene.h"
#import "RAScoreUploadScene.h"
#import "RARankedScore.h"

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
    EntityCategoryRankedPaddle = 1 << 2
};

#define IPAD_MULT_FACTOR    2.0
#define IPAD_BALL_SPEED     385.0

#define MIDDLE_PADDING      64.0
#define TOP_FRAME_PADDING   47.0
#define PADDLE_PADDING      42.0
#define PADDLE_WIDTH        10.0
#define PADDLE_HEIGHT       74.0
#define ARC4RANDOM_MAX      0x100000000
#define PADDLE_ACCEL        1.25
#define PADDLE_DEACCEL      2.85232
#define LOGIC_ANGLE_FACTOR  0.56

#define PADDLE_WIDTH_3X     14.0
#define PADDLE_HEIGHT_3X    86.0

#define COM_ACCEL_EASY      130.0
#define COM_ACCEL_NORM      178.0
#define COM_ACCEL_HARD      198.0
#define COM_ACCEL_RANK      202.0
#define COM_ANGLE_EASY      0.412
#define COM_ANGLE_NORM      0.58
#define COM_ANGLE_HARD      0.78
#define COM_ANGLE_RANK      0.9

#define PAD_COM_ACCEL_EASY  235.0
#define PAD_COM_ACCEL_NORM  278.0
#define PAD_COM_ACCEL_HARD  311.0
#define PAD_COM_ACCEL_RANK  380.0
#define PAD_COM_ANGLE_EASY  0.3
#define PAD_COM_ANGLE_NORM  0.55
#define PAD_COM_ANGLE_HARD  0.78
#define PAD_COM_ANGLE_RANK  0.9

#define BALL_INITIAL_SPEED  189.0
#define BALL_SPEED          150.0
#define BALL_SIZE           11.0
#define BALL_SCORE_CHECK    27.0

static inline CGFloat ScalarRandomRange(CGFloat min, CGFloat max){
    return floorf(((double)arc4random() / ARC4RANDOM_MAX) * (max - min) + min);
}

static inline int randomSign() {
    return (arc4random() % 2 ? 1 : -1);
}

static inline BOOL isPositive(CGFloat num) {
    return num > 0;
}

@interface RAGameScene() <SKPhysicsContactDelegate>
@end

@implementation RAGameScene {
    SKNode *_worldNode;
    SKSpriteNode *_leftPaddle;
    SKSpriteNode *_rightPaddle;
    SKSpriteNode *_ball;
    SKSpriteNode *_menuButton;
    
    SKAction *_bounceSound;
    SKAction *_bongSound;
    SKAction *_fireWorkSound1;
    SKAction *_fireWorkSound2;
    SKAction *_spawnBall;
    
    UITouch *_leftTouch;
    UITouch *_rightTouch;
    
    NSTimeInterval _lastUpdateTime;
    NSTimeInterval _dt;
    
    SKLabelNode *_leftScoreLabel;
    SKLabelNode *_rightScoreLabel;
    SKLabelNode *_winningLabel;
    
    CGFloat _leftDifference;
    CGFloat _rightDifference;
    CGFloat _computerAngle;
    CGFloat _computerSpeed;
    
    BOOL _canSwtichY;
    BOOL _isTwoPlayer;
    BOOL _isRanked;
    int _leftScore;
    int _rightScore;
}

#pragma mark - Init

-(id)initWithSize:(CGSize)size {    
    return [self initWithSize:size withDifficulty:0];
}

-(instancetype)initWithSize:(CGSize)size withDifficulty:(int)difficulty {
    if (self = [super initWithSize:size]) {
        self.backgroundColor = [SKColor blackColor];
        _worldNode = [SKNode node];
        _canSwtichY = true;
        
        if (difficulty == 0) {
            _isTwoPlayer = YES;
        } else if (difficulty == 4) {
            _isRanked = YES;
        } else {
            _isTwoPlayer = NO;
        }
        
        self.physicsWorld.gravity = CGVectorMake(0.0f, 0.0f);
        self.physicsWorld.contactDelegate = self;
        
        [self createLabels];
        [self createButton];
        [self createLeftPaddle];
        [self createRightPaddle];
        [self createBall];
        [self createCenterLine];
        [self createSounds];
        [self createActions];
        [self setIntelegenceLevel:difficulty];
        
        [self resetScores];
        
        [self addChild:_worldNode];
        
        [self runAction:_spawnBall];
    }
    return self;
}

-(void)createActions {
    _spawnBall = [SKAction sequence:@[
                                      [SKAction waitForDuration:1.5],
                                      [SKAction runBlock:^{
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            _ball.physicsBody.velocity = CGVectorMake(IPAD_BALL_SPEED * randomSign(),
                                                      IPAD_BALL_SPEED);
        } else {
            _ball.physicsBody.velocity = CGVectorMake(BALL_INITIAL_SPEED * randomSign(),
                                                      BALL_INITIAL_SPEED);
        }
    }]]];
}

-(void)createCenterLine {
    CGFloat middleLineWidth;
    CGFloat middleLineHeight;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        middleLineWidth = 5.0;
        middleLineHeight = 31.0;
    } else {
        middleLineWidth = 3.0;
        middleLineHeight = 20.0;
    }
    NSInteger numberOfLines = self.frame.size.height / (2*middleLineHeight);
    CGPoint linePosition = CGPointMake(self.frame.size.width / 2.0, middleLineHeight * 1.5);
    for (NSInteger i = 0; i < numberOfLines; i++)
    {
        SKSpriteNode *lineNode = [SKSpriteNode spriteNodeWithColor:[SKColor colorWithWhite:1.0 alpha:0.5] size:CGSizeMake(middleLineWidth, middleLineHeight)];
        lineNode.position = linePosition;
        lineNode.name = @"centerLine";
        linePosition.y += 2 *  middleLineHeight;
        [_worldNode addChild:lineNode];
    }
}

-(void)createButton {
    _menuButton = [SKSpriteNode spriteNodeWithImageNamed:@"menuButton"];
    _menuButton.position = CGPointMake(CGRectGetMidX(self.frame),
                                       CGRectGetHeight(self.frame) - (_menuButton.size.height / 2.0 + TOP_FRAME_PADDING) + 24);
    _menuButton.anchorPoint = CGPointMake(0.5, 0.5);
    _menuButton.xScale = 1.5f;
    _menuButton.yScale = 1.5f;
    [_worldNode addChild:_menuButton];
}

-(void)createLabels {
    if (!_isRanked) {
        _leftScoreLabel = [SKLabelNode labelNodeWithFontNamed:@"Enhanced Dot Digital-7"];
        _leftScoreLabel.position = CGPointMake(CGRectGetMidX(self.frame)+ _leftScoreLabel.frame.size.height / 2.0 - MIDDLE_PADDING, CGRectGetMaxY(self.frame) + _leftScoreLabel.frame.size.height / 2.0 - TOP_FRAME_PADDING);
        _leftScoreLabel.fontColor = [SKColor whiteColor];
        _leftScoreLabel.fontSize = 37.0f;
        _leftScoreLabel.text = @"0";
        [_worldNode addChild:_leftScoreLabel];
    }
    
    _rightScoreLabel = [SKLabelNode labelNodeWithFontNamed:@"Enhanced Dot Digital-7"];
    _rightScoreLabel.position = CGPointMake(CGRectGetMidX(self.frame)+ _rightScoreLabel.frame.size.height / 2.0 + MIDDLE_PADDING, CGRectGetMaxY(self.frame) + _rightScoreLabel.frame.size.height / 2.0 - TOP_FRAME_PADDING);
    _rightScoreLabel.fontColor = [SKColor whiteColor];
    _rightScoreLabel.fontSize = 37.0f;
    _rightScoreLabel.text = @"0";
    [_worldNode addChild:_rightScoreLabel];
    
    _winningLabel = [SKLabelNode labelNodeWithFontNamed:@"Enhanced Dot Digital-7"];
    _winningLabel.position = CGPointMake(CGRectGetMidX(self.frame),
                                         CGRectGetMidY(self.frame) - 35.0f);
    _winningLabel.fontColor = [SKColor whiteColor];
    _winningLabel.fontSize = 87.0f;
    _winningLabel.text = @"YOU WIN!!!";
    _winningLabel.zPosition = 100.0f;
}

-(void)createSounds {
    _bounceSound = [SKAction playSoundFileNamed:@"Bloop.wav" waitForCompletion:NO];
    _bongSound = [SKAction playSoundFileNamed:@"bong.wav" waitForCompletion:NO];
    _fireWorkSound1 = [SKAction playSoundFileNamed:@"FireWork1.wav" waitForCompletion:NO];
    _fireWorkSound2 = [SKAction playSoundFileNamed:@"FireWork2.wav" waitForCompletion:NO];
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
    _ball.physicsBody.velocity = CGVectorMake(0.0f, 0.0f);
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
    } else if([self isLargePhone]) {
        _rightPaddle = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor]
                                                    size:CGSizeMake(PADDLE_WIDTH_3X,
                                                                    PADDLE_HEIGHT_3X)];
        _rightPaddle.position = CGPointMake(PADDLE_PADDING,
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
    _rightPaddle.physicsBody.linearDamping = 5.0f;
    
    [_rightPaddle removeFromParent];
    
    [_worldNode addChild:_rightPaddle];
}

-(void)createLeftPaddle {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        _leftPaddle = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor]
                                                     size:CGSizeMake(PADDLE_WIDTH * IPAD_MULT_FACTOR,
                                                                     PADDLE_HEIGHT * IPAD_MULT_FACTOR)];
        _leftPaddle.position = CGPointMake(CGRectGetWidth(self.frame) - PADDLE_PADDING * IPAD_MULT_FACTOR, CGRectGetMidY(self.frame));
    } else if([self isLargePhone]) {
        _leftPaddle = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor]
                                                    size:CGSizeMake(PADDLE_WIDTH_3X,
                                                                    PADDLE_HEIGHT_3X)];
        _leftPaddle.position = CGPointMake(CGRectGetWidth(self.frame) - PADDLE_PADDING,
                                           CGRectGetMidY(self.frame));
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
    _leftPaddle.physicsBody.categoryBitMask = EntityCategoryRankedPaddle;
    _leftPaddle.physicsBody.collisionBitMask = 0;
    _leftPaddle.physicsBody.contactTestBitMask = EntityCategoryBall;;
    _leftPaddle.physicsBody.usesPreciseCollisionDetection = YES;
    
    [_worldNode addChild:_leftPaddle];
}

#pragma mark - Touches

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        
        if (CGRectContainsPoint(_menuButton.frame, location)) {
            [self returnToMenu];
        }
        
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
            _rightTouch = touch;
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
        }
        else if (touch == _rightTouch) {
            _rightTouch = nil;
        }
    }
}

#pragma mark - Helper

-(void)addParticleToNode:(SKNode *)node withName:(NSString *)name {
    SKEmitterNode *engine = [NSKeyedUnarchiver
                             unarchiveObjectWithFile:
                             [[NSBundle mainBundle]
                              pathForResource:name
                              ofType:@"sks"]];
    engine.position = node.position;
    engine.targetNode = node;
    [self addChild:engine];
}

-(void)addParticleAtLocation:(CGPoint)location withName:(NSString *)name {
    SKEmitterNode *engine = [NSKeyedUnarchiver
                             unarchiveObjectWithFile:
                             [[NSBundle mainBundle]
                              pathForResource:name
                              ofType:@"sks"]];
    engine.position = location;
    engine.targetNode = self;
    [self addChild:engine];
}

-(void)setIntelegenceLevel:(int)level {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (level == 0 || _isTwoPlayer) {
            return;
        } else if (level == 1) {
            // easy
            _computerSpeed = PAD_COM_ACCEL_EASY;
            _computerAngle = PAD_COM_ANGLE_EASY;
        } else if (level == 2) {
            // normal
            _computerSpeed = PAD_COM_ACCEL_NORM;
            _computerAngle = PAD_COM_ANGLE_NORM;
        } else if (level == 3) {
            // hard
            _computerSpeed = PAD_COM_ACCEL_HARD;
            _computerAngle = PAD_COM_ANGLE_HARD;
        } else if (level == 4) {
            _computerSpeed = PAD_COM_ACCEL_RANK;
            _computerAngle = PAD_COM_ANGLE_RANK;
        }
    } else {
        if (level == 0 || _isTwoPlayer) {
            return;
        } else if (level == 1) {
            // easy
            _computerSpeed = COM_ACCEL_EASY;
            _computerAngle = COM_ANGLE_EASY;
        } else if (level == 2) {
            // normal
            _computerSpeed = COM_ACCEL_NORM;
            _computerAngle = COM_ANGLE_NORM;
        } else if (level == 3) {
            // hard
            _computerSpeed = COM_ACCEL_HARD;
            _computerAngle = COM_ANGLE_HARD;
        } else if (level == 4) {
            _computerSpeed = COM_ACCEL_RANK;
            _computerAngle = COM_ANGLE_RANK;
        }
    }
}

-(void)resetScores {
    _rightScore = 0;
    _leftScore = 0;
}

-(void)checkScores {
    if (_rightScore == 7) {
        [self rightWins];
    } else if (_leftScore == 7) {
        [self leftWins];
    }
}

-(void)rightWins {
    if (_isTwoPlayer) {
        _winningLabel.text = @"RIGHT WINS!!!";
        [_worldNode addChild:_winningLabel];
        [_winningLabel runAction:[SKAction repeatActionForever:[SKAction sequence:@[[SKAction scaleBy:1.145f duration:0.231], [SKAction scaleTo:1.0f duration:0.231]]]]];
        [_winningLabel runAction:[SKAction repeatActionForever:[SKAction sequence:@[[SKAction runBlock:^{
            [self addParticleAtLocation:CGPointMake(ScalarRandomRange(CGRectGetMinX(self.frame),CGRectGetMaxX(self.frame)), ScalarRandomRange(CGRectGetMinY(self.frame),CGRectGetMaxY(self.frame))) withName:@"WinningConfetti"];
            if (arc4random() % 5) {
                [self runAction:_fireWorkSound1];
            } else {
                [self runAction:_fireWorkSound2];
            }
        }], [SKAction waitForDuration:0.25]]]]];
    } else {
        _winningLabel.text = @"YOU WIN!!!";
        [_worldNode addChild:_winningLabel];
        [_winningLabel runAction:[SKAction repeatActionForever:[SKAction sequence:@[[SKAction scaleBy:1.145f duration:0.231], [SKAction scaleTo:1.0f duration:0.231]]]]];
        [_winningLabel runAction:[SKAction repeatActionForever:[SKAction sequence:@[[SKAction runBlock:^{
            [self addParticleAtLocation:CGPointMake(ScalarRandomRange(CGRectGetMinX(self.frame),CGRectGetMaxX(self.frame)), ScalarRandomRange(CGRectGetMinY(self.frame),CGRectGetMaxY(self.frame))) withName:@"WinningConfetti"];
            if (arc4random() % 5) {
                [self runAction:_fireWorkSound1];
            } else {
                [self runAction:_fireWorkSound2];
            }
        }], [SKAction waitForDuration:0.25]]]]];
    }
    [_ball removeFromParent];
    [self runAction:[SKAction sequence:@[[SKAction waitForDuration:2.5],
                                         [SKAction runBlock:^{
        [self returnToMenu];
    }]]]];
}

-(void)leftWins {
    if (_isTwoPlayer) {
        _winningLabel.text = @"LEFT WINS!!!";
        [_worldNode addChild:_winningLabel];
        [_winningLabel runAction:[SKAction repeatActionForever:[SKAction sequence:@[[SKAction scaleBy:1.145f duration:0.231], [SKAction scaleTo:1.0f duration:0.231]]]]];
        [_winningLabel runAction:[SKAction repeatActionForever:[SKAction sequence:@[[SKAction runBlock:^{
            [self addParticleAtLocation:CGPointMake(ScalarRandomRange(CGRectGetMinX(self.frame),CGRectGetMaxX(self.frame)), ScalarRandomRange(CGRectGetMinY(self.frame),CGRectGetMaxY(self.frame))) withName:@"WinningConfetti"];
            if (arc4random() % 5) {
                [self runAction:_fireWorkSound1];
            } else {
                [self runAction:_fireWorkSound2];
            }
        }], [SKAction waitForDuration:0.25]]]]];
        [self runAction:[SKAction sequence:@[[SKAction waitForDuration:2.5],
                                             [SKAction runBlock:^{
            [self returnToMenu];
        }]]]];
    } else {
        _winningLabel.text = @"YOU LOOSE!!!";
        [_worldNode addChild:_winningLabel];
        [_winningLabel runAction:[SKAction repeatActionForever:[SKAction sequence:@[[SKAction scaleBy:1.145f duration:0.231], [SKAction scaleTo:1.0f duration:0.231]]]]];
    }
    [_ball removeFromParent];
    [self runAction:[SKAction sequence:@[[SKAction waitForDuration:2.5],
                                         [SKAction runBlock:^{
        [self returnToMenu];
    }]]]];
}
     
-(void)returnToMenu {
    RAMenuScene *menuScene = [RAMenuScene sceneWithSize:self.frame.size];
    SKTransition *transition = [SKTransition fadeWithDuration:1.12];
    [self.view presentScene:menuScene transition:transition];
}

-(void)presentRankedScoreSceneWithScore:(int)score {
    RAScoreUploadScene *scene = [[RAScoreUploadScene alloc] initWithSize:self.frame.size
                                                               withScore:score];
    SKTransition *transition = [SKTransition fadeWithDuration:1.12];
    [self.view presentScene:scene transition:transition];
}

-(void)changeGameColors {
    NSArray *gameColors = @[[SKColor colorWithRed:26.0/255.0f
                                            green:188.0/255.0f
                                             blue:156.0/255.0f
                                            alpha:1.0f],
                            [SKColor colorWithRed:46.0/255.0f
                                            green:204.0/255.0f
                                             blue:113.0/255.0f
                                            alpha:1.0f],
                            [SKColor colorWithRed:52.0/255.0f
                                            green:152.0/255.0f
                                             blue:219.0/255.0f
                                            alpha:1.0f],
                            [SKColor colorWithRed:155.0/255.0f
                                            green:89.0/255.0f
                                             blue:182.0/255.0f
                                            alpha:1.0f],
                            [SKColor colorWithRed:241.0/255.0f
                                            green:196.0/255.0f
                                             blue:15.0/255.0f
                                            alpha:1.0f],
                            [SKColor colorWithRed:230.0/255.0f
                                            green:126.0/255.0f
                                             blue:34.0/255.0f
                                            alpha:1.0f],
                            [SKColor colorWithRed:231.0/255.0f
                                            green:76.0/255.0f
                                             blue:60.0/255.0f
                                            alpha:1.0f],
                            [SKColor colorWithRed:236.0/255.0f
                                            green:240.0/255.0f
                                             blue:241.0/255.0f
                                            alpha:1.0f],
                            [SKColor colorWithRed:149.0/255.0f
                                            green:165.0/255.0f
                                             blue:166.0/255.0f
                                            alpha:1.0f]];
    
    SKColor *color = gameColors[(int)ScalarRandomRange(0, [gameColors count] - 1)];
    
    [_leftPaddle runAction:[SKAction colorizeWithColor:color
                                      colorBlendFactor:1.0f
                                              duration:0.23]];
    [_rightPaddle runAction:[SKAction colorizeWithColor:color
                                       colorBlendFactor:1.0f
                                               duration:0.23]];
    
    [_menuButton runAction:[SKAction colorizeWithColor:color
                                      colorBlendFactor:1.0f
                                              duration:0.23]];
    
    _leftScoreLabel.fontColor = color;
    _rightScoreLabel.fontColor = color;
    
    [_worldNode enumerateChildNodesWithName:@"centerLine" usingBlock:^(SKNode *node, BOOL *stop) {
        [node runAction:[SKAction colorizeWithColor:color
                                   colorBlendFactor:1.0f
                                           duration:0.23]];
    }];
}

-(BOOL)isLargePhone {
    int w = self.frame.size.width;
    int h = self.frame.size.height;
    NSLog(@"WIDTH: %d, HEIGHT: %d", w, h);
    if (w > 640 || h > 1136) {
        return YES;
    } else {
        return NO;
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
    
    CGFloat xPos = _rightPaddle.position.x;
    CGFloat yPos = _rightPaddle.position.y + _leftDifference * PADDLE_ACCEL;
    
    CGFloat yMax = self.frame.size.height - _rightPaddle.size.height/2.0;
    CGFloat yMin = _rightPaddle.size.height/2.0;
    if (yPos > yMax) {
        yPos = yMax;
    } else if (yPos < yMin) {
        yPos = yMin;
    }
    _rightPaddle.position = CGPointMake(xPos, yPos);
}

-(void)moveRightPaddle {
    CGPoint previousLocation = [_rightTouch previousLocationInNode:self];
    CGPoint newLocation = [_rightTouch locationInNode:self];
    _rightDifference = newLocation.y - previousLocation.y; // use this as change in y velocity for the ball
    
    if (newLocation.x < self.frame.size.width / 2.0) {
        if (_isTwoPlayer) {
            return; // touch is on wrong side
        }
    }
    
    CGFloat xPos = _leftPaddle.position.x;
    CGFloat yPos = _leftPaddle.position.y + _rightDifference * PADDLE_ACCEL;
    
    CGFloat yMax = self.frame.size.height - _leftPaddle.size.height/2.0;
    CGFloat yMin = _leftPaddle.size.height/2.0;
    if (yPos > yMax) {
        yPos = yMax;
    } else if (yPos < yMin) {
        yPos = yMin;
    }
    _leftPaddle.position = CGPointMake(xPos, yPos);
}

-(void)moveComputerPaddle {
    if (_ball.position.x <= (CGRectGetWidth(self.frame) * _computerAngle)) {
        
        if (_ball.position.y > _rightPaddle.position.y + (_rightPaddle.frame.size.height / 2.0)) {
            _rightPaddle.position = CGPointMake(_rightPaddle.position.x,
                                                _rightPaddle.position.y + _dt * _computerSpeed);
        } else if (_ball.position.y < _rightPaddle.position.y + (_rightPaddle.frame.size.height / 2.0)) {
            _rightPaddle.position = CGPointMake(_rightPaddle.position.x,
                                                _rightPaddle.position.y - _dt * _computerSpeed);
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

-(void)checkBoundryForBall {
    if (round(round(_ball.position.y) + _ball.size.height / 2) > self.frame.size.height - 1 ||
        round(round(_ball.position.y) - _ball.size.height / 2) < 1) {
        if (_canSwtichY) {
            _canSwtichY = false;
            _ball.physicsBody.velocity = CGVectorMake(_ball.physicsBody.velocity.dx,
                                                      -_ball.physicsBody.velocity.dy);
            [self runAction:_bongSound];
            [self runAction:[SKAction sequence:@[[SKAction waitForDuration:0.435],
                                                 [SKAction runBlock:^{
                _canSwtichY = true;
            }]]]];
        }
    } else if (_ball.position.x >= (self.frame.size.width - BALL_SCORE_CHECK) ||
               _ball.position.x <= BALL_SCORE_CHECK) {
        [_ball runAction:[SKAction sequence:@[[SKAction fadeAlphaTo:0.0f duration:0.23],
                                  [SKAction removeFromParent]]]];
        if (isPositive(_ball.physicsBody.velocity.dx)) {
            // Left Scored
            if (!_isRanked) {
                _leftScore++;
                _leftScoreLabel.text = [NSString stringWithFormat:@"%d", _leftScore];
                [self checkScores];
            } else {
                [self presentRankedScoreSceneWithScore:(int)[RARankedScore sharedRankedScore].score];
            }
        } else {
            // Right Scored
            if (!_isRanked) {
                _rightScore++;
                _rightScoreLabel.text = [NSString stringWithFormat:@"%d", _rightScore];
                [self checkScores];
            } else {
                [RARankedScore sharedRankedScore].score += 150;
                _rightScoreLabel.text = [NSString stringWithFormat:@"%d", (int)[RARankedScore sharedRankedScore].score];
            }
        }
        [self changeGameColors];
        [self createBall];
        [self runAction:_spawnBall];
    }
}

-(void)keepBallInside {
    if (_ball.position.y > self.frame.size.height) {
        _ball.position = CGPointMake(_ball.position.x,
                                     self.frame.size.height - 1);
    } else if (_ball.position.y < 0.0) {
        _ball.position = CGPointMake(_ball.position.x,
                                     1.0);
    }
}

-(void)update:(CFTimeInterval)currentTime {
    if (_lastUpdateTime) {
        _dt = currentTime - _lastUpdateTime;
    } else {
        _dt = 0;
    }
    _lastUpdateTime = currentTime;
    [self keepBallInside];
    
    if (!_isTwoPlayer) [self moveComputerPaddle];
}

#pragma mark - Collision Detection

-(void)didSimulatePhysics {
    [self checkBoundryForBall];
}

-(void)didBeginContact:(SKPhysicsContact *)contact {
    SKPhysicsBody *other = (contact.bodyA.categoryBitMask == EntityCategoryBall ? contact.bodyB : contact.bodyA);
    if (other.categoryBitMask == EntityCategoryPaddle ||
        other.categoryBitMask == EntityCategoryRankedPaddle) {
        
        
        
        if (other.categoryBitMask == EntityCategoryRankedPaddle && _isRanked) {
            [RARankedScore sharedRankedScore].score += 25;
            _rightScoreLabel.text = [NSString stringWithFormat:@"%d", (int)[RARankedScore sharedRankedScore].score];
        }
        
        /*
         *  Paddle logic blueprint
         *
         * -------
         * 1      upperExtreme
         * 2      upperExtreme
         * 3    other
         * 4    other
         * 5    other
         * 6      upperMid
         * 7      lowerMid
         * 8    other
         * 9    other
         * 10   other
         * 11     lowerExtreme
         * 12     lowerExtreme
         * -------
         */
        SKSpriteNode *paddle = (SKSpriteNode *)other.node;
        CGPoint ballPos = _ball.position;
        CGPoint paddlePos = paddle.position;
        CGFloat upperExtreme = (paddlePos.y) + paddle.size.height * (2.0 / 12.0);
        CGFloat lowerExtreme = (paddlePos.y) - paddle.size.height * (2.0 / 12.0);
        CGFloat upperMid = (paddlePos.y) + paddle.size.height * (2.0 / 12.0) + paddle.size.height * (1.0 / 12.0);
        CGFloat lowerMid = (paddlePos.y) - paddle.size.height * (2.0 / 12.0) - paddle.size.height * (1.0 / 12.0);
        
        if (ballPos.y >= upperExtreme) { // extreme upper english
            if (isPositive(_ball.physicsBody.velocity.dy)) {
                _ball.physicsBody.velocity = CGVectorMake(-_ball.physicsBody.velocity.dx * 1.06,
                                                          _ball.physicsBody.velocity.dy * 1.09);
            } else {
                _ball.physicsBody.velocity = CGVectorMake(-_ball.physicsBody.velocity.dx * 1.06,
                                                          -_ball.physicsBody.velocity.dy * 1.06);
            }
        } else if (ballPos.y <= lowerExtreme) {
            if (isPositive(_ball.physicsBody.velocity.dy)) {
                _ball.physicsBody.velocity = CGVectorMake(-_ball.physicsBody.velocity.dx * 1.06,
                                                          -_ball.physicsBody.velocity.dy * 1.06);
            } else {
                _ball.physicsBody.velocity = CGVectorMake(-_ball.physicsBody.velocity.dx * 1.06,
                                                          _ball.physicsBody.velocity.dy * 1.09);
            }
        } else if (!(ballPos.y >= upperExtreme || ballPos.y <= lowerExtreme) &&
                   (ballPos.y <= upperMid || ballPos.y >= lowerMid)) {
            _ball.physicsBody.velocity = CGVectorMake(-_ball.physicsBody.velocity.dx,
                                                      _ball.physicsBody.velocity.dy);
        }
        
        [self runAction:_bounceSound];
        return;
    }
}

@end
