package js.node;

@:jsRequire("ws", "Server")
extern class WebSocketServer {
    function new( options : Dynamic ) : Void;
    function on( eventName : String, callback : haxe.Constraints.Function ) : Void;
    function send( data : Dynamic ) : Void;
}