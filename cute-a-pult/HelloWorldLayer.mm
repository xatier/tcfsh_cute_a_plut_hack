//
//  HelloWorldLayer.mm
//  cute-a-pult
//
//  Created by Gustavo Ambrozio on 23/8/11.
//  Copyright CodeCrop Software 2011. All rights reserved.
//


// Import the interfaces
#import "HelloWorldLayer.h"
#import "GameOverScene.h"

//Pixel to metres ratio. Box2D uses metres as the unit for measurement.
//This ratio defines how many pixels correspond to 1 Box2D "metre"
//Box2D is optimized for objects of 1x1 metre therefore it makes sense
//to define the ratio so that your most common object type is 1x1 metre.
#define PTM_RATIO 32
#define FLOOR_HEIGTH    62.0f

// enums that will be used as tags
enum {
	kTagTileMap    = 1,
	kTagBatchNode  = 1,
	kTagAnimation1 = 1,
};

/* change the value of this, and you'll get some extra points */
int kerker;

@interface HelloWorldLayer()

- (void)resetGame;
- (void)createBullets:(int)count;
- (BOOL)attachBullet;
- (void)createTargets;
- (void)canYouFindMe;

@end

// HelloWorldLayer implementation
@implementation HelloWorldLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
    kerker = 0;
    foo = @"QQQQ";
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init])) {
		
		// enable touches
		self.isTouchEnabled = YES;
				
		CGSize screenSize = [CCDirector sharedDirector].winSize;
		CCLOG(@"Screen width %0.2f screen height %0.2f",screenSize.width,screenSize.height);
		
		// Define the gravity vector.
		b2Vec2 gravity;
		gravity.Set(0.0f, -10.0f);
		
		// Do we want to let bodies sleep?
		// This will speed up the physics simulation
		bool doSleep = true;
		
		// Construct a world object, which will hold and simulate the rigid bodies.
		world = new b2World(gravity, doSleep);
		
		world->SetContinuousPhysics(true);
		
		// Debug Draw functions
		m_debugDraw = new GLESDebugDraw( PTM_RATIO );
		world->SetDebugDraw(m_debugDraw);
		
		uint32 flags = 0;
		flags += b2DebugDraw::e_shapeBit;
		m_debugDraw->SetFlags(flags);		
		
        CCSprite *sprite = [CCSprite spriteWithFile:@"bg.png"];
        sprite.anchorPoint = CGPointZero;
        [self addChild:sprite z:-1];
        
        sprite = [CCSprite spriteWithFile:@"catapult_base_2.png"];
        sprite.anchorPoint = CGPointZero;
        sprite.position = CGPointMake(181.0f, FLOOR_HEIGTH);
        [self addChild:sprite z:0];
		
        sprite = [CCSprite spriteWithFile:@"squirrel_1.png"];
        sprite.anchorPoint = CGPointZero;
        sprite.position = CGPointMake(11.0f, FLOOR_HEIGTH);
        [self addChild:sprite z:0];
		
        sprite = [CCSprite spriteWithFile:@"catapult_base_1.png"];
        sprite.anchorPoint = CGPointZero;
        sprite.position = CGPointMake(181.0f, FLOOR_HEIGTH);
        [self addChild:sprite z:9];
		
        sprite = [CCSprite spriteWithFile:@"squirrel_2.png"];
        sprite.anchorPoint = CGPointZero;
        sprite.position = CGPointMake(240.0f, FLOOR_HEIGTH);
        [self addChild:sprite z:9];
		
        sprite = [CCSprite spriteWithFile:@"fg.png"];
        sprite.anchorPoint = CGPointZero;
        [self addChild:sprite z:10];
		
		// Define the ground body.
		b2BodyDef groundBodyDef;
		groundBodyDef.position.Set(0, 0); // bottom-left corner
		
		// Call the body factory which allocates memory for the ground body
		// from a pool and creates the ground box shape (also from a pool).
		// The body is also added to the world.
		groundBody = world->CreateBody(&groundBodyDef);
		
		// Define the ground box shape.
		b2PolygonShape groundBox;		
		
		// bottom
		groundBox.SetAsEdge(b2Vec2(0,FLOOR_HEIGTH/PTM_RATIO), b2Vec2(screenSize.width*2.0f/PTM_RATIO,FLOOR_HEIGTH/PTM_RATIO));
		groundBody->CreateFixture(&groundBox,0);
		
		// top
		groundBox.SetAsEdge(b2Vec2(0,screenSize.height/PTM_RATIO), b2Vec2(screenSize.width*2.0f/PTM_RATIO,screenSize.height/PTM_RATIO));
		groundBody->CreateFixture(&groundBox,0);
		
		// left
		groundBox.SetAsEdge(b2Vec2(0,screenSize.height/PTM_RATIO), b2Vec2(0,0));
		groundBody->CreateFixture(&groundBox,0);
		
        // Create the catapult's arm
        CCSprite *arm = [CCSprite spriteWithFile:@"catapult_arm.png"];
        [self addChild:arm z:1];
        
        b2BodyDef armBodyDef;
        armBodyDef.type = b2_dynamicBody;
        armBodyDef.linearDamping = 1;
        armBodyDef.angularDamping = 1;
        armBodyDef.position.Set(230.0f/PTM_RATIO,(FLOOR_HEIGTH+91.0f)/PTM_RATIO);
        armBodyDef.userData = arm;
        armBody = world->CreateBody(&armBodyDef);
        
        b2PolygonShape armBox;
        b2FixtureDef armBoxDef;
        armBoxDef.shape = &armBox;
        armBoxDef.density = 0.3F;
        armBox.SetAsBox(11.0f/PTM_RATIO, 91.0f/PTM_RATIO);
        armFixture = armBody->CreateFixture(&armBoxDef);
		
        // Create a joint to fix the catapult to the floor.
        b2RevoluteJointDef armJointDef;
        armJointDef.Initialize(groundBody, armBody, b2Vec2(233.0f/PTM_RATIO, FLOOR_HEIGTH/PTM_RATIO));
        armJointDef.enableMotor = true;
        armJointDef.enableLimit = true;
        armJointDef.motorSpeed  = -10;
        armJointDef.lowerAngle  = CC_DEGREES_TO_RADIANS(9);
        armJointDef.upperAngle  = CC_DEGREES_TO_RADIANS(75);
        armJointDef.maxMotorTorque = 700;
        
        armJoint = (b2RevoluteJoint*)world->CreateJoint(&armJointDef);

		[self schedule: @selector(tick:)];
        [self schedule: @selector(show_score:)];
        [self performSelector:@selector(resetGame) withObject:nil afterDelay:0.5f];

        contactListener = new MyContactListener();
        world->SetContactListener(contactListener);
        
        /* game score */
        score_label =[CCLabelTTF labelWithString:@"score: 0" fontName:@"Arial" fontSize:32];
        [self addChild: score_label];
        score_label.position = CGPointMake (200, 300);
        score_label.color = ccBLUE;

        score = 0;
	}
	return self;
}

