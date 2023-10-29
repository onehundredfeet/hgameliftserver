package aws.gamelift.server;

import hxasync.Asyncable;
import aws.gamelift.*;
import aws.gamelift.server.model.*;
import hx.concurrent.collection.SynchronizedMap;
import aws.gamelift.Util;
import aws.gamelift.GameLiftError;
using aws.gamelift.Extensions;
import aws.gamelift.server.model.Messages;
import js.lib.Promise;

class ExternalPromise<T> {
    var _resolve:T->Void;
    var _reject:Dynamic->Void;
    var _promise:Promise<T>;

    public inline function new() {
        _promise = new Promise<T>(function(res, rej) {
            _resolve = res;
            _reject = rej;
        });
    }

    public inline function resolve(value:T):Void {
        _resolve(value);
    }

    public inline function reject(error:Dynamic):Void {
        _reject(error);
    }

	public var promise(get, never):Promise<T>;
	
	public inline function get_promise():Promise<T> {
		return _promise;
	}
}

class GameLiftWebSocketRequestEntry {
	public var ep:ExternalPromise<GenericOutcome>;
	public var timed:Promise<GenericOutcome>;

	public function new(ep:ExternalPromise<GenericOutcome>, timed:Promise<GenericOutcome>) {
		this.ep = ep;
		this.timed = timed;
	}
}
class GameLiftWebSocketRequestHandler implements Asyncable {
	private static inline final ServiceCallTimeoutMillis = 5000;

	private final requestIdToPromise = SynchronizedMap.from(new Map<String,GameLiftWebSocketRequestEntry>());

	private final gameLiftWebSocket:IGameLiftWebSocket;

	public static var Log(default, null):ILog = LogManager.GetLogger(Type.typeof(GameLiftWebSocketRequestHandler));

	public function new(webSocket:IGameLiftWebSocket = null) {
		gameLiftWebSocket = webSocket;
	}

	public function clear() {
		for (key in requestIdToPromise.keys()) {
			var entry = requestIdToPromise.get(key);
			trace('Canceling request ${key}');
			entry.ep.reject("canceled");
		}
		requestIdToPromise.clear();
	}
	/**
	 * Takes in a request and sends the request to our APIG via GameLiftWebSocket.
	 */
	/**
	 * Takes in a request and timeout and sends the request to our APIG via GameLiftWebSocket.
	 */
	 static function withTimeout<T>(promise:Promise<T>, ms:Int, hint : String = ""):Promise<T> {
        var timeout = new Promise<T>(function(resolve, reject) {
            var timer = haxe.Timer.delay(function() {
				trace('Timed out in $ms ms.');
                reject('${hint} Timed out in $ms ms.');
            }, ms);
            // Clear the timeout if the promise resolves
            promise.finally(()->{
				timer.stop();
			});
        });

        return Promise.race([promise, timeout]);
    }

	public function sendRequest(request:Message, timeoutMillis:Int = ServiceCallTimeoutMillis):Promise<GenericOutcome> {
		if (isNullOrEmpty(request.RequestId)) {
			Log.error("Request does not have request ID, cannot process.");
			return Promise.resolve(new GenericOutcome(new GameLiftError(GameLiftErrorType.INTERNAL_SERVICE_EXCEPTION)));
		}

		if (requestIdToPromise.exists(request.RequestId)) {
			Log.error('Request ${request.RequestId} already exists.');
			return Promise.resolve(new GenericOutcome(new GameLiftError(GameLiftErrorType.INTERNAL_SERVICE_EXCEPTION)));
		}



		var ep = new ExternalPromise();
		var promiseB : Promise<GenericOutcome> = withTimeout(ep.promise, timeoutMillis, request.RequestId);

		var promiseC = promiseB.catchError(function(e) {
			trace('Caught error ${e} on request ${request.RequestId}.');
			removePromise(request.RequestId);
		});

		if (!requestIdToPromise.trySet(request.RequestId, new GameLiftWebSocketRequestEntry(ep, promiseC))) {
			trace('Canceling...');
			ep.reject("canceled");	
			return Promise.resolve(new GenericOutcome(new GameLiftError(GameLiftErrorType.INTERNAL_SERVICE_EXCEPTION)));
		}

		
		trace ('Sending request "${request.RequestId}"');
		gameLiftWebSocket.sendMessage(request);

		return promiseC;
/*
		var promise = new js.lib.Promise<GenericOutcome>((resolve, reject) -> {
			reject("Request ${request.RequestId} timed out.");
			return new GenericOutcome(new GameLiftError(GameLiftErrorType.WEBSOCKET_CONNECT_FAILURE_TIMEOUT));
		});

		if (!requestIdToPromise.trySet(request.RequestId, promise)) {
			
			
		}
		var outcome = 
		if (!outcome.success) {
			promise.setCanceled();
			RemovePromise(request.RequestId);
			return outcome;
		}
		if (!promise.task.wait(timeoutMillis)) {
			Log.error('Response not received within time limit for request ${request.RequestId}.');
			if (RemovePromise(request.RequestId) != null) {
				promise.setCanceled();
			}
			return new GenericOutcome(new GameLiftError(GameLiftErrorType.WEBSOCKET_CONNECT_FAILURE_TIMEOUT));
		}
		return promise.task.result;
		*/
	}

	/**
	 * Takes in a request id that was made before and sets the given result. Any thread waiting on the result of the
	 * promise will then receive the result. Returns true if promise was resolved with result, false otherwise
	 * (e.g. requestId not found).
	 */
	public function handleResponse(requestId:String, result:GenericOutcome) {
        var promise : GameLiftWebSocketRequestEntry = removePromise(requestId);
		if (promise != null) {
			trace('Found promise for request "${requestId}".');
			promise.ep.resolve(result);
			return promise;
		}
		Log.debug('No promise found for request "${requestId}."');
		return null;
	}

	private function removePromise(requestId:String):GameLiftWebSocketRequestEntry {
		trace('Removing promise for request "${requestId}".');
        var promise = requestIdToPromise.tryRemove(requestId);

		if (promise == null) {
			Log.debug('Request ${requestId} already removed.' );
			return null;
		}

		trace('removed promise for request "${requestId}".');
		return promise;
	}
}
