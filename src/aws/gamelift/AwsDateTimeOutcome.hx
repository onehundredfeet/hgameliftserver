package aws.gamelift;

class AwsDateTimeOutcome extends GenericOutcome
{
    public  var Result : Date;

    public function new( error : GameLiftError,  result : Date = null)
    {
        super(error);
        Result = result;
    }
}