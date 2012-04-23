//
//  GameLayer.m
//  woniu
//
//  Created by cocoa on 12-4-17.
//  Copyright 2012年 __MyCompanyName__. All rights reserved.
//

#import "GameLayer.h"
#import "VRope.h"


#define PTM_RATIO 32.0


#define MAXLENGTH 5.5f

enum{
    kTagTileMap=1,
    kTagBatchNode=1,
    kTagAnimation=1,
};


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
        //CGSize winSize=[[CCDirector sharedDirector] winSize];
        
        //Create pig sprite
        CCSprite *pigSprite=[CCSprite spriteWithFile:@"Icon-Small.png"];
        pigSprite.position=ccp(100,100);
        [self addChild:pigSprite];
        
        //Create snail sprite
        CCSprite *snailSprite=[CCSprite spriteWithFile:@"blocks.png" rect: CGRectMake(0,0,32,32)];
        snailSprite.position=ccp(200,100);
        [self addChild:snailSprite];
        
        [self initPhysics];
        
        //Create the pig
        b2BodyDef pigBodyDef;
        pigBodyDef.type=b2_dynamicBody;
        pigBodyDef.position.Set(100/PTM_RATIO,100/PTM_RATIO);
        pigBodyDef.userData=pigSprite;
        pig=world->CreateBody(&pigBodyDef);
        
        b2CircleShape circle;
        circle.m_radius=26/PTM_RATIO;
        
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
        snailBodyDef.position.Set(200/PTM_RATIO, 100/PTM_RATIO);
        snailBodyDef.userData=snailSprite;
        snail=world->CreateBody(&snailBodyDef);
        
        b2CircleShape snailShape;
        snailShape.m_radius=26/PTM_RATIO;
        
        b2FixtureDef snailShapeDef;
        snailShapeDef.shape=&snailShape;
        snailShapeDef.density=2.0f;
        snailShapeDef.friction=0.2f;
        snailShapeDef.restitution=0.0f;
        snail->CreateFixture(&snailShapeDef);
        
        [self createSpriteSheet];
        [self createRope];
        
        //set the tick function
        [self schedule:@selector(tick:)];
        
    }
    return self;
}
-(void) initPhysics
{
	
	CGSize s = [[CCDirector sharedDirector] winSize];
	
	b2Vec2 gravity;
	gravity.Set(0.0f, -10.0f);
	world = new b2World(gravity);
	
	
	// Do we want to let bodies sleep?
	world->SetAllowSleeping(true);
	
	world->SetContinuousPhysics(true);
	
	m_debugDraw = new GLESDebugDraw( PTM_RATIO );
	world->SetDebugDraw(m_debugDraw);
	
	uint32 flags = 0;
	flags += b2Draw::e_shapeBit;
			flags += b2Draw::e_jointBit;
	//		flags += b2Draw::e_aabbBit;
	//		flags += b2Draw::e_pairBit;
	//		flags += b2Draw::e_centerOfMassBit;
	m_debugDraw->SetFlags(flags);		
	
	
	// Define the ground body.
	b2BodyDef groundBodyDef;
	groundBodyDef.position.Set(0, 0); // bottom-left corner
	
	// Call the body factory which allocates memory for the ground body
	// from a pool and creates the ground box shape (also from a pool).
	// The body is also added to the world.
	groundBody = world->CreateBody(&groundBodyDef);
	
	// Define the ground box shape.
	b2EdgeShape groundBox;		
	
	// bottom
	
	groundBox.Set(b2Vec2(0,0), b2Vec2(s.width/PTM_RATIO,0));
	groundBody->CreateFixture(&groundBox,0);
	
	// top
	groundBox.Set(b2Vec2(0,s.height/PTM_RATIO), b2Vec2(s.width/PTM_RATIO,s.height/PTM_RATIO));
	groundBody->CreateFixture(&groundBox,0);
	
	// left
	groundBox.Set(b2Vec2(0,s.height/PTM_RATIO), b2Vec2(0,0));
	groundBody->CreateFixture(&groundBox,0);
	
	// right
	groundBox.Set(b2Vec2(s.width/PTM_RATIO,s.height/PTM_RATIO), b2Vec2(s.width/PTM_RATIO,0));
	groundBody->CreateFixture(&groundBox,0);
}
-(void)tick:(ccTime) dt{
    world->Step(dt, 10, 10);
    for (b2Body *b=world->GetBodyList(); b;b=b->GetNext()) {
        if(b->GetUserData()!=NULL)
        {
            CCSprite *sprite=(CCSprite *)b->GetUserData();
            sprite.position= ccp( b->GetPosition().x * PTM_RATIO , b->GetPosition().y * PTM_RATIO);
            sprite.rotation=-1*CC_RADIANS_TO_DEGREES(b->GetAngle());
        }
    }
    
    //+++ Update rope physics
    [myRope update:dt];
}
-(void) draw
{
	//
	// IMPORTANT:
	// This is only for debug purposes
	// It is recommend to disable it
	//
	[super draw];
	
	ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position );
	
	kmGLPushMatrix();
	
	world->DrawDebugData();	
	
	kmGLPopMatrix();
    
    //+++Update rope sprites
    [myRope updateSprites];
}
-(void) createSpriteSheet{
    
    ropeSpriteSheet =[CCSpriteBatchNode batchNodeWithFile:@"rope.png"];
    [self addChild:ropeSpriteSheet];
    
    
    
}
-(void) createRope
{
    b2RopeJointDef jd;
    jd.bodyA=pig;
    jd.bodyB=snail;
    jd.localAnchorA=b2Vec2(0,0);
    jd.localAnchorB=b2Vec2(0,0);
    //jd.maxLength=(pig->GetPosition() - snail->GetPosition()).Length();
    jd.maxLength=MAXLENGTH;
    world->CreateJoint(&jd);
    myRope = [[VRope alloc] init:pig body2:snail spriteSheet:ropeSpriteSheet];
}
-(void) addNewSpriteWithCoords:(CGPoint)p
{
    CCLOG(@"Add sprite %0.2f x %0.2f",p.x,p.y);
    CCSpriteBatchNode *batch =(CCSpriteBatchNode *) [self getChildByTag:kTagBatchNode];
    
    //We have a 64*64 sprite sheet with 4 different 32*32 images. The folowing code is 
    //just randommly picking one of the images
    
    int idx=(CCRANDOM_0_1() > .5 ? 0:1);
    int idy=(CCRANDOM_0_1() > .5 ? 0:1);
    CCSprite *sprite =[CCSprite spriteWithTexture:[batch texture] rect:CGRectMake(32*idx, 32*idy, 32, 32)];
    [batch addChild:sprite];
    
    sprite.position=ccp(p.x,p.y);
    
    //Define the dynamic body.
    //Set up a 1m squarmd box in the physics world
    
    b2BodyDef bodyDef;
    bodyDef.type=b2_dynamicBody;
    bodyDef.position.Set(p.x/PTM_RATIO, p.y/PTM_RATIO);
    bodyDef.userData=sprite;
    b2Body *body=world->CreateBody(&bodyDef);
    
    //define another box shape for our dynamic body.
    b2PolygonShape dynamicBox;
    dynamicBox.SetAsBox(.5f, .5f);  //These are mid points for our 1m box
    
    //Define the dynamic body fixture.
    b2FixtureDef fixtureDef;
    fixtureDef.shape=&dynamicBox;
    fixtureDef.density=1.0f;
    fixtureDef.friction=0.3f;
    body->CreateFixture(&fixtureDef);
    
    //+++Create box2d joint;
    b2RopeJointDef jd;
    jd.bodyA=anchorBody;
    jd.bodyB=body;
    
    jd.localAnchorA=b2Vec2(0,0);
    jd.localAnchorA=b2Vec2(0,0);
    
    //define max length of joint =current distance between bodys
    jd.maxLength=(body->GetPosition() - anchorBody->GetPosition()).Length();
    
    world->CreateJoint(&jd);
    
    //+++ Create VRope with two b2bodies and pointer to spritesheet
    
    VRope *newRope =[[VRope alloc] init:anchorBody body2:body spriteSheet:ropeSpriteSheet];
    [vRopes addObject:newRope];
    
}
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    
    if(mouseJoint!=nil) return;
    
    UITouch *myTouch=[touches anyObject];
    CGPoint location=[myTouch locationInView:[myTouch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    b2Vec2 locationWorld=b2Vec2(location.x/PTM_RATIO,location.y/PTM_RATIO);
    
    b2Fixture *pigFix=pig->GetFixtureList();
    if(pigFix->TestPoint(locationWorld))
    {
        b2MouseJointDef md;
        md.bodyA=groundBody;
        md.bodyB=pig;
        md.target=locationWorld;
        md.collideConnected=true;
        md.maxForce=1000.0f * pig->GetMass();
        mouseJoint=(b2MouseJoint*)world->CreateJoint(&md);
        return;
    }
    
    b2Fixture *SnailFix=snail->GetFixtureList();
    if(SnailFix->TestPoint(locationWorld))
    {
        b2MouseJointDef md;
        md.bodyA=groundBody;
        md.bodyB=snail;
        md.target=locationWorld;
        md.collideConnected=true;
        md.maxForce=1000.0f * pig->GetMass();
        mouseJoint=(b2MouseJoint*)world->CreateJoint(&md);
    }
}
-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    if(mouseJoint==nil) return;
    UITouch *myTouch=[touches anyObject];
    CGPoint location=[myTouch locationInView:[myTouch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    b2Vec2 locationWorld=b2Vec2(location.x/PTM_RATIO,location.y/PTM_RATIO);
    
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
