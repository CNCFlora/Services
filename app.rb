require 'sinatra'
require 'sinatra/config_file'
require 'sinatra/mustache'
require "sinatra/reloader" if development? || test?
require 'multi_json'
require 'time'

if development? || test? 
    also_reload "api.rb"
    also_reload "couchdb.rb"
end

config_file ENV['CONFIG'] || 'config.yml'

require_relative 'couchdb'
require_relative 'api'

api = @api

get '/' do
    mustache :index, {}, {:url=> (ENV['BASE_URL'] || settings.base_url)+"/api-docs"}
end

get '/api-docs' do
    re = api.clone
    re[:apis] = api[:apis].map { |api| {:path=>api[:path],:description=>api[:description]}}
    MultiJson.dump re
end

get '/api-docs/:path' do
    re = {
        :apiVersion=>api[:apiVersion],
        :swaggerVersion=>api[:swaggerVersion],
        :basePath=>settings.url,
        :resourcePath=>"/#{params[:path]}",
        :produces=>["application/json"],
        :models=>{},
        :apis=>[]

    }
    api[:apis].each { |api| if api[:path] == "/#{params[:path]}" then re[:apis] = api[:apis]; end}
    MultiJson.dump re
end

api[:apis].each { |resource| 
    resource[:apis].each { |api|
        get api[:path].gsub(/{(\w+)}/,':\1') do
            #[400,'{"error"=>"Missing required parameter."}']
            MultiJson.dump api[:operations][0][:execute].call params
        end
    }
}

