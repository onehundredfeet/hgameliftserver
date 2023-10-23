package ;
   
import aws.gamelift.server.GameLiftServerAPI;

class Test {


	public static function main() {
		trace("hi from the other side!");

		GameLiftServerAPI.InitSDK(null);
	}
}