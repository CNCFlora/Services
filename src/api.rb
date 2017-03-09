require 'couchdb_basic'
require 'json'

db = Couchdb.new Sinatra::Application.settings.couchdb
es = Sinatra::Application.settings.elasticsearch

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
                                    :enum=>["assessment","occurrence","profile","taxon","biblio"]
                                }
                            ],
                            :execute=>Proc.new{|params|
                                search(settings.db,params['type'],"#{params['q']} AND metadata.status:\"published\"")
                            }
                        }
                    ]
                },
                {
                    :path=>"/../search/occurrences",
                    :operations=>[
                        {
                            :method=>"GET",
                            :summary=>"Occurrence fulltext search accross whole database",
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
                                    :enum=>["occurrence"]
                                }
                            ],
                            :execute=>Proc.new{|params|
                                search(settings.db,params['type'],"#{params['q']}")
                            }
                        }
                    ]
                }
            ]
        },
        {
            :path=>"/occurrences",
            :description=>"Retrieve occurrences",
            :apis=>[
              {
                  :path=>"/../occurrences/scientificName/{scientificName}",
                  :operations=>[
                       {
                           :method=>"GET",
                           :summary=>"Return published occurrences for taxon",
                           :nickname=>"occurrencesForTaxon",
                           :type=>"Occurrences",
                           :parameters=>[
                               {
                                  :name=>"scientificName",
                                  :description=>"Specie scientific name, without author. Eg.: Aphelandra longiflora",
                                  :required=>true,
                                  :type=>"string",
                                  :paramType=>"path"
                              }
                          ],
                          :execute=> Proc.new{ |params|
                            r=search(settings.db,'occurrence',"scientificName:\"#{params["scientificName"]}\"")
                            r
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
                                search(settings.db,'assessment',"taxon.family:\"#{params["family"]}\" AND ( metadata.status:\"published\" OR metadata.status:\"comments\")")
                                     .each {|doc| families << doc["taxon"]["family"].upcase}
                                 families.uniq.sort
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
                                all_names= http_get_json("#{settings.aka}/nouns")

                                names = {}
                                all_names.each {|name|
                                  n1 = name['noun1']
                                  n2 = name['noun2']
                                  if !names.has_key?(n1)
                                    names[n1]=[]
                                  end
                                  if !names.has_key?(n2)
                                    names[n2]=[]
                                  end
                                  names[n1].push n2
                                  names[n2].push n1
                                }

                                family   = http_get("#{settings.floradata}/api/v1/species?family=#{params["family"]}")["result"]

                                family_names={}
                                family.each {|taxon|
                                  family_names[taxon['scientificNameWithoutAuthorship']]=taxon
                                  taxon['synonyms'].each{|syn|
                                    if !family_names.has_key?(syn['scientificNameWithoutAuthorship'])
                                      family_names[syn['scientificNameWithoutAuthorship']]=taxon
                                    end
                                  }
                                }
                                search(settings.db,'assessment',"taxon.family:\"#{params["family"]}\" AND ( metadata.status:\"published\" OR metadata.status:\"comments\")")
                                     .select {|doc| doc['taxon']['family'].upcase == params['family'].upcase }
                                     .map {|doc|
                                         spp = doc['taxon']['scientificNameWithoutAuthorship']
                                         if !names.has_key?(spp)
                                           names[spp]=[spp]
                                         else
                                           names[spp].push(spp)
                                         end
                                         names[spp].each {|name|
                                           if family_names.has_key?(name)
                                             doc['taxon']['current']=family_names[name]
                                           end
                                         }
                                         doc
                                       }
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
                               names = aka(params['taxon'].gsub("+"," "))
                               taxonomy = taxonomy(params["taxon"].gsub("+"," "))

                               names_query = "taxon.scientificNameWithoutAuthorship:\"#{params["taxon"].gsub("+"," ")}\""
                               if !taxonomy.nil?
                                 names_query = "#{names_query} OR taxon.scientificNameWithoutAuthorship:\"#{taxonomy["scientificNameWithoutAuthorship"]}\""
                                 taxonomy["synonyms"].each {|syn|
                                   names_query = "#{names_query} OR taxon.scientificNameWithoutAuthorship:\"#{syn["scientificNameWithoutAuthorship"]}\""
                                 }
                               end

                               names.each {|name|
                                   names_query = "#{names_query} OR taxon.scientificNameWithoutAuthorship:\"#{name}\""
                               }

                               query = "(metadata.status:\"published\" OR metadata.status:\"comments\") AND (#{names_query})"

                               r=search(settings.db,'assessment',query)[0]
                               if !r.nil?
                                 r["taxon"]["current"]=taxonomy
                               end
                               r

                            }
                        }
                    ]
                },
                {
                    :path=>"/../assessments/2taxon/{taxon}",
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
                               names = aka(params['taxon'].gsub("+"," "))
                               taxonomy = taxonomy(params["taxon"].gsub("+"," "))

                               names_query = "taxon.scientificNameWithoutAuthorship:\"#{params["taxon"].gsub("+"," ")}\""
                               if !taxonomy.nil?
                                 names_query = "#{names_query} OR taxon.scientificNameWithoutAuthorship:\"#{taxonomy["scientificNameWithoutAuthorship"]}\""
                                 taxonomy["synonyms"].each {|syn|
                                   names_query = "#{names_query} OR taxon.scientificNameWithoutAuthorship:\"#{syn["scientificNameWithoutAuthorship"]}\""
                                 }
                               end
                               names.each {|name|
                                   names_query = "#{names_query} OR taxon.scientificNameWithoutAuthorship:\"#{name}\""
                               }

                               query = "(metadata.status:\"published\" OR metadata.status:\"comments\") AND (#{names_query})"
                               r=search(settings.db_test,'assessment',query)[0]

                               if !r.nil?
                                 r["taxon"]["current"]=taxonomy
                               end
                               r

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
                               names = aka(params['taxon'].gsub("+",""))
                               taxonomy = taxonomy(params["taxon"].gsub("+"," "))

                               names_query = "taxon.scientificNameWithoutAuthorship:\"#{params["taxon"].gsub("+"," ")}\""
                               if !taxonomy.nil?
                                 names_query = "#{names_query} OR taxon.scientificNameWithoutAuthorship:\"#{taxonomy["scientificNameWithoutAuthorship"]}\""
                                 taxonomy["synonyms"].each {|syn|
                                   names_query = "#{names_query} OR taxon.scientificNameWithoutAuthorship:\"#{syn["scientificNameWithoutAuthorship"]}\""
                                 }
                               end

                               names.each {|name|
                                   names_query = "#{names_query} OR taxon.scientificNameWithoutAuthorship:\"#{name}\""
                               }

                               query = "metadata.status:\"done\" AND ( #{names_query} )"

                               r=search(settings.db,'profile',query)[0]
                               if !r.nil?
                                 r["taxon"]["current"]=taxonomy
                               end
                               r
                            }
                        }
                    ]
                },
                {
                    :path=>"/../profiles/2taxon/{taxon}",
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
                               names = aka(params['taxon'].gsub("+",""))
                               taxonomy = taxonomy(params["taxon"].gsub("+"," "))

                               names_query = "taxon.scientificNameWithoutAuthorship:\"#{params["taxon"].gsub("+"," ")}\""
                               if !taxonomy.nil?
                                 names_query = "#{names_query} OR taxon.scientificNameWithoutAuthorship:\"#{taxonomy["scientificNameWithoutAuthorship"]}\""
                                 taxonomy["synonyms"].each {|syn|
                                   names_query = "#{names_query} OR taxon.scientificNameWithoutAuthorship:\"#{syn["scientificNameWithoutAuthorship"]}\""
                                 }
                               end

                               names.each {|name|
                                   names_query = "#{names_query} OR taxon.scientificNameWithoutAuthorship:\"#{name}\""
                               }

                               query = "metadata.status:\"done\" AND ( #{names_query} )"

                               r=search(settings.db_test,'profile',query)[0]
                               if !r.nil?
                                 r["taxon"]["current"]=taxonomy
                               end
                               r
                            }
                        }
                    ]
                }
            ]
        }
    ]
}
