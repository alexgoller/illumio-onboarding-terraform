data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_organizations_organization" "current" {}

resource "random_id" "external_id" {
  byte_length = 16
}

# -----------------------------------------------------------------------------
# Management Account: IAM Role for Illumio CloudSecure cross-account access
# -----------------------------------------------------------------------------
resource "aws_iam_role" "illumio" {
  name = var.role_name
  path = "/"
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:${data.aws_partition.current.partition}:iam::${var.illumio_aws_account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = random_id.external_id.hex
          }
        }
      }
    ]
  })
}

# Managed policy: SecurityAudit
resource "aws_iam_role_policy_attachment" "security_audit" {
  role       = aws_iam_role.illumio.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/SecurityAudit"
}

# Inline read-only policy (matches CloudFormation IllumioCloudAWSIntegrationPolicy)
resource "aws_iam_role_policy" "illumio_read" {
  name = "IllumioCloudAWSIntegrationPolicy"
  role = aws_iam_role.illumio.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Resource = "*"
        Action = [
          "apigateway:GET",
          "autoscaling:Describe*",
          "cloudtrail:DescribeTrails",
          "cloudtrail:GetTrailStatus",
          "cloudtrail:LookupEvents",
          "cloudwatch:Describe*",
          "cloudwatch:Get*",
          "cloudwatch:List*",
          "codedeploy:List*",
          "codedeploy:BatchGet*",
          "directconnect:Describe*",
          "docdb-elastic:GetCluster",
          "docdb-elastic:ListTagsForResource",
          "dynamodb:List*",
          "dynamodb:Describe*",
          "ec2:Describe*",
          "ec2:SearchTransitGatewayMulticastGroups",
          "ecs:Describe*",
          "ecs:List*",
          "eks:DescribeAddon",
          "eks:ListAddons",
          "elasticache:Describe*",
          "elasticache:List*",
          "elasticfilesystem:DescribeAccessPoints",
          "elasticfilesystem:DescribeFileSystems",
          "elasticfilesystem:DescribeTags",
          "elasticloadbalancing:Describe*",
          "elasticmapreduce:List*",
          "elasticmapreduce:Describe*",
          "es:ListTags",
          "es:ListDomainNames",
          "es:DescribeElasticsearchDomains",
          "fsx:DescribeFileSystems",
          "fsx:ListTagsForResource",
          "health:DescribeEvents",
          "health:DescribeEventDetails",
          "health:DescribeAffectedEntities",
          "kinesis:List*",
          "kinesis:Describe*",
          "lambda:GetPolicy",
          "lambda:List*",
          "logs:TestMetricFilter",
          "logs:DescribeSubscriptionFilters",
          "organizations:Describe*",
          "organizations:List*",
          "rds:Describe*",
          "rds:List*",
          "redshift:DescribeClusters",
          "redshift:DescribeLoggingStatus",
          "route53:List*",
          "s3:GetBucketLogging",
          "s3:GetBucketLocation",
          "s3:GetBucketNotification",
          "s3:GetBucketTagging",
          "s3:ListAllMyBuckets",
          "sns:List*",
          "sqs:ListQueues",
          "states:ListStateMachines",
          "states:DescribeStateMachine",
          "support:DescribeTrustedAdvisor*",
          "support:RefreshTrustedAdvisorCheck",
          "tag:GetResources",
          "tag:GetTagKeys",
          "tag:GetTagValues",
          "xray:BatchGetTraces",
          "xray:GetTraceSummaries",
          "networkmanager:ListCoreNetworks",
          "networkmanager:GetCoreNetwork",
          "networkmanager:ListAttachments",
          "networkmanager:GetVpcAttachment",
          "networkmanager:GetSiteToSiteVpnAttachment",
          "networkmanager:GetConnectAttachment",
          "networkmanager:GetTransitGatewayRouteTableAttachment",
          "networkmanager:ListPeerings",
          "networkmanager:GetTransitGatewayPeering",
          "networkmanager:GetTransitGatewayRegistrations",
          "memorydb:ListTagsForResource",
        ]
      }
    ]
  })
}

