bidsDeps = new Tracker.Dependency()
# One massive dependency, because it will rarely be used.
bidsContentDeps = new Tracker.Dependency()

Template.bid.rendered = ->
  @$('.datepicker').datepicker(language: i18n.getLanguage())

Template.bid.destroyed = ->
  @$('.datepicker').datepicker("remove")
  
Template.bid.helpers
  displayDate: -> 
    bidsContentDeps.depend()
    moment(@date).format("LL")
  dateInput: -> moment(@date).format(DATE_INPUT_FORMAT)
  displayAmount: -> 
    bidsContentDeps.depend()
    numeral(@amount).format("0,0.00") if @amount?

Template.bid.events
  "change input": (event, template) ->

    bids = Session.get("bids")

    $input = $(event.target)
    index = $input.closest("tr").index()
    
    bid = bids[index]
    
    if $input.hasClass("amount")
      bid.amount = Number $input.val()
    else
      bid.date = moment($input.val(), DATE_INPUT_FORMAT).toDate()

    Session.set "bids", bids

    bidsContentDeps.changed()
  
  # Bids events
  # -------------
  
Template.issue.helpers
  bids: ->
    bidsDeps.depend()
    Session.get "bids"
  
  
Template.issue.events

  "submit form.bids-form": (event, template) ->

    event.preventDefault()

    data = $(event.target).serializeJSON(useIntKeysAsArrayIndex: true).issue or {}

    withProperType = (bid) ->
      bid.date = new Date(bid.date)
      bid.amount = Number(bid.amount)
      bid
      
    empty = (bid) -> not bid.amount or not bid.date

    # Easy client side filter.
    data.bids = _(data.bids).reject(empty) if data.bids
    data.bids =_(data.bids).map(withProperType) if data.bids

    Meteor.call 'saveIssue', @_id, data, Template.handleSave

  "click .js-add-bid": (event, template) ->
    $bid = $(event.target).closest("tr")
    index = $bid.index()
    
    if $bid.hasClass("bid")
      attrs = getAttrsFromBid $bid
#       attrs.date = attrs.date.add(1, "day")
#       attrs.date = selectFreeDay attrs.date, +1, holidays[@currency or 'ca']
#       attrs.date = attrs.date.toDate()
      attrs.date = selectFreeDay(attrs.date.add(1, "day"), +1, holidays[@currency or 'ca']).toDate() if attrs.date
    else
      attrs = 
        date: new Date()
        amount: 100
    
    # Add to the end if this is the last row.
    # This won't work, as we have that extra "empty" row...
    bids = Session.get("bids")
    if $bid.siblings().length is index
      bids.push attrs
    else  
      bids.splice(index, 0, attrs)
    Session.set "bids", bids

    bidsDeps.changed()
    
  "click .js-remove-bid": (event, template) ->
    $bid = $(event.target).closest("tr")
    index = $bid.index()

    bids = Session.get("bids")
    bids.splice(index, 1)
    Session.set "bids", bids
    
    bidsDeps.changed()
    
    
    
getAttrsFromBid = ($bid) ->
  bidDate = $bid.find(".datepicker").val()

  attrs = 
    date: moment(bidDate, DATE_INPUT_FORMAT)
    amount: Number $bid.find(".amount").val()
    
  attrs
    
