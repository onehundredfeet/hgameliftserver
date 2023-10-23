package aws.gamelift.server;

import aws.gamelift.server.model.GameSession;
import aws.gamelift.server.model.UpdateGameSession;

typedef OnStartGameSessionDelegate = (gameSession:GameSession) -> Void;
typedef OnUpdateGameSessionDelegate = (updateGameSession:UpdateGameSession) -> Void;
typedef OnProcessTerminateDelegate = () -> Void;
typedef OnHealthCheckDelegate = () -> Bool;

/// <summary>
/// This data type contains the set of parameters sent to GameLift in a ProcessReady() method.
/// </summary>
class ProcessParameters {
	/// <summary>
	/// Name of callback function that GameLift invokes to activate a new game
	/// session. GameLift calls this function in response to the client request CreateGameSession.
	/// The callback function takes a GameSession object defined in GameLift API Reference.
	/// </summary>
	public var onStartGameSession:OnStartGameSessionDelegate;

	/// <summary>
	/// Name of callback function that GameLift invokes to pass an updated
	/// game session object to the server process. GameLift calls this function when a
	/// match backfill request has been processed in order to provide updated matchmaker
	/// data. It passes a GameSession object, a status update (updateReason), and the
	/// match backfill ticket ID.
	/// </summary>
	///
	public var onUpdateGameSession:OnUpdateGameSessionDelegate;

	/// <summary>
	/// Name of callback function that GameLift invokes to force the server
	/// process to shut down. After calling this function, GameLift waits five minutes for
	/// the server process to shut down and respond with a ProcessEnding() call before it
	/// shuts down the server process.
	/// </summary>
	///
	public var onProcessTerminate:OnProcessTerminateDelegate;

	/// <summary>
	/// Name of callback function that GameLift invokes to request a health
	/// status report from the server process. GameLift calls this function every 60 seconds.
	/// After calling this function GameLift waits 60 seconds for a response, and if none is
	/// received. records the server process as unhealthy.
	/// </summary>
	public var onHealthCheck:OnHealthCheckDelegate;

	/// <summary>
	/// Port number the server process will listen on for new player connections.
	/// The value must fall into the port range configured for any fleet deploying
	/// this game server build. This port number is included in game session and player
	/// session objects, which game sessions use when connecting to a server process.
	/// </summary>
	public var port:Int;

	/// <summary>
	/// Object with a list of directory paths to game session log files.
	/// </summary>
	public var logParameters:LogParameters;

	public function new(onStartGameSession:OnStartGameSessionDelegate = null, onUpdateGameSession:OnUpdateGameSessionDelegate = null,
			onProcessTerminate:OnProcessTerminateDelegate = null, onHealthCheck:OnHealthCheckDelegate = null, port:Int = -1,
			logParameters:LogParameters = null) {
		this.onStartGameSession = onStartGameSession != null ? onStartGameSession : (_) -> {};
		this.onUpdateGameSession = onUpdateGameSession != null ? onUpdateGameSession : (_) -> {};
		this.onProcessTerminate = onProcessTerminate != null ? onProcessTerminate : () -> {};
		this.onHealthCheck = onHealthCheck != null ? onHealthCheck : () -> return true;
		this.port = port;
		this.logParameters = logParameters;
	}
}
