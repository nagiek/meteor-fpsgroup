@News = new Mongo.Collection("news")
@News.allow insert: (userId) ->
  user = Meteor.users.findOne(userId)
  user and user.admin

@News.latest = ->
  News.findOne {},
    sort:
      date: -1

    limit: 1


if Meteor.isServer and @News.find().count() is 0
  Meteor.startup ->
    News.insert
      text: "First of the season citrus has just arrived. Get succulent oranges and tangerines in our produce aisle!"
      date: new Date

    return

