package aws.macro;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;

class JsonAutoSerializer {
    public static function build():Array<Field> {
        var fields = Context.getBuildFields();
        var cl = Context.getLocalClass().get();  // Get the class information

        // Check and get the class name as a string
        var className = switch (cl.kind) {
            case KNormal: cl.name;
            default: throw 'Unsupported class kind for this macro.';
        };

        // Create a type using the class name
        var classType:ComplexType = TPath({pack: cl.pack, name: className, params: null, sub: null});

        // Add toJson method
        fields.push({
            name: 'toJson',
            access: [Access.APublic],
            kind: FieldType.FFun({
                args: [],
                expr: macro return _writer.write(this),
                params: [],
                ret: macro :String
            }),
            pos: Context.currentPos()
        });

        // Add fromJson static method
        fields.push({
            name: 'fromJson',
            access: [Access.APublic, Access.AStatic],
            kind: FieldType.FFun({
                args: [{name: 'json', type: macro:String, opt: false}],
                expr: macro return _parser.fromJson(json),
                params: [],
                ret: macro :$classType
            }),
            pos: Context.currentPos()
        });

        // Add static writer
        fields.push({
            name: '_writer',
            access: [Access.AStatic],
            kind: FieldType.FVar(macro :json2object.JsonWriter<$classType>, macro new json2object.JsonWriter<$classType>()),
            pos: Context.currentPos()
        });

        // Add static parser
        fields.push({
            name: '_parser',
            access: [Access.AStatic],
            kind: FieldType.FVar(macro :json2object.JsonParser<$classType>, macro new json2object.JsonParser<$classType>()),
            pos: Context.currentPos()
        });

        return fields;
    }
}


#end