feedSubscription = undefined
issuesSubscription = undefined
publicFilesSubscription = undefined
privateFilesSubscription = undefined
structureFilesSubscription = undefined

# Handle for launch screen possibly dismissed from app-body.js
@dataReadyHold = null

# Global subscriptions
if Meteor.isClient
  Meteor.subscribe "news"
  Meteor.subscribe "bookmarkCounts"
  feedSubscription = Meteor.subscribe("feed")
  issuesSubscription = Meteor.subscribe("issues")
  publicFilesSubscription = Meteor.subscribe("publicFiles")
  privateFilesSubscription = Meteor.subscribe("privateFiles")
  structureFilesSubscription = Meteor.subscribe("structureFiles")

Router.configure
  layoutTemplate: "appBody"
  notFoundTemplate: "notFound"


# Keep showing the launch screen on mobile devices until we have loaded
# the app's data
@dataReadyHold = LaunchScreen.hold()  if Meteor.isClient

@HomeController = RouteController.extend
  waitOn: -> [issuesSubscription]
  onBeforeAction: ->
    @issuesSubscription = issuesSubscription
    Meteor.subscribe "latestActivity", ->
      dataReadyHold.release()

@FeedController = RouteController.extend
  onBeforeAction: ->
    @feedSubscription = feedSubscription

@RecipesController = RouteController.extend
  data: ->
    _.values RecipesData

@IssuesController = RouteController.extend
  waitOn: -> [issuesSubscription]
  onBeforeAction: ->
    @issuesSubscription = issuesSubscription
  # action: ->
  #   if @ready()
  #     @render()
  #   else
  #     @render "loading"

@StructuresController = RouteController.extend
  waitOn: -> [structureFilesSubscription]
  # action: ->
  #   if @ready()
  #     @render()
  #   else
  #     @render "loading"

@IssueController = RouteController.extend
  waitOn: -> [Meteor.subscribe("issue",  @params._id), publicFilesSubscription, privateFilesSubscription, structureFilesSubscription]
  data: -> Issues.findOne @params._id
  # action: ->
  #   if @ready()
  #     @render()
  #   else
  #     @render "loading"

@BookmarksController = RouteController.extend
  onBeforeAction: ->
    if Meteor.user()
      Meteor.subscribe "bookmarks"
    else
      Overlay.open "authOverlay"

  data: ->
    _.values _.pick(RecipesData, Meteor.user().bookmarkedRecipeNames)  if Meteor.user()

@RecipeController = RouteController.extend
  onBeforeAction: ->
    Meteor.subscribe "recipe", @params.name

  data: ->
    RecipesData[@params.name]

# @AdminController = RouteController.extend
#   action: ->
#     if @ready()
#       @render()
#     else
#       @render "loading"


Router.map ->
  @route "home",
    path: "/"

  @route "feed"
  @route "recipes"

  @route "issues"
  @route "structures"

  @route "newIssue",
    path: "/issues/new"
    action: -> @render "issue"
  @route "issue", path: "/issues/:_id"

  @route "bookmarks"
  @route "about"
  @route "recipe",
    path: "/recipes/:name"

  @route "admin"

Router.onBeforeAction "dataNotFound",
  only: "recipe", "issue"


@routeIsTopLevel = ->
  # XXX: update to the following when IR 1.0 hits
  #      Router.current().route.getName()
  _.contains ["home", "issues", "user", "admin"], Router.current().route.name
