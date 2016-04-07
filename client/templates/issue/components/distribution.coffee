distrDeps = new Tracker.Dependency()

Template.distribution.rendered = ->
  @$('.datepicker').datepicker(language: i18n.getLanguage())

Template.distribution.destroyed = ->
  @$('.datepicker').datepicker("remove")

Template.distribution.helpers

  # locale output
  paymentDate: -> moment(@paymentDate).format("LL")
  paymentDateInput: -> moment(@paymentDate).format(DATE_INPUT_FORMAT)
  valuationDate: -> moment(@valuationDate).format("LL")
  valuationDateInput: -> moment(@valuationDate).format(DATE_INPUT_FORMAT)
  displayThreshold: -> numeral(@threshold/100).format("0%") if @threshold? and not isNaN(@threshold)
  displayAmount: -> numeral(@amount).format("0,0.00") if @amount? and not isNaN(@amount)

  hasDistrValDate: ->
    hasDistrValDate = Session.get "hasDistrValDate"
    hasDistrValDate = Template.parentData(2).hasDistrValDate unless hasDistrValDate?
    hasDistrValDate and "checked"

  hasDistrThreshold: ->
    hasDistrValDate = Session.get "hasDistrThreshold"
    hasDistrValDate = Template.parentData(2).hasDistrThreshold unless hasDistrThreshold?
    hasDistrValDate and "checked"

  # Distr events
  # ------------
Template.issue.helpers

  hasDistributions: -> isAdmin() or !@_id or @distributions and not _.isEmpty @distributions

Template.distributionsPane.helpers

  hasDistrValDate: ->
    hasDistrValDate = Session.get "hasDistrValDate"
    hasDistrValDate = Template.parentData(1).hasDistrValDate unless hasDistrValDate?
    hasDistrValDate and "checked"

  hasDistrThreshold: ->
    hasDistrThreshold = Session.get "hasDistrThreshold"
    hasDistrThreshold = Template.parentData(1).hasDistrThreshold unless hasDistrThreshold?
    hasDistrThreshold and "checked"

  distributions: ->

    # Pause until we get our data.
    # @ won't be populated until later.
    #return if _.isEmpty @

    distrDeps.depend()
    Session.get "distributions"

Template.issue.validators = Template.issue.validators or {}
Template.issue.validators.distributions = (distrs)->

  return unless distrs

  withProperType = (distr) ->
    distr.paymentDate = moment(distr.paymentDate, DATE_INPUT_FORMAT).toDate()
    distr.amount = Number(distr.amount)
    # Optional
    distr.threshold = Number(distr.threshold) if distr.threshold
    distr.valuationDate = moment(distr.valuationDate, DATE_INPUT_FORMAT).toDate() if distr.valuationDate
    distr

  empty = (distr) -> not distr.paymentDate or not distr.amount

  # Easy client side filter.
  distrs = _.chain(distrs)
    .reject(empty)
    .map(withProperType)
    .value() if distrs

  distrs


Template.issue.events

#   "change .distributions input": (event, template) ->
#     $distr = $(event.target).closest("tr")
#     index = $distr.index()

#     attrs = getAttrsFromDistr $distr
#     if attrs.paymentDate then attrs.paymentDate.toDate()
#     if attrs.valuationDate then attrs.valuationDate.toDate()

#     distributions = Session.get "distributions"
#     distributions[index] = attrs
#     Session.set "distributions", distributions

  "click .js-add-distr": (event, template) ->
    $distr = $(event.target).closest("tr")
    $firstDistr = $distr.parent().children().first()
    index = $distr.index()

    attrs = getAttrsFromDistr $firstDistr

    if attrs.paymentDate
      attrs.paymentDate = attrs.paymentDate.add(6 * index, "months")
      attrs.paymentDate = selectFreeDay attrs.paymentDate, +1, holidays[@currency or 'ca']
      attrs.paymentDate = attrs.paymentDate.toDate()
    if attrs.valuationDate
      attrs.valuationDate = attrs.valuationDate.add(6 * index, "months")
      attrs.valuationDate = selectFreeDay attrs.valuationDate, +1, holidays[@currency or 'ca']
      attrs.valuationDate = attrs.valuationDate.toDate()

    # Add to the end if this is the last row.
    # This won't work, as we have that extra "empty" row...
    distributions = Session.get "distributions"
    if $distr.siblings().length is index
      distributions.push attrs
    else
      distributions.splice(index, 0, attrs)

    Session.set "distributions", distributions

    distrDeps.changed()

  "click .js-remove-distr": (event, template) ->
    $distr = $(event.target).closest("tr")
    index = $distr.index()

    distributions = Session.get "distributions"
    distributions.splice(index, 1)
    Session.set "distributions", distributions

    distrDeps.changed()



getAttrsFromDistr = ($distr) ->

  # If this is our first distr, moment will take a null value and return the current date.
  if $distr.length > 0
    attrs =
      paymentDate: moment(Session.get("issuanceDate"))
    return attrs

  # If this is not our first one
  paymentDate = $distr.find(".pay-date-input").val()
  attrs =
    paymentDate: moment(paymentDate, DATE_INPUT_FORMAT)
    amount: Number $distr.find(".amount-input").val()

  # Optional attributes
  $valuationDate = $distr.find(".val-date-input")
  $threshold = $distr.find(".threshold-input")
  if $threshold.length > 0 then attrs.threshold = Number $threshold.val()
  if $valuationDate.length > 0 then attrs.valuationDate = moment($valuationDate.val(), DATE_INPUT_FORMAT)

  attrs
