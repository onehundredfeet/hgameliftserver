package aws.gamelift.server.model;

 /// <summary>
    /// The path to the TLS certificate on your compute and the compute's host name.
    /// </summary>
     class GetComputeCertificateResult
    {
        public var certificatePath : String;

        public var computeName : String;

        public function new( certificatePath : String,  computeName : String)
        {
            this.certificatePath = certificatePath;
            this.computeName = computeName;
        }
    }