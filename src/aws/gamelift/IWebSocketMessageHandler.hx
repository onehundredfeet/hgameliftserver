package aws.gamelift;
import aws.gamelift.server.model.GameSession;
import aws.gamelift.server.model.PlayerSession;
import aws.gamelift.server.model.UpdateReason;

interface IWebSocketMessageHandler {
    function onErrorResponse( requestId : String,  statusCode : Int,  errorMessage : String) : Void;

    function onSuccessResponse( requestId : String): Void;

    function onStartGameSession( gameSession : GameSession): Void;

    function onUpdateGameSession( gameSession : GameSession,  updateReason : UpdateReason,  backfillTicketId : String): Void;

    function onTerminateProcess( terminationTime : Float): Void;

    function onStartMatchBackfillResponse( requestId : String,  ticketId : String): Void;

    function onDescribePlayerSessionsResponse( requestId : String, playerSessions :  Array<PlayerSession>,  nextToken : String): Void;

    function onGetComputeCertificateResponse( requestId : String,  certificatePath : String,  computeName : String): Void;

    function onGetFleetRoleCredentialsResponse(
        requestId : String,
        assumedRoleUserArn : String,
        assumedRoleId : String,
        accessKeyId : String,
        secretAccessKey : String,
        sessionToken : String,
         expiration : Float): Void;

    function onRefreshConnection( refreshConnectionEndpoint : String,  authToken : String): Void;
} 
