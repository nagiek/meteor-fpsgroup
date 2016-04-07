# Object to handle arrays.
portfolioDeps = new Tracker.Dependency()
tickerDeps = new Tracker.Dependency()

# Objects to handle the portfolio calculations
returnDeps = new Tracker.Dependency()
returnModifiersDeps = new Tracker.Dependency()
modifiedReturnDeps = new Tracker.Dependency()

# Array object to handle the per-row calculations
tickerReturnsDeps = []
# Array object to handle the ticker and market data
# tickerNamesDeps = []

# Cached copy of commonly accessed Note properties
curr = null
_id = null

# Boolean Reactive Vars
showTickerWeightVar = new ReactiveVar()
showTickerRankingVar = new ReactiveVar()
hasFXExposureVar = new ReactiveVar()
hasLocalReturnModifierVar = new ReactiveVar()

# Reactive Var Environments
noteCurrencyFn = null
showTickerWeightFn = null
showTickerRankingFn = null
hasFXExposureFn = null
hasLocalReturnModifierFn = null

# Underscore is 1.5.2 in Meteor, but we need the 1.7.x functions.
# Specifically, we need them here because we work with _.memoize.
_memoize = (func, hasher) ->

  memoize = (key) ->
    cache = memoize.cache
    address = if hasher then hasher.apply(this, arguments) else key
    if !_.has(cache, address)
      cache[address] = func.apply(this, arguments)
    cache[address]

  memoize.cache = {}
  memoize

portfolioDefaults =
  tickers: []
  settings:
    tickerFX: "none"
    barrierType: "none"
    portfolioReturn: "average"
    modifiedPortfolioReturn: "none"
    participationThreshold: "ATM"
    showTickerWeight: false
    showTickerRanking: false
    hasFXExposure: false

Template.ticker.helpers

  # locale output
  displayBloomberg: ->
#     tickerNamesDeps[@index].depend()
    pIndex = Template.parentData(1).index
    bloomberg = Session.get "portfolios.#{pIndex}.tickers.#{@index}.bloomberg"
    bloomberg = @bloomberg unless bloomberg?
    tickerName bloomberg
  displayWeight: ->
    pIndex = Template.parentData(1).index
    weight = Session.get "portfolios.#{pIndex}.tickers.#{@index}.weight"
    weight = @weight unless weight?
    return "" unless weight?
    numeral(weight).format("0%")
  displayInitialPrice: ->
    pIndex = Template.parentData(1).index
    initialPrice = Session.get "portfolios.#{pIndex}.tickers.#{@index}.initialPrice"
    initialPrice = @initialPrice unless initialPrice?
    return "" unless initialPrice?
    numeral(initialPrice).format("0,0.00")
  displayInitialFX: ->
    pIndex = Template.parentData(1).index
    initialFX = Session.get "portfolios.#{pIndex}.tickers.#{@index}.initialFX"
    initialFX = @initialFX unless initialFX?
    return "" unless initialFX?
    numeral(initialFX).format("0,0.0000")
  displayCurrentPrice: ->
#     tickerNamesDeps[@index].depend()
    pIndex = Template.parentData(1).index
    bloomberg = Session.get "portfolios.#{pIndex}.tickers.#{@index}.bloomberg"
    price = currentPrice(bloomberg)
    return "" unless price?
    numeral(price).format("0,0.00")
  displayCurrentFX: ->
