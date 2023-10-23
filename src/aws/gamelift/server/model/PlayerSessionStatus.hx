package aws.gamelift.server.model;

enum abstract PlayerSessionStatus(Int) {
	var NOT_SET = 0;
	var RESERVED;
	var ACTIVE;
	var COMPLETED;
	var TIMEDOUT;
}

class PlayerSessionStatusMapper {
	private static final Reserved = "RESERVED";
	private static final Active = "ACTIVE";
	private static final Completed = "COMPLETED";
	private static final Timedout = "TIMEDOUT";
	private static final NotSet = "NOT_SET";

	public static function getPlayerSessionStatusForName(name:String):PlayerSessionStatus {
		switch (name) {
			case Reserved:
				return PlayerSessionStatus.RESERVED;
			case Active:
				return PlayerSessionStatus.ACTIVE;
			case Completed:
				return PlayerSessionStatus.COMPLETED;
			case Timedout:
				return PlayerSessionStatus.TIMEDOUT;
			default:
				return PlayerSessionStatus.NOT_SET;
		}
	}

	public static function getNameForPlayerSessionStatus(value:PlayerSessionStatus):String {
		switch (value) {
			case PlayerSessionStatus.RESERVED:
				return Reserved;
			case PlayerSessionStatus.ACTIVE:
				return Active;
			case PlayerSessionStatus.COMPLETED:
				return Completed;
			case PlayerSessionStatus.TIMEDOUT:
				return Timedout;
			default:
				return NotSet;
		}
	}
}
