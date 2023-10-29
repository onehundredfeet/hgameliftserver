package aws.gamelift.server;

import haxe.Exception;
import seedyrng.*;
import aws.gamelift.server.model.*;
import aws.gamelift.TimeSpan;
import aws.gamelift.IGameLiftWebSocket;
import aws.gamelift.ILog;
import aws.gamelift.Util;
import aws.gamelift.IWebSocketMessageHandler;
import aws.gamelift.GameLiftError;
import aws.gamelift.server.model.Messages;

#if js
import js.lib.Promise;
#end
class ServerState implements IWebSocketMessageHandler {
	// When within 15 minutes of expiration we retrieve new instance role credentials
	public static final InstanceRoleCredentialTtlMin:TimeSpan = TimeSpan.fromMinutes(15);

	private static final EnvironmentVariableWebsocketUrl = "GAMELIFT_SDK_WEBSOCKET_URL";
	private static final EnvironmentVariableProcessId = "GAMELIFT_SDK_PROCESS_ID";
	private static final EnvironmentVariableHostId = "GAMELIFT_SDK_HOST_ID";
	private static final EnvironmentVariableFleetId = "GAMELIFT_SDK_FLEET_ID";
	private static final EnvironmentVariableAuthToken = "GAMELIFT_SDK_AUTH_TOKEN";

	private static final RoleSessionNameMaxLength = 64;
	private static final HealthcheckIntervalSeconds = 60.0;
	private static final HealthcheckMaxJitterSeconds = 10.0;
	private static final HealthcheckTimeoutSeconds:Int = Math.round(HealthcheckIntervalSeconds - HealthcheckMaxJitterSeconds);
	private static final SdkLanguage = "CSharp";

	private static final Epoch:Date = new Date(1970, 1, 1, 0, 0, 0);

	private static final random = new Random(new Xorshift64Plus());

	private final gameLiftWebSocket:IGameLiftWebSocket;
	private final webSocketRequestHandler:GameLiftWebSocketRequestHandler;

	// Map of roleArn -> Credentials for that role
	private var instanceRoleResultCache = new Map<String, GetFleetRoleCredentialsResult>();

	private var processParameters:ProcessParameters;
	@:volatile private var processIsReady:Bool;
	private var gameSessionId:String;
	private var terminationTime:Date; // = Date.MinValue; // init to 1/1/0001 12:00:00 AM
	private var fleetId:String;
	private var hostId:String;
	private var processId:String;
	// Assume we're on managed EC2, if GetFleetRoleCredentials fails we know to set this to false
	private var onManagedEc2 = true;

	public static var instance(default, null) = new ServerState();

	public static final Log:ILog = LogManager.GetLogger(Type.typeof(ServerState));

	public function new(webSocket:IGameLiftWebSocket = null, requestHandler:GameLiftWebSocketRequestHandler = null) {
		gameLiftWebSocket = webSocket != null ? webSocket : new GameLiftWebSocket(this);
		webSocketRequestHandler = requestHandler != null ? requestHandler : new GameLiftWebSocketRequestHandler(gameLiftWebSocket);
	}

	public function processReady(procParameters:ProcessParameters):GenericOutcome {
		processIsReady = true;
		processParameters = procParameters;

		var result = gameLiftWebSocket.sendMessage(new ActivateServerProcessRequest(GameLiftServerAPI.GetSdkVersion().result, SdkLanguage,
			processParameters.port, processParameters.logParameters.LogPaths));

		return result;
	}

	public function ProcessEnding():GenericOutcome {
		processIsReady = false;

		var result = gameLiftWebSocket.sendMessage(new TerminateServerProcessRequest());

		return result;
	}

	public function ActivateGameSession():GenericOutcome {
		if (isNullOrEmpty(gameSessionId)) {
			return new GenericOutcome(new GameLiftError(GameLiftErrorType.GAMESESSION_ID_NOT_SET));
		}

		return gameLiftWebSocket.sendMessage(new ActivateGameSessionRequest(gameSessionId));
	}

