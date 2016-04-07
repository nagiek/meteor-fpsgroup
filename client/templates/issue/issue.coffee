EDITING_KEY = "EDITING_ISSUE_ID"
CURRENT_ISSUE_TAB = "CURRENT_ISSUE_TAB"
VAL_DATE_OFFSET = 3

Session.setDefault EDITING_KEY, false

bids = null
curr = null
graph = null
chartResizeFn = null

originalData = {}

issueDefaults =
  curr: "CAD"

Template.issue.validators = Template.issue.validators or {}

Template.issue.created = ->
  @data = {} unless @data

  _.defaults @data, issueDefaults

  _.each IssuesSchema, (v, k) => Template.convertToSession(v, k, @data)

  # Reset to general for each time we come to this page
  Session.setDefault(CURRENT_ISSUE_TAB, "general")

  originalData = _.clone @data

  # Save a reference for the graph.
  bids = @data.bids
  curr = @data.curr

  @data

Template.issue.destroyed = ->

  # Clean up.
  _.each IssuesSchema, (v, k) ->
    if _.isObject v
      _.each v, (objectValue, objectKey) -> Session.set "#{k}.#{objectKey}", null
    else Session.set k, null

  @$('.datepicker').datepicker("remove")

  Session.set(CURRENT_ISSUE_TAB, null)

  $(window).off(chartResizeFn)

Template.issue.rendered = ->
  @$('.datepicker').datepicker(language: i18n.getLanguage())
  google.load "visualization", "1",
    packages: ["line"]
    callback: Template.issue.googleGraph,
    language: i18n.getLanguage()

Template.issue.googleGraph = ->

  return unless bids and not _.isEmpty bids

  # chartData = _(bids).map(_.values)
  chartData = _(bids).map((bid) -> [new Date(bid.date), Number(bid.amount)])
  data = new google.visualization.DataTable
  data.addColumn 'date', i18n("common.nouns.date")
  data.addColumn 'number', i18n("common.nouns.amount")
  data.addRows chartData
  options =
    chart:
      title: i18n('issue.graph.bidPerformance')
      subtitle: "#{i18n('common.prepositions.in')} #{curr}"
      hAxis:
        title: "none"
        textStyle: "italic"
      vAxis:
        title: "none"
        textStyle: "italic"
      colors: [@variables["brand-primary"]]
#     width: 1000
#     height: 600
    legend:
      position: "none"


  graph = new (google.charts.Line)(document.getElementById("chart"))
  drawGraph = ->
    options.height = Math.round(window.innerWidth * 0.20)
    graph.draw(data, options)
  chartResizeFn = $(window).on("resize", _.throttle(drawGraph, 1000))
  drawGraph()


Template.issue.helpers

  existed: -> !@_id and "hide"

  editing: ->
    if (!@_id or Session.equals(EDITING_KEY, @_id)) then "editing" else "viewing"

  editingActive: ->
    (!@_id or Session.equals(EDITING_KEY, @_id)) and "active"

  editingModal: ->
    (!@_id or Session.equals(EDITING_KEY, @_id)) and "modal-lg"

  currentBid: -> if @bids and not _.isEmpty @bids then numeral(_.last(@bids).amount).format(i18n("common.numbers.formats.currency"))

  currentNetBid: ->
    return "" unless @bids and not _.isEmpty @bids
    return "" unless @etcSchedule and not _.isEmpty @etcSchedule
    return "" unless @issuanceDate
    currentBid = _.last(@bids).amount
    daysFromIssuanceDate = moment().diff(@issuanceDate, "days")
    currentETC = _.find @etcSchedule, (etc) -> etc.fromNum <= daysFromIssuanceDate <= etc.toNum
    numeral(currentBid - currentETC.amount).format(i18n("common.numbers.formats.currency")) if currentETC

  # Conditions
  isAdmin: -> isAdmin()
  isActive: (tab) ->
    tab is Session.get(CURRENT_ISSUE_TAB) and "active"

  # Language
  isEnglish: -> isEnglish()
  isFrench: -> isFrench()

