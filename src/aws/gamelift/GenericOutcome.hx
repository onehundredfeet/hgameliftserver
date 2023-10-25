package aws.gamelift;

import aws.gamelift.GameLiftError;

class GenericOutcome {
	public final error:GameLiftError;
	public final success:Bool;

	public function new(  error : GameLiftError = null) {
		this.success = error == null;
        this.error = error;
	}
}
