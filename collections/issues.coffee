@Issues = new Mongo.Collection("issues")

Issues.allow
  insert: isAdminFromId
  update: isAdminFromId
  remove: isAdminFromId

isAdminFromId = (userId, document) ->
    user = Meteor.users.findOne(userId)
    isAdmin user


@IssuesSchema =

  # Lanuage-specific
  titleEN: String
  titleFR: String

  # Attributes
  structure: String
  family: String
  productType: String

  # Codes
  BondDeskCode: String
  fundSERVCode: String
  ISMBondDesk: String
  ISMFundSERV: String

  # Booleans
  hasCallValDate: Boolean
  hasCallThreshold: Boolean
  hasDistrValDate: Boolean
  hasDistrThreshold: Boolean
  hasFixingTicker: Boolean
  hasFixingsInPercent: Boolean
  hasFixingAmount: Boolean
  hasFixingAdjustedAmount: Boolean
  hasFXExposure: Boolean
  showPortfolioWeight: Boolean

  # Dates
  issuanceDate: Date
  valuationDate: Date
  term: Number
  maturityDate: Date

  # ETC (different from the ETC array)
  etc:
    totalPeriod: Number
    steps: Number
    maxAmount: Number

  # Arrays
  bids: Array
  distributions: Array
  calls: Array
  fixings: Array
  portfolios: Array
  etcSchedule: Array

@PortfoliosSchema =

  # Specs
  participationFactor: Number
  maximum: Number
  minimum: Number
  localMin: Number
  localMax: Number
  assigned: Number
  bonus: Number
  barrierAmount: Number

  # Settings
  settings:
    participationThreshold: String
    barrierType: String
    tickerFX: String
    portfolioReturn: String
    modifiedPortfolioReturn: String
    hasFXExposure: Boolean
    showTickerWeight: Boolean
    showTickerRanking: Boolean

  # Arrays
  tickers: Array

@TickersSchema =

  # Specs
  bloomberg: String
  intitialPrice: Number
  intitialFX: Number
  weight: Number

  # Booleans
  hasFXExposure: Boolean

Meteor.methods
  saveIssue: (id, issue) ->

    if not isAdmin() then throw new Meteor.Error('not-authorized');

    # check issue,
    #   _id: Match.Optional(String)
    #   titleEN: String
    #   titleFR: String
    #   slugEN: String
    #   slugFR: String
    #   issuanceDate: Date
    #   maturityDate: Date

    if id

      issue.updatedAt = new Date()

      Issues.update id, $set: issue


    else
      issue.createdAt = new Date()
      issue.updatedAt = issue.createdAt

      id = Issues.insert issue

    id

  saveIssueProperty: (id, key, value) ->

    if not isAdmin() then throw new Meteor.Error('not-authorized');

    check id, String
    check key, String

    # Inspired by serializeJSON#splitInputNameIntoKeysArray
    # Recursive function to turn keys into an object.
    fillObject = (container) ->
      key = keys.shift()
      unless isNaN(key) then key = parseInt key
      unless keys.length is 0
        # Create a different container depending on if we receive an int or not.
        container[key] = unless isNaN(keys[0]) then [] else {}
        fillObject container[key]
      else
        container[key] = value
      container

    keys = key.split(".")
    data = fillObject {}

    Issues.update id, $set: data

  deleteIssue: (_id) ->
    if not isAdmin() then throw new Meteor.Error('not-authorized');

    check _id, String
    Issues.remove _id

# @Schemas.Issue = new SimpleSchema
#   titleEN:
#     type: String
#     label: "Title EN"
#     max: 255
#   titleFR:
#     type: String
#     label: "Title FR"
#     max: 255
#   issuanceDate:
#     type: Date
#     label: "Issuance Date"
#     optional: true
#     autoform:
#       afFieldInput:
#         type: "bootstrap-datepicker"
#   maturityDate:
#     type: Date
#     label: "Maturity Date"
#     optional: true
#     autoform:
#       afFieldInput:
#         type: "bootstrap-datepicker"

#   createdAt:
#     type: Date
#     denyUpdate: true

#   updatedAt:
#     type: Date

#   "prices":
#     type: [Object]
#     optional: true
#   "prices.$.date":
#     type: Date
#     optional: true
#     autoform:
#       # skipLabel: true
#       "label-class": "sr-only"
#       afFieldInput:
#         type: "bootstrap-datepicker"
#   "prices.$.price":
#     type: Number
#     optional: true
#     autoform:
#       # skipLabel: true
#       "label-class": "sr-only"

# @Issues.attachSchema @Schemas.Issue
