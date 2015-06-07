@DATE_INPUT_FORMAT = i18n("common.dates.formats.output")
  
# replaceFileInput
#
# Credit to blueimp File Upload
# https://github.com/blueimp/jQuery-File-Upload/js/jquery.fileupload.js
Template.replaceFileInput = (input) ->
  inputClone = input.clone(true)
  $("<form></form>").append(inputClone)[0].reset()
  input.replaceWith(inputClone)

  
# "name" is in the form "issue[key]", in order to maintain form compatibility
# To get what we want, we strip the key from the name.
Template.extractKey = (name) -> 
  key = name.substring(name.indexOf("[") + 1, name.length - 1)
  # Replace additional object nesting with our dot notation.
  key.replace(/\]\[/g, ".")

Template.handleSave = (error, _id) ->
  unless error
    # TODO: Update the base data
    # originalData = _id
    notification = 
      title: i18n "common.messages.saved"
      type: "success"
  else
    notification = 
      title: i18n "common.errors.notSaved"
      type: "error"
  Template.appBody.addNotification notification

# Create a reactive helper for each variable.
Template.convertToSession = (v, k, data, prefix) ->
  # namespacing prefixes
  prefix = if prefix then prefix + "." else ""

  switch v 
    when Array
      unless _.isArray data[k] then data[k] = []
      Session.set prefix+k, data[k]
    when String, Boolean, Number
      Session.set prefix+k, data[k]
    when Date
      Session.set prefix+k, data[k]
    else
      # It's an Object, go one level deeper.
      unless _.isObject data[k] then data[k] = {}
      _.each v, (objectValue, objectKey) -> Template.convertToSession(objectValue, objectKey, data[k], prefix + k)

Template.getHelpers = (v, k, helpers, prefixTemplate) ->

  prefixTemplate = if prefixTemplate then prefixTemplate + "." else ""

  # namespacing prefixes
  switch v 
    # Array helpers managed manually.
    when Array then return
    when String, Boolean, Number
      helpers[k] = ->
        if prefixTemplate and not @prefix
          @prefix = _.clone prefixTemplate 
          _.each prefixTemplate.match(/\$[0-9]/g), (match) =>
            indexLevel = Number @prefix.substr(@prefix.indexOf(match)+1,1)
            index = if indexLevel is 0 then @index else Template.parentData(indexLevel).index
            @prefix = @prefix.replace(match, index)
        else @prefix = ""

        ret = Session.get @prefix+k
        # TODO: @k won't work for nested objects.
        ret = @[k] unless ret?
        ret
    when Date
      helpers[k] = ->
        if prefixTemplate and not @prefix
          @prefix = _.clone prefixTemplate 
          _.each prefixTemplate.match(/\$[0-9]/g), (match) =>
            indexLevel = Number @prefix.substr(@prefix.indexOf(match)+1,1)
            index = if indexLevel is 0 then @index else Template.parentData(indexLevel).index
            @prefix = @prefix.replace(match, index)
        else @prefix = ""

        ret = Session.get @prefix+k
        # TODO: @k won't work for nested objects.
        ret = @[k] unless ret?
        if ret then moment(ret).format("LL") else ""

      helpers[k+"Input"] = ->
        if prefixTemplate and not @prefix
          @prefix = _.clone prefixTemplate 
          _.each prefixTemplate.match(/\$[0-9]/g), (match) =>
            indexLevel = Number @prefix.substr(@prefix.indexOf(match)+1,1)
            index = if indexLevel is 0 then @index else Template.parentData(indexLevel).index
            @prefix = @prefix.replace(match, index)
        else @prefix = ""

        ret = Session.get @prefix+k
        # TODO: @k won't work for nested objects.
        ret = @[k] unless ret?
        if ret then moment(ret).format(DATE_INPUT_FORMAT) else ""
    else
      # It's an Object, go one level deeper.
      _.each v, (objectValue, objectKey) -> Template.getHelpers(objectValue, k + "." + objectKey, helpers, prefixTemplate)

