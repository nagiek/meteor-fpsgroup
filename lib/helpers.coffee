@isAdmin = -> true

Meteor.startup ->
  UI.registerHelper 'log', (variable) -> console.log variable
  
  UI.registerHelper 'withIndex', (all) -> 
    _.map all, (val, index) -> val.index = index
    all
  
  @pluralize = (n, thing, options) ->
    plural = thing
    if _.isUndefined(n)
      return thing
    else if n isnt 1
      if thing.slice(-1) is "s"
        plural = thing + "es"
      else
        plural = thing + "s"
    if options and options.hash and options.hash.wordOnly
      plural
    else
      n + " " + plural      
  UI.registerHelper "pluralize", pluralize

  @selectFreeDay = (date, inc, forbiddenDates) ->
    # No weekends or holidays.
    # moment.day() is not locale aware, so we use it instead of moment.weekday().
    if date.day() is 0 or date.day() is 6 or _.contains forbiddenDates, date.toDate()
      selectFreeDay date.add(inc, "day"), inc, forbiddenDates
    else
      date
      
  DIMENSIONS =
    small: "320x350"
    large: "640x480"
    full: "640x800"

  UI.registerHelper "recipeImage", (options) ->
    size = options.hash.size or "large"
    "/img/recipes/" + DIMENSIONS[size] + "/" + options.hash.recipe.name + ".jpg"  if options.hash.recipe

  UI.registerHelper "activePage", ->
    
    # includes Spacebars.kw but that's OK because the route name ain't that.
    routeNames = arguments
    _.include(routeNames, Router.current().route.name) and "active"