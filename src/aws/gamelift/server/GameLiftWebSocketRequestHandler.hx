package aws.gamelift.server;

import aws.gamelift.*;
import aws.gamelift.server.model.*;
import hx.concurrent.collection.SynchronizedMap;
import aws.gamelift.Util;
import aws.gamelift.GameLiftError;
using aws.gamelift.Extensions;

class GameLiftWebSocketRequestHandler {
	private static inline final ServiceCallTimeoutMillis = 20000;

	private final requestIdToPromise = SynchronizedMap.from(new Map<String, TaskCompletionSource<GenericOutcome>>());

	private final gameLiftWebSocket:IGameLiftWebSocket;

	public static var Log(default, null):ILog = LogManager.GetLogger(Type.typeof(GameLiftWebSocketRequestHandler));

	public function new(webSocket:IGameLiftWebSocket = null) {
		gameLiftWebSocket = webSocket;
	}

	/**
	 * Takes in a request and sends the request to our APIG via GameLiftWebSocket.
	 */
	/**
	 * Takes in a request and timeout and sends the request to our APIG via GameLiftWebSocket.
	 */
	public function SendRequest(request:Message, timeoutMillis:Int = ServiceCallTimeoutMillis):GenericOutcome {
		if (isNullOrEmpty(request.requestId)) {
			Log.error("Request does not have request ID, cannot process.");
			return new GenericOutcome(new GameLiftError(GameLiftErrorType.INTERNAL_SERVICE_EXCEPTION));
		}
		var promise = new TaskCompletionSource<GenericOutcome>();
		if (!requestIdToPromise.trySet(request.requestId, promise)) {
			Log.error('Request ${request.requestId} already exists.');
			promise.setCanceled();
			return new GenericOutcome(new GameLiftError(GameLiftErrorType.INTERNAL_SERVICE_EXCEPTION));
		}
		var outcome = gameLiftWebSocket.sendMessage(request);
		if (!outcome.success) {
			promise.setCanceled();
			RemovePromise(request.requestId);
			return outcome;
		}
		if (!promise.task.wait(timeoutMillis)) {
			Log.error('Response not received within time limit for request ${request.requestId}.');
			if (RemovePromise(request.requestId) != null) {
				promise.setCanceled();
			}
			return new GenericOutcome(new GameLiftError(GameLiftErrorType.WEBSOCKET_CONNECT_FAILURE_TIMEOUT));
		}
		return promise.task.result;
	}

	/**
	 * Takes in a request id that was made before and sets the given result. Any thread waiting on the result of the
	 * promise will then receive the result. Returns true if promise was resolved with result, false otherwise
	 * (e.g. requestId not found).
	 */
	public function HandleResponse(requestId:String, result:GenericOutcome) {
        var promise = RemovePromise(requestId);
		if (promise != null) {
			promise.setResult(result);
			return promise;
		}
		Log.debug('No promise found for request ${requestId}.');
		return null;
	}

	private function RemovePromise(requestId:String):TaskCompletionSource<GenericOutcome> {
        var promise = requestIdToPromise.tryRemove(requestId);

		if (promise == null) {
			Log.debug('Request ${requestId} already removed.' );
			return null;
		}
		return promise;
	}
}