	public function GetGameSessionId():AwsStringOutcome {
		if (isNullOrEmpty(gameSessionId)) {
			return new AwsStringOutcome(new GameLiftError(GameLiftErrorType.GAMESESSION_ID_NOT_SET));
		}

		return new AwsStringOutcome(null, gameSessionId);
	}

	public function GetTerminationTime():AwsDateTimeOutcome {
		if (terminationTime.getTime() == Date.fromTime(0.0).getTime()) {
			return new AwsDateTimeOutcome(new GameLiftError(GameLiftErrorType.TERMINATION_TIME_NOT_SET));
		}

		return new AwsDateTimeOutcome(null, terminationTime);
	}

	public function UpdatePlayerSessionCreationPolicy(playerSessionPolicy:PlayerSessionCreationPolicy):GenericOutcome {
		if (isNullOrEmpty(gameSessionId)) {
			return new GenericOutcome(new GameLiftError(GameLiftErrorType.GAMESESSION_ID_NOT_SET));
		}

		return gameLiftWebSocket.sendMessage(new UpdatePlayerSessionCreationPolicyRequest(gameSessionId, playerSessionPolicy));
	}

	public function AcceptPlayerSession(playerSessionId:String):GenericOutcome {
		if (isNullOrEmpty(gameSessionId)) {
			return new GenericOutcome(new GameLiftError(GameLiftErrorType.GAMESESSION_ID_NOT_SET));
		}

		return gameLiftWebSocket.sendMessage(new AcceptPlayerSessionRequest(gameSessionId, playerSessionId));
	}

	public function RemovePlayerSession(playerSessionId:String):GenericOutcome {
		if (isNullOrEmpty(gameSessionId)) {
			return new GenericOutcome(new GameLiftError(GameLiftErrorType.GAMESESSION_ID_NOT_SET));
		}

		return gameLiftWebSocket.sendMessage(new RemovePlayerSessionRequest(gameSessionId, playerSessionId));
	}

	public function DescribePlayerSessions(request:DescribePlayerSessionsRequest):DescribePlayerSessionsOutcome {
		if (request == null) {
			return new DescribePlayerSessionsOutcome(new GameLiftError(GameLiftErrorType.BAD_REQUEST_EXCEPTION, "DescribePlayerSessionsRequest is required"));
		}

		// must have player session id or game session id or player id
		if (isNullOrEmpty(request.PlayerSessionId) && isNullOrEmpty(request.GameSessionId) && isNullOrEmpty(request.PlayerId)) {
			return new DescribePlayerSessionsOutcome(new GameLiftError(GameLiftErrorType.BAD_REQUEST_EXCEPTION,
				"At least one of PlayerSessionId, GameSessionId and PlayerId is required."));
		}

		var outcome = webSocketRequestHandler.SendRequest(request);
		if (!outcome.success) {
			return new DescribePlayerSessionsOutcome(outcome.error);
		}

		return cast(outcome, DescribePlayerSessionsOutcome);
	}

	public function StartMatchBackfill(request:StartMatchBackfillRequest):StartMatchBackfillOutcome {
		if (request == null) {
			return new StartMatchBackfillOutcome(new GameLiftError(GameLiftErrorType.BAD_REQUEST_EXCEPTION, "StartMatchBackfillRequest is required"));
		}

		if (isNullOrEmpty(request.GameSessionArn)) {
			return new StartMatchBackfillOutcome(new GameLiftError(GameLiftErrorType.BAD_REQUEST_EXCEPTION,
				"GameSessionArn is required in StartMatchBackfillRequest"));
		}

		if (isNullOrEmpty(request.MatchmakingConfigurationArn)) {
			return new StartMatchBackfillOutcome(new GameLiftError(GameLiftErrorType.BAD_REQUEST_EXCEPTION,
				"Invalid MatchmakingConfigurationArn request was passed to StopMatchBackfillRequest"));
		}

		if (request.Players == null || request.Players.length == 0) {
			return new StartMatchBackfillOutcome(new GameLiftError(GameLiftErrorType.BAD_REQUEST_EXCEPTION,
				"At least 1 Player is required in StartMatchBackfillRequest"));
		}

		var outcome = webSocketRequestHandler.SendRequest(request);
		if (!outcome.success) {
			return new StartMatchBackfillOutcome(outcome.error);
		}

		return cast(outcome, StartMatchBackfillOutcome);
	}

