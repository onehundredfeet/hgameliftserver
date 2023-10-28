package aws.gamelift;

enum abstract HttpStatusCode(Int) to Int{
    var OK = 200;
    var BadRequest = 400;
    var Forbidden = 403;
    var InternalServerError = 500;
}