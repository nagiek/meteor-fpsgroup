# if the database is empty on server start, create some sample data.
Meteor.startup ->
  if Issues.find().count() is 0
    data = [
      titleEN: 'hi'
      slugEN: 'hi'
      titleFR: 'allo'
      slugFR: 'allo'
      issuanceDate: new Date()
      maturityDate: new Date()
    ,
      titleEN: 'hi2'
      slugEN: 'hi2'
      titleFR: 'allo2'
      slugFR: 'allo2'
      issuanceDate: new Date()
      maturityDate: new Date()
    ,
      titleEN: 'hi3'
      slugEN: 'hi3'
      titleFR: 'allo3'
      slugFR: 'allo3'
      issuanceDate: new Date()
      maturityDate: new Date()
    ]

    _.each data, (issue) -> Issues.insert issue