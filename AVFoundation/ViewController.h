//
//  ViewController.h
//  AVFoundation
//
//  Created by Tarik Djebien on 03/05/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AVFoundation/AVFoundation.h"

@interface ViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic, strong) IBOutlet UIImageView *imgView;
@end
