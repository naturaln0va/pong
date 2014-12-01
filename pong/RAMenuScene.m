//
//  RAMenuScene.m
//  pong
//
//  Created by Ryan Ackermann on 8/30/14.
//  Copyright (c) 2014 Ryan Ackermann. All rights reserved.
//

#import "RAMenuScene.h"
#import "RAGameScene.h"
#import "RAGameKitHelper.h"

#define PAD_FRAME_PADDING   27.0
#define PAD_ITEM_PADDING    74.0
#define PAD_ITEM_SIZE       54.0
#define PAD_DIF_SEL_PADD    267.0
#define PAD_RANKED_BUFFER   69.0

#define FRAME_PADDING       12.0
#define MENU_ITEM_PADDING   54.0
#define MENU_ITEM_SIZE      37.0
#define MID_FRAME_BUFFER    67.0
#define DIF_SELECT_PADDING  168.0
#define ACTION_DURATION     0.67
#define RANKED_LABEL_BUFFER 38.0

NSString *const fontName = @"Enhanced Dot Digital-7";
NSString *const twitterURL = @"https://twitter.com/naturaln0va";
NSString *const treehouseURL = @"http://referrals.trhou.se/naturaln0va";

@implementation RAMenuScene {
    SKLabelNode *_mainLabel;
    SKLabelNode *_onePlayer;
    SKLabelNode *_twoPlayer;
    SKLabelNode *_easyLabel;
    SKLabelNode *_normalLabel;
    SKLabelNode *_hardLabel;
    SKLabelNode *_rankedLabel;
    
    SKAction *_fadeIn;
    SKAction *_fadeOut;
    SKAction *_scaleDown;
    SKAction *_scaleUp;
    SKAction *_bleepSound;
    
    SKNode *_layerPlayersPick;
    SKNode *_layerDifficultySelect;
    
    SKSpriteNode *_twitterIcon;
    SKSpriteNode *_gameCenterOnIcon;
    SKSpriteNode *_treehouseIcon;
}

#pragma mark - Init

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        self.backgroundColor = [SKColor blackColor];
        
        _mainLabel = [SKLabelNode labelNodeWithFontNamed:fontName];
        _mainLabel.text = @"PONG";
        
        _layerPlayersPick = [SKNode node];
        _layerDifficultySelect = [SKNode node];
        
        _onePlayer = [SKLabelNode labelNodeWithFontNamed:fontName];
        _onePlayer.text = @"ONE PLAYER";
        _onePlayer.name = @"playerSelect";
        
        _twoPlayer = [SKLabelNode labelNodeWithFontNamed:fontName];
        _twoPlayer.text = @"TWO PLAYER";
        _twoPlayer.name = @"playerSelect";
        
        _twitterIcon = [SKSpriteNode spriteNodeWithImageNamed:@"TwitterIcon"];
        _gameCenterOnIcon = [SKSpriteNode spriteNodeWithImageNamed:@"PixelGameCenter"];
        _treehouseIcon = [SKSpriteNode spriteNodeWithImageNamed:@"TreehoseHomeIcon"];
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            [self setUpForPad];
        } else {
            [self setUpForPhone];
        }
        
        [_layerPlayersPick addChild:_onePlayer];
        [_layerPlayersPick addChild:_twoPlayer];
        [self addChild:_mainLabel];
        [self addChild:_twitterIcon];
        [self addChild:_treehouseIcon];
        [self addChild:_gameCenterOnIcon];
        [self addChild:_layerPlayersPick];
        [self setUpActions];
        [self createDifficultySelect];
        [_mainLabel runAction:[SKAction repeatActionForever:[SKAction sequence:@[[SKAction scaleBy:1.145f duration:0.231], [SKAction scaleTo:1.0f duration:0.231]]]]];
    }
    return self;
}

