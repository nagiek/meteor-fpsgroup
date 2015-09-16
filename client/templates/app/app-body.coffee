ANIMATION_DURATION = 300
NOTIFICATION_TIMEOUT = 3000
MENU_KEY = "menuOpen"
SHOW_CONNECTION_ISSUE_KEY = "showConnectionIssue"
CONNECTION_ISSUE_TIMEOUT = 5000
Session.setDefault SHOW_CONNECTION_ISSUE_KEY, false
Session.setDefault MENU_KEY, false


# XXX: this work around until IR properly supports this
#   IR refactor will include Location.back, which will ensure that initator is
#   set
nextInitiator = null
initiator = null

Tracker.autorun ->

  # add a dep
  Router.current()
  initiator = nextInitiator
  nextInitiator = null
  return

notifications = new Meteor.Collection(null)

Template.appBody.addNotification = (notification) ->
  id = notifications.insert(notification)
  Meteor.setTimeout (->
    notifications.remove id
    return
  ), NOTIFICATION_TIMEOUT
  return

Meteor.startup ->

  # set up a swipe left / right handler
  $(document.body).touchwipe
    wipeLeft: ->
      Session.set MENU_KEY, false
      return

    wipeRight: ->
      Session.set MENU_KEY, true
      return

    preventDefaultEvents: false


  # Only show the connection error box if it has been 5 seconds since
  # the app started
  setTimeout (->

    # Launch screen handle created in lib/router.js
    dataReadyHold.release()

    # Show the connection error box
    Session.set SHOW_CONNECTION_ISSUE_KEY, true
    return
  ), CONNECTION_ISSUE_TIMEOUT
  return

Template.appBody.rendered = ->
  @find("#content")._uihooks =
    insertElement: (node, next) ->

      # short-circuit and just do it right away
      return $(node).insertBefore(next)  if initiator is "menu"
      # Fade in / fade out for switch?
      return $(node).insertBefore(next)  if initiator is "switch"
      start = (if (initiator is "back") then "-100%" else "100%")
      $.Velocity.hook node, "translateX", start
      $(node).insertBefore(next).velocity
        translateX: [
          0
          start
        ]
      ,
        duration: ANIMATION_DURATION
        easing: "ease-in-out"
        queue: false

      return

    removeElement: (node) ->
      return $(node).remove()  if initiator is "menu"
      # Fade in / fade out for switch?
      return $(node).remove()  if initiator is "switch"
      end = (if (initiator is "back") then "100%" else "-100%")
      $(node).velocity
        translateX: end
      ,
        duration: ANIMATION_DURATION
        easing: "ease-in-out"
        queue: false
        complete: ->
          $(node).remove()
          return

      return

  @find(".notifications")._uihooks =
    insertElement: (node, next) ->
      $(node).insertBefore(next).velocity "slideDown",
        duration: ANIMATION_DURATION
        easing: [
          0.175
          0.885
          0.335
          1.05
        ]

      return

    removeElement: (node) ->
      $(node).velocity "fadeOut",
        duration: ANIMATION_DURATION
        complete: ->
          $(node).remove()
          return

      return

  return

Template.appBody.helpers
  menuOpen: ->
    Session.get(MENU_KEY) and "menu-open"

  overlayOpen: ->
    (if Overlay.isOpen() then "overlay-open" else "")

  connected: ->
    if Session.get(SHOW_CONNECTION_ISSUE_KEY)
      Meteor.status().connected
    else
      true

  notifications: ->
    notifications.find()

  isAdmin: isAdmin

  # Language
  isEnglish: -> isEnglish()
  isFrench: -> isFrench()

Template.appBody.events
  "click .js-menu": (event) ->
    event.stopImmediatePropagation()
    event.preventDefault()
    Session.set MENU_KEY, not Session.get(MENU_KEY)
    return

  "click #primary-nav a": (event) ->
    alreadyTopLevel = routeIsTopLevel()
    nextInitiator = if alreadyTopLevel then "switch" else "back"
    return

  "click .js-back": (event) ->
    nextInitiator = "back"

    # XXX: set the back transition via Location.back() when IR 1.0 hits
    history.back()
    event.stopImmediatePropagation()
    event.preventDefault()
    return

  "click a.js-open": (event) ->

    # On Cordova, open links in the system browser rather than In-App
    if Meteor.isCordova
      event.preventDefault()
      window.open event.target.href, "_system"
    return

  "click .content-overlay": (event) ->
    Session.set MENU_KEY, false
    event.preventDefault()
    return

  "click #menu a": (event) ->
    nextInitiator = "menu"
    Session.set MENU_KEY, false
    return

  "click .js-notification-action": ->
    if _.isFunction(@callback)
      @callback()
      notifications.remove @_id
    return

  "click #js-switch-english": (e) -> e.preventDefault(); i18n.setLanguage("en"); moment.lang("en"); numeral.language('en')
  "click #js-switch-french" : (e) -> e.preventDefault(); i18n.setLanguage("fr"); moment.lang("fr"); numeral.language('fr')
