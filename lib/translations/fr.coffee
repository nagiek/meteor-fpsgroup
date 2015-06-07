numeralFR = 
  delimiters:
    thousands: " "
    decimal: ","

  abbreviations:
    thousand: "k"
    million: "m"
    billion: "b"
    trillion: "t"

  ordinal: (number) ->
    (if number is 1 then "er" else "ème")

  currency:
    symbol: "$"

numeral.language 'fr', numeralFR
    
###
Translation strings for the entire site.
###
i18n.map 'fr', 
            
  ## Common ##     
  "common.classes.issues":                          "Issues"
  "common.classes.structures":                      "Structures"

  "common.actions.save":                            "Save"
  "common.actions.search":                          "Search"
  "common.actions.edit":                            "Edit"
  "common.actions.delete":                          "Delete"
  "common.actions.download":                        "Download"
  "common.actions.cancel":                          "Cancel"
  "common.actions.changes_saved":                   "Changes saved"
  "common.actions.confirm":                         "Are you sure?"
  "common.actions.close":                           "Close"
  "common.actions.reset":                           "Reset"
  "common.actions.remove":                          "Remove"
  "common.actions.upload":                          "Upload"
  
  "common.nouns.actions":                           "Actions"
  "common.nouns.admin":                             "Admin"
  "common.nouns.amount":                            "Amount"
  "common.nouns.documents":                         "Documents"
  "common.nouns.date":                              "Date"
  "common.nouns.dates":                             "Dates"
  "common.nouns.general_info":                      "General Information"
  "common.nouns.history":                           "History"
  "common.nouns.home":                              "Home"
  "common.nouns.number":                            "Number"
  "common.nouns.ranking":                           "Ranking"
  "common.nouns.weight":                            "Weight"
  
  "common.langs.EN":                                "AN"
  "common.langs.FR":                                "FR"
  "common.langs.english":                           "Anglais"
  "common.langs.french":                            "Français"
  
  "common.empty.search":                            "Nothing matches your search"
  
  "common.expressions.mark_read":                   "Mark read"
  "common.expressions.see_all":                     "See all"
  
  "common.conjuctions.and":                         "and"
  "common.conjuctions.or":                          "or"
  
  "common.numbers.formats.input":                   "0"
  "common.numbers.formats.currency":                "0,0.00"
  "common.numbers.formats.percent":                 "0%"
  
  "common.prepositions.from":                       "From"
  "common.prepositions.in":                         "In"
  "common.prepositions.to":                         "To"
  
  "common.dates.formats.medium":                    "D MMM YYYY"
  "common.dates.formats.input":                     "yyyy-mm-dd"
  "common.dates.formats.output":                    "YYYY-MM-DD"
  
  "common.fields.title":                            "Title"
  "common.fields.body":                             "Body"
  "common.fields.email":                            "Email"
  "common.fields.phone":                            "Phone"
  "common.fields.website":                          "Website"
  "common.fields.status":                           "Status"
  "common.fields.name":                             "Name"
  "common.fields.posted":                           "Posted"
  "common.fields.posted_at":                        "Posted at"
          
  "common.messages.saved":                          "Saved"
  "common.errors.notSaved":                         "Not saved"
  "common.errors.required":                         "Required"
  "common.errors.missing":                          "Missing"