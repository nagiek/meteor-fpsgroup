Template.recipeItem.helpers
  path: ->
    Router.path "recipe", @recipe

  highlightedClass: ->
    "highlighted"  if @size is "large"

  bookmarkCount: ->
    count = BookmarkCounts.findOne(recipeName: @name)
    count and count.count

