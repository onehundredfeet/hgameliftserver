package aws.gamelift;

function isNullOrEmpty(s: String): Bool {
    return s == null || s.length == 0;
}


function getEnv(name: String): String {

    #if js
    return cast(untyped __js__('process.env.${name}'), String);
    #else
    return Sys.getEnv(name);
    #end
}