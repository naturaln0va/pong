//
//  RAScoreUploadScene.m
//  pong
//
//  Created by Ryan Ackermann on 9/15/14.
//  Copyright (c) 2014 Ryan Ackermann. All rights reserved.
//

#import "RAScoreUploadScene.h"
#import "RAMenuScene.h"
#import "RAGameKitHelper.h"
#import "RARankedScore.h"

#define MID_SEPERATOR       111.0
#define FONT_SIZE           98.0
#define FONT_NAME_SIZE      53.0
#define FONT_NAME_BELOW     76.0
#define ARC4RANDOM_MAX      0x100000000

static NSString *const RankedLeaderBoardID = @"net.naturaln0va.pong_ranked_high_score";

static inline CGFloat ScalarRandomRange(CGFloat min, CGFloat max){
    return floorf(((double)arc4random() / ARC4RANDOM_MAX) * (max - min) + min);
}

@implementation RAScoreUploadScene {
    SKLabelNode *_currScoreLabel;
    SKLabelNode *_highScoreLabel;
    SKLabelNode *_highScoreName;
    SKLabelNode *_currScoreName;
    
}

- (instancetype)initWithSize:(CGSize)size withScore:(int)score {
    if (self = [super initWithSize:size]) {
        self.backgroundColor = [SKColor blackColor];
        
        if ([RARankedScore sharedRankedScore].score > [RARankedScore sharedRankedScore].highScore) {
            [RARankedScore sharedRankedScore].highScore = [RARankedScore sharedRankedScore].score;
            [[RARankedScore sharedRankedScore] save];
            // Play fireworks
            [self runAction:[SKAction repeatActionForever:[SKAction sequence:@[[SKAction runBlock:^{
                [self addParticleAtLocation:CGPointMake(ScalarRandomRange(CGRectGetMinX(self.frame),CGRectGetMaxX(self.frame)), ScalarRandomRange(CGRectGetMinY(self.frame),CGRectGetMaxY(self.frame))) withName:@"WinningConfetti"];
            }], [SKAction waitForDuration:0.15]]]]];
            // upload score to GameCenter!
            [self reportScoreToGameCenter];
        }
        
        _currScoreLabel = [SKLabelNode labelNodeWithFontNamed:@"Enhanced Dot Digital-7"];
        _currScoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
        _currScoreLabel.verticalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
        _currScoreLabel.position = CGPointMake(CGRectGetMidX(self.frame) - MID_SEPERATOR,
                                               CGRectGetMidY(self.frame));
        _currScoreLabel.fontColor = [SKColor whiteColor];
        _currScoreLabel.fontSize = FONT_SIZE;
        _currScoreLabel.text = [NSString stringWithFormat:@"%d", (int)[RARankedScore sharedRankedScore].score];
        [self addChild:_currScoreLabel];
        
        _highScoreLabel = [SKLabelNode labelNodeWithFontNamed:@"Enhanced Dot Digital-7"];
        _highScoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
        _highScoreLabel.verticalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
        _highScoreLabel.position = CGPointMake(CGRectGetMidX(self.frame) + MID_SEPERATOR,
                                               CGRectGetMidY(self.frame));
        _highScoreLabel.fontColor = [SKColor whiteColor];
        _highScoreLabel.fontSize = FONT_SIZE;
        _highScoreLabel.text = [NSString stringWithFormat:@"%d", (int)[RARankedScore sharedRankedScore].highScore];
        [self addChild:_highScoreLabel];
        
        _currScoreName = [SKLabelNode labelNodeWithFontNamed:@"Enhanced Dot Digital-7"];
        _currScoreName.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
        _currScoreName.verticalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
        _currScoreName.position = CGPointMake(CGRectGetMidX(self.frame) - (MID_SEPERATOR + 21),
                                              CGRectGetMidY(self.frame) - FONT_NAME_BELOW);
        _currScoreName.fontColor = [SKColor whiteColor];
        _currScoreName.fontSize = FONT_SIZE - FONT_NAME_SIZE;
        _currScoreName.text = @"Score";
        [self addChild:_currScoreName];
        
        _highScoreName = [SKLabelNode labelNodeWithFontNamed:@"Enhanced Dot Digital-7"];
        _highScoreName.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
        _highScoreName.verticalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
        _highScoreName.position = CGPointMake(CGRectGetMidX(self.frame) + (MID_SEPERATOR + 21),
                                              CGRectGetMidY(self.frame) - FONT_NAME_BELOW);
        _highScoreName.fontColor = [SKColor whiteColor];
        _highScoreName.fontSize = FONT_SIZE - FONT_NAME_SIZE;
        _highScoreName.text = @"High Score";
        [self addChild:_highScoreName];
        
        [self runAction:[SKAction sequence:@[[SKAction waitForDuration:1.252], [SKAction runBlock:^{
            [self returnToMenu];
        }]]]];
    }
    return self;
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

-(void)reportScoreToGameCenter {
    int64_t scoreToUpload = [RARankedScore sharedRankedScore].highScore;
    [[RAGameKitHelper sharedGameKitHelper] reportScore:scoreToUpload
                                      forLeaderboardID:RankedLeaderBoardID];
}

-(void)returnToMenu {
    [[RARankedScore sharedRankedScore] save];
    [[RARankedScore sharedRankedScore] reset];
    RAMenuScene *menuScene = [RAMenuScene sceneWithSize:self.frame.size];
    SKTransition *transition = [SKTransition fadeWithDuration:1.12];
    [self.view presentScene:menuScene transition:transition];
}

@end