package aws.gamelift.server.model;

class GetComputeCertificateRequest extends Message
    {
        public function new()
        {
            super(MessageActions.GetComputeCertificate);
        }
    }