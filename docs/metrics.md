# Reading metrics from Terraform Azure VM sidecars

**NOTE:** You can look at all the metrics definitions and what they mean on our [metrics reference page](https://cyral.com/docs/sidecars/monitoring/metrics)

To configure metrics exposure, you can use the parameter `monitoring_source_address_prefixes`
to allow CIDR ranges to make requests to the metrics port (`9000` by default).

By default, the `monitoring_source_address_prefixes` is empty, which means nothing can access the
metrics port. We recommend setting the CIDR to your metrics scraper's possible IPs.

## Prometheus service discovery

Service discovery for VM instances is documented under the [`azure_sd_config`](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#azure_sd_config)
section of the `Prometheus` configuration docs. 

A tag `MetricsPort` is added to the VM instances containing the metrics port `9000`.
It makes possible to have configurations similar to the following:

```yaml
scrape_configs:
  - azure_sd_configs:
      - region: eastus
    job_name: AZURE_SCRAPE
    relabel_configs:
      # public IP is used so that Prometheus does not have to be in the same VPC
      # as the sidecar. On a production environment, you would use the
      # `__meta_azure_machine_private_ip` label instead
      - source_labels: [__meta_azure_machine_public_ip, __meta_azure_machine_tag_MetricsPort]
        separator: ':'
        target_label: __address__
```

This configuration discovers all instances on the `eastus` region and creates a target
with its public IP and the value of the `MetricsPort` tag separated by a colon.

## Datadog service discovery

The following snippet can be used to inject a Datadog agent container onto the
sidecar VM instances:

```
export DD_API_KEY=<YOUR DATADOG API KEY> ; echo "init_config:\ninstances:\n    - prometheus_url: http://localhost:${METRICS_PORT:-9000}/metrics\n      namespace: \"cyral\"\n      metrics:\n        - go*\n        - cyral*\n        - node*\n        - up\n      prometheus_metrics_prefix: prom_\n      health_service_check: true\n      send_distribution_buckets: true\n      send_histograms_buckets: true" > conf.yaml ; sudo docker run -d --restart always --network host --name datadog -v $(pwd)/conf.yaml:/etc/datadog-agent/conf.d/openmetrics.d/conf.yaml -e DD_API_KEY=${DD_API_KEY} --log-driver json-file --log-opt max-file=5 --log-opt max-size=10m --log-opt tag="containerName=\"{{.Name}}\"" datadog/agent:7.34.0
```

Simply replace `<YOUR DATADOG API KEY>` in the code snippet above with your
actual Datadog API key you wish to use. Then use the modified snippet as the
parameter value for the `custom_user_data` parameter, using the following format:

```
{"pre": "", "pre_sidecar_start": "", "post": "<CODE SNIPPET HERE>"}
```
