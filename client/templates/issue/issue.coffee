EDITING_KEY = "EDITING_ISSUE_ID"
MODAL_SHOWING = "MODAL_SHOWING"
VAL_DATE_OFFSET = 3

Session.setDefault EDITING_KEY, false
Session.setDefault MODAL_SHOWING, false

bids = null
curr = null
graph = null
chartResizeFn = null

originalData = {}

issueDefaults =
  curr: "CAD"

Template.issue.created = ->
  @data = {} unless @data
  _.defaults @data, issueDefaults

  _.each IssuesSchema, (v, k) => Template.convertToSession(v, k, @data)

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

  $(window).off(chartResizeFn)

Template.issue.rendered = ->
  @$('.datepicker').datepicker(language: i18n.getLanguage())
  google.load "visualization", "1",
    packages: ["line"]
    callback: Template.issue.googleGraph,
    language: i18n.getLanguage()

Template.issue.googleGraph = ->

  return unless bids and not _.isEmpty bids

  chartData = _(bids).map(_.values)

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
    # This doesn't work argh why?


  graph = new (google.charts.Line)(document.getElementById("chart"))
  drawGraph = ->
    options.height = Math.round(window.innerWidth * 0.35)
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

  # Language
  isEnglish: -> isEnglish()
  isFrench: -> isFrench()

Template.issue.events

  # Modal controls
  # Needs global body state functionality..
  # "click .js-launch-modal": -> Session.set(MODAL_SHOWING, true)
  # "click button.close": -> Session.set(MODAL_SHOWING, false)
  # "click .modal-backdrop": -> Session.set(MODAL_SHOWING, false)

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

  helpers = {}
  _.each IssuesSchema, (v, k) => Template.getHelpers(v, k, helpers)
  Template.issue.helpers helpers

  portfolioHelpers = {}
  _.each PortfoliosSchema, (v, k) => Template.getHelpers(v, k, portfolioHelpers, "portfolios.$0")
  Template.portfolio.helpers portfolioHelpers

  tickerHelpers = {}
  _.each TickersSchema, (v, k) => Template.getHelpers(v, k, tickerHelpers, "portfolios.$1.tickers.$0")
  Template.ticker.helpers tickerHelpers

Template.issue.chartjsGraph = ->

  # Chart config (move to own file)
  overriddenChartGlobals =
    animation: true
    animationSteps: 60
    animationEasing: 'easeOutQuart'
    showScale: true
    responsive: true
    showTooltips: false

  Chart.defaults.global = _.defaults overriddenChartGlobals, Chart.defaults.global

  if bids and not _.isEmpty bids

    # My consts.
    DAYS_OF_MONTH = 31
    MAX_CHART_POINTS = 20

    # Turn chartData into an array of arrays (for later),
    # and chain it to prepare for future steps.
    chartData = _.chain(bids)

    # Reduce the amount of data points so that it fits on a graph.
    if chartData.length > MAX_CHART_POINTS

      # Moduluses (moduli?) for filter
      dateModulus = null
      excessModulus = null

      # group by month
      month = (b, i, context) -> b.date.substr(0,7)

      # Date filter to take regular days of the month.
      byDate = (grouping, iteraree, context) ->
        filtered = []
        _.each grouping, (g) ->
          filtered.push _.filter(g, (b, i) -> i % excessModulus is 0)
        filtered


        # Find the date filter to take.
  #       day = Number b.date.substr(8,2)
  #       _.contains(dayIntervals, day) or i is context.length

      # Double check (eg, if we have 2 years of data, monthly data will be too much.)
      ifExcess = (b, i, context) ->
        # Bail early if we're not taking monthly data.
        return true if context.length > MAX_CHART_POINTS

        # Calculate excessModulus based on the input we get.
        excessModulus = excessModulus or Math.ceil(context.length / MAX_CHART_POINTS)
        i % excessModulus is 0

      # Calculate dateModulus and other filter variables.
      dateModulus = Math.ceil(bids.length / MAX_CHART_POINTS)

      # Find out which dates we will be taking.
  #     dayIntervals = if data.bids.length <= MAX_CHART_POINTS then [1]
  #     else _.filter _.range(DAYS_OF_MONTH), (b) -> b % dateModulus is 0

      # Filter the data.
      chartData = chartData.groupBy(month).filter(byDate).flatten(true).filter(ifExcess)

    chartData = chartData.map(_.values).unzip().value()
    labels = chartData[0]
    bids = chartData[1]

    # Always add the last bid.
    if _.last(labels) isnt _.last(bids).date
      bids.push _.last(bids).amount
      labels.push _.last(bids).date

    data =
      labels: labels,
      datasets: [
        label: "My First dataset"
        fillColor: "rgba(151,187,205,0.2)"
        strokeColor: "rgba(151,187,205,1)"
        pointColor: "rgba(151,187,205,1)"
        pointStrokeColor: "#fff"
        pointHighlightFill: "#fff"
        pointHighlightStroke: "rgba(151,187,205,1)"
        data: bids
      ]

    options =
      scaleBeginAtZero: true
      pointDot: false

    ctx = document.getElementById("chart").getContext("2d")
    graph = new Chart(ctx).Line data, options