#     tickerNamesDeps[@index].depend()
    pIndex = Template.parentData(1).index
    bloomberg = Session.get "portfolios.#{pIndex}.tickers.#{@index}.bloomberg"
    FX = currentFX(bloomberg, curr)
    return "" unless FX?
    numeral(FX).format("0,0.0000")

  # Calculated stuff
  displayReturn: ->
    tickerReturnsDeps[@index].depend()
    returns = getReturns(_id + "." + Template.parentData(1).index)
    numReturn = returns[@index]
    return "" unless numReturn
    numeral(numReturn).format("0.00%")
  displayModifiedReturn: ->
    tickerReturnsDeps[@index].depend()
    returnModifiersDeps.depend()
    returns = getModifiedReturns(_id + "." + Template.parentData(1).index)
    numReturn = returns[@index]
    return "" unless numReturn
    numeral(numReturn).format("0.00%")
  ranking: ->
    tickerDeps.depend()
    tickerReturnsDeps[@index].depend()
    returnDeps.depend()
    rankings = getRankings(_id + "." + Template.parentData(1).index)
    rankings[@index]

  hasFXExposure: ->
    pIndex = Template.parentData(1).index
    # Don't call var "hasFXExposure" because it's a global name
    FXExposure = Session.get "portfolios.#{pIndex}.tickers.#{@index}.hasFXExposure"
    FXExposure = @hasFXExposure unless FXExposure?
    FXExposure and "checked"

  parentHasFXExposure: ->
    parentHasFXExposure = Session.get "portfolios.#{@index}.settings.hasFXExposure"
    parentHasFXExposure = Template.parentData(1).settings.hasFXExposure unless parentHasFXExposure?
    parentHasFXExposure

  parentShowsTickerWeight: ->
    pIndex = Template.parentData(1).index
    parentShowsTickerWeight = Session.get "portfolios.#{pIndex}.settings.showTickerWeight"
    parentShowsTickerWeight = Template.parentData(1).settings.showTickerWeight unless parentShowsTickerWeight?
    parentShowsTickerWeight and "checked"

  parentShowsTickerRanking: ->
    pIndex = Template.parentData(1).index
    parentShowsTickerRanking = Session.get "portfolios.#{pIndex}.settings.showTickerRanking"
    parentShowsTickerRanking = Template.parentData(1).settings.showTickerRanking unless parentShowsTickerRanking?
    parentShowsTickerRanking and "checked"

  parentHasLocalReturnModifier: ->
    pIndex = Template.parentData(1).index
    parentHasLocalReturnModifier = Session.get("portfolios.#{pIndex}.localMax") or
                             Session.get("portfolios.#{pIndex}.localMin") or
                             Session.get("portfolios.#{pIndex}.assigned")
    parentHasLocalReturnModifier = Template.parentData(1).localMax or
                             Template.parentData(1).localMin or
                             Template.parentData(1).assigned unless parentHasLocalReturnModifier?
    parentHasLocalReturnModifier

  # Conditions
  isAdmin: -> isAdmin()

Template.ticker.events
  "change input": (event, template) ->

    input = $(event.target)
    type = input.attr("type")
    name = input.attr("name")
    value = input.val()
    value = Number value if type is "number"
    value = event.target.checked if type is "checkbox"

    pIndex = Template.parentData(1).index

    keyString = Template.extractKey name
    keys = keyString.split "."
    # Take the last key in the array.
    key = keys.pop()
    @[key] = value

    # Invalidate weight cache.
    if key is 'weight'
      if value then getWeights.cache["#{_id}.#{pIndex}"][@index] = value
      # Could just delete the index, but what if it's the last one?
      else delete getWeights.cache["#{_id}.#{pIndex}"]

    # Check if we have made a global change to the portfolio's FX
    if key is 'hasFXExposure'
      setting = Session.get "portfolios.#{pIndex}.settings.tickerFX"

      if setting is "none" and value then setting = "individual"
      if setting is "all" and not value then setting = "individual"

      # Check this after after first check, to see if we can go all the way.
      if setting is "individual"
        $portfolio = $(event.target).closest(".portfolio")
        hasAllChecked = $portfolio.find(".js-toggle-ticker-fx-exposure:not(:checked)").length is 0
        hasNoneChecked = $portfolio.find(".js-toggle-ticker-fx-exposure:checked").length is 0
        if hasAllChecked then setting = "all"
        if hasNoneChecked then setting = "none"

      Template.parentData(1).settings.tickerFX = setting
      Session.set "portfolios.#{pIndex}.settings.tickerFX", setting

      hasFXExposure = if setting is "none" then false else true
      Template.parentData(1).settings.hasFXExposure = hasFXExposure
      Session.set "portfolios.#{pIndex}.settings.hasFXExposure", hasFXExposure

    # Store active variables
    Session.set "portfolios.#{pIndex}.tickers.#{@index}.#{key}", value

