//
//  talkBackViewController.m
//  TalkBack3
//
//  Created by Joseph Russo on 4/5/13.
//  Copyright (c) 2013 Dangerous Music. All rights reserved.
//

#import "talkBackViewController.h"
#import "MHRotaryKnob.h"

static const int kOutputChanged;

@interface talkBackViewController ()
@property (nonatomic, strong) AEAudioController *audioController;
@property (nonatomic, retain) AEPlaythroughChannel *playthrough;
@end

@implementation talkBackViewController


-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context {
    if ( context == &kAudioRouteChanged ) {
        BOOL headphonesAreConnected = [_audioController.audioRoute isEqualToString:@"HeadphonesAndMicrophone"];
        //Cut talkback if phones are pulled.
        if(headphonesAreConnected == NO){
            //NSLog(@"no phones!!");
            _playthrough.channelIsMuted=YES;
            _talkButton.selected=NO;
            [_talkButton setImage:[UIImage imageNamed:@"Btn2.png"] forState:UIControlStateNormal];
        }
    }
}

//If talkback is not on, stop the audio engine so it does not continue in the background.
-(void)handleEnteredBackground{
    if (_talkButton.selected==NO) {
        //kill audio
        [_audioController stop];
    }
}

-(void)handleEnterForeground{
    //start audio engine if not already running
    if (_audioController.running==NO) {
        [_audioController start:NULL];
    }
}

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
	[self.rotaryKnob setKnobImage:[UIImage imageNamed:@"Pointer.png"] forState:UIControlStateNormal];
	[self.rotaryKnob setKnobImage:[UIImage imageNamed:@"Pointer.png"] forState:UIControlStateHighlighted];
	[self.rotaryKnob setKnobImage:[UIImage imageNamed:@"Pointer.png"] forState:UIControlStateDisabled];
    [self.rotaryKnob setForegroundImage:[UIImage imageNamed:@"Reflections.png"]];
    [self.rotaryKnob setBackgroundImage:[UIImage imageNamed:@"KnobFixins.png"]];//note: this image is also added to the storyboard as a placeholder.
	self.rotaryKnob.knobImageCenter = CGPointMake(105.0f, 107.0f);
	[self.rotaryKnob addTarget:self action:@selector(rotaryKnobDidChange) forControlEvents:UIControlEventValueChanged];
    
    //----------------------------------------------
    //AUDIO SETUP
    //----------------------------------------------
    self.audioController = [[AEAudioController alloc]
                            initWithAudioDescription:[AEAudioController nonInterleaved16BitStereoAudioDescription]
                            inputEnabled:YES];
    
    NSError *error = NULL;
    BOOL result = [_audioController start:&error];
    if ( !result ) {
        // Report error
    }
    //Turn playthrough on
    self.playthrough = [[AEPlaythroughChannel alloc] initWithAudioController:_audioController];
    [_audioController addInputReceiver:_playthrough];
    [_audioController addChannels:[NSArray arrayWithObject:_playthrough]];
    
    //but keep it muted
    _playthrough.volume=0;
    _playthrough.channelIsMuted=YES;
    
    //observe changes in audioRoute (ie:headphones pulled)
    [_audioController addObserver:self forKeyPath:@"audioRoute" options:0 context:(void*)&kAudioRouteChanged];
    
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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)tbButton:(id)sender {
    //TODO: Make this "momentoggle"
    UIButton *button = (UIButton *)sender;

        //TODO: Workaround for touch down not setting "highlighted" button state. Is there a way around this?
        [button setImage:[UIImage imageNamed:@"BtnDownLight2.png"] forState:UIControlStateNormal];
        
    if (button.selected==NO && [_audioController.audioRoute isEqualToString:@"HeadphonesAndMicrophone"]) {
        button.selected=YES;
        _playthrough.channelIsMuted=NO;
        NSLog(@"ON");                
    }
    
    else if (button.selected==NO && [_audioController.audioRoute isEqualToString:@"SpeakerAndMicrophone"]) {
        button.selected=NO;
        _playthrough.channelIsMuted=YES;
        [button setImage:[UIImage imageNamed:@"Btn2.png"] forState:UIControlStateNormal];
        //NSLog(@"CONNECT SOMETHING!");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning!" message:@"This may cause feedback." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
        [alert show];
    }
    
    else{
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

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
    //speakers are on user wants to turn talkbakc on anyway
    _talkButton.selected=YES;
    _playthrough.channelIsMuted=NO;
    NSLog(@"ON");
    }
}

@end
