//
//  OELanguageModelGenerator+RuleORama.h
//  RuleORama
//
//  Created by Halle on 10/27/13.
//  Copyright (c) 2013 Politepix. All rights reserved.
//

#import <OpenEars/OELanguageModelGenerator.h>

/**
 @category  OELanguageModelGenerator(RuleORama)
 @brief  A plugin which adds the ability to create rules-based grammars.
 
 ## Usage examples
 > What to add to your OpenEars implementation:
 @htmlinclude OELanguageModelGenerator+RuleORama_Implementation.txt
 */

@interface OELanguageModelGenerator (RuleORama) 

/**Dynamically create a fast grammar using OpenEars' natural language system for defining a speech recognition ruleset, that can be used with OEPocketsphinxController or RapidEars. The NSDictionary you submit to the argument generateGrammarFromDictionary: is a key-value pair consisting of an NSArray of words stored in NSStrings indicating the vocabulary to be listened for, and an NSString key which is one of the following #defines from GrammarDefinitions.h, indicating the rule for the vocabulary in the NSArray:

 \verbatim
ThisWillBeSaidOnce
ThisCanBeSaidOnce
ThisWillBeSaidWithOptionalRepetitions
ThisCanBeSaidWithOptionalRepetitions
OneOfTheseWillBeSaidOnce
OneOfTheseCanBeSaidOnce
OneOfTheseWillBeSaidWithOptionalRepetitions // NOTE: RULEORAMA ONLY SUPPORTS A SINGLE REPETITION
OneOfTheseCanBeSaidWithOptionalRepetitions // NOTE: RULEORAMA ONLY SUPPORTS A SINGLE REPETITION
\endverbatim
 
Breaking them down one at a time for their specific meaning in defining a rule:

\verbatim
ThisWillBeSaidOnce // This indicates that the word or words in the array must be said (in sequence, in the case of multiple words), one time.
ThisCanBeSaidOnce // This indicates that the word or words in the array can be said (in sequence, in the case of multiple words), one time, but can also be omitted as a whole from the utterance.
ThisWillBeSaidWithOptionalRepetitions // This indicates that the word or words in the array must be said (in sequence, in the case of multiple words), one time or more.
ThisCanBeSaidWithOptionalRepetitions // This indicates that the word or words in the array can be said (in sequence, in the case of multiple words), one time or more, but can also be omitted as a whole from the utterance.
OneOfTheseWillBeSaidOnce // This indicates that exactly one selection from the words in the array must be said one time.
OneOfTheseCanBeSaidOnce // This indicates that exactly one selection from the words in the array can be said one time, but that all of the words can also be omitted from the utterance.
OneOfTheseWillBeSaidWithOptionalRepetitions // This indicates that exactly one selection from the words in the array must be said, one time or more. NOTE: RULEORAMA ONLY SUPPORTS A SINGLE REPETITION
OneOfTheseCanBeSaidWithOptionalRepetitions // This indicates that exactly one selection from the words in the array can be said, one time or more, but that all of the words can also be omitted from the utterance. NOTE: RULEORAMA ONLY SUPPORTS A SINGLE REPETITION
\endverbatim
 
Since an NSString in these NSArrays can also be a phrase, references to words above should also be understood to apply to complete phrases when they are contained in a single NSString.

A key-value pair can also have NSDictionaries in the NSArray instead of NSStrings, or a mix of NSStrings and NSDictionaries, meaning that you can nest rules in other rules.

Here is an example of a complex rule which can be submitted to the generateGrammarFromDictionary: argument followed by an explanation of what it means:

 \verbatim
@{
    ThisWillBeSaidOnce : @[
        @{ OneOfTheseCanBeSaidOnce : @[@"HELLO COMPUTER", @"GREETINGS ROBOT"]},
        @{ OneOfTheseWillBeSaidOnce : @[@"DO THE FOLLOWING", @"INSTRUCTION"]},
        @{ OneOfTheseWillBeSaidOnce : @[@"GO", @"MOVE"]},
        @{ThisWillBeSaidWithOptionalRepetitions : @[
            @{ OneOfTheseWillBeSaidOnce : @[@"10", @"20",@"30"]}, 
            @{ OneOfTheseWillBeSaidOnce : @[@"LEFT", @"RIGHT", @"FORWARD"]}
        ]},
        @{ OneOfTheseWillBeSaidOnce : @[@"EXECUTE", @"DO IT"]},
        @{ ThisCanBeSaidOnce : @[@"THANK YOU"]}
    ]
};
\endverbatim
 
Breaking it down step by step to explain exactly what the contents mean:

\verbatim
@{
    ThisWillBeSaidOnce : @[ // This means that a valid utterance for this ruleset will obey all of the following rules in sequence in a single complete utterance:
            @{ OneOfTheseCanBeSaidOnce : @[@"HELLO COMPUTER", @"GREETINGS ROBOT"]}, // At the beginning of the utterance there is an optional statement. The optional statement can be either "HELLO COMPUTER" or "GREETINGS ROBOT" or it can be omitted.
            @{ OneOfTheseWillBeSaidOnce : @[@"DO THE FOLLOWING", @"INSTRUCTION"]}, // Next, an utterance will have exactly one of the following required statements: "DO THE FOLLOWING" or "INSTRUCTION".
            @{ OneOfTheseWillBeSaidOnce : @[@"GO", @"MOVE"]}, // Next, an utterance will have exactly one of the following required statements: "GO" or "MOVE"
            @{ThisWillBeSaidWithOptionalRepetitions : @[ // Next, an utterance will have a minimum of one statement of the following nested instructions, but can also accept multiple valid versions of the nested instructions:
                @{ OneOfTheseWillBeSaidOnce : @[@"10", @"20",@"30"]}, // Exactly one utterance of either the number "10", "20" or "30",
                @{ OneOfTheseWillBeSaidOnce : @[@"LEFT", @"RIGHT", @"FORWARD"]} // Followed by exactly one utterance of either the word "LEFT", "RIGHT", or "FORWARD".
            ]},
        @{ OneOfTheseWillBeSaidOnce : @[@"EXECUTE", @"DO IT"]}, // Next, an utterance must contain either the word "EXECUTE" or the phrase "DO IT",
        @{ ThisCanBeSaidOnce : @[@"THANK YOU"]} and there can be an optional single statement of the phrase "THANK YOU" at the end.
    ]
};
\endverbatim
 
So as examples, here are some sentences that this ruleset will report as hypotheses from user utterances:

 \verbatim
"HELLO COMPUTER DO THE FOLLOWING GO 20 LEFT FORWARD EXECUTE THANK YOU"
"GREETINGS ROBOT DO THE FOLLOWING MOVE 10 FORWARD DO IT"
"INSTRUCTION 20 LEFT LEFT EXECUTE"
\endverbatim
 
But it will not report hypotheses for sentences such as the following which are not allowed by the rules:

 \verbatim
"HELLO COMPUTER HELLO COMPUTER"
"MOVE 10"
"GO RIGHT"
\endverbatim
 
Since you as the developer are the designer of the ruleset, you can extract the behavioral triggers from your app from hypotheses which observe your rules.

The words and phrases in languageModelArray must be written with capital letters exclusively, for instance "word" must appear in the array as "WORD".

The last two arguments of the method work identically to the equivalent language model method. The withFilesNamed: argument takes an NSString which is the naming you would like for the files output by this method. Please give your grammars unique names within your session if you want to switch between them, so there is no danger of the engine getting confused between new and old grammars and dictionaries at the time of switching. The argument acousticModelPath takes the path to the relevant acoustic model.

 If this method is successful it will return nil. If it returns nil, you can use the methods pathToSuccessfullyGeneratedDictionaryWithRequestedName: and pathToSuccessfullyGeneratedLanguageModelWithRequestedName: to get your paths to your newly-generated RuleORama fast grammar and dictionaries for use with OEPocketsphinxController. If it doesn't return nil, it will return an error which you can check for debugging purposes.

*/

