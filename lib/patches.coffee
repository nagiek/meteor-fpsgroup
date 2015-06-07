
# Underscore is 1.5.2 in Meteor, but we need the 1.7.x functions
Meteor.startup ->
  _.memoize = (func, hasher) ->

    memoize = (key) ->
      cache = memoize.cache
      address = if hasher then hasher.apply(this, arguments) else key
      if !_.has(cache, address)
        cache[address] = func.apply(this, arguments)
      cache[address]

    memoize.cache = {}
    memoize