provider "aws" {
  region = "us-east-1" # Set your preferred AWS region
}

# Create an SNS topic to receive notifications
resource "aws_sns_topic" "terminate_instances_topic" {
  name = "terminate-instances-topic"
}

# Grant EventBridge permissions to publish to the SNS topic
resource "aws_sns_topic_policy" "allow_eventbridge" {
  arn    = aws_sns_topic.terminate_instances_topic.arn
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "events.amazonaws.com" },
        Action    = "SNS:Publish",
        Resource  = aws_sns_topic.terminate_instances_topic.arn
      }
    ]
  })
}

# Create the EventBridge rule to match "TerminateInstances" API calls
resource "aws_cloudwatch_event_rule" "terminate_instances_rule" {
  name        = "terminate-instances-rule"
  description = "Trigger on TerminateInstances API calls"
  event_pattern = jsonencode({
    "source": ["aws.ec2"],
    "detail-type": ["AWS API Call via CloudTrail"],
    "detail": {
      "eventName": ["TerminateInstances"]
    }
  })
}

# Set up the EventBridge target to send matched events to SNS
resource "aws_cloudwatch_event_target" "sns_target" {
  rule      = aws_cloudwatch_event_rule.terminate_instances_rule.name
  target_id = "send-to-sns"
  arn       = aws_sns_topic.terminate_instances_topic.arn
}

# Grant EventBridge rule permissions to publish to the SNS topic
resource "aws_cloudwatch_event_permission" "allow_eventbridge" {
  principal   = "events.amazonaws.com"
  statement_id = "Allow_EventBridge_Invoke_SNS"
  action      = "events:PutEvents"
  source_arn  = aws_cloudwatch_event_rule.terminate_instances_rule.arn
}
