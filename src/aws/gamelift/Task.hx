package aws.gamelift;

class Task {
    public function wait(timeoutMillis : Int) : Bool { return false; }
    public var result : Dynamic;
    public static function run(f : () -> Void) {}
}