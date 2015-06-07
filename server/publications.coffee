ASC = 1
DESC = -1

Meteor.publish "bookmarkCounts", ->
  BookmarkCounts.find()

Meteor.publish "news", ->
  News.find {},
    sort:
      date: -1

    limit: 1


Meteor.publish "latestActivity", ->
  Activities.latest()

Meteor.publish "feed", ->
  Activities.find {},
    sort:
      date: -1

    limit: 10


Meteor.publish "issues", ->
  Issues.find {}
    # $or:
    #   published: true
    #   admin: @userId
  ,
    sort: issuanceDate: DESC
    # fields: prices: false
    
Meteor.publish "issue", (_id) ->
  check _id, String
  Issues.find _id: _id
    # $or:
    #   published: true
    #   admin: @userId

    
Meteor.publish "privateFiles", ->
  PrivateFiles.find {}
        
Meteor.publish "publicFiles", ->
  PublicFiles.find {}
  
Meteor.publish "structureFiles", ->
  StructureFiles.find {}
  
Meteor.publish "recipe", (name) ->
  check name, String
  [
    BookmarkCounts.find(recipeName: name)
    Activities.find(recipeName: name)
  ]


# autopublish the user's bookmarks and admin status
Meteor.publish null, ->
  Meteor.users.find @userId,
    fields:
      admin: 1
      bookmarkedRecipeNames: 1
      "services.twitter.profile_image_url_https": 1


