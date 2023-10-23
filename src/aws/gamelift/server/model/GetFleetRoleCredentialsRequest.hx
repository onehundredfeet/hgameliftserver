package aws.gamelift.server.model;

import aws.gamelift.server.model.Message;

class GetFleetRoleCredentialsRequest extends Message {
	public var roleArn:String;

	public var roleSessionName:String;

	public function new(roleArn:String) {
        super(MessageActions.GetFleetRoleCredentials);
		this.roleArn = roleArn;
	}
}
