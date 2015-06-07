Meteor.startup ->
  if Meteor.isClient
    if Meteor.user()
      language = Meteor.user().profile.language

    else
      # detect the language used by the browser
      language = window.navigator.userLanguage || window.navigator.language

    i18n.setLanguage language
    moment.locale language


  UI.registerHelper 'pathWithSlug', ->
    language = i18n.getLanguage().substring(0,2).toUpperCase()
    UI._globalHelpers.pathFor.apply(this, arguments) + '/' + @['slug' + language]

  UI.registerHelper 'lang', (string, fallback) ->
    language = i18n.getLanguage().substring(0,2).toUpperCase()
    output = Session.get string+language
    output = this[string+language] unless output
    output = i18n(fallback) unless output
    output
    
  # Same as lang, but without Session variable.
  UI.registerHelper 'langStatic', (string, fallback) ->
    language = i18n.getLanguage().substring(0,2).toUpperCase()
    output = this[string+language]
    output = i18n(fallback) unless output
    output
    
  UI.registerHelper '__', ->
    i18n.apply this, arguments
