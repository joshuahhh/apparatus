_ = require "underscore"
queryString = require "query-string"
Dataflow = require "../Dataflow/Dataflow"
Model = require "./Model"
Util = require "../Util/Util"
Storage = require "../Storage/Storage"


module.exports = class Editor
  constructor: ->
    @_setupLayout()
    @_setupSerializer()
    @_setupProject()
    @_setupRevision()
    @_parseQueryString()

  _setupLayout: ->
    @layout = new Model.Layout()

  _setupProject: ->
    @loadFromLocalStorage()
    if !@project
      @createNewProject()

  _setupSerializer: ->
    builtInObjects = []
    for own name, object of @_builtIn()
      if _.isFunction(object)
        object = object.prototype
      Util.assignId(object, name)
      builtInObjects.push(object)
    @serializer = new Storage.Serializer(builtInObjects)

  # Checks if we should load an external JSON file based on the query string
  # (the ?stuff at the end of the URL).
  _parseQueryString: ->
    parsed = queryString.parse(location.search)
    if parsed.load
      @loadFromURL(parsed.load)

  # builtIn returns all of the built in classes and objects that are used as
  # the "anchors" for serialization and deserialization. That is, all of the
  # objects and classes which should not themselves be serialized but instead
  # be *referenced* from a serialization. When deserialized, these references
  # are then bound appropriately.
  _builtIn: ->
    builtIn = _.clone(Model)
    builtIn["SpreadEnv"] = Dataflow.SpreadEnv
    builtIn["Matrix"] = Util.Matrix
    return builtIn

  # TODO: get version via build process / ENV variable?
  version: "0.4.1"

  load: (jsonString, sourceDescription) ->
    updateStatus = (message, autoDismiss) =>
      if sourceDescription
        title = "Loading " + sourceDescription
        @showStatusNotification({name: 'load', title: title, message: message, autoDismiss: autoDismiss})
    updateError = (message) =>
      title = "Problem loading " + (sourceDescription ? "drawing")
      @showErrorNotification({name: 'load', title: title, message: message})

    updateStatus('Parsing JSON')
    try
      json = JSON.parse(jsonString)
    catch
      updateError("JSON parsing failed")
      return
    # TODO: If the file format changes, this will need to check the version
    # and convert or fail appropriately.
    updateStatus('Deserializing')
    if json.type == "Apparatus"
      try
        @project = @serializer.dejsonify(json)
        updateStatus("Done", 3)
      catch
        updateError("Deserialization failed")
    else
      updateError("This is not an Apparatus drawing")

  save: ->
    json = @serializer.jsonify(@project)
    json.type = "Apparatus"
    json.version = @version
    jsonString = JSON.stringify(json)
    return jsonString

  createNewProject: ->
    @project = new Model.Project()


  # ===========================================================================
  # Local Storage
  # ===========================================================================

  localStorageName: "apparatus"

  saveToLocalStorage: ->
    jsonString = @save()
    window.localStorage[@localStorageName] = jsonString
    return jsonString

  loadFromLocalStorage: ->
    jsonString = window.localStorage[@localStorageName]
    if jsonString
      @load(jsonString, "from browser storage")

  resetLocalStorage: ->
    delete window.localStorage[@localStorageName]


  # ===========================================================================
  # File System
  # ===========================================================================

  saveToFile: ->
    jsonString = @save()
    fileName = @project.editingElement.label + ".json"
    Storage.saveFile(jsonString, fileName, "application/json;charset=utf-8")

  loadFromFile: ->
    Storage.loadFile (jsonString) =>
      @load(jsonString, "uploaded file")
      Apparatus.refresh() # HACK: calling Apparatus seems funky here.


  # ===========================================================================
  # External URL
  # ===========================================================================

  # TODO: Deal with error conditions, timeout, etc.
  # TODO: Maybe move xhr stuff to Util.
  # TODO: Show some sort of loading indicator.
  loadFromURL: (url) ->
    xhr = new XMLHttpRequest()
    xhr.onreadystatechange = =>
      @showStatusNotification({name: 'load', title: 'Loading file', message: 'Downloading'})
      return unless xhr.readyState == 4
      if xhr.status != 200
        message = {401: "Insufficient permissions", 404: "File cannot be found"}[xhr.status] ? "Code: #{xhr.status}"
        @showErrorNotification(name: "load", title: "Problem downloading file", message: message)
        return
      jsonString = xhr.responseText
      @load(jsonString, 'downloaded file')
      @checkpoint()
      Apparatus.refresh() # HACK: calling Apparatus seems funky here.
      @removeNotification("load")
    xhr.open("GET", url, true)
    xhr.send()


  # ===========================================================================
  # Revision History
  # ===========================================================================

  _setupRevision: ->
    # @current is a JSON string representing the current state. @undoStack and
    # @redoStack are arrays of such JSON strings.
    @current = @save()
    @undoStack = []
    @redoStack = []
    @maxUndoStackSize = 100

  checkpoint: ->
    jsonString = @saveToLocalStorage()
    return if @current == jsonString
    @undoStack.push(@current)
    if @undoStack.length > @maxUndoStackSize
      @undoStack.shift()
    @redoStack = []
    @current = jsonString

  undo: ->
    return unless @isUndoable()
    @redoStack.push(@current)
    @current = @undoStack.pop()
    @load(@current)
    @saveToLocalStorage()

  redo: ->
    return unless @isRedoable()
    @undoStack.push(@current)
    @current = @redoStack.pop()
    @load(@current)
    @saveToLocalStorage()

  isUndoable: ->
    return @undoStack.length > 0

  isRedoable: ->
    return @redoStack.length > 0


  # ===========================================================================
  # Notifications
  # ===========================================================================

  showErrorNotification: ({name, title, message})  ->
    return unless @notificationSystem
    console.log("showErrorNotification:", {name, title, message}, @notificationSystem.state.notifications)
    if @currentNotification then @removeNotification(@currentNotification)
    console.log("removal complete", @notificationSystem.state.notifications)
    @currentNotification = @notificationSystem.addNotification
      # uid: name
      title: title ? "Error"
      message: message
      level: "error"
      autoDismiss: 0
      position: "tl"
    console.log("add complete", @notificationSystem.state.notifications)

  showStatusNotification: ({name, title, message, autoDismiss})  ->
    return unless @notificationSystem
    console.log("showStatusNotification:", {name, title, message}, @notificationSystem.state.notifications)
    if @currentNotification then @removeNotification(@currentNotification)
    console.log("removal complete", @notificationSystem.state.notifications)
    @currentNotification = @notificationSystem.addNotification
      # uid: name
      title: title
      message: message
      level: "info"
      autoDismiss: autoDismiss ? 0
      dismissible: false
      position: "tl"
    console.log("add complete", @notificationSystem.state.notifications)

  removeNotification: (notification)->
    return unless @notificationSystem
    @notificationSystem.removeNotification(notification)
    # @notificationSystem._didNotificationRemoved(name)


  fakeCopy: ->
    link = "http://aprt.us/editor/?loadFirebase=-K4vNw-NqMBBmqXn3QJk"
    @notificationSystem.addNotification
      title: "Share successful"
      message: "
        <table style='width: 100%;'><tr>
          <td style='white-space: nowrap;'>
            Copy this URL:
          </td>
          <td style='width: 100%;'>
            <input type='text' value='#{link}' onclick='this.select();'
              style='width: 100%;' />
          </td>
        </tr></table>"
      level: "success"
      autoDismiss: 0
      dismissible: false
      position: "tl"
      action:
        label: "Done"

  fakeError:  ->
    @showErrorNotification
      name: "load"
      title: "Error loading file"
      message: "There was an error loading your file"
