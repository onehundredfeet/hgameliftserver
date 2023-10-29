package aws.gamelift.server;

import haxe.Json;
import js.node.util.Inspect;
import hxasync.Asyncable;
import aws.gamelift.IGameLiftWebSocket;
import aws.gamelift.IWebSocketMessageHandler;
import aws.gamelift.server.model.*;
import aws.gamelift.ILog;
import haxe.Exception;
import aws.gamelift.GameLiftError;
import aws.gamelift.server.model.Messages;
import aws.gamelift.HttpStatusCode;
import aws.gamelift.CloseStatusCode;
import js.node.RetryWebSocket as WebSocket;
import js.node.RetryWebSocket.RawWebSocketErrorEvent as WebsocketError;
import aws.gamelift.Util;

typedef WebsocketMessageEvent = {data:Dynamic, origin:String, lastEventId:String, source:Dynamic, ports:Dynamic};

/// <summary>
/// Methods and classes to handle the connection between your game servers and GameLift.
/// </summary>
class GameLiftWebSocket implements IGameLiftWebSocket implements Asyncable {
	static inline var CONNECTING:Int = js.html.WebSocket.CONNECTING;
	static inline var OPEN:Int = js.html.WebSocket.OPEN;
	static inline var CLOSING:Int = js.html.WebSocket.CLOSING;
	static inline var CLOSED:Int = js.html.WebSocket.CLOSED;

	private static final PidKey = "pID";
	private static final SdkVersionKey = "sdkVersion";
	private static final FlavorKey = "sdkLanguage";
	private static final Flavor = "CSharp";
	private static final AuthTokenKey = "Authorization";
	private static final ComputeIdKey = "ComputeId";
	private static final FleetIdKey = "FleetId";
	private static final SocketClosingErrorMessage = "An error has occurred in closing the connection";

	private static final Log:ILog = LogManager.GetLogger(Type.typeof(GameLiftWebSocket));

	private final handler:IWebSocketMessageHandler;
	private var _socket:WebSocket;
	private var websocketUrl:String;
	private var processId:String;
	private var hostId:String;
	private var fleetId:String;
	private var authToken:String;
	private var _serverError:String;

	public function new(handler:IWebSocketMessageHandler) {
		this.handler = handler;
	}

	@async public function connect(websocketUrl:String, processId:String, hostId:String, fleetId:String, authToken:String):GenericOutcome {
		trace('Connecting....');
		this.websocketUrl = websocketUrl;
		this.processId = processId;
		this.hostId = hostId;
		this.fleetId = fleetId;
		this.authToken = authToken;

		return @await performConnect();
	}

	public function disconnect():GenericOutcome {
		Log.debug('Disconnecting. Socket state is: ${_socket.readyState}');
		// If the websocket is already closing (potentially initiated by GameLift from a ProcessEnding call earlier)
		// Attempt to wait for it to close.

		if (_socket.readyState == CLOSING) {
			Log.info("WebSocket is in Closing state. Attempting to wait for socket to close");
			if (_socket.retryUntilClosed() != null) {
				Log.warning("Timed out waiting for the socket to close. Will retry closing.");
			}
		}

		if (_socket.readyState != CLOSED) {
			Log.debug("Socket is not yet closed. Closing.");
			_socket.close();
		}

		Log.debug('Completed Disconnect. Socket state is: ${_socket.readyState}');

		return new GenericOutcome();
	}

	/**
	 * Develop utility method for simple local testing of sending a message across the websocket.
	 * Update the "action" and message/additional fields to test an API Gateway route/response
	 */
	public function sendMessage(message:Message):GenericOutcome {
		if (_socket == null) {
			Log.error('sendMessage : Socket is null');
			return new GenericOutcome();
		}
		var json:String = haxe.Json.stringify(message);
		try {
			Log.info('Sending message to GameLift: {$json}');
			_socket.send(json);
		} catch (e:Exception) {
			Log.error('Failed to send message to GameLift. Error: ${e.message}');
			return new GenericOutcome(new GameLiftError(GameLiftErrorType.SERVICE_CALL_FAILED));
		}

		return new GenericOutcome();
	}

