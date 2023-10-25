package aws.gamelift;

class AwsStringOutcome extends GenericOutcome
{
    public final result : String;

    public function new( error : GameLiftError,  result : String = null)
    {
        super(error);
        this.result = result;
    }
}