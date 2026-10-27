#import <Foundation/Foundation.h>
#import "DmExternalData.h"
#import <CommonCrypto/CommonDigest.h>
static NSString *sha(NSData *d) { unsigned char h[32]; CC_SHA256(d.bytes,(CC_LONG)d.length,h); NSMutableString *s=[NSMutableString string]; for(int i=0;i<32;i++)[s appendFormat:@"%02x",h[i]]; return s; }
int main(void) { @autoreleasepool {
 NSString *root=[NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
 NSFileManager *fm=NSFileManager.defaultManager; [fm createDirectoryAtPath:[root stringByAppendingPathComponent:@"romfs"] withIntermediateDirectories:YES attributes:nil error:nil];
 NSString *f=[root stringByAppendingPathComponent:@"romfs/DATA1.bin"], *m=[root stringByAppendingPathComponent:@"manifest.json"], *cache=[root stringByAppendingPathComponent:@"cache.plist"];
 NSData *data=[@"good" dataUsingEncoding:NSUTF8StringEncoding];
 NSDictionary *entry=@{@"path":@"romfs/DATA1.bin",@"size":@4,@"sha256":sha(data)};
 NSData *manifest=[NSJSONSerialization dataWithJSONObject:@{@"schema":@1,@"files":@[entry]} options:0 error:nil]; [manifest writeToFile:m atomically:YES];
 NSCAssert(dm_validate_external_data(root,m,cache,nil)!=nil,@"missing accepted");
 [data writeToFile:f atomically:YES]; NSCAssert(dm_validate_external_data(root,m,cache,nil)==nil,@"valid rejected");
 NSCAssert(dm_validate_external_data(root,m,cache,nil)==nil,@"cache rejected");
 NSString *receipt=[root stringByAppendingPathComponent:@"receipt.plist"];
 NSCAssert(!dm_external_receipt_matches(m,receipt),@"missing receipt accepted");
 NSCAssert(dm_write_external_receipt(m,receipt),@"receipt write failed");
 NSCAssert(dm_external_receipt_matches(m,receipt),@"valid receipt rejected");
 [[@"different manifest" dataUsingEncoding:NSUTF8StringEncoding] writeToFile:m atomically:YES];
 NSCAssert(!dm_external_receipt_matches(m,receipt),@"stale receipt accepted");
 [manifest writeToFile:m atomically:YES];

 [[@"bad!" dataUsingEncoding:NSUTF8StringEncoding] writeToFile:f atomically:YES]; NSCAssert(dm_validate_external_data(root,m,cache,nil)!=nil,@"same-size corruption accepted");
 [[@"x" dataUsingEncoding:NSUTF8StringEncoding] writeToFile:f atomically:YES]; NSCAssert(dm_validate_external_data(root,m,cache,nil)!=nil,@"partial copy accepted");
 [data writeToFile:f atomically:YES]; NSCAssert(dm_validate_external_data(root,m,cache,nil)==nil,@"retry failed");
 [fm removeItemAtPath:f error:nil]; [fm createSymbolicLinkAtPath:f withDestinationPath:@"/etc/hosts" error:nil]; NSCAssert(dm_validate_external_data(root,m,cache,nil)!=nil,@"symlink accepted");
 [fm removeItemAtPath:root error:nil]; puts("PASS missing, valid, cached, corruption, incomplete, retry, symlink");
} }
