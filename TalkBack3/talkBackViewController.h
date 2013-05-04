//
//  talkBackViewController.h
//  TalkBack3
//
//  Created by Joseph Russo on 4/5/13.
//  Copyright (c) 2013 Dangerous Music. All rights reserved.
//


@class MHRotaryKnob;

#import <UIKit/UIKit.h>
#import "AEPlaythroughChannel.h"
#import "TheAmazingAudioEngine.h"

@interface talkBackViewController : UIViewController <UIAlertViewDelegate>

@property (nonatomic, weak) IBOutlet MHRotaryKnob *rotaryKnob;
@property (nonatomic, weak) IBOutlet UIButton *talkButton;

- (IBAction)tbButton:(id)sender;

- (IBAction)rotaryKnobDidChange;

@end

static const int kAudioRouteChanged;





