//
//  OEPocketsphinxController+RapidEars.h
//  RapidEars
//
//  Created by Halle Winkler on 5/3/12.
//  Copyright (c) 2012 Politepix. All rights reserved.
//

#import <OpenEars/OEPocketsphinxController.h>

/**
 @category  OEPocketsphinxController(RapidEars)
 @brief  A plugin which adds the ability to do live speech recognition to OEPocketsphinxController.
 
 ## Usage examples
 > Preparing to use the class:
 @htmlinclude OEPocketsphinxController+RapidEars_Preconditions.txt
 > What to add to your implementation:
 @htmlinclude OEPocketsphinxController+RapidEars_Implementation.txt
 @warning Please read OpenEars' OEPocketsphinxController for information about instantiating this object.
 */

/**\cond HIDDEN_SYMBOLS*/   

/**\endcond */   

@interface OEPocketsphinxController (RapidEars)

/**Start the listening loop. You will call this instead of the old OEPocketsphinxController method*/
- (void) startRealtimeListeningWithLanguageModelAtPath:(NSString *)languageModelPath dictionaryAtPath:(NSString *)dictionaryPath acousticModelAtPath:(NSString *)acousticModelPath;

/**Turn logging on or off.*/
- (void) setRapidEarsToVerbose:(BOOL)verbose;

/**You can decide not to have the final hypothesis delivered if you are only interested in live hypotheses. This will save some CPU work.*/
- (void) setFinalizeHypothesis:(BOOL)finalizeHypothesis;

/** Setting this to true will cause you to receive partial hypotheses even when they match the last one you received. This defaults to FALSE, so if you only want to receive new hypotheses you don't need to use this.*/
- (void) setReturnDuplicatePartials:(BOOL)duplicatePartials; 

/** EXPERIMENTAL. This will give you N-Best results, most likely at the expense of performance. This can't be used with setReturnSegments: or setReturnSegmentTimes: . This is a wholly experimental feature and can't be used with overly-large language models or on very slow devices. It is the sole responsibility of the developer to test whether performance is acceptable with this feature and to reduce language model size and latencyTuning in order to get a good UX – there is absolutely no guarantee given that this feature will not result in searches which are too slow to return if it has too much to do. If you want to turn nbest off, you must first set this and OEPocketsphinxController's returnNBest property to FALSE, and after that you must set other setters you are switching to such as setReturnSegments, setReturnSegmentTimes, etc. If this experimental feature results in an excess of support requests due to the experimental nature of the feature, resulting in expected issues such as slowness of realtime n-best being reported as high-priority bugs, it could end up being removed in a future version. */
- (void) setRapidEarsReturnNBest:(BOOL)nBest;

/** This is the maximum number of nbest results you want to receive. You may receive fewer than this number but will not receive more. This defaults to 3 for RapidEars; larger numbers are likely to use more CPU and smaller numbers less. Settings below 2 are invalid and will be set to 2. It is not recommended to ever set this above 3 for realtime processing. */
- (void) setRapidEarsNBestNumber:(NSUInteger)rapidEarsNBestNumber;

/** Setting this to true will cause you to receive your hypotheses as separate words rather than a single NSString. This is a requirement for using OEEventsObserver delegate methods that contain timing or per-word scoring. This can't be used with N-best.*/
- (void) setReturnSegments:(BOOL)returnSegments; 

/** Setting this to true will cause you to receive segment hypotheses with timing attached. This is a requirement for using OEEventsObserver delegate methods that contain word timing information. It only works if you have setReturnSegments set to TRUE. This can't be used with N-best.*/
- (void) setReturnSegmentTimes:(BOOL)returnSegmentTimes; 

/** This can take a value between 1 and 4. 4 means the lowest-latency for partial hypotheses and 1 means the highest. The lower the latency, the higher the CPU overhead, and vice versa. This defaults to 4 (the lowest latency and highest CPU overhead) so you will reduce it if you have a need for less CPU overhead until you find the ideal balance between CPU overhead and speed of hypothesis.*/
- (void) setLatencyTuning:(NSInteger)latencyTuning;

@end



