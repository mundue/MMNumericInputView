//
//  CurrencyViewController.m
//  MMNumericInput
//
//  Created by Matt Martel on 10/17/13.
//  Copyright (c) 2013 Mundue LLC. All rights reserved.
//

#import "CurrencyViewController.h"
#import "MMNumericInputView.h"

@interface CurrencyViewController () {
    IBOutlet UITextField *formattedTextField;
    IBOutlet UITextField *inputTextField;
}
@property (nonatomic) CGFloat floatValue;
@end

@implementation CurrencyViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.title = @"MMNumericInput";
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
	
    inputTextField = [[UITextField alloc] initWithFrame:CGRectZero];
    [self.view addSubview:inputTextField];
    inputTextField.inputView = [MMNumericInputView defaultInputView];

    inputTextField.delegate = self;
    formattedTextField.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textDidChange:)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.floatValue = 0.0f;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setFloatValue:(CGFloat)newValue
{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setMinimumIntegerDigits:2];
    NSString *formattedValue = [formatter stringFromNumber:[NSNumber numberWithFloat:newValue]];
    formattedTextField.text = formattedValue;
}

- (void)done:(id)sender {
    [inputTextField resignFirstResponder];
}

#pragma mark - UITextFieldDelegate notifications

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (textField == formattedTextField) {
        [inputTextField becomeFirstResponder];
        [formattedTextField setBackgroundColor:self.view.tintColor];
        return NO;
    }
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == inputTextField) {
        [formattedTextField setBackgroundColor:nil];
    }
}

- (void)textDidChange:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[UITextField class]]) {
        UITextField *targetTextField = (UITextField*)notification.object;
        NSUInteger length = targetTextField.text.length;
        switch (length) {
            case 0:
            {
                NSString *noDigitString = @"00.00";
                CGFloat noDigitFloat = [noDigitString floatValue];
                NSLog(@"string: \"%@\" float: %g", noDigitString, noDigitFloat);
                self.floatValue = noDigitFloat;
            }
                break;
            case 1:
            {
                NSString *oneDigitString = [NSString stringWithFormat:@"00.0%@",targetTextField.text];
                CGFloat oneDigitFloat = [oneDigitString floatValue];
                NSLog(@"string: \"%@\" float: %g", oneDigitString, oneDigitFloat);
                self.floatValue = oneDigitFloat;
            }
                break;
            case 2:
            {
                NSString *twoDigitString = [NSString stringWithFormat:@"00.%@",targetTextField.text];
                CGFloat twoDigitFloat = [twoDigitString floatValue];
                NSLog(@"string: \"%@\" float: %g", twoDigitString, twoDigitFloat);
                self.floatValue = twoDigitFloat;
            }
                break;
            default:
            {
                NSString *integerString = [targetTextField.text substringToIndex:length-2];
                NSString *fractionString = [targetTextField.text substringFromIndex:length-2];
                NSString *multiDigitString = [NSString stringWithFormat:@"%@.%@",integerString,fractionString];
                CGFloat multiDigitFloat = [multiDigitString floatValue];
                NSLog(@"string: \"%@\" float: %g", integerString, multiDigitFloat);
                self.floatValue = multiDigitFloat;
            }
                break;
        }
    }
}

@end
