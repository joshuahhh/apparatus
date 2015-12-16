Firebase = require "firebase"
Fireproof = require "fireproof"
Q = require "Q"

Fireproof.bless(Q)


module.exports = class FirebaseAccess
  constructor: ->
    # This actually establishes a connection to Firebase and checks the current
    # auth status, so don't make a FirebaseAccess unless you're cool with that.
    @ref = new Fireproof(new Firebase("https://aprtus.firebaseio.com/"))
    @authData = @ref.getAuth()
    console.log("auth", @authData)

  # Returns a promise to go through a login process.
  loginPromise: ->
    return @ref.authWithOAuthPopup("google")
      .then (authData) =>
        @authData = authData

  # Returns a promise to go through a login process, if the user isn't logged in
  # already.
  loginIfNecessaryPromise: ->
    if not @authData
      return @loginPromise()
    else
      return Q()  # simple success

  # saveUserInformationPromise: ->
  #   @loginIfNecessaryPromise().then =>
  #     usersRef = @ref.child("users")
  #     newUserRef = usersRef.push
  #       uid: @authData.uid
  #       date: Firebase.ServerValue.TIMESTAMP
  #       source: drawing
  #     return newDrawingRef.key()

  # Given a JSON string of a drawing, returns a promise to save the drawing's
  # data and return the drawing key. Will go into a login process, if necessary.
  saveDrawingPromise: (drawing) ->
    @loginIfNecessaryPromise().then =>
      drawingsRef = @ref.child("drawings")
      newDrawingRef = drawingsRef.push
        uid: @authData.uid
        date: Firebase.ServerValue.TIMESTAMP
        source: drawing
      console.log("step 1", newDrawingRef)
      newDrawingRef.then (newDrawingRef) =>
        console.log("step x", newDrawingRef)
      return newDrawingRef
    .then (newDrawingRef) =>
      console.log("step 2", newDrawingRef)
      return newDrawingRef.key()

  # Given a drawing key, returns a promise to return the drawing's data block.
  loadDrawingPromise: (key) ->
    drawingsRef = @ref.child("drawings")
    thisDrawingRef = drawingsRef.child(key)

    return thisDrawingRef.then (drawingDataSnapshot) =>
      if not drawingDataSnapshot.exists()
        throw new DrawingNotFoundError()
      drawingData = drawingDataSnapshot.val()
      return drawingData


# The error that occurs when you try to load a drawing that doesn't exist.
FirebaseAccess.DrawingNotFoundError = class DrawingNotFoundError
