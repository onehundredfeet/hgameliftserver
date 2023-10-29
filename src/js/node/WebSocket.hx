package js.node;
import js.html.BinaryType;
import js.html.Blob;

@:jsRequire("ws")
extern class WebSocket {
    static inline var CONNECTING : Int = 0;
	static inline var OPEN : Int = 1;
	static inline var CLOSING : Int = 2;
	static inline var CLOSED : Int = 3;
	
	/**
		The absolute URL of the WebSocket.
	**/
	var url(default,null) : String;
	
	/**
		The current state of the connection.
	**/
	var readyState(default,null) : Int;
	
	/**
		The number of bytes of queued data.
	**/
	var bufferedAmount(default,null) : Int;
	
	/**
		The extensions selected by the server.
	**/
	var extensions(default,null) : String;
	
	/**
		The sub-protocol selected by the server.
	**/
	var protocol(default,null) : String;
		
	/**
		The binary data type used by the connection.
	**/
	var binaryType : BinaryType;
	
    /**
		An event listeners 
	**/
    function on( eventName : String, callback : haxe.Constraints.Function ) : Void;

	/** @throws DOMError */
	@:overload( function( url : String ) : Void {} )
	@:overload( function( url : String, protocols : String ) : Void {} )
	function new( url : String, protocols : Array<String> ) : Void;
	/** @throws DOMError */
	function close( ?code : Int, ?reason : String ) : Void;
	/** @throws DOMError */
	@:overload( function( data : String ) : Void {} )
	@:overload( function( data : Blob ) : Void {} )
	@:overload( function( data : js.lib.ArrayBuffer ) : Void {} )
	function send( data : Dynamic ) : Void;

}


