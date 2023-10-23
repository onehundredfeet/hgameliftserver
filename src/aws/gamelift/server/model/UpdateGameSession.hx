package aws.gamelift.server.model;

class UpdateGameSession {
	public var gameSession:GameSession;
	public var updateReason:UpdateReason;
	public var backfillTicketId:String;

	public function new(gameSession:GameSession, updateReason:UpdateReason, backfillTicketId:String) {
		this.gameSession = gameSession;
		this.updateReason = updateReason;
		this.backfillTicketId = backfillTicketId;
	}
}