	public function StopMatchBackfill(request:StopMatchBackfillRequest):GenericOutcome {
		if (request == null) {
			return new GenericOutcome(new GameLiftError(GameLiftErrorType.BAD_REQUEST_EXCEPTION, "StopMatchBackfillRequest is required"));
		}

		if (isNullOrEmpty(request.GameSessionArn)) {
			return new GenericOutcome(new GameLiftError(GameLiftErrorType.BAD_REQUEST_EXCEPTION, "GameSessionArn is required in StopMatchBackfillRequest"));
		}

		if (isNullOrEmpty(request.MatchmakingConfigurationArn)) {
			return new GenericOutcome(new GameLiftError(GameLiftErrorType.BAD_REQUEST_EXCEPTION,
				"MatchmakingConfigurationArn is required in StopMatchBackfillRequest"));
		}

		if (isNullOrEmpty(request.TicketId)) {
			return new GenericOutcome(new GameLiftError(GameLiftErrorType.BAD_REQUEST_EXCEPTION, "TicketId is required in StopMatchBackfillRequest"));
		}

		return webSocketRequestHandler.SendRequest(request);
	}

	private static function GetNextHealthCheckIntervalSeconds():Float {
		// Jitter the healthCheck interval +/- a random value between [-MAX_JITTER_SECONDS, MAX_JITTER_SECONDS]
		var jitter = HealthcheckMaxJitterSeconds * (2 * random.random() - 1);
		return HealthcheckIntervalSeconds + jitter;
	}

	private function HeartbeatServerProcess():Void // async
	{
		// duplicate ProcessReady check here right before invoking
		if (!processIsReady) {
			Log.debug("Reporting Health on an inactive process. Ignoring.");
			return;
		}

		Log.debug("Reporting health using the OnHealthCheck callback.");

		var healthCheckResult = false;
		try {
			healthCheckResult = processParameters.onHealthCheck();
		} catch (e:Exception) {
			Log.error("Encountered unexpected error when calling onHealthCheck callback. Reporting process as unhealthy.");
			healthCheckResult = false;
		}

		var request = new HeartbeatServerProcessRequest(healthCheckResult);
		var outcome = webSocketRequestHandler.SendRequest(request);
		if (!outcome.success) {
			Log.warning('Failed to report health status to GameLift service. Error: ${outcome.error}');
		}
	}

	public function InitializeNetworking(serverParameters:ServerParameters):GenericOutcome {
		var websocketUrl = getEnv(EnvironmentVariableWebsocketUrl) ?? serverParameters.webSocketUrl;
		processId = getEnv(EnvironmentVariableProcessId) ?? serverParameters.processId;
		hostId = getEnv(EnvironmentVariableHostId) ?? serverParameters.hostId;
		fleetId = getEnv(EnvironmentVariableFleetId) ?? serverParameters.fleetId;
		var authToken = getEnv(EnvironmentVariableAuthToken) ?? serverParameters.authToken;

		if (isNullOrEmpty(websocketUrl)) {
			return new GenericOutcome(new GameLiftError(GameLiftErrorType.BAD_REQUEST_EXCEPTION, "websocketUrl is required in InitSDK ServerParameters"));
		}
		if (isNullOrEmpty(processId)) {
			return new GenericOutcome(new GameLiftError(GameLiftErrorType.BAD_REQUEST_EXCEPTION, "processId is required in InitSDK ServerParameters"));
		}
		if (isNullOrEmpty(hostId)) {
			return new GenericOutcome(new GameLiftError(GameLiftErrorType.BAD_REQUEST_EXCEPTION, "hostId is required in InitSDK ServerParameters"));
		}
		if (isNullOrEmpty(fleetId)) {
			return new GenericOutcome(new GameLiftError(GameLiftErrorType.BAD_REQUEST_EXCEPTION, "fleetId is required in InitSDK ServerParameters"));
		}
		if (isNullOrEmpty(authToken)) {
			return new GenericOutcome(new GameLiftError(GameLiftErrorType.BAD_REQUEST_EXCEPTION, "authToken is required in InitSDK ServerParameters"));
		}

		return establishNetworking(websocketUrl, authToken);
	}

