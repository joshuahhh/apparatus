_ = require "underscore"
R = require "./View/R"
Model = require "./Model/Model"
Dataflow = require "./Dataflow/Dataflow"
Storage = require "./Storage/Storage"
Util = require "./Util/Util"


# For debugging
Apparatus = window.Apparatus = {}
Apparatus.Dataflow = Dataflow
Apparatus.Model = Model
Apparatus.Storage = Storage
Apparatus.R = R
Apparatus.Util = Util




editor = new Model.Editor()




# For debugging
Apparatus.editor = editor




render = ->
  Dataflow.run ->
    R.render(R.Editor({editor}), document.body)

render()



shouldCheckpoint = false

document.addEventListener "mouseup", ->
  shouldCheckpoint = true

debouncedShouldCheckpoint = _.debounce(->
  shouldCheckpoint = true
, 500)
document.addEventListener "keydown", ->
  debouncedShouldCheckpoint()




# willRefreshNextFrame = false
# refresh = Apparatus.refresh = ->
#   return if willRefreshNextFrame
#   willRefreshNextFrame = true
#   requestAnimationFrame ->
#     render()
#     if shouldCheckpoint
#       editor.checkpoint()
#       shouldCheckpoint = false
#     willRefreshNextFrame = false

# refreshEventNames = [
#   "mousedown"
#   "mousemove"
#   "mouseup"
#   "keydown"
#   "keyup"
#   "scroll"
#   "change"
#   "wheel"
#   "mousewheel"
# ]

# for eventName in refreshEventNames
#   window.addEventListener(eventName, refresh)



# HACK: We replace the above with a refresh cycle that re-renders every
# animation frame. This will make fans spin.

Apparatus.refresh = -> return

lastTime = Date.now()
everyTick = ->
  unless document.hidden
    # HACK: We set window.dt to make it accessible in expressions. Really
    # there should be a mechanism for putting variables into scope for
    # expressions.
    now = Date.now()
    window.dt = (now - lastTime) / 1000
    lastTime = now

    editor.project.runEvolveSteps()
    editor.project.runConstrainSteps()
    render()
    if shouldCheckpoint
      editor.checkpoint()
      shouldCheckpoint = false
  requestAnimationFrame(everyTick)

everyTick()
