data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

resource "random_id" "external_id" {
  byte_length = 16
}

# -----------------------------------------------------------------------------
# IAM Role for Illumio CloudSecure cross-account access
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
# Register with Illumio CloudSecure
# -----------------------------------------------------------------------------
resource "illumio-cloudsecure_aws_account" "this" {
  account_id       = data.aws_caller_identity.current.account_id
  name             = var.account_name
  role_arn         = aws_iam_role.illumio.arn
  role_external_id = random_id.external_id.hex
  mode             = var.mode
}

# Optional: register flow logs S3 bucket
resource "illumio-cloudsecure_aws_flow_logs_s3_bucket" "this" {
  count = var.flow_logs_s3_bucket_arn != "" ? 1 : 0

  account_id    = data.aws_caller_identity.current.account_id
  s3_bucket_arn = var.flow_logs_s3_bucket_arn

  depends_on = [illumio-cloudsecure_aws_account.this]
}
