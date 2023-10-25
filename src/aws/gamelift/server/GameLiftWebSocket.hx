package aws.gamelift.server;

import aws.gamelift.IGameLiftWebSocket;
import hx.ws.WebSocket;
import aws.gamelift.IWebSocketMessageHandler;
import aws.gamelift.server.model.*;
import aws.gamelift.ILog;
import hx.ws.State as WebSocketState;
import haxe.Exception;
import aws.gamelift.GameLiftError;
import hx.ws.Log as WebSocketLog;
/*
enum State {
    Handshake;
    Head;
    HeadExtraLength;
    HeadExtraMask;
    Body;
    Closed;
}
*/
/// <summary>
/// Methods and classes to handle the connection between your game servers and GameLift.
/// </summary>
class GameLiftWebSocket implements IGameLiftWebSocket {
	// Websocket library has a built in 10 retry max before all connect attempts raise exceptions.
	private static final MaxConnectRetries = 5;
	private static final InitialConnectRetryDelaySeconds = 2;
	private static final MaxDisconnectWaitRetries = 5;
	private static final DisconnectWaitStepMillis = 200;
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
	private var socket:WebSocket;
	private var websocketUrl:String;
	private var processId:String;
	private var hostId:String;
	private var fleetId:String;
	private var authToken:String;

	public function new(handler:IWebSocketMessageHandler) {
		this.handler = handler;
	}

	public function connect(websocketUrl:String, processId:String, hostId:String, fleetId:String, authToken:String):GenericOutcome {
		Log.info('Connecting to GameLift websocket server. Websocket URL: ${websocketUrl}, processId: ${processId}, hostId: ${hostId}, fleetId: ${fleetId}');
		this.websocketUrl = websocketUrl;
		this.processId = processId;
		this.hostId = hostId;
		this.fleetId = fleetId;
		this.authToken = authToken;

		return PerformConnect();
	}

	public function disconnect():GenericOutcome {
		Log.debug('Disconnecting. Socket state is: ${socket.state}');
		// If the websocket is already closing (potentially initiated by GameLift from a ProcessEnding call earlier)
		// Attempt to wait for it to close.
        /*
		if (socket.state == WebSocketState.Closing) {
			Log.info("WebSocket is in Closing state. Attempting to wait for socket to close");
			if (!WaitForSocketToClose()) {
				Log.warning("Timed out waiting for the socket to close. Will retry closing.");
			}
		}
        */

		if (socket.state != WebSocketState.Closed) {
			Log.debug("Socket is not yet closed. Closing.");
			socket.close();
		}

		Log.debug('Completed Disconnect. Socket state is: ${socket.state}' );

		return new GenericOutcome();
	}

	/**
	 * Develop utility method for simple local testing of sending a message across the websocket.
	 * Update the "action" and message/additional fields to test an API Gateway route/response
	 */
	public function sendMessage(message:Message):GenericOutcome {
		var json:String = haxe.Json.stringify(message);
		try {
			Log.info('Sending message to GameLift: {$json}');
			socket.send(json);
		} catch (e:Exception) {
			Log.error('Failed to send message to GameLift. Error: ${e.message}');
			return new GenericOutcome(new GameLiftError(GameLiftErrorType.SERVICE_CALL_FAILED));
		}

		return new GenericOutcome();
	}

