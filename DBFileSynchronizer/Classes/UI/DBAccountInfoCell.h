//
//  DBAccountInfoCell.h
//  ChineseDailyBread
//
//  Created by Eddie Hiu-Fung Lau on 9/4/14.
//
//

#import <UIKit/UIKit.h>

typedef void (^DBAccountInfoCellCompletionBlock)(BOOL);

@interface DBAccountInfoCell : UITableViewCell

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;
- (void) reload;
- (void) reloadWithCompletionBlock:(DBAccountInfoCellCompletionBlock)completion;

@end
