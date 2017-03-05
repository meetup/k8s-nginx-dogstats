class JSONTransformer
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
        "path" => json["path"].split("?")[0],
        # Here we start matching existing tags in datadog.
        "namespace" => json["kubernetes"]["namespace_name"],
        "container_name" => json["kubernetes"]["container_name"],
        "pod_name" => json["kubernetes"]["namespace_name"] + "/" + json["kubernetes"]["pod_name"]
      }.merge(labels)
    }

    return record
  end
end
