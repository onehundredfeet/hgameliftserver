package aws.gamelift.server.model;

import uuid.Uuid;

class MessageActions {
	// Game Server to Cloud server
	public static final ActivateServerProcess = "ActivateServerProcess";
	public static final TerminateServerProcess = "TerminateServerProcess";
	public static final HeartbeatServerProcess = "HeartbeatServerProcess";

	// Cloud Server to Game Server
	public static final ActivateGameSession = "ActivateGameSession";
	public static final CreateGameSession = "CreateGameSession";
	public static final TerminateProcess = "TerminateProcess";
	public static final UpdateGameSession = "UpdateGameSession";

	// bidirectional
	public static final AcceptPlayerSession = "AcceptPlayerSession";
	public static final UpdatePlayerSessionCreationPolicy = "UpdatePlayerSessionCreationPolicy";
	public static final StartMatchBackfill = "StartMatchBackfill";
	public static final DescribePlayerSessions = "DescribePlayerSessions";
	public static final StopMatchBackfill = "StopMatchBackfill";
	public static final GetComputeCertificate = "GetComputeCertificate";
	public static final GetFleetRoleCredentials = "GetFleetRoleCredentials";
	public static final RefreshConnection = "RefreshConnection";
	public static final RemovePlayerSession = "RemovePlayerSession";
}

@:autoBuild(aws.macro.JsonAutoSerializer.build())
class Message {
	public var Action:String;
	public var RequestId:String;

	public function new() {}

	inline function setClientMessage(action:String) {
		this.Action = action;
		this.RequestId = Uuid.v4(); // Guid.NewGuid().ToString();;;
	}
	inline function setServerMessage(action:String)
	{
		this.Action = action;
	}
}

class MessageWrapper extends Message {}

class ResponseMessage extends Message {
	public var StatusCode:Int;
	public var ErrorMessage:String;

	public static function make(statusCode:Int, errorMessage:String, requestId:String) {
		var _this = new ResponseMessage();
		_this.StatusCode = statusCode;
		_this.ErrorMessage = errorMessage;
		_this.RequestId = requestId;
		return _this;
	}
}

// Server Messages
class UpdateGameSessionMessage extends Message {
	public var GameSession:GameSession;
	public var UpdateReason:String;
	public var BackfillTicketId:String;

	public static function make(gameSession:GameSession, updateReason:String, backfillTicketId:String) {
		var _this = new UpdateGameSessionMessage();
		_this.setServerMessage(MessageActions.UpdateGameSession);
		_this.GameSession = gameSession;
		_this.UpdateReason = updateReason;
		_this.BackfillTicketId = backfillTicketId;
		return _this;
	}
}

class CreateGameSessionMessage extends Message {
	public static function make() {
		var _this = new CreateGameSessionMessage();
		_this.setServerMessage(MessageActions.CreateGameSession);
		return _this;
	}

	public var GameSessionId:String;
	public var GameSessionName:String;
	public var MaximumPlayerSessionCount:Int;
	public var Port:Int;
	public var IpAddress:String;
	public var GameSessionData:String;
	public var MatchmakerData:String;
	public var GameProperties:Map<String, String>;
	public var DnsName:String;
}

class RefreshConnectionMessage extends Message {
	public var RefreshConnectionEndpoint:String;
	public var AuthToken:String;

	public static function make(refreshConnectionEndpoint:String, authToken:String) {
		var _this = new RefreshConnectionMessage();
		_this.setServerMessage(MessageActions.RefreshConnection);
		_this.RefreshConnectionEndpoint = refreshConnectionEndpoint;
		_this.AuthToken = authToken;
		return _this;
	}
}

class TerminateProcessMessage extends Message {
	public var TerminationTime:Float;

	public static function make(terminationTime:Float) {
		var _this = new TerminateProcessMessage();
		_this.setServerMessage(MessageActions.TerminateProcess);
		_this.TerminationTime = terminationTime;
		return _this;
	}
}

// Game Server -> Cloud Server
class AcceptPlayerSessionRequest extends Message {
	public var GameSessionId:String;
	public var PlayerSessionId:String;

	public static function make(gameSessionId:String, playerSessionId:String) {
		var _this = new AcceptPlayerSessionRequest();
		_this.setClientMessage(MessageActions.AcceptPlayerSession);
		_this.GameSessionId = gameSessionId;
		_this.PlayerSessionId = playerSessionId;
		return _this;
	}
}

class ActivateGameSessionRequest extends Message {
	public var gameSessionId:String;

	public static function make(gameSessionId:String) {
		var _this = new ActivateGameSessionRequest();
		_this.setClientMessage(MessageActions.ActivateGameSession);
		_this.gameSessionId = gameSessionId;
		return _this;
	}
}

class DescribePlayerSessionsRequest extends Message {
	public var GameSessionId:String;
	public var PlayerSessionId:String;
	public var PlayerId:String;
	public var PlayerSessionStatusFilter:String;
	public var NextToken:String;
	public var Limit = 50;

