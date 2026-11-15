// Set the font (and recycled working directory) of iTerm2's default profile.
// Usage: osascript -l JavaScript iterm-font.js <defaults domain> <font name> <size>
// Prints the profile it changed, or "no-font" / "no-profiles".
//
// iTerm picks its default profile at launch, before it loads dynamic profiles,
// so a dynamic profile can't reliably be the default. This edits the regular
// profile named by "Default Bookmark Guid" (or the first regular profile)
// through NSUserDefaults (cfprefsd) instead.
ObjC.import("AppKit");

function run(argv) {
    var domain = argv[0], fontName = argv[1], size = argv[2];
    if ($.NSFont.fontWithNameSize(fontName, parseFloat(size)).isNil()) return "no-font";

    var defaults = $.NSUserDefaults.alloc.initWithSuiteName(domain);
    var saved = defaults.arrayForKey("New Bookmarks");
    if (saved.isNil() || saved.count === 0) return "no-profiles";

    var profiles = saved.mutableCopy;
    var isRegular = function (p) { return p.objectForKey("Dynamic Profile Filename").isNil(); };
    var defaultGuid = defaults.stringForKey("Default Bookmark Guid");

    var target = -1;
    for (var i = 0; i < profiles.count; i++) {
        var p = profiles.objectAtIndex(i);
        if (!isRegular(p)) continue;
        if (target < 0) target = i;
        if (!defaultGuid.isNil() && ObjC.unwrap(p.objectForKey("Guid")) === ObjC.unwrap(defaultGuid)) {
            target = i;
            break;
        }
    }
    if (target < 0) return "no-profiles";

    var font = fontName + " " + size;
    var updated = profiles.objectAtIndex(target).mutableCopy;
    updated.setObjectForKey(font, "Normal Font");
    updated.setObjectForKey(font, "Non Ascii Font");
    updated.setObjectForKey("Recycle", "Custom Directory");
    profiles.replaceObjectAtIndexWithObject(target, updated);

    defaults.setObjectForKey(profiles, "New Bookmarks");
    defaults.synchronize;
    return ObjC.unwrap(updated.objectForKey("Name"));
}
