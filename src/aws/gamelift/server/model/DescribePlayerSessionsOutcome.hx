package aws.gamelift.server.model;

class DescribePlayerSessionsOutcome extends GenericOutcome
    {
        public var result : DescribePlayerSessionsResult;

        public function new ( error : GameLiftError = null,  result : DescribePlayerSessionsResult = null)
        {
            super(error);
            this.result = result;
        }
    }