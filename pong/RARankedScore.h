//
//  RARankedScore.h
//  pong
//
//  Created by Ryan Ackermann on 9/15/14.
//  Copyright (c) 2014 Ryan Ackermann. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RARankedScore : NSObject <NSCoding>

@property (nonatomic, assign) NSInteger score;
@property (nonatomic, assign) NSInteger highScore;

+(instancetype)sharedRankedScore;
-(void)reset;
-(void)save;

@end
