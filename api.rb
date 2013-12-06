
db = CouchDB.new ENV['couchdb'] || Sinatra::Application.settings.couchdb

@api = {
    :apiVersion=>"0.0.1",
    :swaggerVersion=>"1.2",
    :info=>{
        :title=>"CNCFlora WebServices",
        :description=>"CNCFlora conservation related public services. 
                        <br /><br />
                        <a href=\"http://cncflora.jbrj.gov.br\">CNCFlora Portal</a>",
        :contact=>"dev@cncflora.jbrj.gov.br",
        :license=>"CC-BY-NC",
        :licenseUrl=>"http://creativecommons.org/licenses/by-nc/4.0/"
    },
    :apis=>[
        {
            :path=>'/assessments',
            :description=>"Retrieve assessments",
            :apis=>[
                {
                    :path=>"/assessments/family/{family}",
                    :operations=>[
                         {
                             :method=>"GET",
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

