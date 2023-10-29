package aws.gamelift;

import aws.gamelift.ILog;
class LogManager implements  ILog{
    public function error(message:String) : Void {
        trace(message);
    }
    public function warning(message:String) : Void {
        trace(message);
    }
    public function debug(message:String) : Void {
        trace(message);

    }
    public function info(message:String) : Void {
        trace(message);

    }
    public function fatal(message:String) : Void {
        trace(message);
    }

    public var isDebugEnabled(default,null) : Bool;
    public var isInfoEnabled(default,null) : Bool;
    public var isWarnEnabled(default,null) : Bool;
    public var isErrorEnabled(default,null) : Bool;

    function new() {}
    static var _this = new LogManager();
    public static function GetLogger(x : Dynamic) : ILog {
        return _this;
    }
}