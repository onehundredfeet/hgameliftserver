/*
 * All or portions of this file Copyright (c) Amazon.com, Inc. or its affiliates or
 * its licensors.
 *
 * For complete copyright and license terms please see the LICENSE at the root of this
 * distribution (the "License"). All use of this software is governed by the License,
 * or, if provided, by the license below or the license accompanying this file. Do not
 * remove or modify any license notices. This file is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 */

package aws.gamelift;

enum abstract GameLiftErrorType(Int) {
	var GAMESESSION_ID_NOT_SET = 0; // No game sessions are bound to this process.
	var SERVICE_CALL_FAILED; // A call to an AWS service has failed.
	var BAD_REQUEST_EXCEPTION;
	var INTERNAL_SERVICE_EXCEPTION;
	var WEBSOCKET_CONNECT_FAILURE; // Failure to connect to the GameLift Service WebSocket
	var WEBSOCKET_CONNECT_FAILURE_FORBIDDEN; // GameLift Service WebSocket returns 403
	var WEBSOCKET_CONNECT_FAILURE_TIMEOUT; // A call to an AWS service has timed out.
	var TERMINATION_TIME_NOT_SET;
}

class GameLiftError {
	private static final fourHundredExceptionStart = 400;
	private static final fourHundredExceptionEnd = 500;

	public final errorType:GameLiftErrorType;
	public final errorName:String;
	public final errorMessage:String;

	public function new(errorType:GameLiftErrorType, errorName:String = null, errorMessage:String = null) {
		this.errorType = errorType;
		this.errorName = errorName != null ? errorName : getDefaultNameForErrorType(errorType);
		this.errorMessage = errorMessage != null ? errorMessage : getDefaultMessageForErrorType(errorType);
	}

	public static function fromStatusCode(statusCode:Int, errorMessage:String) {
		return new GameLiftError(getErrorTypeForStatusCode(statusCode), errorMessage);
	}

	function getDefaultNameForErrorType(errorType:GameLiftErrorType):String {
		switch (errorType) {
			case GameLiftErrorType.GAMESESSION_ID_NOT_SET:
				return "GameSession id is not set.";
			case GameLiftErrorType.SERVICE_CALL_FAILED:
				return "Service call failed.";
			case GameLiftErrorType.BAD_REQUEST_EXCEPTION:
				return "Bad request exception.";
			case GameLiftErrorType.INTERNAL_SERVICE_EXCEPTION:
				return "Internal service exception.";
			case GameLiftErrorType.WEBSOCKET_CONNECT_FAILURE:
				return "WebSocket Connection Failed";
			case GameLiftErrorType.WEBSOCKET_CONNECT_FAILURE_FORBIDDEN:
				return "WebSocket Connection Denied";
			case GameLiftErrorType.WEBSOCKET_CONNECT_FAILURE_TIMEOUT:
				return "WebSocket Connection has timed out";
			case GameLiftErrorType.TERMINATION_TIME_NOT_SET:
				return "Termination time is not set";
			default:
				return "Unknown Error";
		}
	}

	function getDefaultMessageForErrorType(errorType:GameLiftErrorType):String {
		switch (errorType) {
			case GameLiftErrorType.GAMESESSION_ID_NOT_SET:
				return "No game sessions are bound to this process.";
			case GameLiftErrorType.SERVICE_CALL_FAILED:
				return "An AWS service call has failed. See the root cause error for more information.";
			case GameLiftErrorType.BAD_REQUEST_EXCEPTION:
				return "Bad request exception.";
			case GameLiftErrorType.INTERNAL_SERVICE_EXCEPTION:
				return "Internal service exception.";
			case GameLiftErrorType.WEBSOCKET_CONNECT_FAILURE:
				return "Connection to the GameLift Service WebSocket has failed";
			case GameLiftErrorType.WEBSOCKET_CONNECT_FAILURE_FORBIDDEN:
				return "Connection to the GameLift Service WebSocket Connection is denied. A HTTP Status Code 403, Forbidden. Check Authentication Token.";
			case GameLiftErrorType.WEBSOCKET_CONNECT_FAILURE_TIMEOUT:
				return "Connection to the GameLift Service WebSocket has timed out.";
			case GameLiftErrorType.TERMINATION_TIME_NOT_SET:
				return "Termination time is not set because a game session has not started.";
			default:
				return "An unexpected error has occurred.";
		}
	}

	private static function getErrorTypeForStatusCode(statusCode:Int):GameLiftErrorType {
		// Map all 4xx requests to bad request exception. We don't have an error type for all 100 client errors
		if (statusCode >= fourHundredExceptionStart && statusCode < fourHundredExceptionEnd) {
			return GameLiftErrorType.BAD_REQUEST_EXCEPTION;
		}
		// The websocket can return other error types, in this case classify it as an internal service exception
		return GameLiftErrorType.INTERNAL_SERVICE_EXCEPTION;
	}

	public function toString():String {
		return '[GameLiftError: ErrorType={errorType}, ErrorName={errorName}, ErrorMessage={errorMessage}]';
	}
}
