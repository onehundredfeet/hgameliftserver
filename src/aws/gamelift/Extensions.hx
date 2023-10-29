package aws.gamelift;
import haxe.Constraints;
class Extensions {
    public static function trySet<V,K>(map:IMap<K,V>, key:K, value:V):Bool {
        if (map.exists(key)) {
            return false;
        }
        map.set(key, value);
        return true;
    }

    public static function tryRemove<V,K>(map:IMap<K,V>, key:K):Null<V> {
        if (!map.exists(key)) {
            return null;
        }
        var value = map.get(key);
        map.remove(key);
        return value;
    }
}