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

using System;
using System.Net;
using System.Threading;
using Aws.GameLift.Server.Model;
using log4net;
using Newtonsoft.Json;
using Polly;
using WebSocketSharp;
using WebSocket = WebSocketSharp.WebSocket;
using WebSocketState = WebSocketSharp.WebSocketState;

namespace Aws.GameLift.Server
{
    /// <summary>
    /// Methods and classes to handle the connection between your game servers and GameLift.
    /// </summary>
#pragma warning disable S1200
    public class GameLiftWebSocket : IGameLiftWebSocket
#pragma warning restore S1200
    {
        // Websocket library has a built in 10 retry max before all connect attempts raise exceptions.
        private const int MaxConnectRetries = 5;
        private const int InitialConnectRetryDelaySeconds = 2;
        private const int MaxDisconnectWaitRetries = 5;
        private const int DisconnectWaitStepMillis = 200;
        private const string PidKey = "pID";
        private const string SdkVersionKey = "sdkVersion";
        private const string FlavorKey = "sdkLanguage";
        private const string Flavor = "CSharp";
        private const string AuthTokenKey = "Authorization";
        private const string ComputeIdKey = "ComputeId";
        private const string FleetIdKey = "FleetId";
        private const string SocketClosingErrorMessage = "An error has occurred in closing the connection";

        private static readonly ILog Log = LogManager.GetLogger(typeof(GameLiftWebSocket));

        private readonly IWebSocketMessageHandler handler;
        private WebSocket socket;
        private string websocketUrl;
        private string processId;
        private string hostId;
        private string fleetId;
        private string authToken;

        public GameLiftWebSocket(IWebSocketMessageHandler handler)
        {
            this.handler = handler;
        }

        public GenericOutcome Connect(string websocketUrl, string processId, string hostId, string fleetId, string authToken)
        {
            Log.InfoFormat("Connecting to GameLift websocket server. Websocket URL: {0}, processId: {1}, hostId: {2}, fleetId: {3}", websocketUrl, processId, hostId, fleetId);
            this.websocketUrl = websocketUrl;
            this.processId = processId;
            this.hostId = hostId;
            this.fleetId = fleetId;
            this.authToken = authToken;

            return PerformConnect();
        }

        public GenericOutcome Disconnect()
        {
            Log.DebugFormat("Disconnecting. Socket state is: {0}", socket.ReadyState);
            // If the websocket is already closing (potentially initiated by GameLift from a ProcessEnding call earlier)
            // Attempt to wait for it to close.
            if (socket.ReadyState == WebSocketState.Closing)
            {
                Log.Info("WebSocket is in Closing state. Attempting to wait for socket to close");
                if (!WaitForSocketToClose())
                {
                    Log.Warn("Timed out waiting for the socket to close. Will retry closing.");
                }
            }

            if (socket.ReadyState != WebSocketState.Closed)
            {
                Log.Debug("Socket is not yet closed. Closing.");
                socket.Close();
            }

            Log.DebugFormat("Completed Disconnect. Socket state is: {0}", socket.ReadyState);

            return new GenericOutcome();
        }

        /**
          * Develop utility method for simple local testing of sending a message across the websocket.
          * Update the "action" and message/additional fields to test an API Gateway route/response
          */
        public GenericOutcome SendMessage(Message message)
        {
            string json = JsonConvert.SerializeObject(message);
            try
            {
                Log.Info($"Sending message to GameLift: {json}");
                socket.Send(json);
            }
            catch (Exception e)
            {
                Log.Error($"Failed to send message to GameLift. Error: {e.Data}", e);
                return new GenericOutcome(new GameLiftError(GameLiftErrorType.SERVICE_CALL_FAILED));
            }

            return new GenericOutcome();
        }

#pragma warning disable S3776,S1541,S138
        private GenericOutcome PerformConnect()
#pragma warning restore S3776,S1541,S138
        {
            var newSocket = new WebSocket(CreateUri());

            // re-route websocket-sharp logs to use the SDK logger
            newSocket.Log.Output = LogWithGameLiftServerSdk;

            // modify websocket-sharp logging-level to match the SDK's logging level
            // Note: Override if you would like to log websocket library at a different level from the rest of the SDK.
            newSocket.Log.Level = GetLogLevelForWebsockets();

            // Socket connection failed during handshake for TLS errors without this protocol enabled
            newSocket.SslConfiguration.EnabledSslProtocols = System.Security.Authentication.SslProtocols.Tls12;

            // Countdown latch to ensure that InitSDK() failure response waits for onClose() in order to return an error type 
            CountdownEvent onCloseCountdownEvent = new CountdownEvent(1);
            GameLiftErrorType connectionErrorType = GameLiftErrorType.WEBSOCKET_CONNECT_FAILURE;

            newSocket.OnOpen += (sender, e) =>
            {
                Log.Info("Connected to GameLift websocket server.");
            };

            newSocket.OnClose += (sender, e) =>
            {
                Log.InfoFormat("Socket disconnected. Status Code: '{0}'. Reason: '{1}'", e.Code, e.Reason);

                if (e.Code == (ushort) CloseStatusCode.ProtocolError)
                {
                    connectionErrorType = GameLiftErrorType.WEBSOCKET_CONNECT_FAILURE_FORBIDDEN;
                    Log.Error("Handshake with GameLift websocket server failed. Please verify that values of ServerParameters " +
                              "in InitSDK() are correct. For example, process ID needs to be unique between executions, and " +
                              "the authentication token needs to be correct and unexpired.");
                }
                else if (e.Code == (ushort) CloseStatusCode.Abnormal)
                {
                    connectionErrorType = GameLiftErrorType.WEBSOCKET_CONNECT_FAILURE_TIMEOUT;
                    Log.Error("Failed to connect to GameLift websocket server. Please verify that the websocket url in " +
                              "InitSDK() is correct and network status is normal.");
                }

                // Resolve countdown latch to unblock InitSDK() from returning a result
                if (!onCloseCountdownEvent.IsSet)
                {
                    onCloseCountdownEvent.Signal();
                }
            };

            newSocket.OnError += (sender, e) =>
            {
                if (e.Message != null && e.Message.Contains(SocketClosingErrorMessage))
                {
                    Log.Warn("WebSocket reported error on closing connection. This may be because the connection is already closed");
                }
                else
                {
                    Log.ErrorFormat("Error received from GameLift websocket server. Error Message: '{0}'. Exception: '{1}'", e.Message, e.Exception);
                }
            };

            newSocket.OnMessage += (sender, e) =>
            {
                if (e.IsPing)
                {
                    Log.Debug("Received ping from GameLift websocket server.");
                    return;
                }

                if (!e.IsText)
                {
                    Log.WarnFormat("Unknown Data received. Data: {0}", e.Data);
                    return;
                }

                try
                {
                    // Parse message as a response message. This has error fields in it which will be null for a
                    // successful response or generic message not associated with a request.
                    ResponseMessage message = JsonConvert.DeserializeObject<ResponseMessage>(e.Data);
                    if (message == null)
                    {
                        Log.Error($"could not parse message. Data: {e.Data}");
                        return;
                    }

                    Log.InfoFormat("Received {0} for GameLift with status {1}. Data: {2}", message.Action, message.StatusCode, e.Data);

                    // It's safe to cast enums to ints in C#. Each HttpStatusCode enum is associated with its numerical
                    // status code. RequestId will be null when we get a message not associated with a request.
                    if (message.StatusCode != (int)HttpStatusCode.OK && message.RequestId != null)
                    {
                        Log.WarnFormat("Received unsuccessful status code {0} for request {1} with message '{2}'", message.StatusCode, message.RequestId, message.ErrorMessage);
                        handler.OnErrorResponse(message.RequestId, message.StatusCode, message.ErrorMessage);
                        return;
                    }

                    switch (message.Action)
                    {
                        case MessageActions.CreateGameSession:
                        {
                            CreateGameSessionMessage createGameSessionMessage = JsonConvert.DeserializeObject<CreateGameSessionMessage>(e.Data);
                            GameSession gameSession = new GameSession(createGameSessionMessage);
                            handler.OnStartGameSession(gameSession);
                            break;
                        }

                        case MessageActions.UpdateGameSession:
                        {
                            UpdateGameSessionMessage updateGameSessionMessage = JsonConvert.DeserializeObject<UpdateGameSessionMessage>(e.Data);
                            handler.OnUpdateGameSession(
                                updateGameSessionMessage.GameSession, UpdateReasonMapper.GetUpdateReasonForName(updateGameSessionMessage.UpdateReason), updateGameSessionMessage.BackfillTicketId);
                            break;
                        }

                        case MessageActions.TerminateProcess:
                        {
                            TerminateProcessMessage terminateProcessMessage = JsonConvert.DeserializeObject<TerminateProcessMessage>(e.Data);
                            handler.OnTerminateProcess(terminateProcessMessage.TerminationTime);
                            break;
                        }

                        case MessageActions.StartMatchBackfill:
                        {
                            StartMatchBackfillResponse startMatchBackfillResponse = JsonConvert.DeserializeObject<StartMatchBackfillResponse>(e.Data);
                            handler.OnStartMatchBackfillResponse(startMatchBackfillResponse.RequestId, startMatchBackfillResponse.TicketId);
                            break;
                        }

                        case MessageActions.DescribePlayerSessions:
                        {
                            DescribePlayerSessionsResponse describePlayerSessionsResponse = JsonConvert.DeserializeObject<DescribePlayerSessionsResponse>(
                                e.Data, new JsonSerializerSettings { NullValueHandling = NullValueHandling.Ignore });
                            handler.OnDescribePlayerSessionsResponse(describePlayerSessionsResponse.RequestId, describePlayerSessionsResponse.PlayerSessions, describePlayerSessionsResponse.NextToken);
                            break;
                        }

                        case MessageActions.GetComputeCertificate:
                        {
                            GetComputeCertificateResponse getComputeCertificateResponse = JsonConvert.DeserializeObject<GetComputeCertificateResponse>(e.Data);
                            handler.OnGetComputeCertificateResponse(getComputeCertificateResponse.RequestId, getComputeCertificateResponse.CertificatePath, getComputeCertificateResponse.ComputeName);
                            break;
                        }

                        case MessageActions.GetFleetRoleCredentials:
                        {
                            var response = JsonConvert.DeserializeObject<GetFleetRoleCredentialsResponse>(e.Data);
                            handler.OnGetFleetRoleCredentialsResponse(
                                response.RequestId,
                                response.AssumedRoleUserArn,
                                response.AssumedRoleId,
                                response.AccessKeyId,
                                response.SecretAccessKey,
                                response.SessionToken,
                                response.Expiration);
                            break;
                        }

                        case MessageActions.RefreshConnection:
                        {
                            var refreshConnectionMessage = JsonConvert.DeserializeObject<RefreshConnectionMessage>(e.Data);
                            handler.OnRefreshConnection(refreshConnectionMessage.RefreshConnectionEndpoint, refreshConnectionMessage.AuthToken);
                            break;
                        }

                        default:
                            handler.OnSuccessResponse(message.RequestId);
                            break;
                    }
                }
                catch (Exception ex)
                {
                    Log.Error($"could not parse message. Data: {e.Data}", ex);
                }
            };

            // Policy that retries if function returns false with exponential backoff.
            var retryPolicy = Policy
                .HandleResult<bool>(r => !r)
                .WaitAndRetry(MaxConnectRetries, retry => TimeSpan.FromSeconds(Math.Pow(InitialConnectRetryDelaySeconds, retry)));

            // Specific exceptions that prevent connection are swallowed and logged during connect.
            // Exceptions thrown for invalid arguments and max retries, which are not retriable.
            var wasSuccessful = retryPolicy.Execute(() =>
            {
                newSocket.Connect();
                return newSocket.IsAlive;
            });

            if (!wasSuccessful)
            {
                // Wait for countdown latch to be resolved in OnClose() in order to know the connection error type
                onCloseCountdownEvent.Wait();

                try
                {
                    newSocket.CloseAsync(CloseStatusCode.Normal);
                }
                catch (Exception e)
                {
                    Log.Warn("Failed to close new websocket after a connection failure, ignoring", e);
                }

                return new GenericOutcome(new GameLiftError(connectionErrorType));
            }

            // "Flip" traffic from our old websocket to our new websocket. Close the old one if necessary
            var oldSocket = socket;
            socket = newSocket;
            try
            {
                oldSocket?.CloseAsync(CloseStatusCode.Normal);
            }
            catch (Exception e)
            {
                Log.Warn("Failed to close old websocket after a connection refresh, ignoring", e);
            }

            return new GenericOutcome();
        }

        private string CreateUri()
        {
            var queryString = string.Format(
                "{0}={1}&{2}={3}&{4}={5}&{6}={7}&{8}={9}&{10}={11}",
                PidKey,
                processId,
                SdkVersionKey,
                GameLiftServerAPI.GetSdkVersion().Result,
                FlavorKey,
                Flavor,
                AuthTokenKey,
                authToken,
                ComputeIdKey,
                hostId,
                FleetIdKey,
                fleetId);
            var endpoint = string.Format("{0}?{1}", websocketUrl, queryString);
            return endpoint;
        }

        private bool WaitForSocketToClose()
        {
            // Policy that retries if function returns false with with constant interval
            var retryPolicy = Policy
                .HandleResult<bool>(r => !r)
                .WaitAndRetry(MaxDisconnectWaitRetries, retry => TimeSpan.FromMilliseconds(DisconnectWaitStepMillis));

            return retryPolicy.Execute(() => { return socket.ReadyState == WebSocketState.Closed; });
        }

        // Helper method to link WebsocketSharp logger with the GameLift SDK logger
        private static void LogWithGameLiftServerSdk(LogData data, string path)
        {
            string socketLogData = data.ToString();
            switch (data.Level)
            {
                case LogLevel.Info:
                    Log.Info(socketLogData);
                    break;
                case LogLevel.Warn:
                    Log.Warn(socketLogData);
                    break;
                case LogLevel.Error:
                    Log.Error(socketLogData);
                    break;
                case LogLevel.Fatal:
                    Log.Fatal(socketLogData);
                    break;
                default:
                    Log.Debug(socketLogData);
                    break;
            }
        }

        // Helper method to get the logging level the websocket (websocketsharp library) should use.
        // Uses the same logging level as used for GameLift Server SDK.
        private static LogLevel GetLogLevelForWebsockets()
        {
            if (Log.IsDebugEnabled)
            {
                return LogLevel.Trace;
            }

            if (Log.IsInfoEnabled)
            {
                return LogLevel.Info;
            }

            if (Log.IsWarnEnabled)
            {
                return LogLevel.Warn;
            }

            if (Log.IsErrorEnabled)
            {
                return LogLevel.Error;
            }

            // otherwise, only log fatal by default
            return LogLevel.Fatal;
        }
    }
}
