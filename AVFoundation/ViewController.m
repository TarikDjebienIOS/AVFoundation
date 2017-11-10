//
//  ViewController.m
//  AVFoundation
//
//  Created by Tarik Djebien on 03/05/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"

@interface ViewController()
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDevice *videoDevice;
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *frameOutput;
@property (nonatomic, strong) CIContext *context;
@property (nonatomic, strong) CIDetector *faceDetector;
@property (nonatomic, strong) UIImageView *glasses;
@end

@implementation ViewController

@synthesize imgView = _imgView;
@synthesize session = _session;
@synthesize videoDevice = _videoDevice;
@synthesize videoInput = _videoInput;
@synthesize frameOutput = _frameOutput;
@synthesize context = _context;
@synthesize faceDetector = _faceDetector;
@synthesize glasses = _glasses;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = AVCaptureSessionPreset352x288;
    self.videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    self.videoInput = [AVCaptureDeviceInput deviceInputWithDevice:self.videoDevice error:nil];
    self.frameOutput = [[AVCaptureVideoDataOutput alloc] init];
    self.frameOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id) kCVPixelBufferPixelFormatTypeKey];
    self.glasses = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"glasses.png"]];
    [self.glasses setHidden:YES];
    [self.view addSubview:self.glasses];
    
    // Wiring input and output on the session
    [self.session addInput:self.videoInput];
    [self.session addOutput:self.frameOutput];
    
    // Set up delegate
    [self.frameOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    [self.session startRunning];
}

- (void)viewDidUnload
{
    [self setImgView:nil];
    [super viewDidUnload];
    //[self.session stopRunning];
}

- (CIContext *)context
{
    if(!_context){
        _context = [CIContext contextWithOptions:nil];
    }
    return _context;
}

- (CIDetector *)faceDetector
{
    if(!_faceDetector){
        NSDictionary *detectorOptions = [NSDictionary dictionaryWithObjectsAndKeys:CIDetectorAccuracyLow,CIDetectorAccuracy, nil];
        _faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
    }
    return _faceDetector;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVPixelBufferRef pb = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pb];
    
    // Do some filtering
    CIFilter *filter = [CIFilter filterWithName:@"CIHueAdjust"];
    [filter setDefaults];
    [filter setValue:ciImage forKey:@"inputImage"];
    [filter setValue:[NSNumber numberWithFloat:2.0] forKey:@"inputAngle"];
    CIImage *result = [filter valueForKey:@"outputImage"];
    
    // Recognize face on camera
    bool faceFound = false;
    
    NSArray *features = [self.faceDetector featuresInImage:result];
    for (CIFaceFeature *face in features) {
        if (face.hasLeftEyePosition && face.hasRightEyePosition) {
            
            // Milieu d'un segment AB est egal a M(Xa+Xb/2,Ya+Yb/2)
            CGPoint eyeCenter = CGPointMake(face.leftEyePosition.x * 0.5 + face.rightEyePosition.x * 0.5, 
                                            face.leftEyePosition.y * 0.5 + face.rightEyePosition.y * 0.5);
            
            // Set the glasses position based on mouth position
            double scalex = self.imgView.bounds.size.height / ciImage.extent.size.width;
            double scaley = self.imgView.bounds.size.width / ciImage.extent.size.height;
            self.glasses.center = CGPointMake(scaley*eyeCenter.y - self.glasses.bounds.size.height / 4.0, scalex * (eyeCenter.x));
            
            // Set the angle of the glasses using eye deltas
            double deltax = face.leftEyePosition.x - face.rightEyePosition.x;
            double deltay = face.leftEyePosition.y - face.rightEyePosition.y;
            double angle = atan2(deltax, deltay);
            self.glasses.transform = CGAffineTransformMakeRotation(angle + M_PI);
            
            // Set size based on distance between the two eyes
            // distance = racine ((xb-xa) carré + (yb-ya) carré)
            double scale = 3.0 * sqrt(deltax*deltax + deltay*deltay);
            self.glasses.bounds = CGRectMake(0, 0, scale, scale);
            faceFound = true;
        }
    }
    
    if(faceFound){
        [self.glasses setHidden:NO];
    }else{
        [self.glasses setHidden:YES];
    }
    
    CGImageRef ref = [self.context createCGImage:result fromRect:ciImage.extent];
    self.imgView.image = [UIImage imageWithCGImage:ref scale:1.0 orientation:UIImageOrientationRight];
    CGImageRelease(ref);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
