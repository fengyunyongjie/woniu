//
//  GameLayer.m
//  woniu
//
//  Created by cocoa on 12-4-17.
//  Copyright 2012年 __MyCompanyName__. All rights reserved.
//

#import "GameLayer.h"
#define PTM_RARIO 32.0

@implementation GameLayer

+(id)scene{
    CCScene *scene=[CCScene node];
    GameLayer *layer=[GameLayer node];
    [scene addChild:layer];
    return scene;
}
-(id)init{
    if((self=[super init]))
    {
        self.isTouchEnabled=YES;
        CGSize winSize=[[CCDirector sharedDirector] winSize];
        
        //Create pig sprite
        CCSprite *pigSprite=[CCSprite spriteWithFile:@"Icon-Small.png"];
        pigSprite.position=ccp(100,100);
        [self addChild:pigSprite];
        
        //Create snail sprite
        CCSprite *snailSprite=[CCSprite spriteWithFile:@"blocks.png" rect: CGRectMake(0,0,32,32)];
        snailSprite.position=ccp(200,100);
        [self addChild:snailSprite];
        
        //Create a world
        
        b2Vec2 gravity =b2Vec2(0.0f,-30.0f);
        bool doSleep=true;
        world=new b2World(gravity,doSleep);
        
        m_debugDraw=new GLESDebugDraw(PTM_RARIO);
        world->SetDebugDraw(m_debugDraw);
        uint32 flags = 0;
        flags += b2DebugDraw::e_shapeBit;
        m_debugDraw->SetFlags(flags);
        
        //Create edges around the entire screen
        
        b2BodyDef groundBodyDef;
        groundBodyDef.position.Set(0, 0);
        groundBody =world->CreateBody(&groundBodyDef);
        
        b2PolygonShape groundBox;
        b2FixtureDef boxShapeDef;
        boxShapeDef.shape=&groundBox;
        
        //bottom
        groundBox.SetAsEdge(b2Vec2(0,0), b2Vec2(winSize.width/PTM_RARIO,0));
        groundBody->CreateFixture(&boxShapeDef);
        
        //left
        groundBox.SetAsEdge(b2Vec2(0,0), b2Vec2(0,winSize.height/PTM_RARIO));
        groundBody->CreateFixture(&boxShapeDef);
        
        //up
        groundBox.SetAsEdge(b2Vec2(0,winSize.height/PTM_RARIO), b2Vec2(winSize.width/PTM_RARIO,winSize.height/PTM_RARIO));
        groundBody->CreateFixture(&boxShapeDef);
        
        //right
        groundBox.SetAsEdge(b2Vec2(winSize.width/PTM_RARIO,0), b2Vec2(winSize.width/PTM_RARIO,winSize.height/PTM_RARIO));
        groundBody->CreateFixture(&boxShapeDef);
        
        
        //Create the pig
        b2BodyDef pigBodyDef;
        pigBodyDef.type=b2_dynamicBody;
        pigBodyDef.position.Set(100/PTM_RARIO,100/PTM_RARIO);
        pigBodyDef.userData=pigSprite;
        pig=world->CreateBody(&pigBodyDef);
        
        b2CircleShape circle;
        circle.m_radius=26/PTM_RARIO;
        
        b2FixtureDef pigShapeDef;
        pigShapeDef.shape=&circle;
        pigShapeDef.density=2.0f;
        pigShapeDef.friction=0.2f;
        pigShapeDef.restitution=0.0f;
        pig->CreateFixture(&pigShapeDef);
        
        b2Vec2 velocity= b2Vec2(0.5f,0);
        pig->SetLinearVelocity(velocity);
        
        //Create the snail
        b2BodyDef snailBodyDef;
        snailBodyDef.type=b2_dynamicBody;
        snailBodyDef.position.Set(200/PTM_RARIO, 100/PTM_RARIO);
        snailBodyDef.userData=snailSprite;
        snail=world->CreateBody(&snailBodyDef);
        
        b2CircleShape snailShape;
        snailShape.m_radius=26/PTM_RARIO;
        
        b2FixtureDef snailShapeDef;
        snailShapeDef.shape=&snailShape;
        snailShapeDef.density=2.0f;
        snailShapeDef.friction=0.2f;
        snailShapeDef.restitution=0.0f;
        snail->CreateFixture(&snailShapeDef);
        
        //set the tick function
        [self schedule:@selector(tick:)];
        
    }
    return self;
}
-(void)tick:(ccTime) dt{
    world->Step(dt, 10, 10);
    for (b2Body *b=world->GetBodyList(); b;b=b->GetNext()) {
        if(b->GetUserData()!=NULL)
        {
            CCSprite *sprite=(CCSprite *)b->GetUserData();
            sprite.position= ccp( b->GetPosition().x * PTM_RARIO , b->GetPosition().y * PTM_RARIO);
            sprite.rotation=-1*CC_RADIANS_TO_DEGREES(b->GetAngle());
        }
    }
}
-(void) draw {
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_COLOR_ARRAY);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	
	world->DrawDebugData();
	
	// restore default GL states
	glEnable(GL_TEXTURE_2D);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
}
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    
    if(mouseJoint!=nil) return;
    
    UITouch *myTouch=[touches anyObject];
    CGPoint location=[myTouch locationInView:[myTouch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    b2Vec2 locationWorld=b2Vec2(location.x/PTM_RARIO,location.y/PTM_RARIO);
    
    b2MouseJointDef md;
    md.bodyA=groundBody;
    md.bodyB=pig;
    md.target=locationWorld;
    md.maxForce=1000.0f * pig->GetMass();
    mouseJoint=(b2MouseJoint*)world->CreateJoint(&md);
}
-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    if(mouseJoint==nil) return;
    UITouch *myTouch=[touches anyObject];
    CGPoint location=[myTouch locationInView:[myTouch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    b2Vec2 locationWorld=b2Vec2(location.x/PTM_RARIO,location.y/PTM_RARIO);
    
    mouseJoint->SetTarget(locationWorld);
}
-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    if(mouseJoint!=nil){
        world->DestroyJoint(mouseJoint);
        mouseJoint=nil;
    }
}
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	delete world;
	world = NULL;
	
	delete m_debugDraw;
	
	// don't forget to call "super dealloc"
	[super dealloc];
}
@end
