package aws.gamelift;

#if js
import js.lib.Promise;
abstract Noise(Dynamic) {}

class CountdownEvent {
	private var count:Int;
	private var resolve:Noise->Void;
	private var reject:Dynamic->Void;
	private var promise:Promise<Noise>;
	private var isCompleted:Bool = false;

	public function new(initialCount:Int) {
		if (initialCount <= 0)
			throw 'Count must be greater than zero';

		this.count = initialCount;
		this.promise = new Promise<Noise>((resolve, reject) -> {
			this.resolve = resolve;
			this.reject = reject;
		});
	}

	public function signal():Void {
		if (isCompleted)
			return;

		count--;
		if (count == 0) {
			resolve(null);
			isCompleted = true;
		}
	}

	public function cancel(reason:String):Void {
		if (!isCompleted) {
			reject(reason);
			isCompleted = true;
		}
	}

	public function wait():Promise<Noise> {
		return promise;
	}

    public var isSet(get, never):Bool;
	inline function get_isSet():Bool {
		return isCompleted;
	}
}
#elseif (!macro)
import haxe.concurrent.Semaphore;

class CountdownEvent {
	private var initialCount:Int;
	private var count:Int;
	private var semaphore:Semaphore;

	public function new(count:Int) {
		this.initialCount = this.count = count;
		this.semaphore = new Semaphore(0); // initialized to 0
	}

	public function signal():Void {
		if (--count <= 0) {
			for (i in 0...initialCount) {
				semaphore.release();
			}
		}
	}

	public function wait():Void {
		semaphore.acquire();
	}

	public function reset():Void {
		count = initialCount;
	}
}
#end