	private function establishNetworking(webSocketUrl:String, authToken:String):GenericOutcome {
		return gameLiftWebSocket.connect(webSocketUrl, processId, hostId, fleetId, authToken);
	}

	public function GetComputeCertificate():GetComputeCertificateOutcome {
		Log.debug("Calling GetComputeCertificate");

		var webSocketRequest = new GetComputeCertificateRequest();
		var outcome = webSocketRequestHandler.SendRequest(webSocketRequest);
		if (!outcome.success) {
			return new GetComputeCertificateOutcome(outcome.error);
		}

		return cast(outcome, GetComputeCertificateOutcome);
	}

	public function GetFleetRoleCredentials(request:GetFleetRoleCredentialsRequest):GetFleetRoleCredentialsOutcome {
		Log.debug('Calling GetFleetRoleCredentials: ${request}');

		// If we've decided we're not on managed EC2, fail without making an APIGW call
		if (!onManagedEc2) {
			Log.debug("SDK is not running on managed EC2, fast-failing the request");
			return new GetFleetRoleCredentialsOutcome(new GameLiftError(GameLiftErrorType.BAD_REQUEST_EXCEPTION));
		}

		// Check if we're cached credentials recently that still have at least 15 minutes before expiration
		if (instanceRoleResultCache.exists(request.RoleArn)) {
			var previousResult = instanceRoleResultCache[request.RoleArn];
			if (previousResult.expiration.getSeconds() - InstanceRoleCredentialTtlMin.asSeconds() > Date.now().getSeconds()) {
				Log.debug('Returning cached credentials which expire in ${previousResult.expiration.getSeconds() - Date.now().getSeconds()} seconds');
				return new GetFleetRoleCredentialsOutcome(null, previousResult);
			}

			instanceRoleResultCache.remove(request.RoleArn);
		}

		// If role session name was not provided, default to fleetId-hostId
		if (isNullOrEmpty(request.RoleSessionName)) {
			var generatedRoleSessionName = '${fleetId}-${hostId}';
			if (generatedRoleSessionName.length > RoleSessionNameMaxLength) {
				generatedRoleSessionName = generatedRoleSessionName.substring(0, RoleSessionNameMaxLength);
			}

			request.RoleSessionName = generatedRoleSessionName;
		}

		// Role session name cannot be over 64 chars (enforced by IAM's AssumeRole API)
		if (request.RoleSessionName.length > RoleSessionNameMaxLength) {
			return new GetFleetRoleCredentialsOutcome(new GameLiftError(GameLiftErrorType.BAD_REQUEST_EXCEPTION));
		}

		var rawOutcome = webSocketRequestHandler.SendRequest(request);
		if (!rawOutcome.success) {
			return new GetFleetRoleCredentialsOutcome(rawOutcome.error);
		}

		var outcome:GetFleetRoleCredentialsOutcome = cast(rawOutcome, GetFleetRoleCredentialsOutcome);
		var result = outcome.result;

		// If we get a success response from APIGW with empty fields we're not on managed EC2
		if (isNullOrEmpty(result.accessKeyId)) {
			onManagedEc2 = false;
			return new GetFleetRoleCredentialsOutcome(new GameLiftError(GameLiftErrorType.BAD_REQUEST_EXCEPTION));
		}

		instanceRoleResultCache[request.RoleArn] = result;
		return outcome;
	}

	public function onErrorResponse(requestId:String, statusCode:Int, errorMessage:String) {
		webSocketRequestHandler.handleResponse(requestId, new GenericOutcome(new GameLiftError(statusCode, errorMessage)));
	}

	public function onSuccessResponse(requestId:String) {
		if (requestId != null) {
			webSocketRequestHandler.handleResponse(requestId, new GenericOutcome());
		} else {
			Log.info("RequestId was null");
		}
	}

