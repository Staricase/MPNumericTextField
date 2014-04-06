//
//  MPNumericTextFieldDelegate.m
//
//  Version 1.0.0
//
//  Created by Daniele Di Bernardo on 06/04/14.
//  Copyright (c) 2014 Charcoal Design. All rights reserved.
//
//  The MIT License (MIT)
//  
//  Copyright (c) [2014] [Daniele Di Bernardo]
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//  

#import "MPNumericTextFieldDelegate.h"
#import "MPNumericTextField.h"
#import "MPFormatterUtils.h"

#ifndef min
#define min(a,b) a < b ? a : b
#endif

@implementation MPNumericTextFieldDelegate

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
  [textField resignFirstResponder];
  return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
  [textField resignFirstResponder];
  return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
  BOOL result = NO; //default to reject
  
  MPNumericTextField *fxText = (MPNumericTextField *)textField;
  NSLocale *locale = fxText.locale;
  NSNumberFormatter *currencyFormatter = [MPFormatterUtils currencyFormatter:locale];
  
  NSMutableCharacterSet *numberSet = [[NSCharacterSet decimalDigitCharacterSet] mutableCopy];
  [numberSet formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
  NSCharacterSet *nonNumberSet = [numberSet invertedSet];
  
  if([string length] == 0){ //backspace
    result = YES;
  }
  else{
    if([string stringByTrimmingCharactersInSet:nonNumberSet].length > 0){
      result = YES;
    }
  }
  
  //here we deal with the UITextField on our own
  if (result){
    //grab a mutable copy of what's currently in the UITextField
    NSMutableString* oldString = [[textField text] mutableCopy];
    NSNumber *n = nil;
    double mul;
    
    switch (fxText.type) {
      case MPNumericTextFieldCurrency:
        n = [MPFormatterUtils currencyFromString:fxText.encodedValue locale:locale];
        mul = pow(10, [currencyFormatter maximumFractionDigits] + 1);
        n = @(round(([n doubleValue] * mul))/10);
        break;
      case MPNumericTextFieldDecimal:
        n = [MPFormatterUtils numberFromString:fxText.encodedValue locale:locale];
        mul = pow(10, [currencyFormatter maximumFractionDigits] + 1);
        n = @(round(([n doubleValue] * mul))/10);
        break;
      case MPNumericTextFieldPercentage:
        n = [MPFormatterUtils percentageFromString:fxText.encodedValue locale:locale];
        n = @(round(([n doubleValue] * 10000))/10);
        break;
    }
    
    NSMutableString* mstring = [[n stringValue] mutableCopy];
    
    @try {
      if([mstring length] == 0){
        //special case...nothing in the field yet, so set a currency symbol first
        [mstring appendString:[locale objectForKey:NSLocaleCurrencySymbol]];
        
        //now append the replacement string
        [mstring appendString:string];
      }
      else {
        range.location -= [oldString length] - [mstring length];
        //adding a char or deleting?
        if([string length] > 0){
          [mstring insertString:string atIndex:range.location];
        }
        else {
          //delete case - the length of replacement string is zero for a delete
          range.length = min(range.length, [mstring length]);
          [mstring deleteCharactersInRange:range];
        }
      }
    }
    @catch (__unused id exception) {
      mstring = [@"" mutableCopy];
    }
    
    NSNumber *number = [MPFormatterUtils numberFromString:mstring locale:locale];
    double rate = pow(10, currencyFormatter.maximumFractionDigits);
    
    //now format the number back to the proper currency string
    //and get the grouping separators added in and put it in the UITextField
    switch (fxText.type) {
      case MPNumericTextFieldCurrency:
        number = @(number.doubleValue / rate);
        fxText.encodedValue = [MPFormatterUtils stringFromCurrency:number locale:locale];
        break;
      case MPNumericTextFieldDecimal:
        number = @(number.doubleValue / rate);
        fxText.encodedValue = [MPFormatterUtils stringFromNumber:number locale:locale];
        break;
      case MPNumericTextFieldPercentage:
        number = [MPFormatterUtils percentageFromString:mstring locale:locale];
        fxText.encodedValue = [MPFormatterUtils stringFromPercentage:number locale:locale];
        break;
    }
  }
  
  //always return no since we are manually changing the text field
  return NO;
}


@end