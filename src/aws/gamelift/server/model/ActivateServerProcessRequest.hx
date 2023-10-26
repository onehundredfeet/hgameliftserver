package aws.gamelift.server.model;

class ActivateServerProcessRequest extends Message
    {
        public var  sdkVersion : String;

        public var  sdkLanguage : String;

        public var  port : Int;

        public var  logPaths : Array<String>;

        public function new( sdkVersion : String, sdkLanguage: String,  port : Int, logPaths : Array<String>)
        {
            super(MessageActions.ActivateServerProcess);
            this.sdkVersion = sdkVersion;
            this.sdkLanguage = sdkLanguage;
            this.port = port;
            this.logPaths = logPaths;
        }
    }