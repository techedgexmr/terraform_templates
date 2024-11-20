# Variables for Account IDs
variable "hub_account_id" {
  description = "AWS Account ID for Hub Account"
  type        = string
  default     = "123456789012"  # Replace with actual hub account ID
}

variable "spoke_account_1_id" {
  description = "AWS Account ID for Spoke Account 1"
  type        = string
  default     = "210987654321"  # Replace with actual spoke account 1 ID
}

variable "spoke_account_2_id" {
  description = "AWS Account ID for Spoke Account 2"
  type        = string
  default     = "345678901234"  # Replace with actual spoke account 2 ID
}

# Providers using assume role
provider "aws" {
  alias  = "spoke_account_1"
  region = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.spoke_account_1_id}:role/CrossAccountAccessRole"
  }
}

provider "aws" {
  alias  = "spoke_account_2"
  region = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.spoke_account_2_id}:role/CrossAccountAccessRole"
  }
}

provider "aws" {
  alias  = "hub_account"
  region = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.hub_account_id}:role/CrossAccountHubRole"
  }
}

# Hub Account - Custom EventBridge Event Bus
resource "aws_cloudwatch_event_bus" "hub_custom_bus" {
  provider = aws.hub_account
  name     = "hub-custom-event-bus"
}

# Spoke Account 1 - CloudTrail Rule for TerminateInstances
resource "aws_cloudwatch_event_rule" "spoke1_terminate_instances" {
  provider    = aws.spoke_account_1
  name        = "spoke1-terminate-instances-rule"
  description = "Capture TerminateInstances events from Spoke Account 1"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = ["TerminateInstances"]
    }
  })
}

# Spoke Account 2 - CloudTrail Rule for TerminateInstances
resource "aws_cloudwatch_event_rule" "spoke2_terminate_instances" {
  provider    = aws.spoke_account_2
  name        = "spoke2-terminate-instances-rule"
  description = "Capture TerminateInstances events from Spoke Account 2"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = ["TerminateInstances"]
    }
  })
}

# Spoke Account 1 - Event Bridge Target to Hub Account Event Bus
resource "aws_cloudwatch_event_target" "spoke1_hub_target" {
  provider      = aws.spoke_account_1
  rule          = aws_cloudwatch_event_rule.spoke1_terminate_instances.name
  target_id     = "send-to-hub-event-bus"
  arn           = aws_cloudwatch_event_bus.hub_custom_bus.arn
}

# Spoke Account 2 - Event Bridge Target to Hub Account Event Bus
resource "aws_cloudwatch_event_target" "spoke2_hub_target" {
  provider      = aws.spoke_account_2
  rule          = aws_cloudwatch_event_rule.spoke2_terminate_instances.name
  target_id     = "send-to-hub-event-bus"
  arn           = aws_cloudwatch_event_bus.hub_custom_bus.arn
}

# Hub Account - Permission for Spoke Accounts to Send Events
resource "aws_cloudwatch_event_bus_policy" "hub_bus_policy" {
  provider        = aws.hub_account
  event_bus_name  = aws_cloudwatch_event_bus.hub_custom_bus.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSpokesToSendEvents"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${var.spoke_account_1_id}:root",
            "arn:aws:iam::${var.spoke_account_2_id}:root"
          ]
        }
        Action = [
          "events:PutEvents"
        ]
        Resource = aws_cloudwatch_event_bus.hub_custom_bus.arn
      }
    ]
  })
}

# Hub Account - Rule to Forward or Process TerminateInstances Events
resource "aws_cloudwatch_event_rule" "hub_terminate_instances" {
  provider    = aws.hub_account
  name        = "hub-terminate-instances-rule"
  description = "Process TerminateInstances events from Spoke Accounts"

  event_bus_name = aws_cloudwatch_event_bus.hub_custom_bus.name
  event_pattern  = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = ["TerminateInstances"]
    }
  })
}

# Optional: SNS Topic in Hub Account for Notifications
resource "aws_sns_topic" "terminate_instances_topic" {
  provider = aws.hub_account
  name     = "cross-account-terminate-instances"
}

# Hub Account - Event Target to SNS Topic
resource "aws_cloudwatch_event_target" "hub_sns_target" {
  provider        = aws.hub_account
  rule            = aws_cloudwatch_event_rule.hub_terminate_instances.name
  target_id       = "send-to-sns"
  arn             = aws_sns_topic.terminate_instances_topic.arn
  event_bus_name  = aws_cloudwatch_event_bus.hub_custom_bus.name
}
