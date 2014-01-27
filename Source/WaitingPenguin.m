//
//  WaitingPenguin.m
//  PeevedPenguins
//
//  Created by Lee Tze Cheun on 1/27/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "WaitingPenguin.h"

@implementation WaitingPenguin

// We want the waiting penguins to animate randomly, instead of animating at
// the same time. So, we set a random delay to start animation for each penguin.
- (void)didLoadFromCCB
{
    // Generate a random delay between 0.0 and 2.0 seconds.
    CGFloat randomDelayInSeconds = (arc4random() % 2000) / 1000.f;

    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(randomDelayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        // The animation manager of each node is stored in the user object property.
        CCBAnimationManager *animationManager = self.userObject;

        // Run animations for the timeline we named in SpriteBuilder.
        [animationManager runAnimationsForSequenceNamed:@"BlinkAndJump"];
    });
}

@end
