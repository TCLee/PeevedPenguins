//
//  Seal.m
//  PeevedPenguins
//
//  Created by Lee Tze Cheun on 1/24/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Seal.h"

@implementation Seal

- (void)didLoadFromCCB
{
    self.physicsBody.collisionType = @"seal";
}

@end
