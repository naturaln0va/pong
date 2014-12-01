//
//  RARankedScore.m
//  pong
//
//  Created by Ryan Ackermann on 9/15/14.
//  Copyright (c) 2014 Ryan Ackermann. All rights reserved.
//

#import "RARankedScore.h"

static NSString *const RARankedHighScoreKey = @"highscore";

@implementation RARankedScore

+(instancetype)sharedRankedScore {
    static id sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self loadInstance];
    });
    
    return sharedInstance;
}

-(void)reset {
    _score = 0;
}

-(instancetype)initWithCoder:(NSCoder *)decoder {
    self = [self init];
    if (self) {
        _highScore = [decoder decodeIntegerForKey:RARankedHighScoreKey];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInteger:_highScore forKey:RARankedHighScoreKey];
}

+(NSString*)filePath {
    static NSString* filePath = nil;
    if (!filePath) {
        filePath =
        [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]
         stringByAppendingPathComponent:@"SecretScoreData"];
    }
    return filePath;
}

+(instancetype)loadInstance {
    NSData* decodedData = [NSData dataWithContentsOfFile: [RARankedScore filePath]];
    if (decodedData) {
        RARankedScore* gameData = [NSKeyedUnarchiver unarchiveObjectWithData:decodedData];
        return gameData;
    }
    return [[RARankedScore alloc] init];
}

-(void)save {
    NSData* encodedData = [NSKeyedArchiver archivedDataWithRootObject: self];
    [encodedData writeToFile:[RARankedScore filePath] atomically:YES];
}

@end
