variable "alert_email" { type = string }

resource "aws_budgets_budget" "monthly_cost" {
  name              = "monthly-cost"
  budget_type       = "COST"
  limit_amount      = "50"
  limit_unit        = "USD"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator         = "GREATER_THAN"
    notification_type           = "FORECASTED"
    threshold                   = 50
    threshold_type              = "PERCENTAGE"
    subscriber_email_addresses  = [var.alert_email]
  }

  notification {
    comparison_operator         = "GREATER_THAN"
    notification_type           = "FORECASTED"
    threshold                   = 80
    threshold_type              = "PERCENTAGE"
    subscriber_email_addresses  = [var.alert_email]
  }

  notification {
    comparison_operator         = "GREATER_THAN"
    notification_type           = "ACTUAL"
    threshold                   = 100
    threshold_type              = "PERCENTAGE"
    subscriber_email_addresses  = [var.alert_email]
  }
}
