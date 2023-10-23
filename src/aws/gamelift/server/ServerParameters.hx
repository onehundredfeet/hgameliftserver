package aws.gamelift.server;

/// <summary>
/// Connection information and methods for maintaining the connection between GameLift
/// and your game server.
/// </summary>
class ServerParameters {
	public var webSocketUrl:String;

	public var processId:String;

	public var hostId:String;

	public var fleetId:String;

	public var authToken:String;

	public function new(webSocketUrl:String, processId:String, hostId:String, fleetId:String, authToken:String) {
		this.webSocketUrl = webSocketUrl;
		this.processId = processId;
		this.hostId = hostId;
		this.fleetId = fleetId;
		this.authToken = authToken;
	}

	public function equals(other:ServerParameters):Bool {
		return webSocketUrl == other.webSocketUrl && processId == other.processId && hostId == other.hostId && fleetId == other.fleetId
			&& authToken == other.authToken;
	}
}
