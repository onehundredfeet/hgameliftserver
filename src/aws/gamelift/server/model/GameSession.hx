package aws.gamelift.server.model;

class GameSession {
	public var gameSessionId:String;

	public var name:String;

	public var fleetId:String;

	public var maximumPlayerSessionCount:Int;

	public var port:Int;

	public var ipAddress:String;

	public var gameSessionData:String;

	public var matchmakerData:String;

	public var gameProperties:Map<String, String>;

	public var dnsName:String;

	public function new(message:CreateGameSessionMessage = null) {
		if (message != null) {
			gameSessionId = message.gameSessionId;
			name = message.gameSessionName;
			maximumPlayerSessionCount = message.maximumPlayerSessionCount;
			port = message.port;
			ipAddress = message.ipAddress;
			gameSessionData = message.gameSessionData;
			matchmakerData = message.matchmakerData;
			gameProperties = message.gameProperties;
			dnsName = message.dnsName;
		} else {
			gameProperties = new Map<String, String>();
			maximumPlayerSessionCount = 0;
		}
	}
}
