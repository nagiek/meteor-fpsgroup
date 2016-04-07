callDeps = new Tracker.Dependency()

Template.callDate.rendered = ->
  @$('.datepicker').datepicker(language: i18n.getLanguage())

Template.callDate.destroyed = ->
  @$('.datepicker').datepicker("remove")

Template.callDate.helpers

  # locale output
  paymentDate: -> moment(@paymentDate).format("LL")
  paymentDateInput: -> moment(@paymentDate).format(DATE_INPUT_FORMAT)
  valuationDate: -> moment(@valuationDate).format("LL")
  valuationDateInput: -> moment(@valuationDate).format(DATE_INPUT_FORMAT)
  displayThreshold: -> numeral(@threshold/100).format("0%") if @threshold?
  displayAmount: -> numeral(@amount).format("$0,0.00") if @amount?

  hasCallValDate: ->
    hasCallValDate = Session.get "hasCallValDate"
    hasCallValDate = Template.parentData(2).hasCallValDate unless hasCallValDate?
    hasCallValDate and "checked"

  hasCallThreshold: ->
    hasCallThreshold = Session.get "hasCallThreshold"
    hasCallThreshold = Template.parentData(2).hasCallThreshold unless hasCallThreshold?
    hasCallThreshold and "checked"

Template.issue.validators = Template.issue.validators or {}
Template.issue.validators.callDates = (callDates) ->

  return unless callDates

  withProperType = (callDate) ->
    callDate.paymentDate = moment(callDate.paymentDate, DATE_INPUT_FORMAT).toDate()
    callDate.valuationDate = moment(callDate.valuationDate, DATE_INPUT_FORMAT).toDate()
    # Optional
    callDate.amount = Number(callDate.amount) if callDate.amount
    callDate.threshold = Number(callDate.threshold) if callDate.threshold
    callDate

  empty = (callDate) -> not callDate.paymentDate or not callDate.valuationDate

  # Easy client side filter.
  callDates = _.chain(callDates)
    .reject(empty)
    .map(withProperType)
    .value() if callDates

  callDates

  # Call events
  # ------------
Template.issue.helpers

  hasCalls: -> isAdmin() or !@_id or @calls and not _.isEmpty @calls

Template.callsPane.helpers

  hasCallValDate: ->
    hasCallValDate = Session.get "hasCallValDate"
    hasCallValDate = Template.parentData(1).hasCallValDate unless hasCallValDate?
    hasCallValDate and "checked"

  hasCallThreshold: ->
    hasCallThreshold = Session.get "hasCallThreshold"
    hasCallThreshold = Template.parentData(1).hasCallThreshold unless hasCallThreshold?
    hasCallThreshold and "checked"

  calls: ->

    # Pause until we get our data.
    # @ won't be populated until later.
    #return if _.isEmpty @

    callDeps.depend()
    Session.get "calls"


Template.issue.events

  "click .js-add-call": (event, template) ->
    $call = $(event.target).closest("tr")
    $firstCall = $call.parent().children().first()
    index = $call.index()

    attrs = getAttrsFromCall $firstCall
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
    calls = Session.get "calls"
    if $call.siblings().length is index
      calls.push attrs
    else
      calls.splice(index, 0, attrs)
    Session.set "calls", calls

    callDeps.changed()

  "click .js-remove-call": (event, template) ->
    $call = $(event.target).closest("tr")
    index = $call.index()

    calls = Session.get "calls"
    calls.splice(index, 1)
    Session.set "calls", calls

    callDeps.changed()



getAttrsFromCall = ($call) ->

  # If this is our first call, moment will take a null value and return the current date.
  if $call.length > 0
    attrs =
      paymentDate: moment(Session.get("issuanceDate"))
    return attrs

  paymentDate = $call.find(".pay-date-input").val()
  attrs =
    paymentDate: moment(paymentDate, DATE_INPUT_FORMAT)
    amount: Number $call.find(".amount-input").val()

  # Optional attributes
  $valuationDate = $call.find(".val-date-input")
  $threshold = $call.find(".threshold-input")
  if $threshold.length > 0 then attrs.threshold = Number $threshold.val()
  if $valuationDate.length > 0 then attrs.valuationDate = moment($valuationDate.val(), DATE_INPUT_FORMAT)

  attrs
