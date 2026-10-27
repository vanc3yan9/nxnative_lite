#import <Foundation/Foundation.h>
// Returns nil only when every required file matches the bundled manifest.
NSString *dm_validate_external_data(NSString *root, NSString *manifestPath, NSString *cachePath,
                                   void (^progress)(NSUInteger, NSUInteger));

BOOL dm_external_receipt_matches(NSString *manifestPath, NSString *receiptPath);
BOOL dm_write_external_receipt(NSString *manifestPath, NSString *receiptPath);
