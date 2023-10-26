package aws.gamelift.server.model;

class ActivateGameSessionRequest extends Message
    {
        public var gameSessionId : String;

        public function new( gameSessionId : String)
        {
            super( MessageActions.ActivateGameSession );
            this.gameSessionId = gameSessionId;
        }
    }