package aws.gamelift.server.model;

import aws.gamelift.GenericOutcome;
import aws.gamelift.server.model.GetComputeCertificateResult;

class GetComputeCertificateOutcome extends GenericOutcome
    {
        public var result : GetComputeCertificateResult;


        public function new( error : GameLiftError,  result : GetComputeCertificateResult)
        {
            super(error);
            this.result = result;
        }
    }