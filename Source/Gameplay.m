//
//  Gameplay.m
//  PeevedPenguins
//
//  Created by Lee Tze Cheun on 1/24/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Gameplay.h"
#import "Penguin.h"

/**
 * The minimum speed which we will use to check if a penguin is slow 
 * enough for the round to end.
 */
static const CGFloat MIN_SPEED = 5.f;

@implementation Gameplay {

@private
    CCPhysicsNode *_physicsNode;
    CCPhysicsJoint *_catapultJoint;
    CCPhysicsJoint *_pullbackJoint;
    CCPhysicsJoint *_mouseJoint;
    CCPhysicsJoint *_penguinCatapultJoint;
    CCNode *_catapult;
    CCNode *_catapultArm;
    CCNode *_levelNode;
    CCNode *_contentNode;
    CCNode *_pullbackNode;
    CCNode *_mouseJointNode;
    Penguin *_currentPenguin;
    CCAction *_followPenguinAction;
}

#pragma mark - Cocos2d Events

// This method is called when the Gameplay CCB file has been loaded.
- (void)didLoadFromCCB
{
    _physicsNode.collisionDelegate = self;

    // Tell this scene we want to accept touches.
    self.userInteractionEnabled = YES;

    // Load our first level.
    CCScene *levelScene = [CCBReader loadAsScene:@"levels/level1"];
    [_levelNode addChild:levelScene];

    // Uncomment to have cocos2d draw debug rects for the physics objects.
//    _physicsNode.debugDraw = YES;

    // Physics object in the same collision group do not collide.
    // We do not want the catapult arm and the catapult to collide.
    [_catapultArm.physicsBody setCollisionGroup:_catapult];
    [_catapult.physicsBody setCollisionGroup:_catapult];

    // Create a joint to connect the catapult arm with the catapult.
    _catapultJoint = [CCPhysicsJoint connectedPivotJointWithBodyA:_catapultArm.physicsBody
                                                            bodyB:_catapult.physicsBody
                                                          anchorA:_catapultArm.anchorPointInPoints];

    // We don't want anything to collide with our invisible node.
    _pullbackNode.physicsBody.collisionMask = @[];
    _mouseJointNode.physicsBody.collisionMask = @[];

    // Create a spring joint for bringing arm in upright position and
    // snapping back to original position after player shoots.
    _pullbackJoint = [CCPhysicsJoint connectedSpringJointWithBodyA:_pullbackNode.physicsBody
                                                             bodyB:_catapultArm.physicsBody
                                                           anchorA:ccp(0, 0)
                                                           anchorB:ccp(34, 138)
                                                        restLength:60.f
                                                         stiffness:500.f
                                                           damping:40.f];
}

// This method is called by cocos2d for every frame.
- (void)update:(CCTime)delta
{
    // If the penguin has not been fired from the catapult yet, there's no
    // need to perform any checks or calculations.
    if (!_currentPenguin.launched) {
        return;
    }

    // If penguin has slowed down below minimum speed or penguin has exited
    // the world's boundary, then we will start the next round.
    if (TCVelocityIsBelowMinSpeed(_currentPenguin.physicsBody.velocity, MIN_SPEED) ||
        TCPenguinHasExitedWorldBoundary(_currentPenguin.boundingBox, self.boundingBox)) {
        [self nextAttempt];
    }
}

/**
 * Starts the next round for the player to attempt again.
 */
- (void)nextAttempt
{
    // Starting the next round, so remove the reference to the current penguin.
    _currentPenguin = nil;

    // Stop the scrolling action that follows the penguin.
    [_contentNode stopAction:_followPenguinAction];

    // Scroll back the screen to the catapult.
    CCActionMoveTo *scrollBackAction = [CCActionMoveTo actionWithDuration:1.f
                                                                 position:ccp(0, 0)];
    [_contentNode runAction:scrollBackAction];
}

/**
 * Returns \c YES if velocity is slower than the given minimum speed; \c NO otherwise.
 */
FOUNDATION_STATIC_INLINE BOOL TCVelocityIsBelowMinSpeed(CGPoint velocity, CGFloat minSpeed)
{
    return (abs(velocity.x) < minSpeed && abs(velocity.y) < minSpeed);
}

/**
 * Returns \c YES if penguin has exited the world boundary; \c NO othwerwise.
 */
FOUNDATION_STATIC_INLINE BOOL TCPenguinHasExitedWorldBoundary(CGRect penguinRect, CGRect worldRect)
{
    NSRange worldRange = NSMakeRange(worldRect.origin.x, worldRect.size.width);
    NSRange penguinRange = NSMakeRange(penguinRect.origin.x, penguinRect.size.width);

    return (penguinRange.location < worldRange.location ||
            NSMaxRange(penguinRange) > NSMaxRange(worldRange));
}

