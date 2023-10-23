package aws.gamelift.server.model;

import aws.gamelift.server.model.Message;

class CreateGameSessionMessage extends Message
    {
        public var gameSessionId : String;

        public var gameSessionName : String;

        public var maximumPlayerSessionCount : Int;

        public var port : Int;

        public var ipAddress : String;

        public var gameSessionData : String;

        public var matchmakerData : String;

        public var gameProperties : Map<String, String>;

        public var dnsName : String;
    }