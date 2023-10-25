package aws.gamelift.server.model;
import aws.gamelift.ILog;
/// <summary>
    /// Provides a list of requested player session objects.
    /// </summary>
    class DescribePlayerSessionsResult
    {
        private static final MaxPlayerSessions = 1024;

        public static final Log : ILog = LogManager.GetLogger(Type.typeof(ServerState));

        public var nextToken : String;

        public var playerSessions : Array<PlayerSession>;

        public function new( playerSessions : Array<PlayerSession>,  nextToken : String)
        {
            this.playerSessions = playerSessions;
            this.nextToken = nextToken;
        }

        public function addPlayerSession( value : PlayerSession )
        {
            if (playerSessions.length < MaxPlayerSessions)
            {
                playerSessions.push(value);
            }
            else
            {
                //Log.DebugFormat("PlayerSessions count is greater than or equal to max player sessions {0}.", MaxPlayerSessions);
            }
        }
    }