#     # Store everything related to the ticker onto the array variable.
#     tickers = Session.get "portfolios.#{pIndex}.tickers"
#     tickers[@index] = @
#     Session.set "portfolios.#{pIndex}.tickers", tickers

    # Anything we've changed will affect the return.
    # ticker = assembleTicker(pIndex, @index)
    numReturn = getReturn(@)
    getReturns.cache["#{_id}.#{pIndex}"][@index] = numReturn
    # We might not necessarily have a getModifiedReturns.cache yet,
    # if we don't have a local-return modifier.
    getModifiedReturns.cache["#{_id}.#{pIndex}"][@index] = getModifiedReturn(numReturn, @index) if getModifiedReturns.cache["#{_id}.#{pIndex}"]
    delete getRankings.cache["#{_id}.#{pIndex}"]
    tickerReturnsDeps[@index].changed()
    returnDeps.changed()
    modifiedReturnDeps.changed()
    # Get market data for new Bloomberg Ticker.
#     tickerNamesDeps[@index].changed() if key is 'bloomberg'

Template.portfolio.events
  "change .return-modifier": (event, template) ->

    input = $(event.target)
    type = input.attr("type")
    name = input.attr("name")
    value = input.val()
    value = Number value if type is "number"
    value = event.target.checked if type is "checkbox"

    keyString = Template.extractKey name
    keys = keyString.split "."
    # Take the last key in the array.
    key = keys.pop()
    @[key] = value
    Session.set keyString, value

    # Anything we've changed will affect the return.
    if input.hasClass("local-return-modifier")
      _.each tickerReturnsDeps, (tickerReturnsDep) -> tickerReturnsDep.changed()
      delete getModifiedReturns.cache["#{_id}.#{@index}"]
      returnDeps.changed()
      returnModifiersDeps.changed()
    modifiedReturnDeps.changed()


  "click .js-toggle-FX": (event, template) ->
    setting = Session.get "portfolios.#{@index}.settings.tickerFX"
    newSetting = switch setting
      when "none" then "all"
      when "all" then "individual"
      when "individual" then "none"

    @settings.tickerFX = newSetting
    Session.set "portfolios.#{@index}.settings.tickerFX", newSetting
    $(event.target).next().val(newSetting)

    @hasFXExposure = if newSetting is "none" then false else true
    Session.set "portfolios.#{@index}.settings.hasFXExposure", @hasFXExposure

    if newSetting is "none" or newSetting is "all"
      tickers = Session.get "portfolios.#{@index}.tickers"
      _.each tickers, (ticker, index) => Session.set "portfolios.#{@index}.tickers.#{index}.hasFXExposure", @hasFXExposure
      _.each tickerReturnsDeps, (tickerReturnsDep) -> tickerReturnsDep.changed()
      returnDeps.changed()
      modifiedReturnDeps.changed()

  "click .js-toggle-barrier-type": (event, template) ->
    setting = Session.get "portfolios.#{@index}.settings.barrierType"
    newSetting = switch setting
      when "none" then "maturity"
      when "maturity" then "daily"
      when "daily" then "buffer"
      when "buffer" then "twinWin"
      when "twinWin" then "partial"
      when "partial" then "none"

    @settings.barrierType = newSetting
    Session.set "portfolios.#{@index}.settings.barrierType", newSetting
    $(event.target).next().val(newSetting)

  "click .js-toggle-participation-threshold": (event, template) ->
    setting = Session.get "portfolios.#{@index}.settings.participationThreshold"

    newSetting = switch setting
      when "ATM" then "OTM"
      when "OTM" then "ATM"

    @settings.participationThreshold = newSetting
    Session.set "portfolios.#{@index}.settings.participationThreshold", newSetting
    $(event.target).next().val(newSetting)

  "click .js-toggle-portfolio-return-setting": (event, template) ->
    setting = Session.get "portfolios.#{@index}.settings.portfolioReturn"

    newSetting = switch setting
      when "none" then "average"
      when "average" then "min"
      when "min" then "max"
      when "max" then "addition"
      when "addition" then "geometric"
      when "geometric" then "none"

    @settings.portfolioReturn = newSetting
    Session.set "portfolios.#{@index}.settings.portfolioReturn", newSetting
    $(event.target).next().val(newSetting)

  "click .js-toggle-modified-portfolio-return-setting": (event, template) ->
    setting = Session.get "portfolios.#{@index}.settings.modifiedPortfolioReturn"

    newSetting = switch setting
      when "none" then "average"
      when "average" then "min"
      when "min" then "max"
      when "max" then "addition"
      when "addition" then "geometric"
      when "geometric" then "none"

    @settings.modifiedPortfolioReturn = newSetting
    Session.set "portfolios.#{@index}.settings.modifiedPortfolioReturn", newSetting
    $(event.target).next().val(newSetting)

  "click .js-add-ticker": (event, template) ->
    $ticker = $(event.target).closest("tr")
    $portfolio = $ticker.closest(".portfolio")
    index = $ticker.index()

    # Use pIndex, in case we call this from the `empty` state.
    pIndex = $portfolio.index()

    # Add to the end if this is the last row.
    # This won't work, as we have that extra "empty" row...
    tickers = Session.get "portfolios.#{pIndex}.tickers"
    if $ticker.siblings().length is index
      tickers.push {}
    else
      tickers.splice(index, 0, {})
      # Redo calculations, as index has changed
      _.each tickers, (ticker, index) ->
        ticker.index = index
        ticker.prefix = "portfolios.#{pIndex}.tickers.#{index}."

    # Invalidate caches.
    delete getReturns.cache["#{_id}.#{pIndex}"]
    delete getRankings.cache["#{_id}.#{pIndex}"]
    getReturns("#{_id}.#{pIndex}", tickers)
    getRankings("#{_id}.#{pIndex}")

    # Invalidate weight cache if necessary.
    if tickers and not Session.equals("portfolios.#{pIndex}.settings.showTickerWeight", true)
      delete getWeights.cache["#{_id}.#{pIndex}"]
      getWeights("#{_id}.#{pIndex}", tickers)

    @tickers = tickers
    Session.set "portfolios.#{pIndex}.tickers", tickers

    tickerDeps.changed()


  "click .js-remove-ticker": (event, template) ->
    $ticker = $(event.target).closest("tr")
    $portfolio = $ticker.closest(".portfolio")
    index = $ticker.index()

    # Use pIndex, in case we call this from the `empty` state.
    pIndex = $portfolio.index()

    tickers = Session.get "portfolios.#{pIndex}.tickers"
    tickers.splice(index, 1)

    unless $ticker.siblings().length is index
      # Redo calculations, as index has changed
      _.each tickers, (ticker, index) ->
        ticker.index = index
        ticker.prefix = "portfolios.#{pIndex}.tickers.#{index}."

    # Invalidate caches.
    delete getReturns.cache["#{_id}.#{pIndex}"]
    delete getRankings.cache["#{_id}.#{pIndex}"]
    getReturns("#{_id}.#{pIndex}", tickers)
    getRankings("#{_id}.#{pIndex}")

    # Invalidate weight cache if necessary.
    if tickers and not Session.equals("portfolios.#{pIndex}.settings.showTickerWeight", true)
      delete getWeights.cache["#{_id}.#{pIndex}"]
      getWeights("#{_id}.#{pIndex}", tickers)

    @tickers = tickers
    Session.set "portfolios.#{pIndex}.tickers", tickers

    tickerDeps.changed()


