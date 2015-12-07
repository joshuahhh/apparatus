Firebase = require "firebase"
Q = require "q"

Q.longStackSupport = true;

module.exports = class FirebaseAccess
  constructor: ->
    # This actually establishes a connection to Firebase and checks the current
    # auth status, so don't make a FirebaseAccess unless you're cool with that.
    @ref = new Firebase("https://aprtus.firebaseio.com/")
    @authData = @ref.getAuth();

  # Returns a promise to go through a login process.
  loginPromise: ->
    return Q.ninvoke(@ref, "authWithOAuthPopup", "google")
      .then (authData) =>
        @authData = authData

  # Returns a promise to go through a login process, if the user isn't logged in
  # already.
  loginIfNecessaryPromise: ->
    if not @authData
      return @loginPromise()
    else
      return Q()  # simple success

  # Given a JSON string of a drawing, returns a promise to save the drawing's
  # data and return the drawing key. Will go into a login process, if necessary.
  saveDrawingPromise: (drawing) ->
    @loginIfNecessaryPromise().then =>
      drawingsRef = @ref.child("drawings")
      newDrawingRef = drawingsRef.push
        uid: @authData.uid
        date: Firebase.ServerValue.TIMESTAMP
        source: drawing
      return newDrawingRef.key()

  # Given a drawing key, returns a promise to return the drawing's data block.
  loadDrawingPromise: (key) ->
    deferred = Q.defer()

    drawingsRef = @ref.child("drawings")
    thisDrawingRef = drawingsRef.child(key)

    successCallback = (drawingDataSnapshot) =>
      if not drawingDataSnapshot.exists()
        deferred.reject(new DrawingNotFoundError())
      drawingData = drawingDataSnapshot.val()
      deferred.resolve(drawingData)
    failureCallback = (error) =>
      deferred.reject(error)

    thisDrawingRef.once('value', successCallback, failureCallback)

    return deferred.promise


# The error that occurs when you try to load a drawing that doesn't exist.
FirebaseAccess.DrawingNotFoundError = class DrawingNotFoundError
