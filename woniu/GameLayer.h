//
//  GameLayer.h
//  woniu
//
//  Created by cocoa on 12-4-17.
//  Copyright 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Box2D.h"
#import "GLES-Render.h"
#import "VRope.h"

@interface GameLayer : CCLayer {
    
    b2World *world;
    b2Body *groundBody;
    b2Body *pig;
    b2Body *snail;
    
    b2MouseJoint *mouseJoint;
    
    GLESDebugDraw *m_debugDraw;
    
    b2Body *anchorBody;
    CCSpriteBatchNode * ropeSpriteSheet;
    NSMutableArray* vRopes;

    VRope *myRope;
}
+(id)scene;

-(void) addNewSpriteWithCoords:(CGPoint)p;
@end
