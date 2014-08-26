//
//  RAPaddle.m
//  pong
//
//  Created by Ryan Ackermann on 8/26/14.
//  Copyright (c) 2014 Ryan Ackermann. All rights reserved.
//

#import "RAPaddle.h"

@implementation RAPaddle

- (instancetype)initAtPosistion:(CGPoint)position {
    RAPaddle *paddle = [RAPaddle spriteNodeWithImageNamed:@"Paddle"];
    
    
    return paddle;
}

@end
