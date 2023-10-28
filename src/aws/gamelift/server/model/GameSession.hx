package aws.gamelift.server.model;

import aws.gamelift.server.model.Messages;

class GameSession {
	public var GameSessionId:String;
	public var Name:String;
	public var FleetId:String;
	public var MaximumPlayerSessionCount:Int;
	public var Port:Int;
	public var IpAddress:String;
	public var GameSessionData:String;
	public var MatchmakerData:String;
	public var GameProperties:Map<String, String>;
	public var DnsName:String;

	public function new(message:CreateGameSessionMessage = null) {
		if (message != null) {
			GameSessionId = message.GameSessionId;
			Name = message.GameSessionName;
			MaximumPlayerSessionCount = message.MaximumPlayerSessionCount;
			Port = message.Port;
			IpAddress = message.IpAddress;
			GameSessionData = message.GameSessionData;
			MatchmakerData = message.MatchmakerData;
			GameProperties = message.GameProperties;
			DnsName = message.DnsName;
		} else {
			GameProperties = new Map<String, String>();
			MaximumPlayerSessionCount = 0;
		}
	}
}
