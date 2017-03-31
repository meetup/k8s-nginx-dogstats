require 'yaml'

class JSONTransformer
  def initialize
    @config = File.exists?("/opt/nginx_dogstats.yaml") ? YAML.load_file("/opt/nginx_dogstats.yaml") : {}
  end

  def path_tag(path)
    return path unless @config.key?("path_aliases")
    return @config["path_aliases"].reduce(nil) { |a, el|
      el.values.first if /#{el.keys.first}/.match(path)
    } || path
  end

  def transform(json)
    labels =
      if json["kubernetes"].key?("labels")
        Hash[json["kubernetes"]["labels"].map { |k, v| ['kube_' + k, v] }]
      else
        {}
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
      }.merge(labels)
    }

    return record
  end
end
