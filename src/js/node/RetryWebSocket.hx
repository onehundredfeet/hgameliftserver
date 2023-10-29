package js.node;

import js.node.util.Inspect;
import hxasync.Asyncable;
import js.node.WebSocket;
import aws.gamelift.Util;
import aws.gamelift.LogManager;
import aws.gamelift.ILog;
import haxe.Exception;

typedef RawWebSocketErrorEvent = {
	errno : Int,
	code : String,
	syscall : String,
	address : String,
	port : Int
};

class RetryWebSocket implements Asyncable{
	static inline var CONNECTING:Int = WebSocket.CONNECTING;
	static inline var OPEN:Int = WebSocket.OPEN;
	static inline var CLOSING:Int = WebSocket.CLOSING;
	static inline var CLOSED:Int = WebSocket.CLOSED;

	var _ws:WebSocket;

    public var onOpen:haxe.Constraints.Function;
    public var onError:(RawWebSocketErrorEvent)->Void;
    public var onClose:haxe.Constraints.Function;
    public var onMessage:haxe.Constraints.Function;

    public var maxConnectRetries:Int = 5;
    public var initialConnectRetryDelaySeconds:Int = 1;
    public var expansionConnectRetryDelaySeconds:Int = 2;
    public var maxDisconnectWaitRetries:Int = 5;
    public var disconnectWaitStepMillis:Int = 100;

	public function new(url:String) {
		_ws = new WebSocket(url);
        _ws.on('open', _onOpenFn);
        _ws.on('error', _onErrorFn);
        _ws.on('close', _onCloseFn);
        _ws.on('message', _onMessageFn);
	}

    var _serverError:Dynamic;
	private static final _log:ILog = LogManager.GetLogger(Type.typeof(RetryWebSocket));

    @async public function retryUntilOpen():Bool {
		var retryCount = 0;
		while (retryCount < maxConnectRetries) {
			switch (_ws.readyState) {
				case CONNECTING:
					@await delay(10);
				case OPEN:
					retryCount = maxConnectRetries;
					return true;
				case CLOSING:
					@await delay(10);
				case CLOSED:
					if (_serverError != null) {
						_log.error('Failed to connect to websocket server. Error: ${_serverError}');
						return false;
					}
					@await delay(Math.ceil((initialConnectRetryDelaySeconds + Math.pow(expansionConnectRetryDelaySeconds, retryCount) - 1.0) * 1000));
                    _log.info('Retrying connection to websocket server');
					var newSocket = new WebSocket(_ws.url);
                    newSocket.on('open', _onOpenFn);
                    newSocket.on('error', _onErrorFn);
                    newSocket.on('close', _onCloseFn);
                    newSocket.on('message', _onMessageFn);
					_ws = newSocket;
					retryCount++;
			}
		}
		return false;
	}
    
    @async public function retryUntilClosed():Bool {
		var closed = false;

		for (retryCount in 0...maxDisconnectWaitRetries) {
			switch (_ws.readyState) {
				case CONNECTING:
					try {
						_ws.close();
					} catch (e:Exception) {
						_log.warning("Failed to close old websocket after a connection refresh, ignoring");
					}
					@await delay(disconnectWaitStepMillis);
				case OPEN:
					try {
						_ws.close();
					} catch (e:Exception) {
						_log.warning("Failed to close old websocket after a connection refresh, ignoring");
					}
					@await delay(disconnectWaitStepMillis);
				case CLOSING:
					@await delay(disconnectWaitStepMillis);
				case CLOSED:
					closed = true;
					break;
			}
		}

		if (!closed) {
			_log.warning("Timed out waiting for the socket to close. Will retry closing.");
			return false;
		}
		return false;
	}

    function _onCloseFn(event):Void {
        if (onClose != null) {
            onClose(event);
        }
    }
    function _onErrorFn(event):Void {
        trace('error event: ${Inspect.inspect(event)}');

        var error:RawWebSocketErrorEvent = event;

  //      trace('error: ${error}');
        if (onError != null) {
            onError(error);
        }
    }
    function _onMessageFn(event):Void {
//        trace('event: ${Inspect.inspect(event)}');

		/*
		trace('messageRaw: ${messageRaw} type : ${Type.typeof(messageRaw)} data : ${data} str : ${messageStr}');
		for (field in Reflect.fields(messageRaw)) {
			trace('Field: ' + field + ', Value: ' + Reflect.field(messageRaw, field));
		  }
//		trace('Type of ${Type.typeof(messageStr)}');
		var strMessage:String = messageStr;

		try {
//			trace('Parsing... ${strMessage}');
			var json : {
				Error : String,
				Description : String
			} =haxe.Json.parse(strMessage);
//			trace('Json: ${json}');
			if (json != null) {
				if (!isNullOrEmpty(json.Error)) {
					_serverError = json.Description;
					return;
				}
			}
		} catch(e:Exception) {

		}
*/

        if (onMessage != null) {
            onMessage(event);
        }
    }
    function _onOpenFn(event):Void {
        if (onOpen != null) {
            onOpen(event);
        }
    }

	public var url(get, null):String;
    public var readyState(get, null):Int;

    public function close(?code:Int, ?reason:String):Void {
        _ws.close(code, reason);
    }
    public function send( data : Dynamic ) : Void {
        _ws.send(data);
    }
	function get_url():String {
		return _ws.url;
	}
    function get_readyState():Int {
        return _ws.readyState;
    }
    
}
