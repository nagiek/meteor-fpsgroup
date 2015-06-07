@Activities = new Mongo.Collection("activities")
@Activities.allow insert: (userId, doc) ->
  doc.userId is userId

@Activities.latest = ->
  Activities.find {},
    sort:
      date: -1

    limit: 1


Meteor.methods createActivity: (activity, tweet, loc) ->
  check Meteor.userId(), String
  check activity,
    recipeName: String
    text: String
    image: String

  check tweet, Boolean
  check loc, Match.OneOf(Object, null)
  activity.userId = Meteor.userId()
  activity.userAvatar = Meteor.user().services.twitter.profile_image_url_https
  activity.userName = Meteor.user().profile.name
  activity.date = new Date
  activity.place = getLocationPlace(loc)  if not @isSimulation and loc
  id = Activities.insert(activity)
  tweetActivity activity  if not @isSimulation and tweet
  id

if Meteor.isServer
  
  # Uses the Npm request module directly as provided by the request local pkg
  callTwitter = (options) ->
    config = Meteor.settings.twitter
    userConfig = Meteor.user().services.twitter
    options.oauth =
      consumer_key: config.consumerKey
      consumer_secret: config.secret
      token: userConfig.accessToken
      token_secret: userConfig.accessTokenSecret

    Request options

  tweetActivity = (activity) ->
    
    # creates the tweet text, optionally truncating to fit the appended text
    appendTweet = (text, append) ->
      MAX = 117 # Max size of tweet with image attached
      if (text + append).length > MAX
        text.substring(0, (MAX - append.length - 3)) + "..." + append
      else
        text + append
    
    # we need to strip the "data:image/jpeg;base64," bit off the data url
    image = activity.image.replace(/^data.*base64,/, "")
    response = callTwitter(
      method: "post"
      url: "https://upload.twitter.com/1.1/media/upload.json"
      form:
        media: image
    )
    throw new Meteor.Error(500, "Unable to post image to twitter")  if response.statusCode isnt 200
    attachment = JSON.parse(response.body)
    response = callTwitter(
      method: "post"
      url: "https://api.twitter.com/1.1/statuses/update.json"
      form:
        status: appendTweet(activity.text, " #localmarket")
        media_ids: attachment.media_id_string
    )
    throw new Meteor.Error(500, "Unable to create tweet")  if response.statusCode isnt 200
    return

  getLocationPlace = (loc) ->
    url = "https://api.twitter.com/1.1/geo/reverse_geocode.json" + "?granularity=neighborhood" + "&max_results=1" + "&accuracy=" + loc.coords.accuracy + "&lat=" + loc.coords.latitude + "&long=" + loc.coords.longitude
    response = callTwitter(
      method: "get"
      url: url
    )
    if response.statusCode is 200
      data = JSON.parse(response.body)
      place = _.find(data.result.places, (place) ->
        place.place_type is "neighborhood"
      )
      place and place.full_name

# Initialize a seed activity
Meteor.startup ->
  if Meteor.isServer and Activities.find().count() is 0
    Activities.insert
      recipeName: "summer-apricots-honey-panna-cotta"
      text: "I substituted strawberries for apricots - incredible!"
      image: "/img/activity/activity-placeholder-strawberry-640x640.jpg"
      userAvatar: "https://avatars3.githubusercontent.com/u/204768?v=2&s=400"
      userName: "Matt Debergalis"
      place: "SoMA, San Francisco"
      date: new Date

  return