	private function onMessage(messageRaw:Dynamic) {
		var messageStr = messageRaw.toString();

		try {
//			trace('Parsing... ${messageStr}');
			var json:{
				Error:String,
				Description:String
			} = haxe.Json.parse(messageStr);
//			trace('Json: ${json}');
			if (json != null) {
				if (!isNullOrEmpty(json.Error)) {
					_serverError = json.Description;
					return;
				}
			}
		} catch (e:Exception) {
			return;
		}

		try {
			// Parse message as a response message. This has error fields in it which will be null for a
			// successful response or generic message not associated with a request.
			var message = ResponseMessage.fromJson(messageStr);

			if (message == null) {
				Log.error('could not parse message. Data: ${messageStr}');
				return;
			}
			Log.info('Received Action ${message.Action} for GameLift with status ${message.StatusCode}. Data: ${message}');
			// It's safe to cast enums to ints in C#. Each HttpStatusCode enum is associated with its numerical
			// status code. RequestId will be null when we get a message not associated with a request.
			if (message.StatusCode != HttpStatusCode.OK && message.RequestId != null) {
				Log.warning('Received unsuccessful status code ${message.StatusCode} for request ${message.RequestId} with message \'${message.ErrorMessage}\'');
				handler.onErrorResponse(message.RequestId, message.StatusCode, message.ErrorMessage);
				return;
			}
			switch (message.Action) {
				case MessageActions.CreateGameSession:
					{
						var createGameSessionMessage = CreateGameSessionMessage.fromJson(messageStr);
						var gameSession = new GameSession(createGameSessionMessage);
						handler.onStartGameSession(gameSession);
					}
				case MessageActions.UpdateGameSession:
					{
						var updateGameSessionMessage = UpdateGameSessionMessage.fromJson(messageStr);
						handler.onUpdateGameSession(updateGameSessionMessage.GameSession, updateGameSessionMessage.UpdateReason,
							updateGameSessionMessage.BackfillTicketId);
					}
				case MessageActions.TerminateProcess:
					{
						var terminateProcessMessage = TerminateProcessMessage.fromJson(messageStr);
						handler.onTerminateProcess(terminateProcessMessage.TerminationTime);
					}
				case MessageActions.StartMatchBackfill:
					{
						var startMatchBackfillResponse = StartMatchBackfillResponse.fromJson(messageStr);
						handler.onStartMatchBackfillResponse(startMatchBackfillResponse.RequestId, startMatchBackfillResponse.TicketId);
					}
				case MessageActions.DescribePlayerSessions:
					{
						var describePlayerSessionsResponse:DescribePlayerSessionsResponse = haxe.Json.parse(messageStr); // new JsonSerializerSettings { NullValueHandling = NullValueHandling.Ignore })
						handler.onDescribePlayerSessionsResponse(describePlayerSessionsResponse.RequestId, describePlayerSessionsResponse.PlayerSessions,
							describePlayerSessionsResponse.NextToken);
					}
				case MessageActions.GetComputeCertificate:
					{
						var getComputeCertificateResponse:GetComputeCertificateResponse = haxe.Json.parse(messageStr);

						handler.onGetComputeCertificateResponse(getComputeCertificateResponse.RequestId, getComputeCertificateResponse.CertificatePath,
							getComputeCertificateResponse.ComputeName);
					}
				case MessageActions.GetFleetRoleCredentials:
					{
						var response:GetFleetRoleCredentialsResponse = haxe.Json.parse(messageStr);

						handler.onGetFleetRoleCredentialsResponse(response.RequestId, response.AssumedRoleUserArn, response.AssumedRoleId,
							response.AccessKeyId, response.SecretAccessKey, response.SessionToken, response.Expiration);
					}
				case MessageActions.RefreshConnection:
					{
						var refreshConnectionMessage:RefreshConnectionMessage = haxe.Json.parse(messageStr);
						handler.onRefreshConnection(refreshConnectionMessage.RefreshConnectionEndpoint, refreshConnectionMessage.AuthToken);
					}
				default:
					handler.onSuccessResponse(message.RequestId);
			}
		} catch (ex:Exception) {
			Log.error('could not parse message. Data: ${messageStr}');
		}
	}

