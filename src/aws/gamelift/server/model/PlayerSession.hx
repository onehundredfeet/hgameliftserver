package aws.gamelift.server.model;

 /// <summary>
    /// Details about the connection of a player to your game server.
    /// </summary>
    class PlayerSession
    {
        public var playerId : String;

        public var playerSessionId : String;

        public var gameSessionId : String;

        public var fleetId : String;

        public var ipAddress : String;

        public var playerData : String;

        public var port : Int;

        public var creationTime : Float;

        public var terminationTime : Float;

        public var status : PlayerSessionStatus;

        public var dnsName : String;

        public function new()
        {
            port = 0;
            creationTime = 0;
            terminationTime = 0;
        }
    }