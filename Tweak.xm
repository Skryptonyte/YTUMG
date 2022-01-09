

#include <Photos/Photos.h>

// ******
// Apple Stuff
// ******

@interface OBButtonTray : UIView
- (void)addButton:(id)arg1;
- (void)addCaptionText:(id)arg1;;
@end

@interface OBBoldTrayButton : UIButton
-(void)setTitle:(id)arg1 forState:(unsigned long long)arg2;
+(id)buttonWithType:(long long)arg1;
@end

@interface OBWelcomeController : UIViewController
- (OBButtonTray *)buttonTray;
- (id)initWithTitle:(id)arg1 detailText:(id)arg2 icon:(id)arg3;
- (void)addBulletedListItemWithTitle:(id)arg1 description:(id)arg2 image:(id)arg3;
@end


// ******
// Facebook's Texture classes
// ******


// Async Nodes

@interface ASDisplayNode: NSObject
- (void)displayDidFinish;
@end

@interface ASControlNode: ASDisplayNode
@end

@interface ASImageNode: ASControlNode
@end

@interface ASNetworkImageNode: ASImageNode
@end


// Async View Wrapper
@interface _ASDisplayView:UIView
@property (nonatomic, strong, readwrite) ASDisplayNode *asyncdisplaykit_node;
@end


// ******
// Youtube's Goodies
// ******

// Youtube's Zoom Image view

@interface YTImageZoomNode: ASNetworkImageNode
@property (atomic, copy, readwrite) NSURL* URL;
-(void) _didLoad;
-(void) imageNode:(id) arg1 didLoadImage:(id)arg2;
-(void) doSomething;
-(void) saveImage;
@end

// Youtube Player Controller

@interface YTPlayerViewController: UIViewController
-(void) playbackController:(id) arg1 didReceiveAdMarkers:(id) arg2;
-(void) playbackControllerDidLoadPrerollAd:(id)arg1;
- (void) playbackController:(id) arg1 willStartAdSurveyWithAdInterrupt: (id) arg2;
@end


// Youtube playback controller, ad loading is coordinated over here
// A good chunk of its methods are ads related.... Gotta get that sweet ad money eh?
@interface YTLocalPlaybackController: NSObject
-(id) adsPlaybackCoordinator: (id)arg1 playAdInterrupt: (id) arg2;
// arg1: YTAdsControlFlowPlaybackCoordinator
// arg2: YTAdInterrupt
-(void)adsPlaybackCoordinatorPrepareToPlayAd:(id) arg1;
// arg1: YTAdsControlFlowPlaybackCoordinator
-(void) updateForceDisableBackgroundingForVideoController:(id) arg1;
// arg1: YTSingleVideoController
@end


@interface YTAdsPlaybackService: NSObject
-(void) setAdsPlaybackSurface: (id) arg1;
@end
// Youtube Miniplayer

@interface GPBMessage: NSObject
@end

@interface YTIMiniplayerRenderer: GPBMessage
@property (nonatomic,assign,readwrite) int playbackMode;

-(int) playbackMode;
-(void) setPlaybackMode:(int) arg1;
-(void) setHasMinimizedEndpoint: (BOOL) arg1;
-(BOOL) hasMinimizedEndpoint;
@end

static UIImpactFeedbackGenerator* feedbackGen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];

%hook YTImageZoomNode
-(void) _didLoad
{
	%orig; 
	UIView* view = MSHookIvar<UIView*>(self,"_view");

	UILongPressGestureRecognizer* gesture = [[UILongPressGestureRecognizer alloc] initWithTarget: self action: @selector(doSomething:)];
	[view addGestureRecognizer: gesture];
	//NSLog(@"[YTUMG] ImageZoomNode view loaded");
}

%new

