#import "DmExternalData.h"
#import <CommonCrypto/CommonDigest.h>

static NSString *digest(NSData *data) {
    unsigned char hash[CC_SHA256_DIGEST_LENGTH]; CC_SHA256(data.bytes, (CC_LONG)data.length, hash);
    NSMutableString *s = [NSMutableString string];
    for (int i = 0; i < sizeof(hash); i++) [s appendFormat:@"%02x", hash[i]];
    return s;
}
BOOL dm_external_receipt_matches(NSString *manifestPath, NSString *receiptPath) {
    NSData *raw = [NSData dataWithContentsOfFile:manifestPath];
    NSDictionary *receipt = [NSDictionary dictionaryWithContentsOfFile:receiptPath];
    return raw && [receipt[@"manifest"] isEqual:digest(raw)];
}
BOOL dm_write_external_receipt(NSString *manifestPath, NSString *receiptPath) {
    NSData *raw = [NSData dataWithContentsOfFile:manifestPath];
    if (!raw) return NO;
    return [@{@"manifest":digest(raw)} writeToFile:receiptPath atomically:YES];
}
NSString *dm_validate_external_data(NSString *root, NSString *manifestPath, NSString *cachePath,
                                   void (^progress)(NSUInteger, NSUInteger)) {
    NSData *raw = [NSData dataWithContentsOfFile:manifestPath];
    NSDictionary *m = raw ? [NSJSONSerialization JSONObjectWithData:raw options:0 error:nil] : nil;
    if (![m isKindOfClass:NSDictionary.class] || ![m[@"schema"] isEqual:@1] ||
        ![m[@"files"] isKindOfClass:NSArray.class] || ![m[@"files"] count]) return @"Invalid resource manifest. Please reinstall the shell.";
    NSDictionary *cache = [NSDictionary dictionaryWithContentsOfFile:cachePath];
    NSString *manifestHash = digest(raw);
    NSDictionary *old = [cache[@"manifest"] isEqual:manifestHash] ? cache[@"files"] : nil;
    NSMutableDictionary *verified = [NSMutableDictionary dictionary];
    NSFileManager *fm = NSFileManager.defaultManager;
    NSString *resolvedRoot = root.stringByResolvingSymlinksInPath;
    NSUInteger index = 0;
    for (NSDictionary *entry in m[@"files"]) {
        @autoreleasepool {
            if (![entry isKindOfClass:NSDictionary.class]) return @"Invalid resource manifest entry.";
            NSString *rel = entry[@"path"], *expected = entry[@"sha256"];
            if (![rel isKindOfClass:NSString.class] || [rel hasPrefix:@"/"] ||
                [rel.pathComponents containsObject:@".."] ||
                !([rel hasPrefix:@"romfs/"] || [rel hasPrefix:@"aoc/"]) ||
                ![expected isKindOfClass:NSString.class] || expected.length != 64 ||
                ![entry[@"size"] isKindOfClass:NSNumber.class]) return @"Invalid resource manifest entry.";
            NSString *path = [root stringByAppendingPathComponent:rel];
            if (![path.stringByResolvingSymlinksInPath hasPrefix:[resolvedRoot stringByAppendingString:@"/"]])
                return [@"Resource path is outside the app folder: " stringByAppendingString:rel];
            NSDictionary *attrs = [fm attributesOfItemAtPath:path error:nil];
            if (![attrs[NSFileType] isEqual:NSFileTypeRegular]) return [@"Missing resource: " stringByAppendingString:rel];
            if (![attrs[NSFileSize] isEqual:entry[@"size"]]) return [@"Incomplete or wrong-version resource: " stringByAppendingString:rel];
            NSArray *stamp = @[attrs[NSFileSize], attrs[NSFileModificationDate], attrs[NSFileCreationDate]];
            if (![old[rel] isEqual:stamp]) {
                NSInputStream *stream = [NSInputStream inputStreamWithFileAtPath:path]; [stream open];
                CC_SHA256_CTX ctx; CC_SHA256_Init(&ctx);
                uint8_t buffer[1024 * 256]; NSInteger n; uint64_t total = 0;
                while ((n = [stream read:buffer maxLength:sizeof(buffer)]) > 0) { CC_SHA256_Update(&ctx, buffer, (CC_LONG)n); total += n; }
                [stream close];
                if (n < 0 || total != [entry[@"size"] unsignedLongLongValue]) return [@"Cannot read resource: " stringByAppendingString:rel];
                unsigned char hash[CC_SHA256_DIGEST_LENGTH]; CC_SHA256_Final(hash, &ctx);
                NSMutableString *hex = [NSMutableString string];
                for (int i = 0; i < sizeof(hash); i++) [hex appendFormat:@"%02x", hash[i]];
                if (![hex isEqual:expected]) return [@"Damaged or wrong-version resource: " stringByAppendingString:rel];
                NSDictionary *after = [fm attributesOfItemAtPath:path error:nil];
                if (![attrs isEqual:after]) return @"Resources changed during verification. Finish copying, then retry.";
            }
            verified[rel] = stamp;
            if (progress) progress(++index, [m[@"files"] count]);
        }
    }
    [@{@"manifest": manifestHash, @"files": verified} writeToFile:cachePath atomically:YES];
    return nil;
}