- (void)resetGame
{
    // Previous bullets cleanup
    if (bullets)
    {
        for (NSValue *bulletPointer in bullets)
        {
            b2Body *bullet = (b2Body*)[bulletPointer pointerValue];
            CCNode *node = (CCNode*)bullet->GetUserData();
            [self removeChild:node cleanup:YES];
            world->DestroyBody(bullet);
        }
        [bullets release];
        bullets = nil;
    }

    // Previous targets cleanup
    if (targets)
    {
        for (NSValue *bodyValue in targets)
        {
            b2Body *body = (b2Body*)[bodyValue pointerValue];
            CCNode *node = (CCNode*)body->GetUserData();
            [self removeChild:node cleanup:YES];
            world->DestroyBody(body);
        }
        
        [targets release];
        [enemies release];
        targets = nil;
        enemies = nil;
    }

    // 4 bullets
    [self createBullets:4];
    [self createTargets];
    [self runAction:[CCSequence actions:
                     [CCMoveTo actionWithDuration:1.5f position:CGPointMake(-480.0f, 0.0f)], 
                     [CCCallFuncN actionWithTarget:self selector:@selector(attachBullet)],
                     [CCDelayTime actionWithDuration:1.0f],
                     [CCMoveTo actionWithDuration:1.5f position:CGPointZero],
                     nil]];
}

