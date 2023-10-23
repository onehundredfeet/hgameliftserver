package aws.gamelift.server.model;

class StartMatchBackfillRequest extends Message {
	public var gameSessionArn:String;

	public var matchmakingConfigurationArn:String;

	public var players:Array<Player>;

	public var ticketId:String;

	public function new(gameSessionArn:String, matchmakingConfigurationArn:String, players:Array<Player>) {
        super(MessageActions.StartMatchBackfill);
		this.gameSessionArn = gameSessionArn;
		this.matchmakingConfigurationArn = matchmakingConfigurationArn;
		this.players = players;
	}
}

