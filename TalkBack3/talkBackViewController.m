//
//  talkBackViewController.m
//  TalkBack3
//
//  Created by Joseph Russo on 4/5/13.
//  Copyright (c) 2013 Dangerous Music. All rights reserved.
//

#import "talkBackViewController.h"
#import "MHRotaryKnob.h"

@interface talkBackViewController ()
@property (nonatomic, strong) AEAudioController *audioController;
@property (nonatomic, retain) AEPlaythroughChannel *playthrough;


@end

@implementation talkBackViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //----------------------------------------------
    //KNOB SETUP
    //----------------------------------------------
    //TODO: Change images and figure out why it doesn't display background
    
    self.rotaryKnob.interactionStyle = MHRotaryKnobInteractionStyleSliderVertical;
	self.rotaryKnob.scalingFactor = 1.5f;
	self.rotaryKnob.maximumValue = 1;
	self.rotaryKnob.minimumValue =0;
	self.rotaryKnob.value = 0.75;
	self.rotaryKnob.defaultValue = self.rotaryKnob.value;
	self.rotaryKnob.resetsToDefault = YES;
	self.rotaryKnob.backgroundColor = [UIColor clearColor];
	self.rotaryKnob.backgroundImage = [UIImage imageNamed:@"Knob Background.png"];
	[self.rotaryKnob setKnobImage:[UIImage imageNamed:@"Knob Disabled.png"] forState:UIControlStateNormal];
	[self.rotaryKnob setKnobImage:[UIImage imageNamed:@"Knob Highlighted.png"] forState:UIControlStateHighlighted];
	[self.rotaryKnob setKnobImage:[UIImage imageNamed:@"Knob Disabled.png"] forState:UIControlStateDisabled];
	self.rotaryKnob.knobImageCenter = CGPointMake(80.0f, 76.0f);
	[self.rotaryKnob addTarget:self action:@selector(rotaryKnobDidChange) forControlEvents:UIControlEventValueChanged];
    
        
    //----------------------------------------------
    //AUDIO SETUP
    //----------------------------------------------
    //TODO: Force audioController to use headphones output routing only
    
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
    _playthrough.channelIsMuted=YES;
    


}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)tbButton:(id)sender {
    //TODO: Make this "momentoggle"
    UIButton *button = (UIButton *)sender;
    if (button.selected==NO) {
        button.selected=YES;
        //unmute
        _playthrough.channelIsMuted=NO;

    }
    
    else{
        button.selected=NO;
        _playthrough.channelIsMuted=YES;
    }
    
}

- (IBAction)rotaryKnobDidChange
{	
	_playthrough.volume=self.rotaryKnob.value;
}




@end
