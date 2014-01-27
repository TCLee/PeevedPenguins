//
//  Penguin.h
//  PeevedPenguins
//
//  Created by Lee Tze Cheun on 1/24/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCSprite.h"

@interface Penguin : CCSprite

/**
 * A boolean value that determines whether the penguin has been 
 * launched yet or not.
 */
@property (nonatomic, assign, getter = isLaunched) BOOL launched;

@end
