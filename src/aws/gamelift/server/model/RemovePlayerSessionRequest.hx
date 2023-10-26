package aws.gamelift.server.model;

class RemovePlayerSessionRequest extends Message
    {
        public var  gameSessionId : String;

        public var  playerSessionId : String;

        public function new( gameSessionId : String,  playerSessionId : String)
        {
            super(MessageActions.RemovePlayerSession);
            this.gameSessionId = gameSessionId;
            this.playerSessionId = playerSessionId;
        }
    }