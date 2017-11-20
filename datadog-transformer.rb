require 'net/http'
require 'yaml'
require 'json'

class JSONTransformer
  def initialize
    @config = File.exists?("/opt/nginx_dogstats.yaml") ? YAML.load_file("/opt/nginx_dogstats.yaml") : {}
    @gce_zone = self.resolve_gce_zone
    @aws_region = self.resolve_aws_region
  end

  # https://cloud.google.com/compute/docs/storing-retrieving-metadata#querying
  def resolve_gce_zone
    uri = URI("http://metadata.google.internal/computeMetadata/v1/instance/zone")
    req = Net::HTTP::Get.new(uri)
    req['Metadata-Flavor'] = 'Google'
    begin
      resp = Net::HTTP.start(uri.hostname, uri.port, open_timeout: 1, read_timeout: 1) { |http|
        http.request(req)
      }
      resp.body.split("/").last
    rescue Exception => msg
      puts "failed to request gce instance zone: #{msg}"
    end
  end

  # http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-identity-documents.html
  def resolve_aws_region
    uri = URI("http://169.254.169.254/latest/dynamic/instance-identity/document")
    req = Net::HTTP::Get.new(uri)
    begin
      resp = Net::HTTP.start(uri.hostname, uri.port, open_timeout: 1, read_timeout: 1) { |http|
        http.request(req)
      }
      metadata = JSON.parse(resp.body)
      metadata["region"]
    rescue Exception => msg
      puts "failed to request aws instance region: #{msg}"
    end
  end

  def path_tag(path)
    return path unless @config.key?("path_aliases")
    return @config["path_aliases"].reduce(nil) { |a, el|
      if /#{el.keys.first}/.match(path)
        el.values.first
      else
        a
      end
    } || path
  end

  def transform(json)
    labels =
      if json["kubernetes"].key?("labels")
        Hash[json["kubernetes"]["labels"].map { |k, v| ['kube_' + k, v] }]
      else
        {}
      end
    gce_metadata =
      if @gce_zone
        { "gce_zone" => @gce_zone, "cloud_provider": "gcp" }
      else
        {}
      end
    aws_metadata =
      if @aws_region
        { "aws_region" => @aws_region, "cloud_provider": "aws" }
      else
        {}
      end

    upstream_time = {}
    # capture upstream response time, only if it's defined
    if json["upstream_response_time"] != "-"
      upstream_time["upstream_response_time_ms"] = (json["upstream_response_time"].to_f * 1000).to_i
    end
    record = {
      "request_time_ms" => (json["request_time"].to_f * 1000).to_i,
      "status_code" => json["code"],
      "tags" => {
        "status_code" => json["code"],
        "path" => self.path_tag(json["path"].split("?")[0]),
        # Here we start matching existing tags in datadog.
        "namespace" => json["kubernetes"]["namespace_name"],
        "kube_namespace" => json["kubernetes"]["namespace_name"],
        "container_name" => json["kubernetes"]["container_name"],
        "pod_name" => json["kubernetes"]["namespace_name"] + "/" + json["kubernetes"]["pod_name"]
      }.merge(labels).merge(gce_metadata).merge(aws_metadata)
    }.merge(upstream_time)

    return record
  end
end
