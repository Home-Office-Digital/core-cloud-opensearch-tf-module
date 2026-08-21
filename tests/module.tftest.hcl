mock_provider "aws" {}

variables {
  cc_tags = {
    cost_centre      = "cc-001"
    account_code     = "ac-001"
    portfolio_id     = "pf-001"
    project_id       = "pr-001"
    service_id       = "sv-001"
    environment_type = "dev"
    owner_business   = "platform"
    budget_holder    = "engineering"
  }
}

run "basic" {
  command = plan

  variables {
    name = "test-opensearch"
  }

  assert {
    condition     = aws_opensearch_domain.this.domain_name == var.name
    error_message = "Expected the domain name to match the provided name."
  }

  assert {
    condition     = aws_opensearch_domain.this.cluster_config[0].instance_type == "m6g.large.search"
    error_message = "Expected the default instance type to be m6g.large.search."
  }

  assert {
    condition = alltrue([
      aws_opensearch_domain.this.tags["cost-centre"] == "cc-001",
      aws_opensearch_domain.this.tags["Name"] == var.name,
    ])
    error_message = "Expected mandatory Core Cloud tags and the Name tag to be present."
  }
}

run "vpc_zone_awareness" {
  command = plan

  variables {
    name                   = "test-vpc-opensearch"
    subnet_ids             = ["subnet-123", "subnet-456", "subnet-789"]
    security_group_ids     = ["sg-12345678"]
    zone_awareness_enabled = true
    zone_awareness_count   = 3
    instance_count         = 3
  }

  assert {
    condition     = contains(tolist(aws_opensearch_domain.this.vpc_options[0].subnet_ids), "subnet-789")
    error_message = "Expected VPC subnet IDs to be passed to the domain."
  }

  assert {
    condition     = aws_opensearch_domain.this.cluster_config[0].zone_awareness_config[0].availability_zone_count == 3
    error_message = "Expected three-AZ zone awareness configuration."
  }
}

run "gp3_storage" {
  command = plan

  variables {
    name            = "test-gp3-opensearch"
    ebs_volume_type = "gp3"
    ebs_iops        = 6000
    ebs_throughput  = 250
  }

  assert {
    condition = alltrue([
      aws_opensearch_domain.this.ebs_options[0].iops == 6000,
      aws_opensearch_domain.this.ebs_options[0].throughput == 250,
    ])
    error_message = "Expected gp3 IOPS and throughput values to be applied."
  }
}

run "audit_logs" {
  command = plan

  variables {
    name = "test-logs-opensearch"
    log_publishing_options = {
      AUDIT_LOGS = {
        enabled           = true
        retention_in_days = 14
      }
    }
  }

  assert {
    condition     = length(aws_cloudwatch_log_group.this) == 1
    error_message = "Expected one CloudWatch log group to be created when one log type is enabled."
  }

  assert {
    condition     = aws_cloudwatch_log_group.this["AUDIT_LOGS"].retention_in_days == 14
    error_message = "Expected the audit log group retention to match the requested value."
  }
}

run "instance_type_variant" {
  command = plan

  variables {
    name           = "test-instance-variant"
    instance_type  = "r6g.large.search"
    instance_count = 4
  }

  assert {
    condition = alltrue([
      aws_opensearch_domain.this.cluster_config[0].instance_type == "r6g.large.search",
      aws_opensearch_domain.this.cluster_config[0].instance_count == 4,
    ])
    error_message = "Expected the module to accept alternative data node instance types and counts."
  }
}

