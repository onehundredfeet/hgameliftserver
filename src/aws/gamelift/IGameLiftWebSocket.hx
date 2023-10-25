package aws.gamelift;
import aws.gamelift.server.model.Message;

interface IGameLiftWebSocket {
    function sendMessage(message : Message) : GenericOutcome;
    function disconnect() : GenericOutcome;
    function connect(websocketUrl : String,  processId : String,  hostId : String,  fleetId : String,  authToken : String) : GenericOutcome;
}
