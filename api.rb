require 'couchdb_basic'
require 'json'

db = Couchdb.new ENV['COUCHDB'] || Sinatra::Application.settings.couchdb
es = ENV['ESEARCH'] || Sinatra::Application.settings.elasticsearch

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
        :contact=>"diogo@cncflora.jbrj.gov.br",
        :license=>"CC-BY-NC",
        :licenseUrl=>"http://creativecommons.org/licenses/by-nc/4.0/"
    },
    :models=> {
        "Assessment"=> JSON.parse(IO.read('assessment.json'))
    },
    :apis=>[
        {
            :path=>"/search",
            :description=>"Generic search",
            :apis=>[
                {
                    :path=>"/../search/all",
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
                                    :required=>true,
                                    :type=>"string",
                                    :paramType=>"query",
                                    :enum=>["assessment","profile","taxon","biblio"]
                                }
                            ],
                            :execute=>Proc.new{|params|
                                search(params['type'],"#{params['q']} AND metadata.status:\"published\"")
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
                    :path=>"/../assessments/families",
                    :operations=>[
                         {
                             :method=>"GET",
                             :type=>"Assessment",
                             :summary=>"Return families that have published assessments",
                             :nickname=>"families",
                             :parameters=>[
                            ],
                            :execute=> Proc.new{ |params|
                                families = []
                                search('assessment',"taxon.family:\"#{params["family"]}\" AND ( metadata.status:\"published\" OR metadata.status:\"comments\")")
                                     .each {|doc| families << doc["taxon"]["family"].upcase}
                                 families.uniq
                            }
                        }
                    ]
                },
                {
                    :path=>"/../assessments/family/{family}",
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
                                search('assessment',"taxon.family:\"#{params["family"]}\" AND ( metadata.status:\"published\" OR metadata.status:\"comments\")")
                                     .select {|doc| doc['taxon']['family'] == params['family'] }
                            }
                        }
                    ]
                },
                {
                    :path=>"/../assessments/taxon/{taxon}",
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
                               r=search('assessment',"( taxon.scientificNameWithoutAuthorship:\"#{params["taxon"]}\" OR taxon.scientificName:\"#{params["taxon"]}\" ) AND ( metadata.status:\"published\" OR metadata.status:\"comments\")")
                               r.select {|doc| doc['taxon']['scientificNameWithoutAuthorship'] == params['taxon'].gsub("+"," ") || doc['taxon']['scientificName']==params["taxon"].gsub("+"," ") }[0]
                            }
                        }
                    ]
                }
            ]   
        },
        {
            :path=>'/profiles',
            :description=>"Retrieve profiles",
            :apis=>[
                {
                    :path=>"/../profiles/taxon/{taxon}",
                    :operations=>[
                         {
                             :method=>"GET",
                             :summary=>"Return published profile for taxon",
                             :nickname=>"profileForTaxon",
                             :type=>"profile",
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
                               r=search('profile',"( taxon.scientificNameWithoutAuthorship:\"#{params["taxon"]}\" OR taxon.scientificName:\"#{params["taxon"]}\" ) AND metadata.status:\"done\"")
                               r.select {|doc| doc['taxon']['scientificNameWithoutAuthorship'] == params['taxon'].gsub("+"," ") || doc['taxon']['scientificName'] == params['taxon'].gsub('+',' ') }[0]
                            }
                        }
                    ]
                }
            ]
        }
    ]
}

