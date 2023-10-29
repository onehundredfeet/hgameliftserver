package;

import aws.gamelift.server.model.GameSession;
import aws.gamelift.server.model.Messages.MessageActions;
import haxe.Json;
import hxasync.Asyncable;
import aws.gamelift.Util;
import aws.gamelift.server.model.Messages;
import aws.gamelift.HttpStatusCode;

private var _connections = new Array<TestConnection>();

enum ConnectionState {
	Disconnected;
	Connected;
	WaitingForProcessActivation;
	WaitingForSessionActivation;
    Activated;
    Terminating;
    Terminated;
}

class TestConnection {
	var _ws:js.node.WebSocket;
	var _state = ConnectionState.Disconnected;
    var _hbCount = 0;

	function makeSuccessResponse(msg) {
		var response = new ResponseMessage();
		response.RequestId = msg.RequestId;
		response.StatusCode = HttpStatusCode.OK;
		return response;
	}

	function makeFailureResponse(msg, errorMessage) {
		var response = new ResponseMessage();
		response.RequestId = msg.RequestId;
		response.StatusCode = HttpStatusCode.BadRequest;
		response.ErrorMessage = errorMessage;
		return response;
	}

	function sendMsg(msg : Message) {
		_ws.send(Json.stringify(msg));
	}

	public function new(ws:js.node.WebSocket) {
		_ws = ws;
		_state = ConnectionState.WaitingForProcessActivation;

		ws.on('message', function incoming(message) {
			trace('received: ${message}');

			var msg:Message = Json.parse(message);
			trace(msg);

			switch [_state, msg.Action] {
				case [WaitingForProcessActivation, MessageActions.ActivateServerProcess]:
					{
						_state = ConnectionState.WaitingForSessionActivation;
						sendMsg(makeSuccessResponse(msg));
                        var createGameSessionMsg = CreateGameSessionMessage.make();
                        createGameSessionMsg.GameSessionId = "TestGameSessionId";
                        createGameSessionMsg.GameSessionName = "TestGameSession";
                        createGameSessionMsg.MaximumPlayerSessionCount = 10;
                        createGameSessionMsg.DnsName = "TestDNS";
                        createGameSessionMsg.Port = 1339;
                        createGameSessionMsg.IpAddress = "jingle.bells";
                        createGameSessionMsg.GameSessionData = "{}";
                        createGameSessionMsg.MatchmakerData = "{}";
                        createGameSessionMsg.GameProperties = new Map<String, String>();

                        sendMsg(createGameSessionMsg);
                        
					}
                    case [WaitingForSessionActivation, MessageActions.ActivateGameSession]:
                    {
                        _state = ConnectionState.Activated;
                        sendMsg(makeSuccessResponse(msg));
                    }
                    case [Activated, MessageActions.HeartbeatServerProcess]:
                    {
                        trace('Received heartbeat');
                        _hbCount++;
                        if (_hbCount == 2) {
                            trace('Sending game session udpate');
                            var gameSession = new GameSession();
                            gameSession.DnsName = "TestDNS";
                            gameSession.GameSessionId = "TestGameSessionId";
                            gameSession.IpAddress = "jingle.bells";
                            gameSession.MatchmakerData = "{}";
                            gameSession.MaximumPlayerSessionCount = 10;
                            gameSession.Name = "TestGameSession";
                            gameSession.Port = 1339;
                            gameSession.GameSessionData = "{}";
                            gameSession.MatchmakerData = "{}";
                            gameSession.GameProperties = new Map<String, String>();
                            var msg = UpdateGameSessionMessage.make(gameSession, "Cause I said so", "" );
                            sendMsg(msg);
                        }
                        else if (_hbCount == 10) {
                            _state = ConnectionState.Terminating;
                            final AutoTerminateTimerMS = 5000;
                            sendMsg(TerminateProcessMessage.make(Date.now().getTime() + AutoTerminateTimerMS));    
                        } else {
                            sendMsg(makeSuccessResponse(msg));
                        }
                    }
                    case [Terminating, MessageActions.TerminateServerProcess]:
                    {
                        _state = ConnectionState.Terminated;
                        sendMsg(makeSuccessResponse(msg));
                        _ws.close();
                    }

				default:
					sendMsg(makeFailureResponse(msg, 'Unknown action for state ${_state}'));
			}
			// {"Action":"ActivateServerProcess","RequestId":"d6cc90ad-01e3-49e2-824c-dde3af912d02","SdkVersion":"5.1.1","SdkLanguage":"CSharp","Port":1338,"LogPaths":["./logs.txt"]}
		});
		ws.on('close', function close(_) {
			trace('disconnected from client');
			_connections.remove(this);
		});
	}
}

class TestWebSocketServer implements Asyncable {
	@async public static function execute() {
		trace("hi from the other side!");
		var webSocketServer = new js.node.WebSocketServer({port: 1337});

		webSocketServer.on('connection', function connection(ws) {
			_connections.push(new TestConnection(ws));
		});

		webSocketServer.on('error', function error() {
			trace('error');
		});
		webSocketServer.on('listening', function listening() {
			trace('listening');
		});
		webSocketServer.on('headers', function headers() {
			trace('headers');
		});
		webSocketServer.on('upgrade', function upgrade() {
			trace('upgrade');
		});
		webSocketServer.on('request', function request() {
			trace('request');
		});
		webSocketServer.on('message', function message() {
			trace('message');
		});

		trace('waiting one secondx');
		@await delay(1000);
		trace('Done now');
		null;
	}

	public static function main() {
		execute();
	}
}
