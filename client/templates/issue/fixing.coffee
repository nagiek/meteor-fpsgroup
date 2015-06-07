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
  displayAmount: -> numeral(@amount).format(getFormat()) if @amount?
  displayAdjustedAmount: -> numeral(@adjustedAmount).format(getFormat()) if @adjustedAmount?

    

  # Fixing events
  # ------------
Template.issue.helpers

  hasFixings: -> isAdmin() or !@_id or @fixings and not _.isEmpty @fixings
  hasFixingTicker: -> @hasFixingTicker and "checked"
  hasFixingAdjustedAmount: -> @hasFixingAdjustedAmount and "checked"
  
  fixings: ->

    # Pause until we get our data.
    # @ won't be populated until later.
    #return if _.isEmpty @

    fixingDeps.depend()
    Session.get "fixings"

    
Template.issue.events
  
  "submit form.fixing-form": (event, template) ->

    event.preventDefault()

    data = $(event.target).serializeJSON(useIntKeysAsArrayIndex: true).issue or {}

    Meteor.call 'saveIssue', @_id, data, Template.handleSave
        
#   "change .fixings input": (event, template) ->
#     $fixing = $(event.target).closest("tr")
#     index = $fixing.index()

#     attrs = getAttrsFromFixing $fixing
#     attrs.date = attrs.date.toDate()
    
#     fixings = Session.get "fixings"
#     fixings[index] = attrs
#     Session.set "fixings", fixings
      
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