Template.portfolio.helpers

  tickers: ->
    tickerDeps.depend()
    Session.get "portfolios.#{@index}.tickers"

  # Footer columns.
  "Col1": ->
    col = 3
    col += 1 if showTickerWeightVar.get()
    col += 2 if hasFXExposureVar.get()
    # If we have a local return, we will want to shift everything over by one.
    col
  "Col2": ->
    col = 1
    col += 1 if showTickerWeightVar.get()
    col += 1 if hasLocalReturnModifierVar.get()
    col
  # Divide return columns.
  "Col2a": -> if hasLocalReturnModifierVar.get() then 1 else 2
  "Col2b": -> if showTickerRankingVar.get() then 2 else 1

  hasFooter: ->
    hasFooter = not Session.equals("portfolios.#{@index}.settings.portfolioReturn", "none") or
                not Session.equals("portfolios.#{@index}.settings.modifiedPortfolioReturn", "none")
    hasFooter = @settings.portfolioReturn isnt "none" or
                @settings.modifiedPortfolioReturn isnt "none" unless hasFooter?
    hasFooter

  hasMoreThanOneAsset: ->
    tickers = Session.get("portfolios.#{@index}.tickers")
    tickers = @tickers unless tickers?
    tickers? and tickers.length > 1

  hasParticipationFactor: ->
    hasParticipationFactor = Session.get("portfolios.#{@index}.participationFactor")
    hasParticipationFactor = @participationFactor unless hasParticipationFactor?
    hasParticipationFactor isnt 1 and hasParticipationFactor > 0.1

  hasMaximum: ->
    hasMaximum = Session.get("portfolios.#{@index}.maximum")
    hasMaximum = @maximum unless hasMaximum?
    !!hasMaximum

  # Set a reactive data source.
  parentHasFXExposure: ->
    parentHasFXExposure = Session.get "hasFXExposure"
    parentHasFXExposure = Template.parentData(1).hasFXExposure unless hasFXExposure?
    parentHasFXExposure

  displayTickerFXSetting: ->
    setting = Session.get "portfolios.#{@index}.settings.tickerFX"
    i18n("issue.fx." + setting)

  displayMaximum: ->
    maximum = Session.get "portfolios.#{@index}.maximum"
    maximum = @maximum unless maximum?
    format = if maximum and maximum is maximum.toFixed(2) then "0%" else "0.00%"
    numeral(maximum).format(format) if maximum

  displayParticipationFactor: ->
    participationFactor = Session.get "portfolios.#{@index}.participationFactor"
    participationFactor = @participationFactor unless participationFactor?
    format = if participationFactor and participationFactor is participationFactor.toFixed(2) then "0%" else "0.00%"
    numeral(participationFactor).format(format) if participationFactor

  displayMinimum: ->
    minimum = Session.get "portfolios.#{@index}.minimum"
    minimum = @minimum unless minimum?
    format = if minimum and minimum is minimum.toFixed(2) then "0%" else "0.00%"
    numeral(minimum).format(format) if minimum

  displayBonusReturn: ->
    bonusReturn = Session.get "portfolios.#{@index}.bonusReturn"
    bonusReturn = @bonusReturn unless bonusReturn?
    format = if bonusReturn and bonusReturn is barrierAmount.toFixed(2) then "0%" else "0.00%"
    numeral(bonusReturn).format(format) if bonusReturn

  displayBarrierAmount: ->
    barrierAmount = Session.get "portfolios.#{@index}.barrierAmount"
    barrierAmount = @barrierAmount unless barrierAmount?
    format = if barrierAmount and barrierAmount is barrierAmount.toFixed(2) then "0%" else "0.00%"
    numeral(barrierAmount).format(format) if barrierAmount

  displayBarrierType: ->
    barrierType = Session.get "portfolios.#{@index}.settings.barrierType"
    barrierType = @settings.barrierType unless barrierType?
    i18n("issue.barriers." + barrierType)

  displayParticipationThreshold: ->
    participationThreshold = Session.get "portfolios.#{@index}.settings.participationThreshold"
    participationThreshold = @settings.participationThreshold unless participationThreshold?
    i18n("issue.participation." + participationThreshold)

  displayPortfolioReturnSetting: ->
    setting = Session.get "portfolios.#{@index}.settings.portfolioReturn"
    i18n("issue.returns.#{setting}")

  portfolioReturnIsPositive: ->
    returnDeps.depend()
    portfolioReturn = getPortfolioReturn.call(this)
    portfolioReturn > 0

  displayPortfolioReturn: ->
    returnDeps.depend()
    portfolioReturn = getPortfolioReturn.call(this)
    return "" if portfolioReturn is ""
    numeral(portfolioReturn).format("0.00%")

  displayMultipliedPortfolioReturn: ->
    returnDeps.depend()
    portfolioReturn = getPortfolioReturn.call(this)
    return "" if portfolioReturn is ""
    participationFactor = Session.get("portfolios.#{@index}.participationFactor")
    participationFactor = @participationFactor unless participationFactor?
    numeral(portfolioReturn * participationFactor).format("0.00%")

  displayModifiedPortfolioReturnSetting: ->
    setting = Session.get "portfolios.#{@index}.settings.modifiedPortfolioReturn"
    i18n("issue.returns.#{setting}")

  displayModifiedPortfolioReturn: ->
    modifiedReturnDeps.depend()
    setting = Session.get("portfolios.#{@index}.settings.modifiedPortfolioReturn")
    return "" if setting is "none"
    returns = getModifiedReturns("#{_id}.#{@index}")
    if returns.length is 0 then return null
    switch setting
      when "average"
        sumReturn = 0
        tickers = Session.get("portfolios.#{@index}.tickers") or @tickers
        weights = getWeights("#{_id}.#{@index}", tickers)
        _.each returns, (numReturn, index) -> sumReturn += numReturn * weights[index] if numReturn? and weights[index]?
      when "min"
        _.each returns, (numReturn) ->
          sumReturn = sumReturn or numReturn
          sumReturn = Math.min(sumReturn, numReturn) if numReturn?
      when "max"
        _.each returns, (numReturn) ->
          sumReturn = sumReturn or numReturn
          sumReturn = Math.max(sumReturn, numReturn) if numReturn?
      when "addition"
        sumReturn = 0
        _.each returns, (numReturn) -> sumReturn += numReturn if numReturn?
      when "geometric"
        sumReturn = 1
        _.each returns, (numReturn) -> sumReturn *= (1 + numReturn) if numReturn?
        sumReturn -= 1
    numeral(sumReturn).format("0.00%")

  hasFXExposure: -> hasFXExposureVar.get()
  showTickerWeight: -> showTickerWeightVar.get()
  showTickerRanking: -> showTickerRankingVar.get()
  hasLocalReturnModifier: -> hasLocalReturnModifierVar.get()
  showBarrier: -> not Session.equals "portfolios.#{@index}.settings.barrierType", "none"
  isAdmin: -> isAdmin()


