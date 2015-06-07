TAB_KEY = "recipeShowTab"
Template.recipe.created = ->
  if Router.current().params.activityId
    Template.recipe.setTab "feed"
  else
    Template.recipe.setTab "recipe"
  return

Template.recipe.rendered = ->
  @$(".recipe").touchwipe
    wipeDown: ->
      Template.recipe.setTab "make"  if Session.equals(TAB_KEY, "recipe")
      return

    preventDefaultEvents: false

  @$(".attribution-recipe").touchwipe
    wipeUp: ->
      Template.recipe.setTab "recipe"  unless Session.equals(TAB_KEY, "recipe")
      return

    preventDefaultEvents: false

  return


# CSS transitions can't tell the difference between e.g. reaching
#   the "make" tab from the expanded state or the "feed" tab
#   so we need to help the transition out by attaching another
#   class that indicates if the feed tab should slide out of the
#   way smoothly, right away, or after the transition is over
Template.recipe.setTab = (tab) ->
  lastTab = Session.get(TAB_KEY)
  Session.set TAB_KEY, tab
  fromRecipe = (lastTab is "recipe") and (tab isnt "recipe")
  $(".feed-scrollable").toggleClass "instant", fromRecipe
  toRecipe = (lastTab isnt "recipe") and (tab is "recipe")
  $(".feed-scrollable").toggleClass "delayed", toRecipe
  return

Template.recipe.helpers
  isActiveTab: (name) ->
    Session.equals TAB_KEY, name

  activeTabClass: ->
    Session.get TAB_KEY

  bookmarked: ->
    Meteor.user() and _.include(Meteor.user().bookmarkedRecipeNames, @name)

  activities: ->
    Activities.find
      recipeName: @name
    ,
      sort:
        date: -1


Template.recipe.events
  "click .js-add-bookmark": (event) ->
    event.preventDefault()
    return Overlay.open("authOverlay")  unless Meteor.userId()
    Meteor.call "bookmarkRecipe", @name
    return

  "click .js-remove-bookmark": (event) ->
    event.preventDefault()
    Meteor.call "unbookmarkRecipe", @name
    return

  "click .js-show-recipe": (event) ->
    event.stopPropagation()
    Template.recipe.setTab "make"
    return

  "click .js-show-feed": (event) ->
    event.stopPropagation()
    Template.recipe.setTab "feed"
    return

  "click .js-uncollapse": ->
    Template.recipe.setTab "recipe"
    return

  "click .js-share": ->
    Overlay.open "shareOverlay", this
    return