-(void)setUpForPad {
    _mainLabel.position = CGPointMake(CGRectGetMidX(self.frame),
                                      CGRectGetMidY(self.frame) + 75.0f);
    _mainLabel.fontColor = [SKColor whiteColor];
    _mainLabel.fontSize = 200.0f;
    
    _onePlayer.position = CGPointMake(CGRectGetMidX(self.frame),
                                      CGRectGetMidY(self.frame) - (PAD_ITEM_PADDING / 2.0));
    _onePlayer.fontColor = [SKColor whiteColor];
    _onePlayer.fontSize = PAD_ITEM_SIZE;
    
    _twoPlayer.position = CGPointMake(CGRectGetMidX(self.frame),
                                      CGRectGetMidY(self.frame) - (PAD_ITEM_PADDING * 2.0));
    _twoPlayer.fontColor = [SKColor whiteColor];
    _twoPlayer.fontSize = PAD_ITEM_SIZE;
    
    _twitterIcon.position = CGPointMake(CGRectGetWidth(self.frame) - (_twitterIcon.size.width / 2.0 + PAD_FRAME_PADDING), (_twitterIcon.size.height / 2.0) + PAD_FRAME_PADDING);
    
    _gameCenterOnIcon.position = CGPointMake(_gameCenterOnIcon.size.width / 2.0 + PAD_FRAME_PADDING,
                                             _gameCenterOnIcon.size.height / 2.0 + PAD_FRAME_PADDING);
    
    _treehouseIcon.position = CGPointMake(CGRectGetWidth(self.frame) - ((_treehouseIcon.size.width / 2.0) + PAD_FRAME_PADDING), CGRectGetHeight(self.frame) - ((_treehouseIcon.size.height / 2.0) + PAD_FRAME_PADDING));
}

-(void)setUpForPhone {
    _mainLabel.position = CGPointMake(CGRectGetMidX(self.frame),
                                      CGRectGetMidY(self.frame) + 45.0f);
    _mainLabel.fontColor = [SKColor whiteColor];
    _mainLabel.fontSize = 120.0f;
    
    _onePlayer.position = CGPointMake(CGRectGetMidX(self.frame),
                                      CGRectGetMidY(self.frame) - (MENU_ITEM_PADDING / 2.0));
    _onePlayer.fontColor = [SKColor whiteColor];
    _onePlayer.fontSize = MENU_ITEM_SIZE;
    
    _twoPlayer.position = CGPointMake(CGRectGetMidX(self.frame),
                                      CGRectGetMidY(self.frame) - (MENU_ITEM_PADDING * 2.0));
    _twoPlayer.fontColor = [SKColor whiteColor];
    _twoPlayer.fontSize = MENU_ITEM_SIZE;
    
    _twitterIcon.position = CGPointMake(CGRectGetWidth(self.frame) - (_twitterIcon.size.width / 2.0 + FRAME_PADDING), (_twitterIcon.size.height / 2.0) + FRAME_PADDING);
    
    _gameCenterOnIcon.position = CGPointMake(_gameCenterOnIcon.size.width / 2.0 + FRAME_PADDING,
                                             _gameCenterOnIcon.size.height / 2.0 + FRAME_PADDING);
    
    _treehouseIcon.position = CGPointMake(CGRectGetWidth(self.frame) - ((_treehouseIcon.size.width / 2.0) + FRAME_PADDING), CGRectGetHeight(self.frame) - ((_treehouseIcon.size.height / 2.0) + FRAME_PADDING));
}

#pragma mark - Difficulty Setup

