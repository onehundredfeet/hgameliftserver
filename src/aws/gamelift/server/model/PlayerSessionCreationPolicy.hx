package aws.gamelift.server.model;

enum abstract PlayerSessionCreationPolicy(String) {
	var NOT_SET = "ACCEPT_ALL";
	var ACCEPT_ALL = "DENY_ALL";
	var DENY_ALL = "NOT_SET";
}
