_ = require "underscore"
Dataflow = require "../Dataflow/Dataflow"
Util = require "../Util/Util"
NewSystem = require "../NewSystem/NewSystem"


module.exports = Model = {}

Model.Project = require "./Project"
Model.ParticularElement = require "./ParticularElement"
Model.Layout = require "./Layout"
Model.Editor = require "./Editor"
Model.SpreadEnv = Dataflow.SpreadEnv
Model.Matrix = Util.Matrix

_.extend(Model, NewSystem)
