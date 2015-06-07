ETCDeps = new Tracker.Dependency()
toDateDep = new Tracker.Dependency()
fromDateDep = new Tracker.Dependency()

Template.ETC.rendered = ->
  @$('.datepicker').datepicker(language: i18n.getLanguage())

Template.ETC.destroyed = ->
  @$('.datepicker').datepicker("remove")
  
Template.ETC.helpers
  
  highlight: ->
    issuanceDate = Session.get "issuanceDate"
    # Get from parentData, not session, as it will not be in the session for non-admins.
    issuanceDate = Template.parentData(1).issuanceDate unless issuanceDate
    return "" unless issuanceDate
    daysFromIssuanceDate = moment().diff(issuanceDate, "days")
    fromDateDep.depend()
    toDateDep.depend()
    @fromNum <= daysFromIssuanceDate <= @toNum and "info"
    
  # locale output
  fromDate: -> 
    fromDateDep.depend()
    issuanceDate = Session.get "issuanceDate"
    return unless issuanceDate
    moment(issuanceDate).add(@fromNum, "days").format("LL")
  toDate: ->
    toDateDep.depend()
    issuanceDate = Session.get "issuanceDate"
    return unless issuanceDate
    moment(issuanceDate).add(@toNum, "days").format("LL")
  displayAmount: -> 
    numeral(@amount).format(i18n("common.numbers.formats.currency")) if @amount?

  # ETC events
  # ------------
Template.issue.helpers

  hasETCs: -> isAdmin() or !@_id or @ETCs and not _.isEmpty @ETCs
  
  currentETC: -> 
    return "" unless @issuanceDate
    return "" unless @etcSchedule and not _.isEmpty @etcSchedule
    daysFromIssuanceDate = moment().diff(@issuanceDate, "days")
    currentETC = _.find @etcSchedule, (etc) -> etc.fromNum <= daysFromIssuanceDate <= etc.toNum
    numeral(currentETC.amount).format(i18n("common.numbers.formats.currency")) if currentETC
  
  ETCs: ->
    ETCDeps.depend()
    Session.get "etcSchedule"

Template.issue.events
  
  "submit form.etc-form": (event, template) ->
    event.preventDefault()
    data = $(event.target).serializeJSON(useIntKeysAsArrayIndex: true).issue or {}
    Meteor.call 'saveIssue', @_id, data, Template.handleSave
  
  "change input.etc-to-num-input": (event, template) -> 
    issuanceDate = Session.get("issuanceDate")
    @toNum = $(event.target).val()
    toDateDep.changed()
    
  "change input.etc-from-num-input": (event, template) -> 
    issuanceDate = Session.get("issuanceDate")
    @fromNum = $(event.target).val()
    fromDateDep.changed()

  "click .js-set-last-etc-to-mat-date": (event, template) ->
    issuanceDate = Session.get("issuanceDate")
    maturityDate = Session.get("maturityDate")
    unless issuanceDate and maturityDate
      field = "issuanceDate" unless issuanceDate
      field = "maturityDate" unless maturityDate
      notification = 
        title: i18n("common.errors.missing") + " " + i18n("issue.fields." + field)
        type: "error"
      Template.appBody.addNotification notification
      return
    
    etcs = Session.get "etcSchedule"
    
    toNum = moment(maturityDate).diff(issuanceDate, "days")
    
    lastStep = etcs.pop() 
    lastStep.toNum = toNum
    etcs.push lastStep
    
    Session.set "etcSchedule", etcs
    
  "click .js-create-etcs": (event, template) ->
    
    totalPeriod = Session.get("etc.totalPeriod")
    steps = Session.get("etc.steps")
    maxAmount = Session.get("etc.maxAmount")
    
    unless totalPeriod and steps and maxAmount
      field = "totalPeriod" unless totalPeriod
      field = "steps" unless steps
      field = "maxAmount" unless maxAmount
      notification = 
        title: i18n("common.errors.missing") + " " + i18n("issue.fields." + field)
        type: "error"
      Template.appBody.addNotification notification
      return 
  
    etcs = []
    for i in [0..steps-1]
      etcs[i] = 
        fromNum: totalPeriod * i / steps + 1
        toNum: totalPeriod * (i + 1) / steps
        amount: (maxAmount * (steps - i) / steps).toFixed(2)
        
    # Special Case for last entry
    issuanceDate = Session.get("issuanceDate")
    maturityDate = Session.get("maturityDate")
    if issuanceDate and maturityDate
      toNum = moment(maturityDate).diff(issuanceDate, "days")
      etcs[steps] = 
        fromNum: totalPeriod + 1
        toNum: toNum
        amount: 0
    
    Session.set "etcSchedule", etcs
    
  "click .js-reset-etcs": (event, template) ->
    Session.set "etcSchedule", []
    
  "click .js-add-etc": (event, template) ->

    $ETC = $(event.target).closest("tr")
    index = $ETC.index()
    stepDays = Session.get("etc.totalPeriod") / Session.get("etc.step")
    stepAmount = Session.get("etc.maxAmount") / Session.get("etc.step")

    prevAttrs = getAttrsFromETC $ETC
    
    attrs = 
      fromNum: null
      toNum: null
      amount: null
      
    # No need to selectFreeDay here, as these days are absolute, not relative.    
    if prevAttrs.fromNum and prevAttrs.toNum 
      attrs.fromNum = attrs.fromNum + 1
      attrs.toNum = attrs.toNum + stepDays
    
    attrs.amount = prevAttrs.amount - stepAmount if prevAttrs.amount
    
    ETCs = Session.get "etcSchedule"
    if $ETC.siblings().length is index
      ETCs.push attrs
    else  
      ETCs.splice(index, 0, attrs)
    Session.set "etcSchedule", ETCs

    ETCDeps.changed()
    
  "click .js-remove-etc": (event, template) ->
    $ETC = $(event.target).closest("tr")
    index = $ETC.index()

    ETCs = Session.get "etcSchedule"
    ETCs.splice(index, 1)
    Session.set "etcSchedule", ETCs
    
    ETCDeps.changed()
    
  #   "change .etcs input": (event, template) ->
  #     $ETC = $(event.target).closest("tr")
  #     index = $ETC.index()

  #     attrs = getAttrsFromETC $ETC

  #     ETCs = Session.get "etcSchedule"
  #     ETCs[index] = attrs
  #     Session.set "etcSchedule", ETCs
        
getAttrsFromETC = ($ETC) ->
  
  attrs =
    fromNum: Number $ETC.find(".from-num-input").val()
    toNum: Number $ETC.find(".to-num-input").val()
    amount: Number $ETC.find(".amount-input").val()
  
  attrs