provider "aws" {
 region = "us-west-2"
}

resource "aws_sns_topic" "terminate_instances" {
 name = "terminate-instances-topic"
}

resource "aws_cloudwatch_event_rule" "terminate_instances" {
 name        = "terminate-instances-rule"
 description = "Capture TerminateInstances API calls"

 event_pattern = <<EOF
{
 "source": ["aws.ec2"],
 "detail-type": ["AWS API Call via CloudTrail"],
 "detail": {
   "eventSource": ["ec2.amazonaws.com"],
   "eventName": ["TerminateInstances"]
 }
}
EOF
}

resource "aws_cloudwatch_event_target" "sns" {
 rule      = aws_cloudwatch_event_rule.terminate_instances.name
 target_id = "send-to-sns"
 arn       = aws_sns_topic.terminate_instances.arn
}
