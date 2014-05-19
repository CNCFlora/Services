Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require 'sinatra'
require 'sinatra/config_file'
require "sinatra/reloader" if development? || test?

require 'securerandom'
require 'json'
require 'uri'
require 'net/http'

if development? || test? 
    also_reload "api.rb"
end

require_relative 'setup'
require_relative 'api'

api = @api

get '/' do
    redirect "#{settings.path}/index.html"
end

get '/api-docs' do
    re = api.clone
    re[:apis] = api[:apis].map { |api| {:path=>api[:path],:description=>api[:description]}}
    re.to_json
end

get '/api-docs/:path' do

    re = {
        :apiVersion=>api[:apiVersion],
        :swaggerVersion=>api[:swaggerVersion],
        :resourcePath=>"/#{params[:path]}",
        :produces=>["application/json"],
        :models=>api[:models],
        :apis=>[]
        }

    api[:apis].each { |api| 
        if api[:path] == "/#{params[:path]}" then 
            re[:apis] = api[:apis]; 
        end
    }

    re.to_json
end

api[:apis].each { |resource| 
    resource[:apis].each { |api|
        path = api[:path].gsub(/{(\w+)}/,':\1').gsub("../","")
        puts api[:path]
        puts path
        get path do
            r = {}
            begin
                data = api[:operations][0][:execute].call(params)
                r = {:success=>true,:result=>data}
            rescue Exception => e
                r = {:success=>false,:result=>nil,:error=>e.message} 
            end
            r.to_json
        end
    }
}

