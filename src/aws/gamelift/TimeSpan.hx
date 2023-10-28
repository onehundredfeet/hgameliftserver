package aws.gamelift;

abstract TimeSpan(Float) from Float to Float{

    public inline static function fromMinutes(minutes : Float) : TimeSpan {
        return minutes * 60.0;
    }

    public inline static function fromSeconds(seconds: Int): TimeSpan {
        return seconds;
    }

    public inline static function fromMilliseconds(ms: Int): TimeSpan {
        return ms / 1000.0 ;
    }

    public inline function asMilliseconds(): Int {
        return Math.round(this * 1000.0);
    }
    
    public inline function asSeconds(): Float {
        return this ;
    }

    public inline function asMinutes(): Float {
        return asSeconds() / 60.0;
    }

    public inline function asHours(): Float {
        return asMinutes() / 60.0;
    }

    public inline function asDays(): Float {
        return asHours() / 24.0;
    }
}