	public function onStartGameSession(gameSession:GameSession) {
		// Inject data that already exists on the server
		gameSession.FleetId = fleetId;

		Log.debug('ServerState got the startGameSession signal. GameSession : ${gameSession}');

		if (!processIsReady) {
			Log.debug("Got a game session on inactive process. Ignoring.");
			return;
		}

		gameSessionId = gameSession.GameSessionId;

		Task.run(() -> {
			processParameters.onStartGameSession(gameSession);
		});
	}

	public function onUpdateGameSession(gameSession:GameSession, updateReason:UpdateReason, backfillTicketId:String) {
		Log.debug('ServerState got the updateGameSession signal. GameSession : ${gameSession}');

		if (!processIsReady) {
			Log.warning("Got an updated game session on inactive process.");
			return;
		}

		Task.run(() -> {
			processParameters.onUpdateGameSession(new UpdateGameSession(gameSession, updateReason, backfillTicketId));
		});
	}

	public function onTerminateProcess(terminationTime:Float) {
		// TerminationTime is milliseconds that have elapsed since Unix epoch time begins (00:00:00 UTC Jan 1 1970).
		// this.terminationTime = new Date(1970, 1, 1, 0, 0, 0).addMilliseconds(terminationTime); // DateTimeKind.Utc
		this.terminationTime = Date.fromTime(terminationTime); // milliseconds

		Log.debug('ServerState got the terminateProcess signal. termination time : ${this.terminationTime}');

		Task.run(() -> {
			processParameters.onProcessTerminate();
		});
	}

	public function onStartMatchBackfillResponse(requestId:String, ticketId:String) {
		var result = new StartMatchBackfillResult(ticketId);
		webSocketRequestHandler.handleResponse(requestId, new StartMatchBackfillOutcome(result));
	}

	public function onDescribePlayerSessionsResponse(requestId:String, playerSessions:Array<PlayerSession>, nextToken:String) {
		var result = new DescribePlayerSessionsResult(playerSessions, nextToken);
		webSocketRequestHandler.handleResponse(requestId, new DescribePlayerSessionsOutcome(result));
	}

	public function onGetComputeCertificateResponse(requestId:String, certificatePath:String, computeName:String) {
		var result = new GetComputeCertificateResult(certificatePath, computeName);
		webSocketRequestHandler.handleResponse(requestId, new GetComputeCertificateOutcome(null, result));
	}

	public function onGetFleetRoleCredentialsResponse(requestId:String, assumedRoleUserArn:String, assumedRoleId:String, accessKeyId:String,
			secretAccessKey:String, sessionToken:String, expirationMS:Float) {
		var result = new GetFleetRoleCredentialsResult(assumedRoleUserArn, assumedRoleId, accessKeyId, secretAccessKey, sessionToken,
			Date.fromTime(expirationMS));
		webSocketRequestHandler.handleResponse(requestId, new GetFleetRoleCredentialsOutcome(null, result));
	}

	public function onRefreshConnection(refreshConnectionEndpoint:String, authToken:String) {
		var outcome = establishNetworking(refreshConnectionEndpoint, authToken);

		if (!outcome.success) {
			Log.error('Failed to refresh websocket connection. The GameLift SDK will try again each minute until the refresh succeeds, or the websocket is forcibly closed. ${outcome.error}');
		}
	}

    #if js
    static function delay(ms: Int): Promise<Void> {
        return new Promise(function(resolve, _) {
            js.Node.setTimeout(resolve, ms);
        });
    }
    #end
    
	public function Shutdown() {
		processIsReady = false;

		// Sleep thread for 1 sec.
		// This is to help deal with race conditions related to processReady flag being turned off (i.e. HeartbeatServerProcess)
        #if js
        delay(2000).then(function(_) {
            trace("2 seconds later");
        });
        #else
		Sys.sleep(TimeSpan.fromSeconds(1).asMilliseconds());
        #end

		gameLiftWebSocket.disconnect();
	}

	var _lastHealthCheck = 0;

	public function tick(dt:Float):Void {
		if (processIsReady) {
			if (Date.now().getSeconds() - _lastHealthCheck > HealthcheckIntervalSeconds) {
				_lastHealthCheck = Date.now().getSeconds();
				HeartbeatServerProcess();
			}
		}
	}
}
