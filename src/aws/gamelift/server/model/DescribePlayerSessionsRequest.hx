package aws.gamelift.server.model;

import aws.gamelift.server.model.Message;

class DescribePlayerSessionsRequest extends Message
    {
        public var gameSessionId : String;

        public var playerSessionId : String;

        public var playerId : String;

        public var playerSessionStatusFilter : String;

        public var nextToken : String;

        public var limit = 50;

        public function new()
        {
            super(MessageActions.DescribePlayerSessions);
        }
    }