# Inline write policy (conditional, only in ReadWrite mode)
resource "aws_iam_role_policy" "illumio_write" {
  count = var.mode == "ReadWrite" ? 1 : 0

  name = "IllumioCloudAWSProtectionPolicy"
  role = aws_iam_role.illumio.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "IllumioEC2Access"
        Effect = "Allow"
        Resource = [
          "arn:aws:ec2:*:*:security-group-rule/*",
          "arn:aws:ec2:*:*:security-group/*",
          "arn:aws:ec2:*:*:network-acl/*",
          "arn:aws:ec2:*:*:vpc/*",
          "arn:aws:ec2:*:*:network-interface/*",
        ]
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:UpdateSecurityGroupRuleDescriptionsIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:UpdateSecurityGroupRuleDescriptionsEgress",
          "ec2:ModifySecurityGroupRules",
          "ec2:DescribeTags",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:DescribeNetworkAcls",
          "ec2:CreateNetworkAclEntry",
          "ec2:ReplaceNetworkAclEntry",
          "ec2:DeleteNetworkAclEntry",
          "ec2:ModifyNetworkInterfaceAttribute",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:DescribeSecurityGroups",
        ]
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# StackSet: Deploy IAM Role to member accounts via CloudFormation
# -----------------------------------------------------------------------------
resource "aws_cloudformation_stack_set" "illumio_role" {
  name             = "IllumioCloudSecureIntegrationRole"
  description      = "Deploys the Illumio CloudSecure IAM role to member accounts"
  permission_model = "SERVICE_MANAGED"
  call_as          = "DELEGATED_ADMIN"

  auto_deployment {
    enabled                          = true
    retain_stacks_on_account_removal = false
  }

  capabilities = ["CAPABILITY_NAMED_IAM"]

  parameters = {
    ExternalId       = random_id.external_id.hex
    IllumioAccountId = var.illumio_aws_account_id
    RoleName         = var.role_name
    Mode             = var.mode
  }

  template_body = <<-TEMPLATE
    AWSTemplateFormatVersion: "2010-09-09"
    Description: "Illumio CloudSecure cross-account IAM role for member accounts"

    Parameters:
      ExternalId:
        Type: String
        Description: External ID for cross-account trust
      IllumioAccountId:
        Type: String
        Description: Illumio AWS account ID
      RoleName:
        Type: String
        Description: Name of the IAM role
      Mode:
        Type: String
        AllowedValues:
          - Read
          - ReadWrite
        Description: Access mode

    Conditions:
      IsReadWrite: !Equals [!Ref Mode, "ReadWrite"]

    Resources:
      IllumioCloudIntegrationRole:
        Type: AWS::IAM::Role
        Properties:
          RoleName: !Ref RoleName
          Path: "/"
          AssumeRolePolicyDocument:
            Version: "2012-10-17"
            Statement:
              - Effect: Allow
                Principal:
                  AWS: !Sub "arn:$${AWS::Partition}:iam::$${IllumioAccountId}:root"
                Action: "sts:AssumeRole"
                Condition:
                  StringEquals:
                    "sts:ExternalId": !Ref ExternalId
          ManagedPolicyArns:
            - !Sub "arn:$${AWS::Partition}:iam::aws:policy/SecurityAudit"
          Policies:
            - PolicyName: IllumioCloudAWSIntegrationPolicy
              PolicyDocument:
                Version: "2012-10-17"
                Statement:
                  - Effect: Allow
                    Resource: "*"
                    Action:
                      - "apigateway:GET"
                      - "autoscaling:Describe*"
                      - "cloudtrail:DescribeTrails"
                      - "cloudtrail:GetTrailStatus"
                      - "cloudtrail:LookupEvents"
                      - "cloudwatch:Describe*"
                      - "cloudwatch:Get*"
                      - "cloudwatch:List*"
                      - "codedeploy:List*"
                      - "codedeploy:BatchGet*"
                      - "directconnect:Describe*"
                      - "docdb-elastic:GetCluster"
                      - "docdb-elastic:ListTagsForResource"
                      - "dynamodb:List*"
                      - "dynamodb:Describe*"
                      - "ec2:Describe*"
                      - "ec2:SearchTransitGatewayMulticastGroups"
                      - "ecs:Describe*"
                      - "ecs:List*"
                      - "eks:DescribeAddon"
                      - "eks:ListAddons"
                      - "elasticache:Describe*"
                      - "elasticache:List*"
                      - "elasticfilesystem:DescribeAccessPoints"
                      - "elasticfilesystem:DescribeFileSystems"
                      - "elasticfilesystem:DescribeTags"
                      - "elasticloadbalancing:Describe*"
                      - "elasticmapreduce:List*"
                      - "elasticmapreduce:Describe*"
                      - "es:ListTags"
                      - "es:ListDomainNames"
                      - "es:DescribeElasticsearchDomains"
                      - "fsx:DescribeFileSystems"
                      - "fsx:ListTagsForResource"
                      - "health:DescribeEvents"
                      - "health:DescribeEventDetails"
                      - "health:DescribeAffectedEntities"
                      - "kinesis:List*"
                      - "kinesis:Describe*"
                      - "lambda:GetPolicy"
                      - "lambda:List*"
                      - "logs:TestMetricFilter"
                      - "logs:DescribeSubscriptionFilters"
                      - "organizations:Describe*"
                      - "organizations:List*"
                      - "rds:Describe*"
                      - "rds:List*"
                      - "redshift:DescribeClusters"
                      - "redshift:DescribeLoggingStatus"
                      - "route53:List*"
                      - "s3:GetBucketLogging"
                      - "s3:GetBucketLocation"
                      - "s3:GetBucketNotification"
                      - "s3:GetBucketTagging"
                      - "s3:ListAllMyBuckets"
                      - "sns:List*"
                      - "sqs:ListQueues"
                      - "states:ListStateMachines"
                      - "states:DescribeStateMachine"
                      - "support:DescribeTrustedAdvisor*"
                      - "support:RefreshTrustedAdvisorCheck"
                      - "tag:GetResources"
                      - "tag:GetTagKeys"
                      - "tag:GetTagValues"
                      - "xray:BatchGetTraces"
                      - "xray:GetTraceSummaries"
                      - "networkmanager:ListCoreNetworks"
                      - "networkmanager:GetCoreNetwork"
                      - "networkmanager:ListAttachments"
                      - "networkmanager:GetVpcAttachment"
                      - "networkmanager:GetSiteToSiteVpnAttachment"
                      - "networkmanager:GetConnectAttachment"
                      - "networkmanager:GetTransitGatewayRouteTableAttachment"
                      - "networkmanager:ListPeerings"
                      - "networkmanager:GetTransitGatewayPeering"
                      - "networkmanager:GetTransitGatewayRegistrations"
                      - "memorydb:ListTagsForResource"
            - !If
              - IsReadWrite
              - PolicyName: IllumioCloudAWSProtectionPolicy
                PolicyDocument:
                  Version: "2012-10-17"
                  Statement:
                    - Sid: IllumioEC2Access
                      Effect: Allow
                      Resource:
                        - "arn:aws:ec2:*:*:security-group-rule/*"
                        - "arn:aws:ec2:*:*:security-group/*"
                        - "arn:aws:ec2:*:*:network-acl/*"
                        - "arn:aws:ec2:*:*:vpc/*"
                        - "arn:aws:ec2:*:*:network-interface/*"
                      Action:
                        - "ec2:AuthorizeSecurityGroupIngress"
                        - "ec2:RevokeSecurityGroupIngress"
                        - "ec2:UpdateSecurityGroupRuleDescriptionsIngress"
                        - "ec2:AuthorizeSecurityGroupEgress"
                        - "ec2:RevokeSecurityGroupEgress"
                        - "ec2:UpdateSecurityGroupRuleDescriptionsEgress"
                        - "ec2:ModifySecurityGroupRules"
                        - "ec2:DescribeTags"
                        - "ec2:CreateTags"
                        - "ec2:DeleteTags"
                        - "ec2:DescribeNetworkAcls"
                        - "ec2:CreateNetworkAclEntry"
                        - "ec2:ReplaceNetworkAclEntry"
                        - "ec2:DeleteNetworkAclEntry"
                        - "ec2:ModifyNetworkInterfaceAttribute"
                        - "ec2:CreateSecurityGroup"
                        - "ec2:DeleteSecurityGroup"
                        - "ec2:DescribeSecurityGroups"
              - !Ref "AWS::NoValue"

    Outputs:
      RoleArn:
        Description: ARN of the Illumio CloudSecure IAM role
        Value: !GetAtt IllumioCloudIntegrationRole.Arn
  TEMPLATE

  tags = var.tags

  lifecycle {
    ignore_changes = [
      administration_role_arn,
    ]
  }
}