// TODO: Use native GBoard view controller for more consistent UI experience
-(void) doSomething: (UILongPressGestureRecognizer*) gesture
{

	if (gesture.state != UIGestureRecognizerStateBegan)
		return;
	UIViewController* imgController = [[UIApplication sharedApplication] delegate].window.rootViewController;

	//NSLog(@"[YTUMG] LONG PRESS");
	
	OBWelcomeController *saveImageController = [[OBWelcomeController alloc] 
	initWithTitle:@"Save Image" 
	detailText:@"Save Community Post Image?" 
		icon:nil];

	[saveImageController addBulletedListItemWithTitle:@"Saving images" 
		description:@"Image will be saved straight to your Photos" 
		image:[UIImage systemImageNamed:@"1.circle.fill"]];
	[saveImageController addBulletedListItemWithTitle:@"Saving animated images" 
		description:@"While it works, animated images are in WEBP format so most apps will display it as a still" 
		image:[UIImage systemImageNamed:@"2.circle.fill"]];

	OBBoldTrayButton* saveButton = [OBBoldTrayButton buttonWithType:1];
	[saveButton setTitle: @"Save" forState: UIControlStateNormal];
	[saveButton setTitleColor: [UIColor whiteColor] forState: UIControlStateNormal];
	[saveButton addTarget: self action:@selector(saveImage) forControlEvents: UIControlEventTouchUpInside];

	[[saveImageController buttonTray] addButton: saveButton ];

	saveImageController.modalPresentationStyle = UIModalPresentationPageSheet;
	[feedbackGen impactOccurred];
	[imgController presentViewController:saveImageController animated:YES completion:nil];
	


	[feedbackGen prepare];

}

%new
-(void) saveImage
{
	dispatch_async(dispatch_get_main_queue(),^{
		NSURL* imgURL = self.URL;
		NSData* data = [NSData dataWithContentsOfURL: imgURL];
		[[PHPhotoLibrary sharedPhotoLibrary]
		performChanges:
		^{
			[[PHAssetCreationRequest creationRequestForAsset] addResourceWithType: PHAssetResourceTypePhoto data: data options: nil];
		}
		completionHandler: nil
		];
	}
	);

	UIViewController* imgController = [[UIApplication sharedApplication] delegate].window.rootViewController;
	[imgController dismissViewControllerAnimated: YES completion: nil];


}
%end

%hook YTLocalPlaybackController

/*
-(void)adsPlaybackCoordinatorPrepareToPlayAd:(id) arg1
{
	NSLog(@"[YTUMG] Prepare to play Ad, arg1: %@",arg1);
	%orig;
}

-(id) adsPlaybackCoordinator: (id)arg1 playAdInterrupt: (id) arg2
{
	NSLog(@"[YTUMG] Playback Coordinator: %@ plays ad interrupt: %@",arg1,arg2);
	//return %orig;
	return nil;
}
*/
// Enable Background Play
-(void) updateForceDisableBackgroundingForVideoController:(id) arg1
{
	//NSLog(@"[YTUMG] Override force background off %@",arg1);
	if (arg1)
	{
		MSHookIvar<BOOL>(arg1,"_currentlyBackgroundable") = YES;
		MSHookIvar<BOOL>(arg1,"_isBackgroundingForcedDisabled") = NO;
	}
}
%end

%hook YTAdsPlaybackService
// Very simple solution to remove ads
-(void) setAdsPlaybackSurface:(id) arg1
{
	//NSLog(@"[YTUMG] Override ads playback surface: %@",arg1);
	arg1 = nil;

	%orig;
}
%end

// Override Miniplayer Pause for kids video (Snippet not working despite working in FLEX, no idea why pls halp)
%hook YTIMiniplayerRenderer
-(void) setPlaybackMode:(int) arg1
{
	arg1 = 2;   // 0 - Unknown, 2 - Normal Playback, 4 - Pause Only
	%orig;
}

-(void) setHasMinimizedEndpoint: (BOOL) arg1
{
	arg1 = NO;
	%orig;
}

-(int) playbackMode
{
	return 2;
}
-(BOOL) hasMinimizedEndpoint
{	
	return NO;
}
%end
