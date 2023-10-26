package aws.gamelift.server.model;

class TerminateServerProcessRequest extends Message {
	public function new() {
		super(MessageActions.TerminateServerProcess);
	}
}
