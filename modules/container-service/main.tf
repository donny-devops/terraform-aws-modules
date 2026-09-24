terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

data "aws_region" "current" {}

# ─────────────────────────────────────────────────────────────────────────────
# ECS Cluster & Fargate Service using terraform-aws-modules/ecs/aws
# ─────────────────────────────────────────────────────────────────────────────

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.11"

  cluster_name = var.name

  # Capacity providers: Fargate primary
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 0
      }
    }
  }

  services = {
    (var.name) = {
      cpu    = var.cpu
      memory = var.memory

      # Desired tasks
      desired_count = var.desired_count

      # Task definition configuration
      enable_execute_command = true

      container_definitions = {
        (var.name) = {
          cpu       = var.cpu
          memory    = var.memory
          essential = true
          image     = var.container_image

          port_mappings = [
            {
              name          = var.name
              containerPort = var.container_port
              hostPort      = var.container_port
              protocol      = "tcp"
            }
          ]

          environment = [
            for k, v in var.environment_variables : {
              name  = k
              value = v
            }
          ]

          secrets = var.secrets

          enable_cloudwatch_logging              = true
          create_cloudwatch_log_group            = true
          cloudwatch_log_group_retention_in_days = 30

          readonly_root_filesystem = false
        }
      }

      load_balancer = {
        service = {
          target_group_arn = var.target_group_arn
          container_name   = var.name
          container_port   = var.container_port
        }
      }

      subnet_ids = var.subnet_ids

      security_group_rules = {
        alb_ingress = {
          type        = "ingress"
          from_port   = var.container_port
          to_port     = var.container_port
          protocol    = "tcp"
          description = "Allow inbound from ALB"
          cidr_blocks = ["0.0.0.0/0"] # Restricted at ALB level or through dedicated SG
        }
        egress_all = {
          type        = "egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }

      # Optional Autoscaling (Scale out on high CPU/Memory)
      autoscaling_min_capacity = var.min_capacity
      autoscaling_max_capacity = var.max_capacity
      autoscaling_policies = var.enable_autoscaling ? {
        cpu = {
          policy_type = "TargetTrackingScaling"
          target_tracking_scaling_policy_configuration = {
            predefined_metric_specification = {
              predefined_metric_type = "ECSServiceAverageCPUUtilization"
            }
            target_value       = 70.0
            scale_in_cooldown  = 300
            scale_out_cooldown = 60
          }
        }
        memory = {
          policy_type = "TargetTrackingScaling"
          target_tracking_scaling_policy_configuration = {
            predefined_metric_specification = {
              predefined_metric_type = "ECSServiceAverageMemoryUtilization"
            }
            target_value       = 80.0
            scale_in_cooldown  = 300
            scale_out_cooldown = 60
          }
        }
      } : {}
    }
  }

  tags = var.tags
}