# Must be invoked using .call(this)
getPortfolioReturn = ->
  setting = Session.get("portfolios.#{@index}.settings.portfolioReturn")
  return "" if setting is "none"
  returns = getReturns("#{_id}.#{@index}")
  if returns.length is 0 then return null
  switch setting
    when "average"
      sumReturn = 0
      tickers = Session.get("portfolios.#{@index}.tickers") or @tickers
      weights = getWeights("#{_id}.#{@index}", tickers)
      _.each returns, (numReturn, index) -> sumReturn += numReturn * weights[index] if numReturn? and weights[index]?
    when "min"
      _.each returns, (numReturn) ->
        sumReturn = sumReturn or numReturn
        sumReturn = Math.min(sumReturn, numReturn) if numReturn?
    when "max"
      _.each returns, (numReturn) ->
        sumReturn = sumReturn or numReturn
        sumReturn = Math.max(sumReturn, numReturn) if numReturn?
    when "addition"
      sumReturn = 0
      _.each returns, (numReturn) -> sumReturn += numReturn if numReturn?
    when "geometric"
      sumReturn = 1
      _.each returns, (numReturn) -> sumReturn *= (1 + numReturn) if numReturn?
      sumReturn -= 1
  sumReturn

getReturn = (ticker) ->
  price = currentPrice(ticker.bloomberg)
  FX = currentFX(ticker.bloomberg, curr)
  return null unless ticker.initialPrice and price
  return null if ticker.hasFXExposure? and not ticker.initialFX and currentFX
  numReturn = if ticker.hasFXExposure
    (FX * price) / (ticker.initialFX * ticker.initialPrice) - 1
  else price / ticker.initialPrice - 1
  numReturn

