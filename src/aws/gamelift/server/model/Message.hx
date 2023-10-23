package aws.gamelift.server.model;

import uuid.Uuid;

class Message
{
    public var action : String;
    public var requestId : String;

    public function new(action : String = null)
    {
        this.action = action;
        requestId = Uuid.v4(); //Guid.NewGuid().ToString();
    }
}