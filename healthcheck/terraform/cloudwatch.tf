variable "alb_full_name" {
  type        = string
  description = "Exact ALB resource name, Fill after first Ingress is created."
  default     = null
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx_rate" {
  alarm_name          = "${var.cluster_name}-alb-5xx-rate"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 1
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  period              = 300
  treat_missing_data  = "notBreaching"
  alarm_description   = "ALB Target 5xx rate > 1% over 5m"

  metric_query {
    id          = "e1"
    expression  = "(m5xx / MAX([mreq,1])) * 100"
    label       = "5xx rate %"
    return_data = true
  }
  metric_query {
    id = "mreq"
    metric {
      namespace  = "AWS/ApplicationELB"
      metric_name= "RequestCount"
      period     = 300
      stat       = "Sum"
      dimensions = { LoadBalancer = var.alb_full_name }
    }
  }
  metric_query {
    id = "m5xx"
    metric {
      namespace  = "AWS/ApplicationELB"
      metric_name= "HTTPCode_Target_5XX_Count"
      period     = 300
      stat       = "Sum"
      dimensions = { LoadBalancer = var.alb_full_name }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_p95_latency" {
  alarm_name          = "${var.cluster_name}-alb-p95-latency"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetResponseTime"
  dimensions          = { LoadBalancer = var.alb_full_name }
  period              = 300
  evaluation_periods  = 1
  threshold           = 0.300
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  extended_statistic  = "p95"
  alarm_description   = "ALB p95 > 300ms over 5m"
}