getModifiedReturn = (numReturn, index) ->
  return "" unless numReturn

  pIndex = Template.parentData(1).index

  # Vars not set in standard way.
  localMax = Session.get("portfolios.#{pIndex}.localMax") or Template.parentData(1).localMax
  localMin = Session.get("portfolios.#{pIndex}.localMin") or Template.parentData(1).localMin
  assigned = Session.get("portfolios.#{pIndex}.assigned") or Template.parentData(1).assigned

  if localMax then numReturn = Math.min(numReturn, localMax)
  if localMin then numReturn = Math.max(numReturn, localMin)
  if assigned
    rankings = getRankings("#{_id}.#{pIndex}")
    if rankings[index] < 8 then numReturn = assignedReturn("#{_id}.#{pIndex}")
  numReturn

# cache, because it may be long.
assignedReturn = _memoize (_id) ->

  pIndex = Template.parentData(1).index
  assigned = Session.get("portfolios.#{pIndex}.assigned") or Template.parentData(1).assigned
  issuanceDate = Session.get("issuanceDate") or Template.parentData(2).issuanceDate
  issuanceDate = Session.get("maturityDate") or Template.parentData(2).maturityDate

  today = new Date()
  if maturityDate >= today then return assigned
  if issuanceDate < today then return 0

  daysEllapsed = moment(today).diff(issuanceDate)
  daysTotal = moment(maturityDate).diff(issuanceDate)
  assigned * daysEllapsed / daysTotal

