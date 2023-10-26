package aws.gamelift.server.model;

class AcceptPlayerSessionRequest extends Message
    {
        public var  gameSessionId : String;

        public var  playerSessionId : String;

        public function new( gameSessionId : String, playerSessionId : String)
        {
            super( MessageActions.AcceptPlayerSession);
            this.gameSessionId = gameSessionId;
            this.playerSessionId = playerSessionId;
        }
    }