- (NSError *) generateFastGrammarFromDictionary:(NSDictionary *)grammarDictionary withFilesNamed:(NSString *)fileName forAcousticModelAtPath:(NSString *)acousticModelPath;

/** This is a convenience method for when you want to create a single sentence where the rule is that it is recognized progressively until it is complete, for instance if you are having the user read out a line from a book and want it to emerge in real time as they say it. The advantage to doing this with RuleORama versus a default language model is that RuleORama will not reorder the sentence words. */

- (NSError *) generateFastSentenceRuleFromString:(NSString *)sentenceString withFilesNamed:(NSString *)fileName forAcousticModelAtPath:(NSString *)acousticModelPath;

- (NSString *) pathToSuccessfullyGeneratedRuleORamaRulesetWithRequestedName:(NSString *)name;
/**Rule-O-Rama will warn you if you have rulesets with nothing in them but optionals, since this creates an overly-large and/or impossible logic for the grammar. If you get tired of hearing the warning and want to use those rulesets despite the mentioned problems, you can turn the warning off, but please don't report bugs that occur when you are receiving these warnings, supressed or otherwise.*/
@property(nonatomic,assign) BOOL noWarningsAboutPureOptionalRulesets;

/**Rule-O-Rama can look for every alternative pronunciation of a term, however, this can result is extremely large grammars and phonetic dictionaries. If you have more than a few rules and you are seeing accuracy issues, try setting this to TRUE in order to see if the reduced-size search space results in more accuracy even without the alternative pronunciations.*/
@property(nonatomic,assign) BOOL noAlternativePronunciations;

@end