-(void)createDifficultySelect {
    _easyLabel = [SKLabelNode labelNodeWithFontNamed:fontName];
    _easyLabel.position = CGPointMake(CGRectGetMidX(self.frame) - DIF_SELECT_PADDING,
                                      CGRectGetMidY(self.frame) - MID_FRAME_BUFFER);
    _easyLabel.fontColor = [SKColor whiteColor];
    _easyLabel.fontSize = MENU_ITEM_SIZE;
    _easyLabel.text = @"EASY";
    _easyLabel.name = @"difficultySelect";
    _easyLabel.xScale = 0.0f;
    _easyLabel.yScale = 0.0f;
    _easyLabel.alpha = 0.0f;
    
    _normalLabel = [SKLabelNode labelNodeWithFontNamed:fontName];
    _normalLabel.position = CGPointMake(CGRectGetMidX(self.frame),
                                        CGRectGetMidY(self.frame) - MID_FRAME_BUFFER);
    _normalLabel.fontColor = [SKColor whiteColor];
    _normalLabel.fontSize = MENU_ITEM_SIZE;
    _normalLabel.text = @"NORMAL";
    _normalLabel.name = @"difficultySelect";
    _normalLabel.xScale = 0.0f;
    _normalLabel.yScale = 0.0f;
    _normalLabel.alpha = 0.0f;
    
    _hardLabel = [SKLabelNode labelNodeWithFontNamed:fontName];
    _hardLabel.position = CGPointMake(CGRectGetMidX(self.frame) + DIF_SELECT_PADDING,
                                      CGRectGetMidY(self.frame) - MID_FRAME_BUFFER);
    _hardLabel.fontColor = [SKColor whiteColor];
    _hardLabel.fontSize = MENU_ITEM_SIZE;
    _hardLabel.text = @"HARD";
    _hardLabel.name = @"difficultySelect";
    _hardLabel.xScale = 0.0f;
    _hardLabel.yScale = 0.0f;
    _hardLabel.alpha = 0.0f;
    
    _rankedLabel = [SKLabelNode labelNodeWithFontNamed:fontName];
    _rankedLabel.position = CGPointMake(CGRectGetMidX(self.frame),
                                        -82.0f);
    _rankedLabel.fontColor = [SKColor whiteColor];
    _rankedLabel.fontSize = MENU_ITEM_SIZE;
    _rankedLabel.text = @"RANKED";
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        _easyLabel.position = CGPointMake(CGRectGetMidX(self.frame) - PAD_DIF_SEL_PADD,
                                          CGRectGetMidY(self.frame) - MID_FRAME_BUFFER);
        _easyLabel.fontSize = PAD_ITEM_SIZE;
        _normalLabel.fontSize = PAD_ITEM_SIZE;
        
        _hardLabel.position = CGPointMake(CGRectGetMidX(self.frame) + PAD_DIF_SEL_PADD,
                                          CGRectGetMidY(self.frame) - MID_FRAME_BUFFER);
        _hardLabel.fontSize = PAD_ITEM_SIZE;
        _rankedLabel.fontSize = PAD_ITEM_SIZE;
    }
}

-(void)showDifficultySelect {
    [self addChild:_layerDifficultySelect];
    
    [_layerDifficultySelect addChild:_easyLabel];
    [_layerDifficultySelect addChild:_normalLabel];
    [_layerDifficultySelect addChild:_hardLabel];
    
    [_layerDifficultySelect enumerateChildNodesWithName:@"difficultySelect" usingBlock:^(SKNode *node, BOOL *stop) {
        [node runAction:_scaleUp];
        [node runAction:_fadeIn];
        [node runAction:[SKAction waitForDuration:0.53]];
    }];
    [self runAction:[SKAction sequence:@[[SKAction waitForDuration:0.5],
                                         [SKAction runBlock:^{
        [_layerPlayersPick removeFromParent];
        [self runAction:[SKAction waitForDuration:0.092]];
        [self showRankedMode];
    }]]]];
}

-(void)showRankedMode {
    [self addChild:_rankedLabel];
    
    SKAction *moveUp;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        moveUp = [SKAction moveTo:CGPointMake(_rankedLabel.position.x, CGRectGetMidY(self.frame) - MID_FRAME_BUFFER - PAD_RANKED_BUFFER) duration:0.8795];
    } else {
        moveUp = [SKAction moveTo:CGPointMake(_rankedLabel.position.x, CGRectGetMidY(self.frame) - MID_FRAME_BUFFER - RANKED_LABEL_BUFFER) duration:0.8795];
    }
    [moveUp setTimingMode:SKActionTimingEaseOut];
    [_rankedLabel runAction:moveUp];
    SKAction *moveAway = [SKAction moveByX:0 y:32 duration:0.8795];
    [moveAway setTimingMode:SKActionTimingEaseOut];
    [_layerDifficultySelect enumerateChildNodesWithName:@"difficultySelect" usingBlock:^(SKNode *node, BOOL *stop) {
        [node runAction:moveAway];
    }];
}

