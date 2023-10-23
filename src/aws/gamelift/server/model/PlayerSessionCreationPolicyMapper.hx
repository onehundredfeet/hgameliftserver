package aws.gamelift.server.model;

enum abstract PlayerSessionCreationPolicy(Int) {
	var NOT_SET = 0;
	var ACCEPT_ALL;
	var DENY_ALL;
}

class PlayerSessionCreationPolicyMapper {
	private static final AcceptAll = "ACCEPT_ALL";
	private static final DenyAll = "DENY_ALL";
	private static final NotSet = "NOT_SET";

	public static function getPlayerSessionCreationPolicyForName(name:String):PlayerSessionCreationPolicy {
		switch (name) {
			case AcceptAll:
				return PlayerSessionCreationPolicy.ACCEPT_ALL;
			case DenyAll:
				return PlayerSessionCreationPolicy.DENY_ALL;
			default:
				return PlayerSessionCreationPolicy.NOT_SET;
		}
	}

	public static function GetNameForPlayerSessionCreationPolicy( value : PlayerSessionCreationPolicy):String {
		switch (value) {
			case PlayerSessionCreationPolicy.ACCEPT_ALL:
				return AcceptAll;
			case PlayerSessionCreationPolicy.DENY_ALL:
				return DenyAll;
			default:
				return NotSet;
		}
	}
}
