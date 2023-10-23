package aws.gamelift.server.model;

 /// <summary>
    /// The service role credentials provided to GameLift that allow the compute
    /// access to other AWS services in your account.
    /// </summary>
    class GetFleetRoleCredentialsResult
    {
        public var assumedRoleUserArn : String;

        public var assumedRoleId : String;

        public var accessKeyId : String;

        public var secretAccessKey : String;

        public var sessionToken : String;

        public var expiration : Date;

        public function new(
             assumedRoleUserArn : String,
             assumedRoleId : String,
             accessKeyId : String,
             secretAccessKey : String,
             sessionToken : String,
             expiration : Date)
        {
            this.assumedRoleUserArn = assumedRoleUserArn;
            this.assumedRoleId = assumedRoleId;
            this.accessKeyId = accessKeyId;
            this.secretAccessKey = secretAccessKey;
            this.sessionToken = sessionToken;
            this.expiration = expiration;
        }
    }