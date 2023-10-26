package aws.gamelift.server.model;
import aws.gamelift.server.model.Message;

class HeartbeatServerProcessRequest extends Message
{
    public var  healthStatus : Bool;

    public function new( healthStatus : Bool)
    {
        super(MessageActions.HeartbeatServerProcess);
        this.healthStatus = healthStatus;
    }
}