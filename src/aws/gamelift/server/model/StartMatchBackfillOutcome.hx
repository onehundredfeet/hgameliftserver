package aws.gamelift.server.model;
import aws.gamelift.GenericOutcome;
import aws.gamelift.server.model.StartMatchBackfillResult;

class StartMatchBackfillOutcome extends GenericOutcome
    {
        public var result : StartMatchBackfillResult;

        public function new( error : GameLiftError = null,  result : StartMatchBackfillResult = null)
        {
            super(error);
            this.result = result;
        }
    }