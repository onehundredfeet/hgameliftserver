package aws.gamelift.server.model;

import aws.gamelift.server.model.Message;

class StopMatchBackfillRequest extends Message {
	public var gameSessionArn:String;
	public var matchmakingConfigurationArn:String;
	public var ticketId:String;

	public function new(gameSessionArn:String, matchmakingConfigurationArn:String, ticketId:String) {
		super(MessageActions.StopMatchBackfill);
		this.gameSessionArn = gameSessionArn;
		this.matchmakingConfigurationArn = matchmakingConfigurationArn;
		this.ticketId = ticketId;
	}
}
