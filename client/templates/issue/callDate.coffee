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

    

  # Call events
  # ------------
Template.issue.helpers

  hasCalls: -> isAdmin() or !@_id or @calls and not _.isEmpty @calls
  hasCallValDate: -> @hasCallValDate and "checked"
  hasCallThreshold: -> @hasCallThreshold and "checked"
  
  calls: ->

    # Pause until we get our data.
    # @ won't be populated until later.
    #return if _.isEmpty @

    callDeps.depend()
    Session.get "calls"

    
Template.issue.events
  
  "submit form.call-form": (event, template) ->

    event.preventDefault()

    data = $(event.target).serializeJSON(useIntKeysAsArrayIndex: true).issue or {}

    Meteor.call 'saveIssue', @_id, data, Template.handleSave
    
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