- (void)createBullets:(int)count
{
    // currentBullet form 0 to 4, the game will be ended when the value == 4
    currentBullet = 0;
    CGFloat pos = 62.0f;
    
    if (count > 0)
    {
        // delta is the spacing between corns
        // 62 is the position o the screen where we want the corns to start appearing
        // 165 is the position on the screen where we want the corns to stop appearing
        // 30 is the size of the corn
        CGFloat delta = (count > 1)?((165.0f - 62.0f - 30.0f) / (count - 1)):0.0f;

        bullets = [[NSMutableArray alloc] initWithCapacity:count];
        for (int i=0; i<count; i++, pos+=delta)
        {
            // Create the bullet
            CCSprite *sprite = [CCSprite spriteWithFile:@"acorn.png"];
            [self addChild:sprite z:1];
            
            b2BodyDef bulletBodyDef;
            bulletBodyDef.type = b2_dynamicBody;
            bulletBodyDef.bullet = true;
            bulletBodyDef.position.Set(pos/PTM_RATIO,(FLOOR_HEIGTH+15.0f)/PTM_RATIO);
            bulletBodyDef.userData = sprite;
            b2Body *bullet = world->CreateBody(&bulletBodyDef);
            bullet->SetActive(false);
            
            b2CircleShape circle;
            circle.m_radius = 15.0/PTM_RATIO;
            
            b2FixtureDef ballShapeDef;
            ballShapeDef.shape = &circle;
            ballShapeDef.density = 0.8f;
            ballShapeDef.restitution = 0.2f;
            ballShapeDef.friction = 0.99f;
            bullet->CreateFixture(&ballShapeDef);
            
            [bullets addObject:[NSValue valueWithPointer:bullet]];
        }
    }
}

- (BOOL)attachBullet
{
    if (currentBullet < [bullets count])
    {
        bulletBody = (b2Body*)[[bullets objectAtIndex:currentBullet++] pointerValue];
        bulletBody->SetTransform(b2Vec2(230.0f/PTM_RATIO,(155.0f+FLOOR_HEIGTH)/PTM_RATIO), 0.0f);
        bulletBody->SetActive(true);

        b2WeldJointDef weldJointDef;
        weldJointDef.Initialize(bulletBody, armBody, b2Vec2(230.0f/PTM_RATIO,(155.0f+FLOOR_HEIGTH)/PTM_RATIO));
        weldJointDef.collideConnected = false;
        
        bulletJoint = (b2WeldJoint*)world->CreateJoint(&weldJointDef);
        return YES;
    }
    
    return NO;
}

- (void)resetBullet
{
    NSLog(@"resetBullet: [bullets: %d/%d enimies: %d]", currentBullet, [bullets count], [enemies count]);
    NSLog(@"score: %d", score);
    /* this an infinity loop */
    /*
    for (kerker = 0; kerker < 1;) {
        NSLog(@"i'm an infinity loop, haha!");
    }*/
    
    
    /* add win/lose after the game */
    
    // win or lose
    // win: no more enemies
    if ([enemies count] == 0) {
        NSLog(@"win  score:%d", score);
        GameOverScene *gameOverScene = [GameOverScene node];
        [gameOverScene.layer.label setString:[NSString stringWithFormat:@"You Win!      score:%d", score]];
        [[CCDirector sharedDirector] replaceScene:gameOverScene];
        [self performSelector:@selector(resetGame) withObject:nil afterDelay:2.0f];
    }
    // lose: 4 bullets are all already used
    else if (currentBullet == 4) {
        NSLog(@"lose  score:%d", score);
        GameOverScene *gameOverScene = [GameOverScene node];
        [gameOverScene.layer.label setString:@"You Lose!"];
        [[CCDirector sharedDirector] replaceScene:gameOverScene];
    }
    else if ([self attachBullet])
    {
        [self runAction:[CCMoveTo actionWithDuration:2.0f position:CGPointZero]];
    }
    else
    {
        // We can reset the whole scene here
        [self performSelector:@selector(resetGame) withObject:nil afterDelay:2.0f];
    }
}

- (void) canYouFindMe {
    NSLog(@"can you find me");
    score += 100;
    [score_label setString:[NSString stringWithFormat:@"score: %d", score]];
}



