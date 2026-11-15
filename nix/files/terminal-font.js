// Set the font of Terminal.app's default and startup profiles.
// Usage: osascript -l JavaScript terminal-font.js <defaults domain> <font name> <size>
// Prints the profiles it changed (comma-separated), or "no-font" / "no-profiles".
//
// Terminal stores each profile's font as an archived NSFont, so this goes
// through NSUserDefaults (cfprefsd) rather than editing the plist file, which
// a running Terminal would overwrite.
ObjC.import("AppKit");

function run(argv) {
    var domain = argv[0], fontName = argv[1], size = parseFloat(argv[2]);
    var font = $.NSFont.fontWithNameSize(fontName, size);
    if (font.isNil()) return "no-font";

    var defaults = $.NSUserDefaults.alloc.initWithSuiteName(domain);
    var saved = defaults.dictionaryForKey("Window Settings");
    if (saved.isNil()) return "no-profiles";

    var names = [];
    ["Default Window Settings", "Startup Window Settings"].forEach(function (key) {
        var name = defaults.stringForKey(key);
        if (!name.isNil() && names.indexOf(ObjC.unwrap(name)) < 0) names.push(ObjC.unwrap(name));
    });
    if (names.length === 0) names.push("Basic");

    var data = $.NSKeyedArchiver.archivedDataWithRootObjectRequiringSecureCodingError(font, false, null);
    var profiles = saved.mutableCopy;
    var changed = names.filter(function (name) {
        var profile = profiles.objectForKey(name);
        if (profile.isNil()) return false;
        var updated = profile.mutableCopy;
        updated.setObjectForKey(data, "Font");
        profiles.setObjectForKey(updated, name);
        return true;
    });
    if (changed.length === 0) return "no-profiles";

    defaults.setObjectForKey(profiles, "Window Settings");
    defaults.synchronize;
    return changed.join(",");
}
