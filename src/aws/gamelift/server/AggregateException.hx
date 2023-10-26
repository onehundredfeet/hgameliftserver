package aws.gamelift.server;

class AggregateException extends haxe.Exception {
    public final innerExceptions : Array<haxe.Exception>;

    public function new(innerExceptions : Array<haxe.Exception>) {
        super(null, null);
        this.innerExceptions = innerExceptions;
    }
}