- (void)createTarget:(NSString*)imageName
          atPosition:(CGPoint)position
            rotation:(CGFloat)rotation
            isCircle:(BOOL)isCircle
            isStatic:(BOOL)isStatic
             isEnemy:(BOOL)isEnemy
{
    CCSprite *sprite = [CCSprite spriteWithFile:imageName];
    [self addChild:sprite z:1];
    
    b2BodyDef bodyDef;
    bodyDef.type = isStatic?b2_staticBody:b2_dynamicBody;
    bodyDef.position.Set((position.x+sprite.contentSize.width/2.0f)/PTM_RATIO,
                         (position.y+sprite.contentSize.height/2.0f)/PTM_RATIO);
    bodyDef.angle = CC_DEGREES_TO_RADIANS(rotation);
    bodyDef.userData = sprite;
    b2Body *body = world->CreateBody(&bodyDef);
    
    b2FixtureDef boxDef;
    if (isCircle)
    {
        b2CircleShape circle;
        circle.m_radius = sprite.contentSize.width/2.0f/PTM_RATIO;
        boxDef.shape = &circle;
    }
    else
    {
        b2PolygonShape box;
        box.SetAsBox(sprite.contentSize.width/2.0f/PTM_RATIO, sprite.contentSize.height/2.0f/PTM_RATIO);
        boxDef.shape = &box;
    }
    
    if (isEnemy)
    {
        boxDef.userData = (void*)1;
        [enemies addObject:[NSValue valueWithPointer:body]];
    }
    
    boxDef.density = 0.5f;
    body->CreateFixture(&boxDef);
    
    [targets addObject:[NSValue valueWithPointer:body]];
}

- (void)createTargets
{
    [targets release];
    [enemies release];
    
    targets = [[NSMutableSet alloc] init];
    enemies = [[NSMutableSet alloc] init];
    
    // First block
    [self createTarget:@"brick_2.png" atPosition:CGPointMake(675.0, FLOOR_HEIGTH) rotation:0.0f isCircle:NO isStatic:NO isEnemy:NO];
    [self createTarget:@"brick_1.png" atPosition:CGPointMake(741.0, FLOOR_HEIGTH) rotation:0.0f isCircle:NO isStatic:NO isEnemy:NO];
    [self createTarget:@"brick_1.png" atPosition:CGPointMake(741.0, FLOOR_HEIGTH+23.0f) rotation:0.0f isCircle:NO isStatic:NO isEnemy:NO];
    [self createTarget:@"brick_3.png" atPosition:CGPointMake(672.0, FLOOR_HEIGTH+46.0f) rotation:0.0f isCircle:NO isStatic:NO isEnemy:NO];
    [self createTarget:@"brick_1.png" atPosition:CGPointMake(707.0, FLOOR_HEIGTH+58.0f) rotation:0.0f isCircle:NO isStatic:NO isEnemy:NO];
    [self createTarget:@"brick_1.png" atPosition:CGPointMake(707.0, FLOOR_HEIGTH+81.0f) rotation:0.0f isCircle:NO isStatic:NO isEnemy:NO];

    /* add a lot of dogs here */
    for (int i = 0; i < 20 && kerker == 2; i++) {
        [self createTarget:@"head_dog.png" atPosition:CGPointMake(707.0, FLOOR_HEIGTH+100.0f+10i) rotation:0.0f isCircle:YES isStatic:NO isEnemy:YES];
    }

    /* hide enemies for debugging */
//    [self createTarget:@"head_dog.png" atPosition:CGPointMake(702.0, FLOOR_HEIGTH) rotation:0.0f isCircle:YES isStatic:NO isEnemy:YES];

    [self createTarget:@"head_cat.png" atPosition:CGPointMake(680.0, FLOOR_HEIGTH+58.0f) rotation:0.0f isCircle:YES isStatic:NO isEnemy:YES];
    [self createTarget:@"head_dog.png" atPosition:CGPointMake(740.0, FLOOR_HEIGTH+58.0f) rotation:0.0f isCircle:YES isStatic:NO isEnemy:YES];

    // 2 bricks at the right of the first block
    [self createTarget:@"brick_2.png" atPosition:CGPointMake(770.0, FLOOR_HEIGTH) rotation:0.0f isCircle:NO isStatic:NO isEnemy:NO];
    [self createTarget:@"brick_2.png" atPosition:CGPointMake(770.0, FLOOR_HEIGTH+46.0f) rotation:0.0f isCircle:NO isStatic:NO isEnemy:NO];
    
    // The dog between the blocks
    [self createTarget:@"head_dog.png" atPosition:CGPointMake(830.0, FLOOR_HEIGTH) rotation:0.0f isCircle:YES isStatic:NO isEnemy:YES];
    
    // Second block
    [self createTarget:@"brick_platform.png" atPosition:CGPointMake(839.0, FLOOR_HEIGTH) rotation:0.0f isCircle:NO isStatic:YES isEnemy:NO];
    [self createTarget:@"brick_2.png"  atPosition:CGPointMake(854.0, FLOOR_HEIGTH+28.0f) rotation:0.0f isCircle:NO isStatic:NO isEnemy:NO];
    [self createTarget:@"brick_2.png"  atPosition:CGPointMake(854.0, FLOOR_HEIGTH+28.0f+46.0f) rotation:0.0f isCircle:NO isStatic:NO isEnemy:NO];
    [self createTarget:@"head_cat.png" atPosition:CGPointMake(881.0, FLOOR_HEIGTH+28.0f) rotation:0.0f isCircle:YES isStatic:NO isEnemy:YES];
    [self createTarget:@"brick_2.png"  atPosition:CGPointMake(909.0, FLOOR_HEIGTH+28.0f) rotation:0.0f isCircle:NO isStatic:NO isEnemy:NO];
    [self createTarget:@"brick_1.png"  atPosition:CGPointMake(909.0, FLOOR_HEIGTH+28.0f+46.0f) rotation:0.0f isCircle:NO isStatic:NO isEnemy:NO];
    [self createTarget:@"brick_1.png"  atPosition:CGPointMake(909.0, FLOOR_HEIGTH+28.0f+46.0f+23.0f) rotation:0.0f isCircle:NO isStatic:NO isEnemy:NO];
    [self createTarget:@"brick_2.png"  atPosition:CGPointMake(882.0, FLOOR_HEIGTH+108.0f) rotation:90.0f isCircle:NO isStatic:NO isEnemy:NO];
}

