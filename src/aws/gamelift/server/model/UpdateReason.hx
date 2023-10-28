package aws.gamelift.server.model;

enum abstract UpdateReason(String) from String to String {
	var MATCHMAKING_DATA_UPDATED = "MATCHMAKING_DATA_UPDATED";
	var BACKFILL_FAILED = "BACKFILL_FAILED";
	var BACKFILL_TIMED_OUT = "BACKFILL_TIMED_OUT";
	var BACKFILL_CANCELLED = "BACKFILL_CANCELLED";
	var UNKNOWN = "UNKNOWN";
}
/*
class UpdateReasonMapper {
	private static final MatchmakingDataUpdatedReason = "MATCHMAKING_DATA_UPDATED";
	private static final BackfillFailedReason = "BACKFILL_FAILED";
	private static final BackfillTimedOutReason = "BACKFILL_TIMED_OUT";
	private static final BackfillCancelledReason = "BACKFILL_CANCELLED";
	private static final UnknownReason = "UNKNOWN";

	public static function getUpdateReasonForName(name:String):UpdateReason {
		switch (name) {
			case MatchmakingDataUpdatedReason:
				return UpdateReason.MATCHMAKING_DATA_UPDATED;
			case BackfillFailedReason:
				return UpdateReason.BACKFILL_FAILED;
			case BackfillTimedOutReason:
				return UpdateReason.BACKFILL_TIMED_OUT;
			case BackfillCancelledReason:
				return UpdateReason.BACKFILL_CANCELLED;
			default:
				return UpdateReason.UNKNOWN;
		}
	}

	public static function getNameForUpdateReason(value:UpdateReason):String {
		return switch (value) {
			case UpdateReason.MATCHMAKING_DATA_UPDATED:
				MatchmakingDataUpdatedReason;
			case UpdateReason.BACKFILL_FAILED:
				BackfillFailedReason;
			case UpdateReason.BACKFILL_TIMED_OUT:
				BackfillTimedOutReason;
			case UpdateReason.BACKFILL_CANCELLED:
				BackfillCancelledReason;
			default:
				UnknownReason;
		}
	}
}
*/