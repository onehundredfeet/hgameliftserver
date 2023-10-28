
package ;
   
import uuid.Uuid;

class Message
{
    public var Action : String;
    public var RequestId : String;

    public function new(action : String = null)
    {
        this.Action = action;
        this.RequestId = Uuid.v4();
    }
}

class JsonTest {


	public static function main() {
        var value = new Message("");

        var writer = new json2object.JsonWriter<Message>(); // Creating a writer for Cls class
        var parser = new json2object.JsonParser<Message>(); // Creating a parser for Cls class
        
		trace('${writer.write(value)}');
        value.Action = null;
		trace('${writer.write(value)}');

        parser.fromJson('{"action": "","requestId": "305c095d-b5b3-4971-b37a-d9badd40e083"}', ""); // Parsing a string. A filename is specified for errors management
        var parsed:Message = parser.value; // Access the parsed class
        trace('Parsed ${parsed}');
        var errors:Array<json2object.Error> = parser.errors; // Access the potential errors yield during the parsing
        trace('Errors ${errors}');
	}
}


