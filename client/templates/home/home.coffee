Template.home.helpers
  currentIssues: ->
    Issues.find {},
      sort:
        issuanceDate: -1

  isAdmin: isAdmin

  ready: ->
    Router.current().issuesSubscription.ready()
