//
//  OEEventsObserver+RapidEars.h
//  RapidEars
//
//  Created by Halle Winkler on 5/3/12.
//  Copyright (c) 2012 Politepix. All rights reserved.
//

#import <OpenEars/OEEventsObserver.h>

/**
 @category  OEEventsObserver(RapidEars)
 @brief  This plugin returns the results of your speech recognition by adding some new callbacks to the OEEventsObserver.
 
 ## Usage examples
 > What to add to your implementation:
 @htmlinclude OEEventsObserver+RapidEars_Implementation.txt
 @warning It is a requirement that any OEEventsObserver you use in a view controller or other object is a property of that object, or it won't work.
 */

@interface OEEventsObserver (RapidEars) <OEEventsObserverDelegate>

/**The engine has detected in-progress speech. This is the simple delegate method that should be used in most cases, which just returns the hypothesis string and its score.*/
- (void) rapidEarsDidReceiveLiveSpeechHypothesis:(NSString *)hypothesis recognitionScore:(NSString *)recognitionScore;

/**A final speech hypothesis was detected after the user paused. This is the simple delegate method that should be used in most cases, which just returns the hypothesis string and its score.*/
- (void) rapidEarsDidReceiveFinishedSpeechHypothesis:(NSString *)hypothesis recognitionScore:(NSString *)recognitionScore;

/**The engine has detected in-progress speech. Words and respective scores are delivered in separate arrays with corresponding indexes.*/
- (void) rapidEarsDidDetectLiveSpeechAsWordArray:(NSArray *)words andScoreArray:(NSArray *)scores;

/**A final speech hypothesis was detected after the user paused. Words and respective scores are delivered in separate arrays with corresponding indexes.*/
- (void) rapidEarsDidDetectFinishedSpeechAsWordArray:(NSArray *)words andScoreArray:(NSArray *)scores;

/**The engine has detected in-progress speech. Words and respective scores and timing are delivered in separate arrays with corresponding indexes.*/
- (void) rapidEarsDidDetectLiveSpeechAsWordArray:(NSArray *)words scoreArray:(NSArray *)scores startTimeArray:(NSArray *)startTimes endTimeArray:(NSArray *)endTimes;

/**A final speech hypothesis was detected after the user paused. Words and respective scores and timing are delivered in separate arrays with corresponding indexes.*/
- (void) rapidEarsDidDetectFinishedSpeechAsWordArray:(NSArray *)words scoreArray:(NSArray *)scores startTimeArray:(NSArray *)startTimes endTimeArray:(NSArray *)endTimes;

/**The engine has detected in-progress speech. N-Best words and respective scores are delivered in separate arrays with corresponding indexes.*/
- (void) rapidEarsDidDetectLiveSpeechAsNBestArray:(NSArray *)words andScoreArray:(NSArray *)scores;

/**A final speech hypothesis was detected after the user paused. N-Best words and respective scores are delivered in separate arrays with corresponding indexes.*/
- (void) rapidEarsDidDetectFinishedSpeechAsNBestArray:(NSArray *)words andScoreArray:(NSArray *)scores;

@end
