fixingDeps = new Tracker.Dependency()

getFormat = -> if Session.equals("hasFixingsInPercent", true) then "0%" else "0"

Template.fixing.rendered = ->
  @$('.datepicker').datepicker(language: i18n.getLanguage())

Template.fixing.destroyed = ->
  @$('.datepicker').datepicker("remove")

Template.fixing.helpers

  # locale output
  date: -> moment(@paymentDate).format("LL")
  dateInput: -> moment(@paymentDate).format(DATE_INPUT_FORMAT)
  displayTicker: -> tickerName @ticker
  displayAmount: -> numeral(@amount).format(getFormat()) if @amount? and not isNaN(@amount)
  displayAdjustedAmount: -> numeral(@adjustedAmount).format(getFormat()) if @adjustedAmount? and not isNaN(@adjustedAmount)

  hasFixingTicker: ->
    hasFixingTicker = Session.get "hasFixingTicker"
    hasFixingTicker = Template.parentData(2).hasFixingTicker unless hasFixingTicker?
    hasFixingTicker and "checked"

  hasFixingAmount: ->
    hasFixingAmount = Session.get "hasFixingAmount"
    hasFixingAmount = Template.parentData(2).hasFixingAmount unless hasFixingAmount?
    hasFixingAmount and "checked"

  hasFixingAdjustedAmount: ->
    hasFixingAdjustedAmount = Session.get "hasFixingAdjustedAmount"
    hasFixingAdjustedAmount = Template.parentData(2).hasFixingAdjustedAmount unless hasFixingAdjustedAmount?
    hasFixingAdjustedAmount and "checked"

Template.issue.validators = Template.issue.validators or {}
Template.issue.validators.fixings = (fixings) ->

    return unless fixings

    withProperType = (fixing) ->
      distr.paymentDate = moment(fixing.paymentDate, DATE_INPUT_FORMAT).toDate()
      # Optional
      distr.amount = Number(fixing.amount) if fixing.amount
      distr.adjustedAmount = Number(fixing.adjustedAmount) if fixing.adjustedAmount
      distr

    empty = (fixing) -> not fixing.paymentDate

    # Easy client side filter.
    fixings = _.chain(fixings)
      .reject(empty)
      .map(withProperType)
      .value() if fixings

    fixings

  # Fixing events
  # ------------
Template.issue.helpers

  hasFixings: -> isAdmin() or !@_id or @fixings and not _.isEmpty @fixings

Template.fixingsPane.helpers

  hasFixingTicker: ->
    hasFixingTicker = Session.get "hasFixingTicker"
    hasFixingTicker = Template.parentData(1).hasFixingTicker unless hasFixingTicker?
    hasFixingTicker and "checked"

  hasFixingAmount: ->
    hasFixingAmount = Session.get "hasFixingAmount"
    hasFixingAmount = Template.parentData(1).hasFixingAmount unless hasFixingAmount?
    hasFixingAmount and "checked"

  hasFixingAdjustedAmount: ->
    hasFixingAdjustedAmount = Session.get "hasFixingAdjustedAmount"
    hasFixingAdjustedAmount = Template.parentData(1).hasFixingAdjustedAmount unless hasFixingAdjustedAmount?
    hasFixingAdjustedAmount and "checked"

  fixings: ->

    # Pause until we get our data.
    # @ won't be populated until later.
    #return if _.isEmpty @

    fixingDeps.depend()
    Session.get "fixings"


Template.issue.events

  "click .js-add-fixing": (event, template) ->
    $fixing = $(event.target).closest("tr")
    $firstFixing = $fixing.parent().children().first()
    index = $fixing.index()

    attrs = getAttrsFromFixing $firstFixing
    if attrs.date
      attrs.date = attrs.date.add(index, "years")
      attrs.date = selectFreeDay attrs.date, +1, holidays[@currency or 'ca']
      attrs.date = attrs.date.toDate()

    # Add to the end if this is the last row.
    # This won't work, as we have that extra "empty" row...
    fixings = Session.get "fixings"
    if $fixing.siblings().length is index
      fixings.push attrs
    else
      fixings.splice(index, 0, attrs)
    Session.set "fixings", fixings

    fixingDeps.changed()

  "click .js-remove-fixing": (event, template) ->
    $fixing = $(event.target).closest("tr")
    index = $fixing.index()

    fixings = Session.get "fixings"
    fixings.splice(index, 1)
    Session.set "fixings", fixings

    fixingDeps.changed()



getAttrsFromFixing = ($fixing) ->
  date = $fixing.find(".date-input").val()
  attrs =
    date: moment(date, DATE_INPUT_FORMAT)

  # Optional attributes
  $amount = $fixing.find(".amount-input")
  $adjustedAmount = $fixing.find(".adjusted-amount-input")
  if $amount.length > 0 then attrs.amount = Number $amount.val()
  if $adjustedAmount.length > 0 then attrs.adjustedAmount = Number $adjustedAmount.val()

  attrs
