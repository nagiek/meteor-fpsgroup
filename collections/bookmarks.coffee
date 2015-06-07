@BookmarkCounts = new Meteor.Collection("bookmarkCounts")

Meteor.methods
  bookmarkRecipe: (recipeName) ->
    check @userId, String
    check recipeName, String
    affected = Meteor.users.update(
      _id: @userId
      bookmarkedRecipeNames:
        $ne: recipeName
    ,
      $addToSet:
        bookmarkedRecipeNames: recipeName
    )
    if affected
      BookmarkCounts.update
        recipeName: recipeName
      ,
        $inc:
          count: 1

    return

  unbookmarkRecipe: (recipeName) ->
    check @userId, String
    check recipeName, String
    affected = Meteor.users.update(
      _id: @userId
      bookmarkedRecipeNames: recipeName
    ,
      $pull:
        bookmarkedRecipeNames: recipeName
    )
    if affected
      BookmarkCounts.update
        recipeName: recipeName
      ,
        $inc:
          count: -1

    return


# Initialize bookmark counts. We could use upsert instead.
if Meteor.isServer and @BookmarkCounts.find().count() is 0
  Meteor.startup ->
    _.each RecipesData, (recipe, recipeName) ->
      BookmarkCounts.insert
        recipeName: recipeName
        count: 0

      return

    return

