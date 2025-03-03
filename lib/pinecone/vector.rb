require "pinecone/vector/query"
require "pinecone/vector/filter"
require "pinecone/vector/sparse_vector"

module Pinecone
  class Vector
    include HTTParty

    attr_reader :base_uri

    def initialize(index_name)
      @base_uri = set_base_uri(index_name)

      @headers = {
        "Content-Type" => "application/json",
        "Accept" => "application/json",
        "Api-Key" => Pinecone.configuration.api_key,
      }
    end

    def delete(namespace: "", ids: [], delete_all: false)
      inputs = {
        "namespace": namespace,
        "ids": ids,
        "deleteAll": delete_all,
      }.to_json
      payload = options.merge(body: inputs)
      self.class.post("#{@base_uri}/vectors/delete", payload)
    end

    def fetch(namespace: "", ids: [])
      query_string = URI.encode_www_form({ namespace: namespace, ids: ids})
      self.class.get("#{@base_uri}/vectors/fetch?#{query_string}", options)
    end

    def upsert(body)
      payload = options.merge(body: body.to_json)
      self.class.post("#{@base_uri}/vectors/upsert", payload)
    end

    def query(query)
      object = query.is_a?(Pinecone::Vector::Query) ? query : Pinecone::Vector::Query.new(query)
      payload = options.merge(body: object.to_json)
      self.class.post("#{@base_uri}/query", payload)
    end

    def update(id:, values: [], sparse_values: {indices: [], values: []}, set_metadata: {}, namespace: "")
      inputs = {
        "id": id
      }
      inputs["values"] = values unless values.empty?
      inputs["sparseValues"] = sparse_values unless sparse_values[:indices].empty? || sparse_values[:values].empty?
      inputs["setMetadata"] = set_metadata unless set_metadata.empty?
      inputs["namespace"] = namespace unless namespace.empty?

      payload = options.merge(body: inputs.to_json)
      self.class.post("#{@base_uri}/vectors/update", payload)
    end

    def describe_index_stats(filter: {})
      payload = if filter.empty?
        options
      else
        options.merge(body: {filter: filter}.to_json)
      end
      self.class.post("#{@base_uri}/describe_index_stats", payload)
    end


    def options
      {
        headers: @headers,
      }
    end

    private

    # https://index_name-project_id.svc.environment.pinecone.io
    def set_base_uri(index_name)
      index_description = Pinecone::Index.new.describe(index_name)
      raise Pinecone::IndexNotFoundError, "Index #{index_name} does not exist" if index_description.code != 200
      uri = index_description.parsed_response["status"]["host"]
      "https://#{uri}"
    end
  end
end