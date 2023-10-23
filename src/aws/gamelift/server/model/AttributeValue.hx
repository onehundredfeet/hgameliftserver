package aws.gamelift.server.model;

enum abstract AttrType(Int) {
	var STRING = 0;
	var DOUBLE;
	var STRING_LIST;
	var STRING_DOUBLE_MAP;
}

/// <summary>
/// Values for use in <seealso cref="Player"/> attribute key-value pairs. This object
/// lets you specify an attribute value using any of the valid data types:
/// string, number, string array, or data map. Each <c>AttributeValue</c> object
/// can use only one of the available properties.
/// </summary>
class AttributeValue {
	public var attrType:AttrType;

	public var S:String;

	public var N:Float;

	public var SL:Array<String>;

	public var SDM:Map<String, Float>;

	function new(attrType:AttrType) {
		this.attrType = attrType;
	}

	public static function fromString( s : String) {
		var av = new AttributeValue(AttrType.STRING);
		av.S = s;
		return av;
	}

	public static function fromDouble( n : Float) {
		var av = new AttributeValue(AttrType.DOUBLE);
		av.N = n;
		return av;
	}

	public static function fromStringArray(sl:Array<String>) {
		var av = new AttributeValue(AttrType.STRING_LIST);
		av.SL = sl;
		return av;
	}

	public static function fromDictionary(sdm:Map<String, Float>) {
		var av = new AttributeValue(AttrType.STRING_DOUBLE_MAP);
		av.SDM = sdm;
		return av;
	}
}
