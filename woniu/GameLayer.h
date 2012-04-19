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

@interface GameLayer : CCLayer {
    
    b2World *world;
    b2Body *groundBody;
    b2Body *pig;
    b2Body *snail;
    
    b2MouseJoint *mouseJoint;
    b2LineJoint *lineJoint;
    
    GLESDebugDraw *m_debugDraw;
    
}
+(id)scene;
@end
