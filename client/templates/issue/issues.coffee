Template.issues.helpers
  currentIssues: ->
    Issues.find {},
      sort:
        issuanceDate: -1

  ready: ->
    Router.current().issuesSubscription.ready()