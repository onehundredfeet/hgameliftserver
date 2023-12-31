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

namespace Aws.GameLift.Server.Model
{
    public class DescribePlayerSessionsRequest : Message
    {
        public string GameSessionId { get; set; }

        public string PlayerSessionId { get; set; }

        public string PlayerId { get; set; }

        public string PlayerSessionStatusFilter { get; set; }

        public string NextToken { get; set; }

        public int Limit { get; set; } = 50;

        public DescribePlayerSessionsRequest()
        {
            Action = MessageActions.DescribePlayerSessions;
        }
    }
}
