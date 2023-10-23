package aws.gamelift.server.model;

/// <summary>
/// The match backfill ticket ID.
/// </summary>
class StartMatchBackfillResult {
	public var ticketId:String;

	public function new(ticketId:String) {
		this.ticketId = ticketId;
	}
}
