ENV['RACK_ENV'] = 'test'

require_relative 'app'
require_relative 'couchdb'

require 'rspec'
require 'rack/test'
require 'multi_json'

include Rack::Test::Methods

def app
    Sinatra::Application
end

describe "Web app" do

    before(:all) do
        @couch = CouchDB.new Sinatra::Application.settings.couchdb
        @couch._post(MultiJson.load(IO.read("load.json")),"/_bulk_docs")
    end

    after(:all) do
        r =  @couch._get("/_all_docs")
        r[:rows].each { | row |
            if !row[:id].match /^_design\//
                @couch.delete({:_id=>row[:id],:_rev=>row[:value][:rev]})
            end
        }
    end

    it "Can list assessments of family" do
        get "/assessments/family/ACANTHACEAE"
        r = MultiJson.load(last_response.body, :symbolize_keys => true)
        expect(r.map {|doc| doc[:taxon][:family]}.uniq).to eq(["ACANTHACEAE"])
        expect(r.count).to eq(2)

        get "/assessments/family/BROMELIACEAE"
        r = MultiJson.load(last_response.body, :symbolize_keys => true)
        expect(r.map {|doc| doc[:taxon][:family]}.uniq).to eq(["BROMELIACEAE"])
        expect(r.count).to eq(1)
    end

    it "Can get assessment of taxon" do
        get "/assessments/taxon/Aphelandra%20espirito-santensis"
        r = MultiJson.load(last_response.body, :symbolize_keys => true)
        expect(r[:assessment]).to eq('CR')

        get "/assessments/taxon/NO"
        r = MultiJson.load(last_response.body, :symbolize_keys => true)
        expect(r).to eq(nil)
    end

end

