// finder-setup: make Finder's sidebar favorites and nested view settings match
// what's passed in, and do nothing when they already do.
//
//   finder-setup [--favorite <path>]... [--hide-hard-drives]
//                [--string <Key.Sub.Key> <value>]... [--bool <Key.Sub.Key> <true|false>]...
//
// --favorite (repeatable, in order) sets the sidebar's Favorites to exactly
// those folders; missing folders are skipped. --string/--bool set values in
// com.apple.finder, where dots step into nested dictionaries (which `defaults
// write` can't reach). Prints one line per change and exits 0; prints nothing
// when there was nothing to do.

#import <CoreServices/CoreServices.h>
#import <Foundation/Foundation.h>

#pragma clang diagnostic ignored "-Wdeprecated-declarations"

static NSString *const kFinderDomain = @"com.apple.finder";
static NSString *const kShowHardDrives = @"com.apple.LSSharedFileList.FavoriteVolumes.ShowHardDrives";

static NSArray<NSURL *> *currentFavorites(LSSharedFileListRef list, NSArray **itemsOut) {
    UInt32 seed = 0;
    NSArray *items = CFBridgingRelease(LSSharedFileListCopySnapshot(list, &seed));
    NSMutableArray<NSURL *> *urls = [NSMutableArray array];
    for (id item in items) {
        CFURLRef url = LSSharedFileListItemCopyResolvedURL(
            (__bridge LSSharedFileListItemRef)item,
            kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes, NULL);
        // Special items (Recents, AirDrop) have no URL; a sentinel keeps them
        // counted, so a list containing one never compares equal
        [urls addObject:url ? CFBridgingRelease(url) : [NSURL URLWithString:@"special:"]];
    }
    if (itemsOut) *itemsOut = items;
    return urls;
}

static BOOL syncFavorites(NSArray<NSURL *> *wanted) {
    LSSharedFileListRef list = LSSharedFileListCreate(NULL, kLSSharedFileListFavoriteItems, NULL);
    if (!list) {
        fprintf(stderr, "finder-setup: can't open the sidebar favorites list\n");
        exit(1);
    }
    NSArray *items = nil;
    NSArray<NSURL *> *have = currentFavorites(list, &items);

    BOOL same = have.count == wanted.count;
    for (NSUInteger i = 0; same && i < wanted.count; i++) {
        same = [have[i].URLByStandardizingPath.path isEqualToString:wanted[i].URLByStandardizingPath.path];
    }
    if (same) {
        CFRelease(list);
        return NO;
    }

    for (id item in items) LSSharedFileListItemRemove(list, (__bridge LSSharedFileListItemRef)item);
    for (NSURL *url in wanted) {
        LSSharedFileListItemRef added = LSSharedFileListInsertItemURL(
            list, kLSSharedFileListItemLast, NULL, NULL, (__bridge CFURLRef)url, NULL, NULL);
        if (added) CFRelease(added);
    }
    CFRelease(list);
    return YES;
}

static BOOL hideHardDrives(void) {
    LSSharedFileListRef list = LSSharedFileListCreate(NULL, kLSSharedFileListFavoriteVolumes, NULL);
    if (!list) {
        fprintf(stderr, "finder-setup: can't open the sidebar locations list\n");
        exit(1);
    }
    CFTypeRef value = LSSharedFileListCopyProperty(list, (__bridge CFStringRef)kShowHardDrives);
    BOOL shown = value && CFGetTypeID(value) == CFBooleanGetTypeID() && CFBooleanGetValue(value);
    if (value) CFRelease(value);
    if (shown) LSSharedFileListSetProperty(list, (__bridge CFStringRef)kShowHardDrives, kCFBooleanFalse);
    CFRelease(list);
    return shown;
}

// Set a dotted key path in a nested preferences dictionary, creating missing
// levels. Returns YES when the stored value changed
static BOOL setPref(NSString *keyPath, id value) {
    NSArray<NSString *> *keys = [keyPath componentsSeparatedByString:@"."];
    NSString *top = keys.firstObject;
    id current = CFBridgingRelease(CFPreferencesCopyAppValue((__bridge CFStringRef)top, (__bridge CFStringRef)kFinderDomain));

    if (keys.count == 1) {
        if ([current isEqual:value]) return NO;
        CFPreferencesSetAppValue((__bridge CFStringRef)top, (__bridge CFPropertyListRef)value, (__bridge CFStringRef)kFinderDomain);
        return YES;
    }

    NSMutableDictionary *root = [current isKindOfClass:[NSDictionary class]]
        ? CFBridgingRelease(CFPropertyListCreateDeepCopy(NULL, (__bridge CFPropertyListRef)current, kCFPropertyListMutableContainersAndLeaves))
        : [NSMutableDictionary dictionary];
    NSMutableDictionary *node = root;
    for (NSUInteger i = 1; i + 1 < keys.count; i++) {
        id child = node[keys[i]];
        if (![child isKindOfClass:[NSMutableDictionary class]]) {
            child = [NSMutableDictionary dictionary];
            node[keys[i]] = child;
        }
        node = child;
    }
    if ([node[keys.lastObject] isEqual:value]) return NO;
    node[keys.lastObject] = value;
    CFPreferencesSetAppValue((__bridge CFStringRef)top, (__bridge CFPropertyListRef)root, (__bridge CFStringRef)kFinderDomain);
    return YES;
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSMutableArray<NSURL *> *favorites = nil;
        BOOL wantHideHardDrives = NO;
        NSMutableArray<NSArray *> *prefs = [NSMutableArray array];

        for (int i = 1; i < argc; i++) {
            NSString *arg = @(argv[i]);
            if ([arg isEqualToString:@"--favorite"] && i + 1 < argc) {
                if (!favorites) favorites = [NSMutableArray array];
                NSString *path = @(argv[++i]).stringByExpandingTildeInPath;
                BOOL isDir = NO;
                if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir) {
                    [favorites addObject:[NSURL fileURLWithPath:path isDirectory:YES]];
                } else {
                    printf("skipped missing favorite %s\n", path.UTF8String);
                }
            } else if ([arg isEqualToString:@"--hide-hard-drives"]) {
                wantHideHardDrives = YES;
            } else if ([arg isEqualToString:@"--string"] && i + 2 < argc) {
                [prefs addObject:@[ @(argv[i + 1]), @(argv[i + 2]) ]];
                i += 2;
            } else if ([arg isEqualToString:@"--bool"] && i + 2 < argc) {
                [prefs addObject:@[ @(argv[i + 1]), @(strcmp(argv[i + 2], "true") == 0) ]];
                i += 2;
            } else {
                fprintf(stderr, "finder-setup: unexpected argument %s\n", argv[i]);
                return 2;
            }
        }

        if (favorites && syncFavorites(favorites)) printf("sidebar favorites updated\n");
        if (wantHideHardDrives && hideHardDrives()) printf("hard disks hidden from the sidebar\n");

        BOOL prefsChanged = NO;
        for (NSArray *pref in prefs) {
            if (setPref(pref[0], pref[1])) {
                printf("set %s\n", [pref[0] UTF8String]);
                prefsChanged = YES;
            }
        }
        if (prefsChanged) {
            CFPreferencesAppSynchronize((__bridge CFStringRef)kFinderDomain);
            printf("restart-finder\n");
        }
    }
    return 0;
}
