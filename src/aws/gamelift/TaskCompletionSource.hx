package aws.gamelift;

class TaskCompletionSource<T> {
    public function new(){
        
    }
    public function setCanceled(){}
    public function setResult(result:T){}
    public var task:Task;
}