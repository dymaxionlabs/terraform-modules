/**
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// This file was automatically generated from a template in ./autogen

locals {
  healthchecks = concat(
    google_compute_health_check.https[*].self_link,
    google_compute_health_check.http[*].self_link,
    google_compute_health_check.tcp[*].self_link,
  )
  distribution_policy_zones    = coalescelist(var.distribution_policy_zones, data.google_compute_zones.available.names)
  autoscaling_scale_in_enabled = var.autoscaling_scale_in_control.fixed_replicas != null || var.autoscaling_scale_in_control.percent_replicas != null
}

data "google_compute_zones" "available" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_region_instance_group_manager" "mig" {
  provider           = google-beta
  base_instance_name = var.hostname
  project            = var.project_id

  version {
    name              = "${var.hostname}-mig-version-0"
    instance_template = var.instance_template
  }

  name   = var.mig_name == "" ? "${var.hostname}-mig" : var.mig_name
  region = var.region
  dynamic "named_port" {
    for_each = var.named_ports
    content {
      name = lookup(named_port.value, "name", null)
      port = lookup(named_port.value, "port", null)
    }
  }
  target_pools = var.target_pools
  target_size  = var.autoscaling_enabled ? null : var.target_size

  wait_for_instances = var.wait_for_instances

  dynamic "auto_healing_policies" {
    for_each = local.healthchecks
    content {
      health_check      = auto_healing_policies.value
      initial_delay_sec = var.health_check["initial_delay_sec"]
    }
  }

  dynamic "stateful_disk" {
    for_each = var.stateful_disks
    content {
      device_name = stateful_disk.value.device_name
      delete_rule = lookup(stateful_disk.value, "delete_rule", null)
    }
  }

  dynamic "stateful_internal_ip" {
    for_each = [for static_ip in var.stateful_ips : static_ip if static_ip["is_external"] == false]
    content {
      interface_name = stateful_internal_ip.value.interface_name
      delete_rule    = lookup(stateful_internal_ip.value, "delete_rule", null)
    }
  }

  dynamic "stateful_external_ip" {
    for_each = [for static_ip in var.stateful_ips : static_ip if static_ip["is_external"] == true]
    content {
      interface_name = stateful_external_ip.value.interface_name
      delete_rule    = lookup(stateful_external_ip.value, "delete_rule", null)
    }
  }

  distribution_policy_target_shape = var.distribution_policy_target_shape
  distribution_policy_zones        = local.distribution_policy_zones
  dynamic "update_policy" {
    for_each = var.update_policy
    content {
      instance_redistribution_type   = lookup(update_policy.value, "instance_redistribution_type", null)
      max_surge_fixed                = lookup(update_policy.value, "max_surge_fixed", null)
      max_surge_percent              = lookup(update_policy.value, "max_surge_percent", null)
      max_unavailable_fixed          = lookup(update_policy.value, "max_unavailable_fixed", null)
      max_unavailable_percent        = lookup(update_policy.value, "max_unavailable_percent", null)
      min_ready_sec                  = lookup(update_policy.value, "min_ready_sec", null)
      replacement_method             = lookup(update_policy.value, "replacement_method", null)
      most_disruptive_allowed_action = lookup(update_policy.value, "most_disruptive_allowed_action", null)
      minimal_action                 = update_policy.value.minimal_action
      type                           = update_policy.value.type
    }
  }

  all_instances_config {
    labels   = var.labels
    metadata = var.metadata
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [distribution_policy_zones]
  }

  timeouts {
    create = var.mig_timeouts.create
    update = var.mig_timeouts.update
    delete = var.mig_timeouts.delete
  }
}

resource "google_compute_region_autoscaler" "autoscaler" {
  provider = google
  count    = var.autoscaling_enabled ? 1 : 0
  name     = var.autoscaler_name == "" ? "${var.hostname}-autoscaler" : var.autoscaler_name
  project  = var.project_id
  region   = var.region

  target = google_compute_region_instance_group_manager.mig.self_link

  autoscaling_policy {
    max_replicas    = var.max_replicas
    min_replicas    = var.min_replicas
    cooldown_period = var.cooldown_period
    mode            = var.autoscaling_mode
    dynamic "scale_in_control" {
      for_each = local.autoscaling_scale_in_enabled ? [var.autoscaling_scale_in_control] : []
      content {
        max_scaled_in_replicas {
          fixed   = lookup(scale_in_control.value, "fixed_replicas", null)
          percent = lookup(scale_in_control.value, "percent_replicas", null)
        }
        time_window_sec = lookup(scale_in_control.value, "time_window_sec", null)
      }
    }
    dynamic "cpu_utilization" {
      for_each = var.autoscaling_cpu
      content {
        target            = lookup(cpu_utilization.value, "target", null)
        predictive_method = lookup(cpu_utilization.value, "predictive_method", null)
      }
    }
    dynamic "metric" {
      for_each = var.autoscaling_metric
      content {
        name   = lookup(metric.value, "name", null)
        target = lookup(metric.value, "target", null)
        type   = lookup(metric.value, "type", null)
      }
    }
    dynamic "load_balancing_utilization" {
      for_each = var.autoscaling_lb
      content {
        target = lookup(load_balancing_utilization.value, "target", null)
      }
    }
    dynamic "scaling_schedules" {
      for_each = var.scaling_schedules
      content {
        disabled              = lookup(scaling_schedules.value, "disabled", null)
        duration_sec          = lookup(scaling_schedules.value, "duration_sec", null)
        min_required_replicas = lookup(scaling_schedules.value, "min_required_replicas", null)
        name                  = lookup(scaling_schedules.value, "name", null)
        schedule              = lookup(scaling_schedules.value, "schedule", null)
        time_zone             = lookup(scaling_schedules.value, "time_zone", null)
      }
    }
  }
}

resource "google_compute_health_check" "https" {
  count   = var.health_check["type"] == "https" ? 1 : 0
  project = var.project_id
  name    = var.health_check_name == "" ? "${var.hostname}-https-healthcheck" : var.health_check_name

  check_interval_sec  = var.health_check["check_interval_sec"]
  healthy_threshold   = var.health_check["healthy_threshold"]
  timeout_sec         = var.health_check["timeout_sec"]
  unhealthy_threshold = var.health_check["unhealthy_threshold"]

  https_health_check {
    port         = var.health_check["port"]
    request_path = var.health_check["request_path"]
    host         = var.health_check["host"]
    response     = var.health_check["response"]
    proxy_header = var.health_check["proxy_header"]
  }
}

resource "google_compute_health_check" "http" {
  count   = var.health_check["type"] == "http" ? 1 : 0
  project = var.project_id
  name    = var.health_check_name == "" ? "${var.hostname}-http-healthcheck" : var.health_check_name

  check_interval_sec  = var.health_check["check_interval_sec"]
  healthy_threshold   = var.health_check["healthy_threshold"]
  timeout_sec         = var.health_check["timeout_sec"]
  unhealthy_threshold = var.health_check["unhealthy_threshold"]

  http_health_check {
    port         = var.health_check["port"]
    request_path = var.health_check["request_path"]
    host         = var.health_check["host"]
    response     = var.health_check["response"]
    proxy_header = var.health_check["proxy_header"]
  }

  log_config {
    enable = var.health_check["enable_logging"]
  }
}

resource "google_compute_health_check" "tcp" {
  count   = var.health_check["type"] == "tcp" ? 1 : 0
  project = var.project_id
  name    = var.health_check_name == "" ? "${var.hostname}-tcp-healthcheck" : var.health_check_name

  timeout_sec         = var.health_check["timeout_sec"]
  check_interval_sec  = var.health_check["check_interval_sec"]
  healthy_threshold   = var.health_check["healthy_threshold"]
  unhealthy_threshold = var.health_check["unhealthy_threshold"]

  tcp_health_check {
    port         = var.health_check["port"]
    request      = var.health_check["request"]
    response     = var.health_check["response"]
    proxy_header = var.health_check["proxy_header"]
  }

  log_config {
    enable = var.health_check["enable_logging"]
  }
}