	private function PerformConnect():GenericOutcome {
		var newSocket = new WebSocket(CreateUri());


		// re-route websocket-sharp logs to use the SDK logger
        WebSocketLog.logFn = LogWithGameLiftServerSdk;
		//newSocket.Log.Output = LogWithGameLiftServerSdk;

		// modify websocket-sharp logging-level to match the SDK's logging level
		// Note: Override if you would like to log websocket library at a different level from the rest of the SDK.
		//newSocket.Log.Level = GetLogLevelForWebsockets();

		// Socket connection failed during handshake for TLS errors without this protocol enabled
		newSocket.SslConfiguration.EnabledSslProtocols = System.Security.Authentication.SslProtocols.Tls12;

		// Countdown latch to ensure that InitSDK() failure response waits for onClose() in order to return an error type
		var onCloseCountdownEvent = new CountdownEvent(1);
		var connectionErrorType = GameLiftErrorType.WEBSOCKET_CONNECT_FAILURE;

		newSocket.onopen = (sender, e) -> {
			Log.info("Connected to GameLift websocket server.");
		};

		newSocket.onclose = (sender, e) -> {
			Log.info("Socket disconnected. Status Code: '{0}'. Reason: '{1}'", e.Code, e.Reason);

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

			// Resolve countdown latch to unblock InitSDK() from returning a result
			if (!onCloseCountdownEvent.IsSet) {
				onCloseCountdownEvent.Signal();
			}
		};

		newSocket.onerror = (sender, e) -> {
			if (e.Message != null && e.Message.Contains(SocketClosingErrorMessage)) {
				Log.warning("WebSocket reported error on closing connection. This may be because the connection is already closed");
			} else {
				Log.error("Error received from GameLift websocket server. Error Message: '{0}'. Exception: '{1}'", e.Message, e.Exception);
			}
		};

		newSocket.onmessage = (message: Dynamic) -> {
			if (e.IsPing) {
				Log.debug("Received ping from GameLift websocket server.");
				return;
			}

			if (!e.IsText) {
				Log.warning("Unknown Data received. Data: {0}", e.Data);
				return;
			}

			try {
				// Parse message as a response message. This has error fields in it which will be null for a
				// successful response or generic message not associated with a request.
				var message:ResponseMessage = haxe.Json.parse(e.Data);
				if (message == null) {
					Log.error('could not parse message. Data: ${e.Data}');
					return;
				}

				Log.info('Received ${message.Action} for GameLift with status ${message.StatusCode}. Data: ${e.Data}');

				// It's safe to cast enums to ints in C#. Each HttpStatusCode enum is associated with its numerical
				// status code. RequestId will be null when we get a message not associated with a request.
				if (message.StatusCode != HttpStatusCode.OK && message.RequestId != null) {
					Log.warning("Received unsuccessful status code {0} for request {1} with message '{2}'", message.StatusCode, message.RequestId,
						message.ErrorMessage);
					handler.OnErrorResponse(message.RequestId, message.StatusCode, message.ErrorMessage);
					return;
				}

				switch (message.Action) {
					case MessageActions.CreateGameSession:
						{
							var createGameSessionMessage:CreateGameSessionMessage = JsonConvert.DeserializeObject<CreateGameSessionMessage>(e.Data);
							var gameSession = new GameSession(createGameSessionMessage);
							handler.OnStartGameSession(gameSession);
						}

					case MessageActions.UpdateGameSession:
						{
							var updateGameSessionMessage:UpdateGameSessionMessage = JsonConvert.DeserializeObject<UpdateGameSessionMessage>(e.Data);
							handler.OnUpdateGameSession(updateGameSessionMessage.GameSession,
								UpdateReasonMapper.GetUpdateReasonForName(updateGameSessionMessage.UpdateReason), updateGameSessionMessage.BackfillTicketId);
						}

					case MessageActions.TerminateProcess:
						{
							var terminateProcessMessage:TerminateProcessMessage = JsonConvert.DeserializeObject<TerminateProcessMessage>(e.Data);
							handler.OnTerminateProcess(terminateProcessMessage.TerminationTime);
						}

					case MessageActions.StartMatchBackfill:
						{
							var startMatchBackfillResponse:StartMatchBackfillResponse = JsonConvert.DeserializeObject<StartMatchBackfillResponse>(e.Data);
							handler.OnStartMatchBackfillResponse(startMatchBackfillResponse.RequestId, startMatchBackfillResponse.TicketId);
						}

					case MessageActions.DescribePlayerSessions:
						{
							var describePlayerSessionsResponse:DescribePlayerSessionsResponse = JsonConvert.DeserializeObject<DescribePlayerSessionsResponse>(e.Data); // new JsonSerializerSettings { NullValueHandling = NullValueHandling.Ignore })
							handler.OnDescribePlayerSessionsResponse(describePlayerSessionsResponse.RequestId, describePlayerSessionsResponse.PlayerSessions,
								describePlayerSessionsResponse.NextToken);
						}

					case MessageActions.GetComputeCertificate:
						{
							var getComputeCertificateResponse:GetComputeCertificateResponse = JsonConvert.DeserializeObject<GetComputeCertificateResponse>(e.Data);
							handler.OnGetComputeCertificateResponse(getComputeCertificateResponse.RequestId, getComputeCertificateResponse.CertificatePath,
								getComputeCertificateResponse.ComputeName);
						}

					case MessageActions.GetFleetRoleCredentials:
						{
							var response:GetFleetRoleCredentialsResponse = haxe.Json.parse(e.Data);
							handler.OnGetFleetRoleCredentialsResponse(response.RequestId, response.AssumedRoleUserArn, response.AssumedRoleId,
								response.AccessKeyId, response.SecretAccessKey, response.SessionToken, response.Expiration);
						}

					case MessageActions.RefreshConnection:
						{
							var refreshConnectionMessage:RefreshConnectionMessage = haxe.Json.parse(e.Data);
							handler.OnRefreshConnection(refreshConnectionMessage.RefreshConnectionEndpoint, refreshConnectionMessage.AuthToken);
						}

					default:
						handler.OnSuccessResponse(message.RequestId);
				}
			} catch (ex:Exception) {
				Log.error('could not parse message. Data: ${ex.Data}');
			}
		};

		// Policy that retries if function returns false with exponential backoff.
		var retryPolicy = Policy.HandleResult<bool>(r -> !r)
			.WaitAndRetry(MaxConnectRetries, retry -> TimeSpan.FromSeconds(Math.Pow(InitialConnectRetryDelaySeconds, retry)));

		// Specific exceptions that prevent connection are swallowed and logged during connect.
		// Exceptions thrown for invalid arguments and max retries, which are not retriable.
		var wasSuccessful = retryPolicy.Execute(() -> {
			newSocket.connect();
			return newSocket.IsAlive;
		});

		if (!wasSuccessful) {
			// Wait for countdown latch to be resolved in OnClose() in order to know the connection error type
			onCloseCountdownEvent.Wait();

			try {
				newSocket.close(CloseStatusCode.Normal);
			} catch (e:Exception) {
				Log.warning("Failed to close new websocket after a connection failure, ignoring", e);
			}

			return new GenericOutcome(new GameLiftError(connectionErrorType));
		}

		// "Flip" traffic from our old websocket to our new websocket. Close the old one if necessary
		var oldSocket = socket;
		socket = newSocket;
		try {
			oldSocket?.close(CloseStatusCode.Normal);
		} catch (e:Exception) {
			Log.warning("Failed to close old websocket after a connection refresh, ignoring", e);
		}

		return new GenericOutcome();
	}