# Because we will likely call this first from a portfolio context,
# we can't use Template.parentData() without un-future-proofing.
# Therefore, we pass in the tickers directly.
getWeights = _memoize (address, tickers) ->
  weights = []
  weight = 1 / tickers.length
  _.each tickers, (ticker, index) -> weights[index] = if ticker.weight then ticker.weight else weight
  weights

# cache, because it may be long.
getReturns = _memoize (address, tickers) ->
  returns = []
  tickers = Template.parentData(1).tickers unless tickers
  _.each tickers, (ticker, index) -> returns[index] = getReturn(ticker)
  returns

# don't cache, because we may change
getModifiedReturns =  _memoize (address) ->
  returns = getReturns(address)
  modifiedReturns = {}
  _.each returns, (numReturn, index) -> modifiedReturns[index] = getModifiedReturn(numReturn, index)
  modifiedReturns

# cache, because it may be long.
getRankings = _memoize (address) ->
  returns = getReturns(address)
  rankArray = []
  rankings = {}
  # convert object to an array, and sort the result.
  _.each returns, (v, k) -> rankArray.push index: k, numReturn: v
  # Sort in descending order (highest first)
  rankArray.sort((a,b) -> b.numReturn - a.numReturn)
  # now get a workable object with the rank.
  _.each rankArray, (ticker, ranking) -> rankings[ticker.index] = ranking + 1
  rankings

# assembleTicker = (pIndex, index) ->
#   ticker = {}
#   _.each TickersSchema, (v, k) -> ticker[k] = Session.get "portfolios.#{pIndex}.tickers.#{index}.#{k}"
#   ticker

Template.portfolio.created = ->
  @data = {} unless @data
  _.defaults @data, portfolioDefaults
  @data.prefix = "portfolios.#{@data.index}."

  _id = Template.parentData(1)._id

  # Get index from @data.index at this point.
  _.each PortfoliosSchema, (v, k) => Template.convertToSession(v, k, @data, "portfolios.#{@data.index}")

  # Create an environment for the note currency, in case it changes.
  noteCurrencyFn = Tracker.autorun =>
    curr = Session.get("curr")
    curr = @data.curr unless curr?
    curr = "CAD" unless curr?
    curr

  # Note the output names are reduced. This is because having
  #   `showTickerWeight = ...` will actually overwrite the function.
  # Don't want to debug THAT again...
  showTickerWeightFn = Tracker.autorun =>
    show = Session.get "portfolios.#{@data.index}.settings.showTickerWeight"
    show = @data.settings.showTickerWeight unless show?
    showTickerWeightVar.set(show and "checked")
    show and "checked"

  showTickerRankingFn = Tracker.autorun =>
    show = Session.get "portfolios.#{@data.index}.settings.showTickerRanking"
    show = @data.settings.showTickerRanking unless show?
    showTickerRankingVar.set(show and "checked")
    show and "checked"

  hasFXExposureFn = Tracker.autorun =>
    has = Session.get "portfolios.#{@data.index}.settings.hasFXExposure"
    has = @data.settings.hasFXExposure unless has?
    hasFXExposureVar.set(has and "checked")
    has and "checked"

  hasLocalReturnModifierFn = Tracker.autorun =>
    has = Session.get("portfolios.#{@data.index}.localMax") or
          Session.get("portfolios.#{@data.index}.localMin") or
          Session.get("portfolios.#{@data.index}.assigned")
    has = @data.localMax or
          @data.localMin or
          @data.assigned unless has?
    hasLocalReturnModifierVar.set(has)
    has

  @data

Template.portfolio.destroyed = ->

  # Clean up.
  _.each PortfoliosSchema, (v, k) =>
    if _.isObject v
      _.each v, (objectValue, objectKey) => Session.set "portfolios.#{@index}.#{k}.#{objectKey}", null
    else Session.set k, null

  # Stop Autorun comps.
  noteCurrencyFn.stop()
  showTickerWeightFn.stop()
  showTickerRankingFn.stop()
  hasFXExposureFn.stop()
  hasLocalReturnModifierFn.stop()

Template.ticker.created = ->
  pIndex = Template.parentData(1).index

  @data = {} unless @data
  @data.prefix = "portfolios.#{pIndex}.tickers.#{@data.index}."

  tickerReturnsDeps[@data.index] = new Tracker.Dependency()
