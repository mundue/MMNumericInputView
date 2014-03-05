//
//  MMNumericInputView.m
//  MMNumericInput
//
//  Created by Matt Martel on 10/17/13.
//  Copyright (c) 2013 Mundue LLC. All rights reserved.
//

/* Based in part on https://github.com/fprosper/FPNumberPadView, which is in turn heavily inspired by the following post on Stack Overflow
 http://stackoverflow.com/questions/13205160/how-do-i-retrieve-keystrokes-from-a-custom-keyboard-on-an-ios-app
 */

#import "MMNumericInputView.h"

@interface MMNumericInputView () <UIInputViewAudioFeedback>
@property (nonatomic,weak) UIResponder <UITextInput> *targetTextInput;
@end

@implementation MMNumericInputView

#pragma mark - Shared MMNumericInputView method

+ (MMNumericInputView *)defaultInputView {
    static MMNumericInputView *defaultMMNumericInputView = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        defaultMMNumericInputView = [[[NSBundle mainBundle] loadNibNamed:@"MMNumericInputView" owner:self options:nil] objectAtIndex:0];
    });
    return defaultMMNumericInputView;
}

#pragma mark - view lifecycle

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addObservers];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self addObservers];
    }
    return self;
}

- (void)addObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(editingDidBegin:)
                                                 name:UITextFieldTextDidBeginEditingNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(editingDidBegin:)
                                                 name:UITextViewTextDidBeginEditingNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(editingDidEnd:)
                                                 name:UITextFieldTextDidEndEditingNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(editingDidEnd:)
                                                 name:UITextViewTextDidEndEditingNotification
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UITextFieldTextDidBeginEditingNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UITextViewTextDidBeginEditingNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UITextFieldTextDidEndEditingNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UITextViewTextDidEndEditingNotification
                                                  object:nil];
    self.targetTextInput = nil;
}

#pragma mark - editingDidBegin/End

- (void)editingDidBegin:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[UIResponder class]]) {
        if ([notification.object conformsToProtocol:@protocol(UITextInput)]) {
            self.targetTextInput = notification.object;
            return;
        }
    }
    // Not a valid target.
    self.targetTextInput = nil;
}

- (void)editingDidEnd:(NSNotification *)notification {
    self.targetTextInput = nil;
}

- (IBAction)keyTapped:(UIButton *)sender {
    if (self.targetTextInput) {
        UITextField *textField = (UITextField *)self.targetTextInput;
        NSRange dot = [textField.text rangeOfString:@"."];
        switch (sender.tag) {
            case 10:
                // Clear
            {
                UITextRange *selectedTextRange = [self.targetTextInput textRangeFromPosition:self.targetTextInput.beginningOfDocument toPosition:self.targetTextInput.endOfDocument];
                if (selectedTextRange) {
                    [self textInput:self.targetTextInput replaceTextAtTextRange:selectedTextRange withString:@""];
                }
                [[UIDevice currentDevice] playInputClick];
            }
                break;
            case 11:
				// Done
            {
                [self.targetTextInput resignFirstResponder];
            }
                break;
            default:
                // Max of 2 decimals
                if (dot.location == NSNotFound || textField.text.length <= dot.location + 2) {
                    UITextRange *selectedTextRange = self.targetTextInput.selectedTextRange;
                    if (selectedTextRange) {
                        [self textInput:self.targetTextInput replaceTextAtTextRange:selectedTextRange withString:[NSString stringWithFormat:@"%d", sender.tag]];
                    }
                    [[UIDevice currentDevice] playInputClick];
                }
                break;
        }
    }
}

#pragma mark - text replacement routines

// Check delegate methods to see if we should change the characters in range
- (BOOL)textInput:(id <UITextInput>)textInput shouldChangeCharactersInRange:(NSRange)range withString:(NSString *)string {
    if (textInput) {
        if ([textInput isKindOfClass:[UITextField class]]) {
            UITextField *textField = (UITextField *)textInput;
            if ([textField.delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
                if ([textField.delegate textField:textField
                    shouldChangeCharactersInRange:range
                                replacementString:string]) {
                    return YES;
                }
            } else {
                // Delegate does not respond, so default to YES
                return YES;
            }
        } else if ([textInput isKindOfClass:[UITextView class]]) {
            UITextView *textView = (UITextView *)textInput;
            if ([textView.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
                if ([textView.delegate textView:textView
                        shouldChangeTextInRange:range
                                replacementText:string]) {
                    return YES;
                }
            } else {
                // Delegate does not respond, so default to YES
                return YES;
            }
        }
    }
    return NO;
}

// Replace the text of the textInput in textRange with string if the delegate approves
- (void)textInput:(id <UITextInput>)textInput replaceTextAtTextRange:(UITextRange *)textRange withString:(NSString *)string {
    if (textInput) {
        if (textRange) {
            // Calculate the NSRange for the textInput text in the UITextRange textRange:
            int startPos                    = [textInput offsetFromPosition:textInput.beginningOfDocument
                                                                 toPosition:textRange.start];
            int length                      = [textInput offsetFromPosition:textRange.start
                                                                 toPosition:textRange.end];
            NSRange selectedRange           = NSMakeRange(startPos, length);
            
            if ([self textInput:textInput shouldChangeCharactersInRange:selectedRange withString:string]) {
                // Make the replacement:
                [textInput replaceRange:textRange withText:string];
            }
        }
    }
}

#pragma mark - UIInputViewAudioFeedback delegate

- (BOOL)enableInputClicksWhenVisible {
    return YES;
}

@end
