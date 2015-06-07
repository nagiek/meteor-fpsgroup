@PublicFiles = new FS.Collection "publicFiles",
  beforeWrite: (fileObj) ->
    fileObj.extension 'pdf', save: false
    fileObj.type 'application/pdf', save: false
  stores: [new FS.Store.FileSystem "publicFiles",
    path: "~/uploads/public"
    filter: 
      # maxSize: 1048576 # in bytes
      allow:
        contentTypes: ['application/*'],
        extensions: ['pdf']
      onInvalid: (message) ->
        if (Meteor.isClient)
          alert message
        else
          console.log message
  ]

PublicFiles.allow
  insert: (userId, doc) -> true # return !!userId
  update: (userId, doc) -> true # return doc.creatorId == userId
  download: (userId, doc) -> true # return doc.creatorId == userId
  remove: (userId, doc) -> true # return doc.creatorId == userId
  
@PrivateFiles = new FS.Collection "privateFiles",
  beforeWrite: (fileObj) ->
    fileObj.extension 'pdf', save: false
    fileObj.type 'application/pdf', save: false
  stores: [new FS.Store.FileSystem "privateFiles",
    path: "~/uploads/private"
    filter: 
      # maxSize: 1048576 # in bytes
      allow:
        contentTypes: ['application/*'],
        extensions: ['pdf']
      onInvalid: (message) ->
        if (Meteor.isClient)
          alert message
        else
          console.log message
  ]

PrivateFiles.allow
  insert: (userId, doc) -> true # return !!userId
  update: (userId, doc) -> true # return doc.creatorId == userId
  download: (userId, doc) -> true # return doc.creatorId == userId
  remove: (userId, doc) -> true # return doc.creatorId == userId
  
@StructureFiles = new FS.Collection "structureFiles",
  beforeWrite: (fileObj) ->
    fileObj.extension 'pdf', save: false
    fileObj.type 'application/pdf', save: false
  stores: [new FS.Store.FileSystem "structureFiles",
    path: "~/uploads/structure"
    filter: 
      # maxSize: 1048576 # in bytes
      allow:
        contentTypes: ['application/*'],
        extensions: ['pdf']
      onInvalid: (message) ->
        if (Meteor.isClient)
          alert message
        else
          console.log message
  ]

StructureFiles.allow
  insert: (userId, doc) -> true # return !!userId
  update: (userId, doc) -> true # return doc.creatorId == userId
  download: (userId, doc) -> true # return doc.creatorId == userId
  remove: (userId, doc) -> true # return doc.creatorId == userId
  