package aws.gamelift;


enum abstract LogLevel(Int) {
    var Fatal;
    var Error;
    var Warn;
    var Debug;
    var Info;
    var Trace;
}
class LogData {
    public var level : LogLevel;
    public var message : String;
    public var time : Date;
    public var file : String;
    public var line : Int;
    public var column : Int;
    public var context : String;
    public function toString() : String {
        return '${time} ${level} ${message}';
    }
}

interface ILog {
    function error(message:String) : Void;
    function warning(message:String) : Void;
    function debug(message:String) : Void;
    function info(message:String) : Void;
    function fatal(message:String) : Void;

    var isDebugEnabled(default,null) : Bool;
    var isInfoEnabled(default,null) : Bool;
    var isWarnEnabled(default,null) : Bool;
    var isErrorEnabled(default,null) : Bool;
}
