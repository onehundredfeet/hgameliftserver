package ;
   
import aws.gamelift.server.GameLiftWebSocket;
import aws.gamelift.IWebSocketMessageHandler;
import aws.gamelift.server.model.*;
import aws.gamelift.Util;
import hxasync.Asyncable;
import aws.gamelift.Util;
class TestWebSockets implements IWebSocketMessageHandler implements Asyncable{
	function new() {}
	public function onErrorResponse( requestId : String,  statusCode : Int,  errorMessage : String) : Void {
		trace('onErrorResponse');
	}

    public function onSuccessResponse( requestId : String): Void {
		trace('onSuccessResponse');

	}

    public function onStartGameSession( gameSession : GameSession): Void {
		trace('onStartGameSession');
	}

    public function onUpdateGameSession( gameSession : GameSession,  updateReason : UpdateReason,  backfillTicketId : String): Void {
		trace('onUpdateGameSession');
	}

    public function onTerminateProcess( terminationTime : Float): Void {
		trace('onTerminateProcess');
	}

    public function onStartMatchBackfillResponse( requestId : String,  ticketId : String): Void {
		trace('onStartMatchBackfillResponse');
	}

    public function onDescribePlayerSessionsResponse( requestId : String, playerSessions :  Array<PlayerSession>,  nextToken : String): Void {
		trace('onDescribePlayerSessionsResponse');
	}

    public function onGetComputeCertificateResponse( requestId : String,  certificatePath : String,  computeName : String): Void {
		trace('onGetComputeCertificateResponse');
	}

    public function onGetFleetRoleCredentialsResponse(
        requestId : String,
        assumedRoleUserArn : String,
        assumedRoleId : String,
        accessKeyId : String,
        secretAccessKey : String,
        sessionToken : String,
         expiration : Float): Void {
		trace('onGetFleetRoleCredentialsResponse');
		 }

    public function onRefreshConnection( refreshConnectionEndpoint : String,  authToken : String): Void {

	}

	private static final EnvironmentVariableWebsocketUrl = "GAMELIFT_SDK_WEBSOCKET_URL";
	private static final EnvironmentVariableProcessId = "GAMELIFT_SDK_PROCESS_ID";
	private static final EnvironmentVariableHostId = "GAMELIFT_SDK_HOST_ID";
	private static final EnvironmentVariableFleetId = "GAMELIFT_SDK_FLEET_ID";
	private static final EnvironmentVariableAuthToken = "GAMELIFT_SDK_AUTH_TOKEN";


	@async public  static function execute()  {
		trace("hi from the other side!");
		var tws = new TestWebSockets();
        var webSocket = new GameLiftWebSocket(tws);
		var websocketUrl = getEnv(EnvironmentVariableWebsocketUrl) ?? "ws://localhost:1337"; //wss://ws.postman-echo.com/raw";
		var processId = getEnv(EnvironmentVariableProcessId) ?? "Derp";
		var hostId = getEnv(EnvironmentVariableHostId) ?? "localhost";
		var fleetId = getEnv(EnvironmentVariableFleetId) ?? "0";
		var authToken = getEnv(EnvironmentVariableAuthToken) ?? "empty";

		trace('websocketUrl: ' + websocketUrl);
		var x = @await webSocket.connect(websocketUrl, processId, hostId, fleetId, authToken);

		webSocket.sendRaw(haxe.Json.stringify({message: "Hello from Haxe"}));	

		trace('waiting one second ${x}');
		@await delay(1000);
		trace('Done now');

		webSocket.disconnect();
		null;
	}
	public static function main() {
		execute();
	}
}