	private function CreateUri():String {
		var queryString = '${PidKey}=${processId}&${SdkVersionKey}=${GameLiftServerAPI.GetSdkVersion().result}&${FlavorKey}=${Flavor}&${AuthTokenKey}=${authToken}&${ComputeIdKey}=${hostId}&${FleetIdKey}=${fleetId}';
		var endpoint = '${websocketUrl}?${queryString}';
		return endpoint;
	}

	private function WaitForSocketToClose():Bool {
		// Policy that retries if function returns false with with constant interval
		var retryPolicy = Policy.HandleResult<bool>(r -> !r)
			.WaitAndRetry(MaxDisconnectWaitRetries, retry -> TimeSpan.FromMilliseconds(DisconnectWaitStepMillis));
		return retryPolicy.Execute(() -> {
			return socket.state == WebSocketState.Closed;
		});
	}

	// Helper method to link WebsocketSharp logger with the GameLift SDK logger

	private static function LogWithGameLiftServerSdk(data : Dynamic) { //data:LogData, path:String
        Log.debug(data);
        /*
		var socketLogData = data.toString();
		switch (data.level) {
			case LogLevel.Info:
				Log.info(socketLogData);
			case LogLevel.Warn:
				Log.warning(socketLogData);
			case LogLevel.Error:
				Log.error(socketLogData);
			case LogLevel.Fatal:
				Log.fatal(socketLogData);
			default:
				Log.debug(socketLogData);
		}
        */
	}

	// Helper method to get the logging level the websocket (websocketsharp library) should use.
	// Uses the same logging level as used for GameLift Server SDK.

	private static function GetLogLevelForWebsockets():LogLevel {
		if (Log.isDebugEnabled) {
			return LogLevel.Trace;
		}
		if (Log.isInfoEnabled) {
			return LogLevel.Info;
		}
		if (Log.isWarnEnabled) {
			return LogLevel.Warn;
		}
		if (Log.isErrorEnabled) {
			return LogLevel.Error;
		}
		// otherwise, only log fatal by default
		return LogLevel.Fatal;
	}
}