#pragma mark - Touch Events

// User begins dragging the catapult arm.
- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchLocation = [touch locationInNode:_contentNode];

    // Check if the user has dragged on the catapult arm.
    if (CGRectContainsPoint([_catapultArm boundingBox], touchLocation)) {
        _mouseJointNode.position = touchLocation;

        // Setup a spring joint between the mouse joint node and the catapult arm.
        _mouseJoint = [CCPhysicsJoint connectedSpringJointWithBodyA:_mouseJointNode.physicsBody
                                                              bodyB:_catapultArm.physicsBody
                                                            anchorA:ccp(0, 0)
                                                            anchorB:ccp(34, 138)
                                                         restLength:0.f
                                                          stiffness:3000.f
                                                            damping:150.f];

        _currentPenguin = (Penguin *)[CCBReader load:@"Penguin"];

        // Initially, position the penguin on the scoop of the catapult arm.
        // We need to translate the penguin position to the physics node
        // space coordinates because the penguin node is the child of the physics node.
        CGPoint penguinPosition = [_catapultArm convertToWorldSpace:ccp(34, 138)];
        _currentPenguin.position = [_physicsNode convertToNodeSpace:penguinPosition];

        [_physicsNode addChild:_currentPenguin];

        // We do not want the penguin to rotate while it is sitting on
        // the scoop of the catapult arm.
        _currentPenguin.physicsBody.allowsRotation = NO;

        // Create a joint to keep the penguin fixed to the scoop of the
        // catapult arm, until the catapult is released.
        _penguinCatapultJoint = [CCPhysicsJoint connectedPivotJointWithBodyA:_currentPenguin.physicsBody
                                                                       bodyB:_catapultArm.physicsBody
                                                                     anchorA:_currentPenguin.anchorPointInPoints];
    }
}

// User continues to drag the catapult arm.
- (void)touchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchLocation = [touch locationInNode:_contentNode];

    // Update the mouse joint node location, so that the catapult arm is
    // dragged in the correct direction.
    _mouseJointNode.position = touchLocation;
}

// When player releases their finger from the screen, release the catapult.
- (void)touchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    [self releaseCatapult];
}

// If player's touch has been cancelled for whatever reason, we also release
// the catapult.
- (void)touchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
    [self releaseCatapult];
}

- (void)releaseCatapult
{
    _currentPenguin.launched = YES;

    if (nil != _mouseJoint) {
        // Releases the mouse joint to let the catapult arm snap
        // back to original position.
        [_mouseJoint invalidate];
        _mouseJoint = nil;

        // Releases the joint and lets the penguin fly.
        [_penguinCatapultJoint invalidate];
        _penguinCatapultJoint = nil;

        // After releasing the penguin from the catapult, we will enable
        // rotation again.
        _currentPenguin.physicsBody.allowsRotation = YES;

        // Make the camera follow the flying penguin.
        _followPenguinAction = [CCActionFollow actionWithTarget:_currentPenguin
                                                  worldBoundary:self.boundingBox];
        [_contentNode runAction:_followPenguinAction];
    }
}

#pragma mark - CCPhysicsCollisionDelegate

- (void)ccPhysicsCollisionPostSolve:(CCPhysicsCollisionPair *)pair
                               seal:(CCNode *)nodeA
                           wildcard:(CCNode *)nodeB
{
    CGFloat energy = [pair totalKineticEnergy];

    // If seal was hit hard enough, we will remove the seal from the scene.
    if (energy > 5000.f) {
        [self sealRemoved:nodeA];
    }
}

- (void)sealRemoved:(CCNode *)seal
{
    // Load the explosion particle effect.
    CCParticleSystem *explosion = (CCParticleSystem *)[CCBReader load:@"SealExplosion"];

    // The particle effect will be removed from the scene on completion.
    explosion.autoRemoveOnFinish = YES;

    // Place the particle effect at the seal's position.
    explosion.position = seal.position;

    // Add the explosion particle effect to the same parent node as the seal.
    [seal.parent addChild:explosion];

    // Finally, we're done with the seal node. So, remove it.
    [seal removeFromParent];
}

#pragma mark - Button Action

// When user taps the Restart button we will reset the level.
- (void)retry
{
    [[CCDirector sharedDirector] replaceScene:
     [CCBReader loadAsScene:@"Gameplay"]];
}

@end