	var onCloseCountdownEvent = new CountdownEvent(1);
	var connectionOpened = false;

	function onOpen() {
		Log.info("Connected to GameLift websocket server.");
	}

	function onClose() {
		Log.info('Socket disconnected.');

		/*
			if (e.Code == CloseStatusCode.ProtocolError) {
				connectionErrorType = GameLiftErrorType.WEBSOCKET_CONNECT_FAILURE_FORBIDDEN;
				Log.error("Handshake with GameLift websocket server failed. Please verify that values of ServerParameters "
					+ "in InitSDK() are correct. For example, process ID needs to be unique between executions, and "
					+ "the authentication token needs to be correct and unexpired.");
			} else if (e.Code == CloseStatusCode.Abnormal) {
				connectionErrorType = GameLiftErrorType.WEBSOCKET_CONNECT_FAILURE_TIMEOUT;
				Log.error("Failed to connect to GameLift websocket server. Please verify that the websocket url in "
					+ "InitSDK() is correct and network status is normal.");
			}
		 */

		// Resolve countdown latch to unblock InitSDK() from returning a result
		if (!onCloseCountdownEvent.isSet) {
			onCloseCountdownEvent.signal();
		}
	}

	function onError(e:WebsocketError) {
		Log.error('Connection error: ${e.errno} : ${e.code}');
	};

	@async private function performConnect():GenericOutcome {
		Log.info('performConnect Connecting to GameLift websocket server. Websocket URL: ${websocketUrl}, processId: ${processId}, hostId: ${hostId}, fleetId: ${fleetId}');
		var newSocket = new WebSocket(createUri());

		// modify websocket-sharp logging-level to match the SDK's logging level
		// Note: Override if you would like to log websocket library at a different level from the rest of the SDK.
		// newSocket.Log.Level = GetLogLevelForWebsockets();

		// Socket connection failed during handshake for TLS errors without this protocol enabled
		// newSocket.SslConfiguration.EnabledSslProtocols = System.Security.Authentication.SslProtocols.Tls12;

		// Countdown latch to ensure that InitSDK() failure response waits for onClose() in order to return an error type
		onCloseCountdownEvent = new CountdownEvent(1);
		var connectionErrorType = GameLiftErrorType.WEBSOCKET_CONNECT_FAILURE;

		newSocket.onOpen = onOpen;
		newSocket.onClose = onClose;
		newSocket.onError = onError;
		newSocket.onMessage = onMessage;

		// Policy that retries if function returns false with exponential backoff.
		// Specific exceptions that prevent connection are swallowed and logged during connect.
		// Exceptions thrown for invalid arguments and max retries, which are not retriable.

		var opened = @await newSocket.retryUntilOpen();

		if (!opened) {
			// Wait for countdown latch to be resolved in OnClose() in order to know the connection error type
			if (newSocket.readyState != CLOSED) {
				newSocket.close(); // CloseStatusCode.Normal
			}

			return new GenericOutcome(new GameLiftError(connectionErrorType));
		}

		// "Flip" traffic from our old websocket to our new websocket. Close the old one if necessary
		var oldSocket = _socket;
		_socket = newSocket;
		try {
			oldSocket?.close(); // CloseStatusCode.Normal
		} catch (e:Exception) {
			Log.warning("Failed to close old websocket after a connection refresh, ignoring");
		}

		return new GenericOutcome();
	}

	private function createUri():String {
		var queryString = '${PidKey}=${processId}&${SdkVersionKey}=${GameLiftServerAPI.GetSdkVersion().result}&${FlavorKey}=${Flavor}&${AuthTokenKey}=${authToken}&${ComputeIdKey}=${hostId}&${FleetIdKey}=${fleetId}';
		var endpoint = '${websocketUrl}?${queryString}';
		return endpoint;
	}


	public function sendRaw(data:Dynamic):Void {
		if (_socket == null) {
			trace('Socket is null');
			return;
		}
		if (_socket.readyState == OPEN) {
			_socket.send(data);
		}
	}
}
