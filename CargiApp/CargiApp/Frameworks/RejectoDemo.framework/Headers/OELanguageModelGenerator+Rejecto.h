//
//  OELanguageModelGenerator+Rejecto.h
//  Rejecto
//
//  Created by Halle on 8/14/12.
//  Copyright (c) 2012 Politepix. All rights reserved.
//

#import <OpenEars/OELanguageModelGenerator.h>

/**
 @category  OELanguageModelGenerator(Rejecto)
 @brief  A plugin which adds the ability to reject out-of-vocabulary words and statements when using OpenEars or RapidEars speech recognition. It is always necessary to run Rejecto while using a Rejecto model. There is no support for use of the output Rejecto model without running the plugin, since features of the plugin are developed on the assumption that it will be in use when its features are needed.
 
 ## Usage examples
 > What to add to your OpenEars implementation:
 @htmlinclude OELanguageModelGenerator+Rejecto_Implementation.txt
 @warning It isn't necessary to use optionalExclusions in order to try to tell Rejecto not to add a phoneme that is equivalent to a word in your vocabulary (for instance, Rejecto will add a phoneme by default that represents the "I" sound in the word "I" and the word "EYE", but if those words (or another word using the "I" sound by itself) are in your vocabulary, it will automatically not add the rejection phoneme that has the "I" sound. 
 
 It is only necessary to use optionalExclusions in the uncommon event that there is a phoneme that is being perceived more frequently than it is spoken, to the detriment of your speech detection of words that are really in your vocabulary.
 */

@interface OELanguageModelGenerator (Rejecto) 


/**This is the method which replaces OpenEars' OELanguageModelGenerator's generateLanguageModelFromArray: method in a project which you have added this plugin to. 
It generates a language model from an array of NSStrings which are the words and phrases you want OEPocketsphinxController or OEPocketsphinxController+RapidEars to understand. Putting a phrase in as a string makes it somewhat more probable that the phrase will be recognized as a phrase when spoken. <br>
 
 fileName is the way you want the output files to be named. Please give your language models unique names within your session if you want to switch between them, so there is no danger of the engine getting confused between new and old models and dictionaries at the time of switching. <br>
 
  If this method is successful it will return nil. If it returns nil, you can use the methods pathToSuccessfullyGeneratedDictionaryWithRequestedName: and pathToSuccessfullyGeneratedLanguageModelWithRequestedName: or pathToSuccessfullyGeneratedGrammarWithRequestedName: to get your paths to your newly-generated language models and grammars and dictionaries for use with OEPocketsphinxController. If it doesn't return nil, it will return an error which you can check for debugging purposes.
 
Pass in the path to the acoustic model you want to use, e.g. [OEAcousticModel pathToModel:@"AcousticModelEnglish"] or [OEAcousticModel pathToModel:@"AcousticModelSpanish"] or other Rejecto-compatible models you may be using (to be Rejecto-compatible a model needs to have a grapheme to phoneme model which has to be created by Politepix, so inquire about this at the forums if your model is missing this. Being Rejecto-compatible does not mean that results will be great or that Politepix will be able to give support for your results with models other than the default English model.<br>

optionalExclusions can either be set to nil, or given an NSArray of NSStrings which contain phonemes which you do not want to have added to the rejection model. A case in which you might want to do this is when you have over-active rejection such that words that are really in the vocabulary are being rejected. 
 
 You can first turn on deliverRejectedSpeechInHypotheses: in order to see which phonemes are being detected overzealously and then you can add them to the exclusionArray. Set this parameter to nil if you aren't using it.

usingVowelsOnly allows you to limit the rejection model to only vowel phonemes, which should improve performance in cases where that is desired. Set this parameter to FALSE if you aren't using it.

The last optional parameter is weight, which should usually be set to nil, but can also be set to an NSNumber with a floatValue that is greater than zero and equal or less than 2.0. This will increase or decrease the weighting of the rejection model relative to the rest of the vocabulary. 
 
 If it is less than 1.0 it will reduce the probability that the rejection model is detected, and if it is more than 1.0 it will increase the probability that the rejection model is detected. Only use this if your testing reveals that the rejection model is either being detected too frequently, or not frequently enough. 
 
 It defaults to 1.0 and if you don't set it to anything (and you shouldn't, unless you have reason to believe that you should increase or decrease the probability of the rejection model being detected) it will automatically use the right setting. If you set it to a value that is equal to 1.0, or zero or less, or more than 2.0, the weight setting will be ignored and the default will be used. An NSNumber with a float looks like this: [NSNumber numberWithFloat:1.1]. The weight setting has no effect on the rest of your vocabulary, only the rejection model probabilities. Set this parameter to nil if you aren't using it. */

- (NSError *) generateRejectingLanguageModelFromArray:(NSArray *)languageModelArray withFilesNamed:(NSString *)fileName withOptionalExclusions:(NSArray *) optionalExclusions usingVowelsOnly:(BOOL)vowelsOnly withWeight:(NSNumber *)weight forAcousticModelAtPath:(NSString *)acousticModelPath;


/**Rejecto defaults to hiding recognized statements which are not words from your vocabulary (out of vocabulary recognitions), however if you want to see them for troubleshooting purposes you can set this method to TRUE. 
   
 If you do not need to see them, you don't have to run the method since the default is for hypotheses with Rejecto phonemes only to not be returned. */

- (void) deliverRejectedSpeechInHypotheses:(BOOL)deliverRejectedSpeech;

@end