#pragma mark - Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        
        if (CGRectContainsPoint(_onePlayer.frame, location)) {
            [_layerPlayersPick enumerateChildNodesWithName:@"playerSelect" usingBlock:^(SKNode *node, BOOL *stop) {
                [node runAction:_scaleDown];
                [node runAction:_fadeOut];
            }];
            
            [self runAction:[SKAction sequence:@[[SKAction waitForDuration:0.03],
                                                 [SKAction runBlock:^{
                [self showDifficultySelect];
            }]]]];
            [self runAction:_bleepSound];
        } else if (CGRectContainsPoint(_twoPlayer.frame, location)) {
            [self presentGamewithGameOption:@"twoplayer"];
            [self runAction:_bleepSound];
        } else if (CGRectContainsPoint(_twitterIcon.frame, location)) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:twitterURL]];
            [self runAction:_bleepSound];
        } else if (CGRectContainsPoint(_treehouseIcon.frame, location)) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:treehouseURL]];
            [self runAction:_bleepSound];
        } else if (CGRectContainsPoint(_easyLabel.frame, location)) {
            [self presentGamewithGameOption:@"easy"];
            [self runAction:_bleepSound];
        } else if (CGRectContainsPoint(_normalLabel.frame, location)) {
            [self presentGamewithGameOption:@"normal"];
            [self runAction:_bleepSound];
        } else if (CGRectContainsPoint(_hardLabel.frame, location)) {
            [self presentGamewithGameOption:@"hard"];
            [self runAction:_bleepSound];
        } else if (CGRectContainsPoint(_rankedLabel.frame, location)) {
            [self presentGamewithGameOption:@"ranked"];
            [self runAction:_bleepSound];
        } else if (CGRectContainsPoint(_gameCenterOnIcon.frame, location)) {
            [[RAGameKitHelper sharedGameKitHelper] showGKGameCenterViewController:self.view.window.rootViewController];
        }
    }
}

#pragma mark - Helper

-(void)setUpActions {
    _fadeIn = [SKAction fadeAlphaTo:1.0f duration:ACTION_DURATION];
    _fadeOut = [SKAction fadeAlphaTo:0.0f duration:ACTION_DURATION];
    _scaleUp = [SKAction scaleTo:1.0f duration:ACTION_DURATION];
    _scaleDown = [SKAction scaleTo:0.0f duration:ACTION_DURATION];
    _bleepSound = [SKAction playSoundFileNamed:@"blip.wav" waitForCompletion:NO];
}

#pragma mark - Presentation

- (void)presentGamewithGameOption:(NSString *)option {
    RAGameScene *gameScene;
    if ([option isEqual:@"easy"]) {
        gameScene = [[RAGameScene alloc] initWithSize:self.frame.size withDifficulty:1];
    } else if ([option isEqual:@"normal"]) {
        gameScene = [[RAGameScene alloc] initWithSize:self.frame.size withDifficulty:2];
    } else if ([option isEqual:@"hard"]) {
        gameScene = [[RAGameScene alloc] initWithSize:self.frame.size withDifficulty:3];
    } else if ([option isEqual:@"twoplayer"]) {
        gameScene = [[RAGameScene alloc] initWithSize:self.frame.size];
    } else if ([option isEqual:@"ranked"]) {
        gameScene = [[RAGameScene alloc] initWithSize:self.frame.size withDifficulty:4];
    }
    
    SKTransition *transition = [SKTransition fadeWithDuration:1.12];
    [self.view presentScene:gameScene transition:transition];
}

@end
