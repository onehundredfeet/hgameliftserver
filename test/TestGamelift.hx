package;

import aws.gamelift.server.GameLiftWebSocket;
import aws.gamelift.IWebSocketMessageHandler;
import aws.gamelift.server.GameLiftServerAPI;
import aws.gamelift.server.ServerParameters;
import aws.gamelift.server.ProcessParameters;
import aws.gamelift.server.LogParameters;
import aws.gamelift.server.model.*;
import aws.gamelift.Util;
import hxasync.Asyncable;
import aws.gamelift.Util;

class TestGamelift implements Asyncable {
	function new() {}

	private static final EnvironmentVariableWebsocketUrl = "GAMELIFT_SDK_WEBSOCKET_URL";
	private static final EnvironmentVariableProcessId = "GAMELIFT_SDK_PROCESS_ID";
	private static final EnvironmentVariableHostId = "GAMELIFT_SDK_HOST_ID";
	private static final EnvironmentVariableFleetId = "GAMELIFT_SDK_FLEET_ID";
	private static final EnvironmentVariableAuthToken = "GAMELIFT_SDK_AUTH_TOKEN";

    #if cloud
    static var gameRoot = "/local/game";
    #else
    static var gameRoot = "";
    #end
	// Set a custom trace function
	static var _logFileName = gameRoot + "/log.txt";

	@async public static function execute() {
		// Identify port number (hard coded here for simplicity) the game server is listening on for player connections
		var listeningPort = 7777;

		// WebSocketUrl from RegisterHost call
		var webSocketUrl = "wss://us-east-1.api.amazongamelift.com";

		// Unique identifier for this process
		var processId = "myProcess";

		// Unique identifier for your host that this process belongs to
		var hostId = "myHost";

		// Unique identifier for your fleet that this host belongs to
		var fleetId = "myFleet";

		// Authentication token for this host process.
		var authToken = "myAuthToken";

		var serverParameters = new ServerParameters(webSocketUrl, processId, hostId, fleetId, authToken);

		@await GameLiftServerAPI.initSDK(serverParameters);

		var processParameters = new ProcessParameters();
		processParameters.onStartGameSession = function(gameSession:GameSession) {
			trace("onStartGameSession");
			GameLiftServerAPI.activateGameSession();
		};
		processParameters.onUpdateGameSession = function(update:GameSession, reason:UpdateReason, backfillTicketId:String) {
			trace("onUpdateGameSession");
		};
		var _ended = false;
		var _endTime = null;

		processParameters.onProcessTerminate = function(time:Date) {
			trace('onTerminateProcess before ${time}');
			_ended = true;
			_endTime = time;
			GameLiftServerAPI.processEnding();
		};
		processParameters.onHealthCheck = function() {
			trace("onHealthCheck");
			return true;
		};
		processParameters.port = listeningPort;
		var logs = new LogParameters([_logFileName]);
		processParameters.logParameters = logs;

		GameLiftServerAPI.processReady(processParameters);
		trace("hi from the other side!");

		while (_endTime == null || _endTime.getTime() > Date.now().getTime()) {
			if (_endTime != null) {
				Sys.println('Shutting down in ${_endTime.getTime() - Date.now().getTime()} ms');
			}
			trace('Ticking ${_endTime} - ${Date.now()}');
			GameLiftServerAPI.tick(.100);
			@await delay(100);
		}

		trace('Destroying');
		@await GameLiftServerAPI.destroy();
		trace('Destroyed');
		null;
	}

	static function customTrace(v:Dynamic, ?infos:haxe.PosInfos) {
		var date = Date.now();

		var message = '${date} ${infos.fileName}:${infos.lineNumber}: ${v}';

		// Write the message to the console
		Sys.println(message);

		// Append the message to a file
		appendToFile(_logFileName, message);
	}

	static function appendToFile(filename:String, text:String):Void {
		var contents = sys.io.File.getContent(filename);
		contents += text + '\n';
		sys.io.File.saveContent(filename, contents);
	}

	static function resetLog() {
		if (sys.FileSystem.exists(_logFileName)) {
			try {
				sys.FileSystem.deleteFile(_logFileName);
			} catch (e:Dynamic) {
				Sys.println("Error deleting log file: " + e);
			}
		}
		sys.io.File.saveContent(_logFileName, "");
	}

	public static function main() {
		resetLog();
		haxe.Log.trace = customTrace;
		try {
			execute();
		} catch (e:Dynamic) {
			Sys.println("Error: " + e);
		}
	}
}