Template.issue.events

  # Modal controls
  # Needs global body state functionality..
  "click .nav a": (event, template) ->
    event.preventDefault()
    target = $(event.target).data("target")
    Session.set CURRENT_ISSUE_TAB, target

  "change .issue-form input": (event, template) ->
    input = $(event.target)
    type = input.attr("type")
    name = input.attr("name")
    value = input.val()
    value = moment(value, DATE_INPUT_FORMAT).toDate() if type is "date"
    value = Number value if type is "number"

    key = Template.extractKey name
    Session.set key, value

  "change .js-session": (event, template) ->
    input = $(event.target)
    type = input.attr("type")
    name = input.attr("name")
    value = input.val()
    value = moment(value, DATE_INPUT_FORMAT).toDate() if type is "date"
    value = Number value if type is "number"
    value = event.target.checked if type is "checkbox"

    key = Template.extractKey name
    Session.set key, value

  "change .js-autosave": (event, template) ->
    # We don't know where we'll get the ID from.
    _id = @_id
    _id = Template.parentData(1)._id unless _id
    return unless _id

    name = $(event.target).attr("name")
    key = Template.extractKey name
    value = event.target.checked

    Session.set key, value

    Meteor.call 'saveIssueProperty', _id, key, value, (error, result) -> alert error if error

  "click button.js-update-val-from-mat": (event, template) ->
    maturityDate = Session.get "maturityDate"

    unless maturityDate
      notification =
        title: i18n("common.errors.missing") + " " + i18n("issue.fields.maturityDate")
        type: "error"
      return Template.appBody.addNotification notification

    valDateOffset = VAL_DATE_OFFSET
    valuationDate = moment(maturityDate).subtract(valDateOffset, "days").toDate()
    template.$(".valuation-date").datepicker "update", valuationDate
    Session.set "valuationDate", valuationDate

  "click button.js-update-mat-from-term": (event, template) ->
    issuanceDate = Session.get "issuanceDate"
    term = Session.get "term"
    years = Math.floor(term)
    months = Math.round((term % 1) * 12)

    unless issuanceDate
      notification =
        title: i18n("common.errors.missing") + " " + i18n("issue.fields.issuanceDate")
        type: "error"
      return Template.appBody.addNotification notification

    unless term
      notification =
        title: i18n("common.errors.missing") + " " + i18n("issue.fields.term")
        type: "error"
      return Template.appBody.addNotification notification

    potentialDate = moment(issuanceDate).add(years, "years").add(months, "months")
    maturityDate = selectFreeDay(potentialDate, +1, holidays[@currency or "ca"]).toDate()
    template.$(".maturity-date").datepicker "update", maturityDate
    Session.set "maturityDate", maturityDate

  "click button.js-edit-issue": (event, template) ->
    editing = unless Session.equals(EDITING_KEY, @_id) then @_id else false
    Session.set EDITING_KEY, editing

    # Force the template to redraw based on the reactive change
#     Tracker.flush();
    template.find('input[type=text]').focus()

  "submit form.issue-form": (event, template) ->

    event.preventDefault()

    data = $(event.target).serializeJSON(useIntKeysAsArrayIndex: true).issue or {}


    # Slugs
    data.slugEN = _.slugify data.titleEN
    data.slugFR = _.slugify data.titleFR

    # Dates
    data.issuanceDate = moment(data.issuanceDate, DATE_INPUT_FORMAT).toDate()
    data.maturityDate = moment(data.maturityDate, DATE_INPUT_FORMAT).toDate()
    _.each data.prices, (p) -> p.date = moment(p.date, DATE_INPUT_FORMAT).toDate()

    # Validate components
    Template.issue.validators.portfolios(data.portfolios) if data.portfolios
    Template.issue.validators.bids(data.bids) if data.bids
    Template.issue.validators.etcs(data.etcs) if data.etcs
    Template.issue.validators.distributions(data.distributions) if data.distributions
    Template.issue.validators.calls(data.calls) if data.calls
    Template.issue.validators.fixings(data.fixings) if data.fixings

    # Copy in new data.
    _.extend @, data

    # Update Session array variables
    _.each @portfolios, (portfolio, pIndex) ->
      _.each PortfoliosSchema, (v, k) -> Template.convertToSession(v, k, portfolio, "portfolios.#{pIndex}")

    _.each IssuesSchema, (v, k) => Template.convertToSession(v, k, @)
    # _.each PortfoliosSchema, (v, k) => Template.convertToSession(v, k, @, "portfolios.#{@index}")

    Meteor.call 'saveIssue', @_id, data, Template.handleSave

  "click .js-reset": (event, template) ->
    _.each IssuesSchema, (v, k) => Template.convertToSession(v, k, originalData, "")

  "click button.js-delete-issue": (event, template) ->

    event.preventDefault()

    if confirm i18n("common.actions.confirm")

      Meteor.call 'deleteIssue', @_id, (error, result) ->
        unless error
          # examine result
          Router.go "home"
        else
          # handle error
          alert error

# Attach our schema
Meteor.startup ->

  helpersReference = {}
  _.each IssuesSchema, (v, k) => Template.assignHelpers(helpersReference, v, k)
  Template.issue.helpers helpersReference

  portfolioHelpersReference = {}
  _.each PortfoliosSchema, (v, k) => Template.assignHelpers(portfolioHelpersReference, v, k, "portfolios.$0")
  Template.portfolio.helpers portfolioHelpersReference

  tickerHelpersReference = {}
  _.each TickersSchema, (v, k) => Template.assignHelpers(tickerHelpersReference, v, k, "portfolios.$1.tickers.$0")
  Template.ticker.helpers tickerHelpersReference
