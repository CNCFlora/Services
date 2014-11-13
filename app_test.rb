ENV['RACK_ENV'] = 'test'

require_relative 'app'

require 'couchdb_basic'

require 'rspec'
require 'rack/test'
require 'json'

include Rack::Test::Methods

def app
    Sinatra::Application
end

describe "Web app" do

    before(:all) do
        @couch = Couchdb.new Sinatra::Application.settings.couchdb
        @couch._post(JSON.parse(IO.read("load.json")),"/_bulk_docs")
        sleep(3)
    end

    after(:all) do
        r =  @couch._get("/_all_docs")
        r[:rows].each { | row |
            if !row[:id].match /^_design\//
                @couch.delete({:_id=>row[:id],:_rev=>row[:value][:rev]})
            end
        }
    end

    it "Can list families" do
        get "/assessments/families"
        r = JSON.parse(last_response.body)
        expect(r).to eq(['ACANTHACEAE','BROMELIACEAE'])
    end

    it "Can list assessments of family" do
        get "/assessments/family/ACANTHACEAE"
        r = JSON.parse(last_response.body)
        expect(r.map {|doc| doc['taxon']['family']}.uniq).to eq(["ACANTHACEAE"])
        expect(r.count).to eq(2)

        get "/assessments/family/BROMELIACEAE"
        r = JSON.parse(last_response.body)
        expect(r.map {|doc| doc['taxon']['family']}.uniq).to eq(["BROMELIACEAE"])
        expect(r.count).to eq(1)
    end

    it "Can get assessment of taxon" do
        get "/assessments/taxon/Aphelandra%20espirito-santensis"
        r = JSON.parse(last_response.body,{:quirks_mode=>true})
        expect(r['assessment']=='CR')

        get "/assessments/taxon/Aphelandra+espirito-santensis"
        r = JSON.parse(last_response.body,{:quirks_mode=>true})
        expect(r['assessment']=='CR')

        get "/assessments/taxon/Aphelandra%20longiflora"
        r = JSON.parse(last_response.body,{:quirks_mode=>true})
        expect(r['assessment']=='VU')

        get "/assessments/taxon/NO"
        r = JSON.parse(last_response.body,{:quirks_mode=>true})
        expect(r).to eq(nil)

        get "/assessments/taxon/Another%20longiflora"
        r = JSON.parse(last_response.body,{:quirks_mode=>true})
        expect(r).to eq(nil)

        get "/assessments/taxon/Aphelandra"
        r = JSON.parse(last_response.body,{:quirks_mode=>true})
        expect(r).to eq(nil)
    end

    it "Can get profile of taxon" do
        get "/profiles/taxon/Aphelandra%20espirito-santensis"
        r = JSON.parse(last_response.body,{:quirks_mode=>true})
        expect(r['profile']=='CR')

        get "/profiles/taxon/Aphelandra+espirito-santensis"
        r = JSON.parse(last_response.body,{:quirks_mode=>true})
        expect(r['profile']=='CR')

        get "/profiles/taxon/Aphelandra%20longiflora"
        r = JSON.parse(last_response.body,{:quirks_mode=>true})
        expect(r['profile']=='VU')

        get "/profiles/taxon/NO"
        r = JSON.parse(last_response.body,{:quirks_mode=>true})
        expect(r).to eq(nil)

        get "/profiles/taxon/Another%20longiflora"
        r = JSON.parse(last_response.body,{:quirks_mode=>true})
        expect(r).to eq(nil)

        get "/profiles/taxon/Aphelandra"
        r = JSON.parse(last_response.body,{:quirks_mode=>true})
        expect(r).to eq(nil)
    end

    it "Can search" do
        get "/search/all?q=Aphelandra%20longiflora"
        r = JSON.parse(last_response.body)
        expect(r).to be_an_instance_of(Array)
        expect(r[0]['assessment']).to eq("VU")
    end

end

