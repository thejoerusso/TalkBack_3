//
//  talkBackViewController.m
//  TalkBack3
//
//  Created by Joseph Russo on 4/5/13.
//  Copyright (c) 2013 Dangerous Music. All rights reserved.
//

#import "talkBackViewController.h"
#import "MHRotaryKnob.h"
#import "JRTalkController.h"


static const int kOutputChanged;
BOOL foreground;
BOOL interrupted;

@interface talkBackViewController ()
@property (nonatomic, strong) AEAudioController *audioController;
@property (nonatomic, retain) AEPlaythroughChannel *playthrough;
@property (nonatomic, retain) NSDate *startDate;
@end

@implementation talkBackViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //----------------------------------------------
    //KNOB SETUP
    //----------------------------------------------
    self.rotaryKnob.interactionStyle = MHRotaryKnobInteractionStyleSliderVertical;
	self.rotaryKnob.scalingFactor = 1.5f;
	self.rotaryKnob.maximumValue = 1;
	self.rotaryKnob.minimumValue =0;
	self.rotaryKnob.value = 0;
	self.rotaryKnob.defaultValue = self.rotaryKnob.value;
	self.rotaryKnob.resetsToDefault = YES;
	self.rotaryKnob.backgroundColor = [UIColor clearColor];
	[self.rotaryKnob setKnobImage:[UIImage imageNamed:@"Pointer2.png"] forState:UIControlStateNormal];
	[self.rotaryKnob setKnobImage:[UIImage imageNamed:@"Pointer2.png"] forState:UIControlStateHighlighted];
	[self.rotaryKnob setKnobImage:[UIImage imageNamed:@"Pointer2.png"] forState:UIControlStateDisabled];
    [self.rotaryKnob setForegroundImage:[UIImage imageNamed:@"Reflection2.png"]];
    [self.rotaryKnob setBackgroundImage:[UIImage imageNamed:@"Knob2.png"]];//note: this image is also added to the storyboard as a placeholder.
	self.rotaryKnob.knobImageCenter = CGPointMake(105.0f, 105.0f);
	[self.rotaryKnob addTarget:self action:@selector(rotaryKnobDidChange) forControlEvents:UIControlEventValueChanged];
    
    //----------------------------------------------
    //AUDIO SETUP
    //----------------------------------------------
    self.audioController = [[AEAudioController alloc]
                            initWithAudioDescription:[AEAudioController nonInterleaved16BitStereoAudioDescription]
                            inputEnabled:YES];
    
        //Turn playthrough on
    self.playthrough = [[AEPlaythroughChannel alloc] initWithAudioController:_audioController];
    [_audioController addInputReceiver:_playthrough];
    [_audioController addChannels:[NSArray arrayWithObject:_playthrough]];
    
    //but keep it muted
    _playthrough.volume=0;
    _playthrough.channelIsMuted=YES;
    
    NSError *error = NULL;
    BOOL result = [_audioController start:&error];
    if ( !result ) {
        // Report error
    }
    
    //----------------------------------------------
    //OBSERVER SETUP
    //----------------------------------------------
    
    //observe changes in audioRoute (ie:headphones pulled)
    [_audioController                     addObserver:self
                                           forKeyPath:@"audioRoute"
                                              options:0
                                              context:(void*)&kAudioRouteChanged];
    
    //observe for entering background
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleEnteredBackground)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
    
    //observe for entering foreground
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleEnterForeground)
                                                 name: UIApplicationWillEnterForegroundNotification
                                               object: nil];
    
    //observe for entering active
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleActive)
                                                 name: UIApplicationDidBecomeActiveNotification
                                               object: nil];
    
    if ([_audioController.audioRoute isEqualToString:@"HeadphonesAndMicrophone"]) {
        _talkButton.enabled=YES;
        _headPhone.hidden=YES;
        _label.hidden=YES;
    }
    else{
        _talkButton.enabled=NO;
        _headPhone.hidden=NO;
        _label.hidden=NO;
    }
}


- (IBAction)tbButton:(id)sender {
    UIButton *button = (UIButton *)sender;
    
    _startDate = [NSDate date];
    
    [button setImage:[UIImage imageNamed:@"BtnDownLight2.png"] forState:UIControlStateNormal];//change img on touch down
        
    if (button.selected==NO) {
        _talkButton.selected=YES;
        _playthrough.channelIsMuted=NO;
        NSLog(@"ON");
    }

    else{
        button.selected=NO;
        _playthrough.channelIsMuted=YES;
         NSLog(@"OFF");
        [button setImage:[UIImage imageNamed:@"Btn2.png"] forState:UIControlStateNormal];
    }
}


-(IBAction)buttonUp:(id)sender
{
    UIButton *button = (UIButton *)sender;
    NSTimeInterval pressedForInSeconds = [[NSDate date] timeIntervalSince1970] - [_startDate timeIntervalSince1970];
    NSLog(@"button was pressed for: %f seconds", pressedForInSeconds);
    if (pressedForInSeconds > 0.4) {
        button.selected=NO;
        _playthrough.channelIsMuted=YES;
        NSLog(@"OFF");
        [button setImage:[UIImage imageNamed:@"Btn2.png"] forState:UIControlStateNormal];
    }
}


- (IBAction)rotaryKnobDidChange
{	
	_playthrough.volume=self.rotaryKnob.value;
}


//Listen for change in audioroute and kill talkback or enable button
-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context {
    if ( context == &kAudioRouteChanged ) {
        BOOL headphonesAreConnected = [_audioController.audioRoute isEqualToString:@"HeadphonesAndMicrophone"];
        //Cut talkback if phones are pulled.
        if(headphonesAreConnected == NO){
            NSLog(@"no phones!!");
            _playthrough.channelIsMuted=YES;
            _talkButton.selected=NO;
            _talkButton.enabled=NO;
            _headPhone.hidden=NO;
            _label.hidden=NO;
            [_talkButton setImage:[UIImage imageNamed:@"Btn2.png"] forState:UIControlStateNormal];
           
            if(foreground == NO){
                [_audioController stop]; 
            }
        }
        else{  
            _playthrough.channelIsMuted=YES;
            _talkButton.selected=NO;
            _talkButton.enabled=YES;
            _headPhone.hidden=YES;
            _label.hidden=YES;
            if(foreground == YES){
                if (_audioController.running==NO) {
                    [_audioController start:NULL];
                }
            }
        }
    }
}

//If talkback is not on, stop the audio engine so it does not continue in the background.
-(void)handleEnteredBackground{
        foreground=NO;
    if (_talkButton.selected==NO) {
        //kill audio
        [_audioController stop];
    }
}

//Start audio engine if not already running
-(void)handleEnterForeground{
        foreground=YES;
    if (_audioController.running==NO) {
        [_audioController start:NULL];
    }
}

-(void)handleActive{
    NSLog(@"active");
    if (_playthrough.channelIsMuted == YES) {
        _talkButton.selected=NO;
        [_talkButton setImage:[UIImage imageNamed:@"Btn2.png"] forState:UIControlStateNormal];
    }
}

- (void)dealloc
{
    //TODO: Move these??
    [_audioController removeObserver:self forKeyPath:@"audioRoute"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if ( _playthrough ) {
        [_audioController removeInputReceiver:_playthrough];
        self.playthrough = nil;
    }
    self.audioController = nil;
    
}
@end
