package aws.gamelift.server.model;

import uuid.Uuid;

class MessageActions {
	public static final AcceptPlayerSession = "AcceptPlayerSession";
	public static final ActivateGameSession = "ActivateGameSession";
	public static final TerminateServerProcess = "TerminateServerProcess";
	public static final ActivateServerProcess = "ActivateServerProcess";
	public static final UpdatePlayerSessionCreationPolicy = "UpdatePlayerSessionCreationPolicy";
	public static final CreateGameSession = "CreateGameSession";
	public static final UpdateGameSession = "UpdateGameSession";
	public static final StartMatchBackfill = "StartMatchBackfill";
	public static final TerminateProcess = "TerminateProcess";
	public static final DescribePlayerSessions = "DescribePlayerSessions";
	public static final StopMatchBackfill = "StopMatchBackfill";
	public static final HeartbeatServerProcess = "HeartbeatServerProcess";
	public static final GetComputeCertificate = "GetComputeCertificate";
	public static final GetFleetRoleCredentials = "GetFleetRoleCredentials";
	public static final RefreshConnection = "RefreshConnection";
	public static final RemovePlayerSession = "RemovePlayerSession";
}

@:autoBuild(aws.macro.JsonAutoSerializer.build())
class Message {
	public var Action:String;
	public var RequestId:String;

	public function new(action:String = null) {
		this.Action = action;
		this.RequestId = Uuid.v4(); // Guid.NewGuid().ToString();
	}
}

class MessageWrapper extends Message {}

class ResponseMessage extends Message {
	public var StatusCode:Int;
	public var ErrorMessage:String;

	public function new() {
		super();
		this.RequestId = null;
	}
}

class UpdateGameSessionMessage extends Message {
	public var GameSession:GameSession;
	public var UpdateReason:String;
	public var BackfillTicketId:String;

	public function new(gameSession:GameSession, updateReason:String, backfillTicketId:String) {
		super();
		GameSession = gameSession;
		UpdateReason = updateReason;
		BackfillTicketId = backfillTicketId;
	}
}

class CreateGameSessionMessage extends Message {
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

class AcceptPlayerSessionRequest extends Message {
	public var GameSessionId:String;
	public var PlayerSessionId:String;

	public function new(gameSessionId:String, playerSessionId:String) {
		super(MessageActions.AcceptPlayerSession);
		this.GameSessionId = gameSessionId;
		this.PlayerSessionId = playerSessionId;
	}
}

class ActivateGameSessionRequest extends Message {
	public var gameSessionId:String;

	public function new(gameSessionId:String) {
		super(MessageActions.ActivateGameSession);
		this.gameSessionId = gameSessionId;
	}
}

class DescribePlayerSessionsRequest extends Message {
	public var GameSessionId:String;
	public var PlayerSessionId:String;
	public var PlayerId:String;
	public var PlayerSessionStatusFilter:String;
	public var NextToken:String;
	public var Limit = 50;

	public function new() {
		super(MessageActions.DescribePlayerSessions);
	}
}

class ActivateServerProcessRequest extends Message {
	public var SdkVersion:String;
	public var SdkLanguage:String;
	public var Port:Int;
	public var LogPaths:Array<String>;

	public function new(sdkVersion:String, sdkLanguage:String, port:Int, logPaths:Array<String>) {
		super(MessageActions.ActivateServerProcess);
		this.SdkVersion = sdkVersion;
		this.SdkLanguage = sdkLanguage;
		this.Port = port;
		this.LogPaths = logPaths;
	}
}

class GetComputeCertificateRequest extends Message {
	public function new() {
		super(MessageActions.GetComputeCertificate);
	}
}

class GetFleetRoleCredentialsRequest extends Message {
	public var RoleArn:String;

	public var RoleSessionName:String;

	public function new(roleArn:String) {
		super(MessageActions.GetFleetRoleCredentials);
		this.RoleArn = roleArn;
	}
}

class HeartbeatServerProcessRequest extends Message {
	public var HealthStatus:Bool;

	public function new(healthStatus:Bool) {
		super(MessageActions.HeartbeatServerProcess);
		this.HealthStatus = healthStatus;
	}
}

class StopMatchBackfillRequest extends Message {
	public var GameSessionArn:String;
	public var MatchmakingConfigurationArn:String;
	public var TicketId:String;

	public function new(gameSessionArn:String, matchmakingConfigurationArn:String, ticketId:String) {
		super(MessageActions.StopMatchBackfill);
		this.GameSessionArn = gameSessionArn;
		this.MatchmakingConfigurationArn = matchmakingConfigurationArn;
		this.TicketId = ticketId;
	}
}

class StartMatchBackfillRequest extends Message {
	public var GameSessionArn:String;
	public var MatchmakingConfigurationArn:String;
	public var Players:Array<Player>;
	public var TicketId:String;

	public function new(gameSessionArn:String, matchmakingConfigurationArn:String, players:Array<Player>) {
		super(MessageActions.StartMatchBackfill);
		this.GameSessionArn = gameSessionArn;
		this.MatchmakingConfigurationArn = matchmakingConfigurationArn;
		this.Players = players;
	}
}

class TerminateServerProcessRequest extends Message {
	public function new() {
		super(MessageActions.TerminateServerProcess);
	}
}

class TerminateProcessMessage extends Message {
	public var TerminationTime:Float;

	public function new(terminationTime:Float) {
		super(MessageActions.TerminateProcess);
		TerminationTime = terminationTime;
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

class RefreshConnectionMessage extends Message {
	public var RefreshConnectionEndpoint:String;
	public var AuthToken:String;

	public function new(refreshConnectionEndpoint:String, authToken:String) {
		super(MessageActions.RefreshConnection);
		RefreshConnectionEndpoint = refreshConnectionEndpoint;
		AuthToken = authToken;
	}
}

class RemovePlayerSessionRequest extends Message {
	public var gameSessionId:String;
	public var playerSessionId:String;

	public function new(gameSessionId:String, playerSessionId:String) {
		super(MessageActions.RemovePlayerSession);
		this.gameSessionId = gameSessionId;
		this.playerSessionId = playerSessionId;
	}
}

class UpdatePlayerSessionCreationPolicyRequest extends Message {
	public var gameSessionId:String;
	public var playerSessionPolicy:String;

	public function new(gameSessionId:String, policy:PlayerSessionCreationPolicy) {
		super(MessageActions.UpdatePlayerSessionCreationPolicy);
		this.gameSessionId = gameSessionId;
		this.playerSessionPolicy = policy;
	}
}