	public static function make() {
		var _this = new DescribePlayerSessionsRequest();
		_this.setClientMessage(MessageActions.DescribePlayerSessions);
		return _this;
	}
}

class ActivateServerProcessRequest extends Message {
	public var SdkVersion:String;
	public var SdkLanguage:String;
	public var Port:Int;
	public var LogPaths:Array<String>;

	public static function make(sdkVersion:String, sdkLanguage:String, port:Int, logPaths:Array<String>) {
		var _this = new ActivateServerProcessRequest();
		_this.setClientMessage(MessageActions.ActivateServerProcess);
		_this.SdkVersion = sdkVersion;
		_this.SdkLanguage = sdkLanguage;
		_this.Port = port;
		_this.LogPaths = logPaths;
		return _this;
	}
}

class GetComputeCertificateRequest extends Message {
	public static function make() {
		var _this = new GetComputeCertificateRequest();
		_this.setClientMessage(MessageActions.GetComputeCertificate);
		return _this;
	}
}

class GetFleetRoleCredentialsRequest extends Message {
	public var RoleArn:String;

	public var RoleSessionName:String;

	public static function make(roleArn:String) {
		var _this = new GetFleetRoleCredentialsRequest();
		_this.setClientMessage(MessageActions.GetFleetRoleCredentials);
		_this.RoleArn = roleArn;
		return _this;
	}
}

class HeartbeatServerProcessRequest extends Message {
	public var HealthStatus:Bool;

	public static function make(healthStatus:Bool) {
		var _this = new HeartbeatServerProcessRequest();
		_this.setClientMessage(MessageActions.HeartbeatServerProcess);
		_this.HealthStatus = healthStatus;
		return _this;
	}
}

class StopMatchBackfillRequest extends Message {
	public var GameSessionArn:String;
	public var MatchmakingConfigurationArn:String;
	public var TicketId:String;

	public static function make(gameSessionArn:String, matchmakingConfigurationArn:String, ticketId:String) {
		var _this = new StopMatchBackfillRequest();
		_this.setClientMessage(MessageActions.StopMatchBackfill);
		_this.GameSessionArn = gameSessionArn;
		_this.MatchmakingConfigurationArn = matchmakingConfigurationArn;
		_this.TicketId = ticketId;
		return _this;
	}
}

class StartMatchBackfillRequest extends Message {
	public var GameSessionArn:String;
	public var MatchmakingConfigurationArn:String;
	public var Players:Array<Player>;
	public var TicketId:String;

	public static function make(gameSessionArn:String, matchmakingConfigurationArn:String, players:Array<Player>) {
		var _this = new StartMatchBackfillRequest();
		_this.setClientMessage(MessageActions.StartMatchBackfill);
		_this.GameSessionArn = gameSessionArn;
		_this.MatchmakingConfigurationArn = matchmakingConfigurationArn;
		_this.Players = players;
		return _this;
	}
}

class TerminateServerProcessRequest extends Message {
	public static function make() {
		var _this = new TerminateServerProcessRequest();
		_this.setClientMessage(MessageActions.TerminateServerProcess);
		return _this;
	}
}



class StartMatchBackfillResponse extends Message {
	public var TicketId:String;
}

class DescribePlayerSessionsResponse extends Message {
	/// <summary>
	/// A pagination character used to view results as sequential pages.
	/// </summary>
	public var NextToken:String;

	/// <summary>
	/// A list of <see cref="PlayerSession"/> objects containing information about the specific player sessions.
	/// </summary>
	public var PlayerSessions:Array<PlayerSession>;
}

class GetComputeCertificateResponse extends Message {
	public var CertificatePath:String;
	public var ComputeName:String;
}

class GetFleetRoleCredentialsResponse extends Message {
	public var AssumedRoleUserArn:String;
	public var AssumedRoleId:String;
	public var AccessKeyId:String;
	public var SecretAccessKey:String;
	public var SessionToken:String;
	public var Expiration:Float;
}



class RemovePlayerSessionRequest extends Message {
	public var gameSessionId:String;
	public var playerSessionId:String;

	public static function make(gameSessionId:String, playerSessionId:String) {
		var _this = new RemovePlayerSessionRequest();
		_this.setServerMessage(MessageActions.RemovePlayerSession);
		_this.gameSessionId = gameSessionId;
		_this.playerSessionId = playerSessionId;
		return _this;
	}
}

class UpdatePlayerSessionCreationPolicyRequest extends Message {
	public var gameSessionId:String;
	public var playerSessionPolicy:String;

	public static function make(gameSessionId:String, policy:PlayerSessionCreationPolicy) {
		var _this = new UpdatePlayerSessionCreationPolicyRequest();
		_this.setClientMessage(MessageActions.UpdatePlayerSessionCreationPolicy);
		_this.gameSessionId = gameSessionId;
		_this.playerSessionPolicy = policy;
		return _this;
	}
}
