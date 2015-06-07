Template.issue.helpers

  # files
  i18nFile: (type) -> i18n "issue.docs.#{type}" 
  publicFiles: -> PublicFiles.find(issue: @_id, lang: i18n.getLanguage().substr(0,2).toUpperCase())
  privateFiles: -> PrivateFiles.find(issue: @_id, lang: i18n.getLanguage().substr(0,2).toUpperCase())
  greensheetEN: -> PrivateFiles.findOne(@greensheetEN)
  greensheetFR: -> PrivateFiles.findOne(@greensheetFR)

Template.issue.events

    
  "change .file-input": (event, template) ->
    file = event.target.files[0]
    input = $(event.target)
    name = input.attr("name")
    key = Template.extractKey name
    doc = key.substring 0, key.length - 2
    lang = key.substring key.length - 2
    
    f = new FS.File(file);
    FS.Utility.extend f, owner: Meteor.userId(), doc: doc, key: key, lang: lang, issue: @_id
    f.name(key + "-" + @_id)
      
    PrivateFiles.insert f, (err, fileObj) =>
      # Clear the input.
      Template.replaceFileInput input
      
      # We will disable saving if we haven't first saved the issue.
      Meteor.call "saveIssueProperty", @_id, key, fileObj._id if @_id and not err