Meteor.startup ->
  # Add missing underscore functions
  # --------------------------------
  underscore = {}

  # Save bytes in the minified (but not gzipped) version:
  ArrayProto = Array.prototype
  ObjProto = Object.prototype
  FuncProto = Function.prototype
  # Create quick reference variables for speed access to core prototypes.
  push = ArrayProto.push
  slice = ArrayProto.slice
  toString = ObjProto.toString
  hasOwnProperty = ObjProto.hasOwnProperty

  cb = (value, context, argCount) ->
    if value == null
      return _.identity
    if _.isFunction(value)
      return optimizeCb(value, context, argCount)
    if _.isObject(value)
      return _.matcher(value)
    _.property value

  # Complement of _.zip. Unzip accepts an array of arrays and groups
  # each array's elements on shared indices
  _.unzip = underscore.unzip = (array) ->
    length = array and _.max(array, 'length').length or 0
    result = Array(length)
    index = 0
    while index < length
      result[index] = _.pluck(array, index)
      index++
    result

  _.property = underscore.property = (key) ->
    (obj) -> if obj == null then undefined else obj[key]

  # Memoize an expensive function by storing its results.
  _.memoize = underscore.memoize = (func, hasher) ->
    memoize = (key) ->
      cache = memoize.cache
      address = if hasher then hasher.apply(this, arguments) else key
      if !_.has(cache, address)
        cache[address] = func.apply(this, arguments)
      cache[address]

    memoize.cache = {}
    memoize

  _.last = underscore.last = (array, n, guard) ->
    unless array?
      return undefined
    if not n or guard
      return array[array.length - 1]
    _.rest array, Math.max(0, array.length - n)

  _.max = underscore.max = (obj, iteratee, context) ->
    result = -Infinity
    lastComputed = -Infinity
    value = undefined
    computed = undefined
    if iteratee == null and obj != null
      obj = if isArrayLike(obj) then obj else _.values(obj)
      i = 0
      length = obj.length
      while i < length
        value = obj[i]
        if value > result
          result = value
        i++
    else
      iteratee = cb(iteratee, context)
      _.each obj, (value, index, list) ->
        computed = iteratee(value, index, list)
        if computed > lastComputed or computed == -Infinity and result == -Infinity
          result = value
          lastComputed = computed
        return
    result

  # Returns a function, that, when invoked, will only be triggered at most once
  # during a given window of time. Normally, the throttled function will run
  # as much as it can, without ever going more than once per `wait` duration;
  # but if you'd like to disable the execution on the leading edge, pass
  # `{leading: false}`. To disable execution on the trailing edge, ditto.
  _.throttle = underscore.throttle = (func, wait, options) ->
    context = undefined
    args = undefined
    result = undefined
    timeout = null
    previous = 0
    if !options
      options = {}

    later = ->
      previous = if options.leading == false then 0 else _.now()
      timeout = null
      result = func.apply(context, args)
      if !timeout
        context = args = null
      return

    ->
      now = _.now()
      if !previous and options.leading == false
        previous = now
      remaining = wait - (now - previous)
      context = this
      args = arguments
      if remaining <= 0 or remaining > wait
        if timeout
          clearTimeout timeout
          timeout = null
        previous = now
        result = func.apply(context, args)
        if !timeout
          context = args = null
      else if !timeout and options.trailing != false
        timeout = setTimeout(later, remaining)
      result

  # A (possibly faster) way to get the current timestamp as an integer.
  _.now = Date.now or -> (new Date).getTime()
      
  # Returns everything but the first entry of the array.
  # Aliased as tail and drop. Especially useful on the arguments object.
  # Passing an n will return the rest N values in the array.
  underscore.rest = underscore.tail = underscore.drop = 
  _.rest = _.tail = _.drop = (array, n, guard) ->
    slice.call array, if n == null or guard then 1 else n

  _.mixin(underscore)