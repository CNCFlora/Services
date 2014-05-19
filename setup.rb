
config_file ENV['config'] || 'config.yml'
use Rack::Session::Pool
set :session_secret, '1flora2'
set :views, 'views'

def http_get(uri)
    JSON.parse(Net::HTTP.get(URI(uri)))
end

def http_post(uri,doc) 
    uri = URI.parse(uri)
    header = {'Content-Type'=> 'application/json'}
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri, header)
    request.body = doc.to_json
    response = http.request(request)
    JSON.parse(response.body)
end

def search(index,query)
    query="scientificName:'Aphelandra longiflora'" unless query != nil && query.length > 0
    result = []
    r = http_get("#{settings.elasticsearch}/#{index}/_search?size=999&q=#{URI.encode(query)}")
    r['hits']['hits'].each{|hit|
        result.push(hit["_source"])
    }
    result
end

config = {}

set :etcd, ENV["ETCD"] || settings.etcd

if settings.etcd
    etcd = http_get("#{settings.etcd}/v2/keys/?recursive=true") 
    etcd['node']['nodes'].each {|node|
        if node.has_key?('nodes')
            node['nodes'].each {|entry|
                if entry.has_key?('value') && entry['value'].length >= 1 
                    key = entry['key'].gsub("/","_").gsub("-","_").downcase()[1..-1]
                    config[key.to_sym] = entry['value']
                end
            }
        end
    }
end

set :couchdb, "#{config[:couchdb_url]}/#{settings.base}"
set :elasticsearch, "#{config[:elasticsearch_url]}/#{settings.base}"

