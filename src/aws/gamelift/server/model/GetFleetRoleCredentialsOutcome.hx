package aws.gamelift.server.model;

import aws.gamelift.GenericOutcome;
import aws.gamelift.server.model.GetFleetRoleCredentialsResult;

class GetFleetRoleCredentialsOutcome extends GenericOutcome {
	public var result:GetFleetRoleCredentialsResult;

	public function new( error : GameLiftError,  result : GetFleetRoleCredentialsResult = null)
	{
        super(error);
		this.result = result;
	}
}