resource "aws_cloudformation_stack_set_instance" "illumio_role" {
  stack_set_name = aws_cloudformation_stack_set.illumio_role.name
  call_as        = "DELEGATED_ADMIN"

  deployment_targets {
    organizational_unit_ids = var.target_ou_ids
  }

  operation_preferences {
    failure_tolerance_percentage = var.stackset_failure_tolerance_percentage
    max_concurrent_percentage    = var.stackset_max_concurrent_percentage
  }
}

# -----------------------------------------------------------------------------
# Register management account with Illumio CloudSecure
# -----------------------------------------------------------------------------
resource "illumio-cloudsecure_aws_account" "management" {
  account_id       = data.aws_caller_identity.current.account_id
  name             = "${var.organization_name} (Management)"
  role_arn         = aws_iam_role.illumio.arn
  role_external_id = random_id.external_id.hex
  mode             = var.mode
}

# -----------------------------------------------------------------------------
# Register member accounts with Illumio CloudSecure (optional)
# -----------------------------------------------------------------------------
resource "illumio-cloudsecure_aws_account" "member" {
  for_each = var.member_account_ids

  account_id       = each.value
  name             = "${var.organization_name} (${each.value})"
  role_arn         = "arn:${data.aws_partition.current.partition}:iam::${each.value}:role/${var.role_name}"
  role_external_id = random_id.external_id.hex
  mode             = var.mode

  depends_on = [aws_cloudformation_stack_set_instance.illumio_role]
}

# -----------------------------------------------------------------------------
# Optional: register flow logs S3 bucket for management account
# -----------------------------------------------------------------------------
resource "illumio-cloudsecure_aws_flow_logs_s3_bucket" "management" {
  count = var.flow_logs_s3_bucket_arn != "" ? 1 : 0

  account_id    = data.aws_caller_identity.current.account_id
  s3_bucket_arn = var.flow_logs_s3_bucket_arn

  depends_on = [illumio-cloudsecure_aws_account.management]
}