-(void) draw
{
	// Default GL states: GL_TEXTURE_2D, GL_VERTEX_ARRAY, GL_COLOR_ARRAY, GL_TEXTURE_COORD_ARRAY
	// Needed states:  GL_VERTEX_ARRAY, 
	// Unneeded states: GL_TEXTURE_2D, GL_COLOR_ARRAY, GL_TEXTURE_COORD_ARRAY
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_COLOR_ARRAY);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	
	world->DrawDebugData();
	
	// restore default GL states
	glEnable(GL_TEXTURE_2D);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);

}

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (mouseJoint != nil) return;
    
    UITouch *myTouch = [touches anyObject];
    CGPoint location = [myTouch locationInView:[myTouch view]];
    location = [[CCDirector sharedDirector] convertToGL:location];
    b2Vec2 locationWorld = b2Vec2(location.x/PTM_RATIO, location.y/PTM_RATIO);
    
    if (locationWorld.x < armBody->GetWorldCenter().x + 50.0/PTM_RATIO)
    {
        b2MouseJointDef md;
        md.bodyA = groundBody;
        md.bodyB = armBody;
        md.target = locationWorld;
        md.maxForce = 2000;
        
        mouseJoint = (b2MouseJoint *)world->CreateJoint(&md);
    }
}

- (void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (mouseJoint == nil) return;
    
    UITouch *myTouch = [touches anyObject];
    CGPoint location = [myTouch locationInView:[myTouch view]];
    location = [[CCDirector sharedDirector] convertToGL:location];
    b2Vec2 locationWorld = b2Vec2(location.x/PTM_RATIO, location.y/PTM_RATIO);
    
    mouseJoint->SetTarget(locationWorld);
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (mouseJoint != nil)
    {
        if (armJoint->GetJointAngle() >= CC_DEGREES_TO_RADIANS(10))
        {
            releasingArm = YES;
        }

        world->DestroyJoint(mouseJoint);
        mouseJoint = nil;
    }
}