#   tickerNamesDeps[@data.index] = new Tracker.Dependency()

  # Get index from @data.index at this point.
  _.each TickersSchema, (v, k) => Template.convertToSession(v, k, @data, "portfolios.#{pIndex}.tickers.#{@data.index}")

  @data

Template.ticker.destroyed = ->
  pIndex = Template.parentData(1).index
  _.each TickersSchema, (v, k) =>
    if _.isObject v
      _.each v, (objectValue, objectKey) => Session.set "portfolios.#{pIndex}.tickers.#{@index}.#{k}.#{objectKey}", null
    else Session.set k, null

# ticker events
# ------------

Template.issue.validators.portfolios = (portfolios) ->

  return unless portfolios

  withProperType = (portfolio) ->
    # Optional
    portfolio.minimum = Number(portfolio.minimum) if portfolio.minimum
    portfolio.maximum = Number(portfolio.maximum) if portfolio.maximum
    portfolio.participationFactor = Number(portfolio.participationFactor) if portfolio.participationFactor
    portfolio.participationThreshold = Number(portfolio.participationThreshold) if portfolio.participationThreshold
    portfolio.barrierAmount = Number(portfolio.barrierAmount) if portfolio.barrierAmount
    portfolio.bonusReturn = Number(portfolio.bonusReturn) if portfolio.bonusReturn
    portfolio.localMin = Number(portfolio.localMin) if portfolio.localMin
    portfolio.localMax = Number(portfolio.localMax) if portfolio.localMax

    if portfolio.settings?
      # Booleans
      portfolio.settings.showTickerWeight = !!portfolio.settings.showTickerWeight if portfolio.settings.showTickerWeight
      portfolio.settings.showTickerRanking = !!portfolio.settings.showTickerRanking if portfolio.settings.showTickerRanking

    portfolio

  autoAdjust = (portfolio) ->

    if portfolio.settings?
      if portfolio.settings.portfolioReturn?
        if not _.contains ["average", "min", "max", "addition", "geometric"], portfolio.settings.portfolioReturn
          portfolio.settings.portfolioReturn = "average"

    portfolio

  empty = (portfolio) -> not portfolio.tickers or portfolio.tickers.length is 0

  # Easy client side filter.

  portfolios = _.chain(portfolios)
    .reject(empty)
    .map(withProperType)
    .map(autoAdjust)
    .each((portfolio) -> Template.issue.validators.tickers(portfolio.tickers))
    .value() if portfolios

  portfolios

Template.issue.validators = Template.issue.validators or {}
Template.issue.validators.tickers = (tickers) ->

  return unless tickers

  withProperType = (ticker) ->
    # Optional
    ticker.initialPrice = Number(ticker.initialPrice) if ticker.initialPrice
    ticker.initialFX = Number(ticker.initialFX) if ticker.initialFX
    ticker

  empty = (ticker) -> not ticker.bloomberg or not ticker.initialPrice

  autoAdjust = (ticker) ->
    ticker.weight = weight unless ticker.weight

  # Easy client side filter.
  weight = 1 / tickers.length
  tickers = _(tickers).reject(empty) if tickers
  tickers = _.chain(tickers).map(withProperType).map(autoAdjust).value() if tickers

  tickers


Template.issue.helpers

  showPortfolioWeight: ->
    showPortfolioWeight = Session.get "showPortfolioWeight"
    showPortfolioWeight = @showPortfolioWeight unless showPortfolioWeight?
    showPortfolioWeight and "checked"

  portfolios: ->

    portfolioDeps.depend()
    Session.get "portfolios"


Template.issue.events

  "click .js-add-portfolio": (event, template) ->
    $portfolio = $(event.target).closest(".portfolio")
    index = $portfolio.index()

    # Add to the end if this is the last row.
    # This won't work, as we have that extra "empty" row...
    portfolios = Session.get "portfolios"
    if $portfolio.siblings().length is index
      portfolios.push portfolioDefaults
    else
      portfolios.splice(index, 0, {})
    Session.set "portfolios", portfolios

    portfolioDeps.changed()

  "click .js-remove-portfolio": (event, template) ->
    $portfolio = $(event.target).closest(".portfolio")
    index = $portfolio.index()

    portfolios = Session.get "portfolios"
    portfolios.splice(index, 1)
    Session.set "portfolios", portfolios

    portfolioDeps.changed()
