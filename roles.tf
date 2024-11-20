# Hub Account Resources
resource "aws_iam_role" "hub_eventbus_role" {
  provider = aws.hub_account
  name     = "HubEventBusAccessRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${var.spoke_account_1_id}:root",
            "arn:aws:iam::${var.spoke_account_2_id}:root"
          ]
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "hub_eventbus_policy" {
  provider = aws.hub_account
  name     = "HubEventBusAccessPolicy"
  role     = aws_iam_role.hub_eventbus_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "events:PutEvents"
        ]
        Resource = aws_cloudwatch_event_bus.hub_custom_bus.arn
      }
    ]
  })
}

# Spoke Account 1 Role
resource "aws_iam_role" "spoke1_eventbridge_role" {
  provider = aws.spoke_account_1
  name     = "Spoke1EventBridgeRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.hub_account_id}:root"
        }
      }
    ]
  })
}

# Spoke Account 2 Role
resource "aws_iam_role" "spoke2_eventbridge_role" {
  provider = aws.spoke_account_2
  name     = "Spoke2EventBridgeRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.hub_account_id}:root"
        }
      }
    ]
  })
}
