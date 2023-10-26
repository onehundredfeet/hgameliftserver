package aws.gamelift.server.model;

class UpdatePlayerSessionCreationPolicyRequest extends Message
    {
        public var  gameSessionId : String;

        public var  playerSessionPolicy : String;

        public function new( gameSessionId : String,  policy : PlayerSessionCreationPolicy)
        {
            super(MessageActions.UpdatePlayerSessionCreationPolicy);
            this.gameSessionId = gameSessionId;
            this.playerSessionPolicy = policy;
        }
    }