/* turn on the NSLog to show the scheduling between two functions */
-(void) show_score: (ccTime) dt {
//    NSLog(@"show_score %f, %d", dt, score);
    score_label.position = CGPointMake (-position_.x + 200, position_.y + 300);
}

-(void) tick: (ccTime) dt
{
//    NSLog(@"tick %f, %d", dt, score);
    
	//It is recommended that a fixed time step is used with Box2D for stability
	//of the simulation, however, we are using a variable time step here.
	//You need to make an informed choice, the following URL is useful
	//http://gafferongames.com/game-physics/fix-your-timestep/
	
	int32 velocityIterations = 8;
	int32 positionIterations = 1;
	
	// Instruct the world to perform a single step of simulation. It is
	// generally best to keep the time step and iterations fixed.
	world->Step(dt, velocityIterations, positionIterations);


    
	// Iterate over the bodies in the physics world
	for (b2Body* b = world->GetBodyList(); b; b = b->GetNext())
	{
		if (b->GetUserData() != NULL) {
			// Synchronize the AtlasSprites position and rotation with the corresponding body
			CCSprite *myActor = (CCSprite*)b->GetUserData();
			myActor.position = CGPointMake( b->GetPosition().x * PTM_RATIO, b->GetPosition().y * PTM_RATIO);
			myActor.rotation = -1 * CC_RADIANS_TO_DEGREES(b->GetAngle());
		}	
	}
    
    // Arm is being released.
    if (releasingArm && bulletJoint)
    {
        // Check if the arm reached the end so we can return the limits
        if (armJoint->GetJointAngle() <= CC_DEGREES_TO_RADIANS(10))
        {
            releasingArm = NO;
            
            // Destroy joint so the bullet will be free
            world->DestroyJoint(bulletJoint);
            bulletJoint = nil;
            [self performSelector:@selector(resetBullet) withObject:nil afterDelay:5.0f];
        }
    }
    
    // Bullet is moving.
    if (bulletBody && bulletJoint == nil)
    {
        b2Vec2 position = bulletBody->GetPosition();
        CGPoint myPosition = self.position;
        CGSize screenSize = [CCDirector sharedDirector].winSize;
        
        // Move the camera.
        if (position.x > screenSize.width / 2.0f / PTM_RATIO)
        {
            myPosition.x = -MIN(screenSize.width * 2.0f - screenSize.width, position.x * PTM_RATIO - screenSize.width / 2.0f);
            self.position = myPosition;
        }
        if (kerker == 3) {
            [self canYouFindMe];
        }
    }
    
    // Check for impacts
    std::set<b2Body*>::iterator pos;
    for(pos = contactListener->contacts.begin(); 
        pos != contactListener->contacts.end(); ++pos)
    {
        b2Body *body = *pos;
        
        CCNode *contactNode = (CCNode*)body->GetUserData();
        CGPoint position = contactNode.position;
        [self removeChild:contactNode cleanup:YES];
        world->DestroyBody(body);
        
        score += 10;
        [score_label setString:[NSString stringWithFormat:@"score: %d", score]];
        
        [targets removeObject:[NSValue valueWithPointer:body]];
        [enemies removeObject:[NSValue valueWithPointer:body]];
        

        CCParticleSun* explosion = [[CCParticleSun alloc] initWithTotalParticles:200];
        explosion.autoRemoveOnFinish = YES;
        explosion.startSize = 10.0f;
        explosion.speed = 70.0f;
        explosion.anchorPoint = ccp(0.5f,0.5f);
        explosion.position = position;
        explosion.duration = 1.0f;
        [self addChild:explosion z:11];
        [explosion release];
    }
    
    // remove everything from the set
    contactListener->contacts.clear();
    
    
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
    [bullets release];
    
    [targets release];
    [enemies release];
    
	// in case you have something to dealloc, do it in this method
	delete world;
	world = NULL;
	
    delete contactListener;
    contactListener = NULL;

	delete m_debugDraw;

	// don't forget to call "super dealloc"c
    
	[super dealloc];
}
@end
