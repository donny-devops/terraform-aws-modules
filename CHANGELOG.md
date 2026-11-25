# Changelog

All notable changes to the Terraform AWS Modules collection will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- Tailored CONTRIBUTING.md for Terraform conventions
- Polished README with clearer structure and MIT license confirmation

## [Initial] - 2026-03-29

### Added
- Core modules for networking (VPC, subnets, endpoints), security (IAM roles/policies, security groups), compute (EC2, ASG, ECS), storage (S3, RDS, DynamoDB), and observability (CloudWatch)
- Example root modules (single-vpc, ecs-service, static-site-s3-cloudfront)
- Environment structure for dev/stage/prod
- Security hygiene workflow
