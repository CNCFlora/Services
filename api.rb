
db = CouchDB.new ENV['COUCHDB'] || Sinatra::Application.settings.couchdb
es = ENV['ESEARCH'] || Sinatra::Application.settings.esearch

@api = {
    :apiVersion=>"0.0.1",
    :swaggerVersion=>"1.2",
    :info=>{
        :title=>"CNCFlora WebServices",
        :description=>"CNCFlora conservation and biodiversity public web services. 
                        <br /><br/>
                        The following services provide the data generated and curated by the CNCFlora team and collaborators
                        on the consolidation of species data and risk assessment.
                        <br /><br />
                        See also the <a href=\"http://cncflora.jbrj.gov.br\">CNCFlora Portal</a>.",
        :contact=>"dev@cncflora.jbrj.gov.br",
        :license=>"CC-BY-NC",
        :licenseUrl=>"http://creativecommons.org/licenses/by-nc/4.0/"
    },
    :models=> {
        "Assessment"=> MultiJson.load(db.get("_design/assessments")[:schema][:assessment][27..-4], :symbolize_keys=>true)
    },
    :apis=>[
        {
            :path=>"/search",
            :description=>"Generic search",
            :apis=>[
                {
                    :path=>"/search/all",
                    :operations=>[
                        {
                            :method=>"GET",
                            :summary=>"General fulltext search accross whole database",
                            :nickname=>"search",
                            :parameters=>[
                                {
                                    :name=>"q",
                                    :description=>"query",
                                    :required=>true,
                                    :type=>"string",
                                    :paramType=>"query"
                                },
                                {
                                    :name=>"type",
                                    :description=>"query",
                                    :required=>false,
                                    :type=>"string",
                                    :paramType=>"query",
                                    :enum=>["assessment","profile","taxon","biblio"]
                                }
                            ],
                            :execute=>Proc.new{|params|
                                type = "#{params['type']}/" || '/';
                                url = "#{es}/#{type}_search?q=#{params['q'].to_uri}"
                                r = RestClient.get url
                                MultiJson.load(r.to_str, :symbolize_keys => true)[:hits][:hits]
                            }
                        }
                    ]
                }
            ]
        },
        {
            :path=>'/assessments',
            :description=>"Retrieve assessments",
            :apis=>[
                {
                    :path=>"/assessments/family/{family}",
                    :operations=>[
                         {
                             :method=>"GET",
                             :type=>"Assessment",
                             :summary=>"Return published assessments for given family",
                             :nickname=>"assessmentsByFamily",
                             :parameters=>[
                                 {
                                    :name=>"family",
                                    :description=>"family name",
                                    :required=>true,
                                    :type=>"string",
                                    :paramType=>"path"
                                }
                            ],
                            :execute=> Proc.new{ |params|
                                db.view('assessments','by_family_and_status',
                                            {:key=>[ params[:family].upcase,"published"]})
                                  .map {|row| row[:value]}
                            }
                        }
                    ]
                },
                {
                    :path=>"/assessments/taxon/{taxon}",
                    :operations=>[
                         {
                             :method=>"GET",
                             :summary=>"Return published assessment for taxon",
                             :nickname=>"assessmentForTaxon",
                             :type=>"Assessment",
                             :parameters=>[
                                 {
                                    :name=>"taxon",
                                    :description=>"Specie scientific name, without author. Eg.: Aphelandra longiflora",
                                    :required=>true,
                                    :type=>"string",
                                    :paramType=>"path"
                                }
                            ],
                            :execute=> Proc.new{ |params|
                                db.view('assessments','by_taxon_name',
                                         {:key=>params[:taxon]})
                                  .map {|row| row[:value]}
                                  .last
                            }
                        }
                    ]
                }
            ]   
        }
    ]
}

