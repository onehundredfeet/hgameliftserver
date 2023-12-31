﻿/*
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
using System.Collections.Generic;

namespace Aws.GameLift.Server.Model
{
    public class CreateGameSessionMessage : Message
    {
        public string GameSessionId { get; set; }

        public string GameSessionName { get; set; }

        public int MaximumPlayerSessionCount { get; set; }

        public int Port { get; set; }

        public string IpAddress { get; set; }

        public string GameSessionData { get; set; }

        public string MatchmakerData { get; set; }

        public Dictionary<string, string> GameProperties { get; set; }

        public string DnsName { get; set; }
    }
}
