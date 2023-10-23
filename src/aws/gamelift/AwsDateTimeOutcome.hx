package aws.gamelift;

class AwsDateTimeOutcome extends GenericOutcome
{
    public  var Result : Date;

    public function new( error : GameLiftError,  result : Date)
    {
        super(error);
        Result = result;
    }
}