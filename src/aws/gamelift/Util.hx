package aws.gamelift;

import js.node.Process;

function isNullOrEmpty(s: String): Bool {
    return s == null || s.length == 0;
}


function getEnv(name: String): String {
    return Sys.getEnv(name);
}

function delay(ms:Int):js.lib.Promise<Dynamic> {
    return new js.lib.Promise<Dynamic>(function(resolve, reject) {
        haxe.Timer.delay(function() {
            resolve(null);
        }, ms);
    });
}