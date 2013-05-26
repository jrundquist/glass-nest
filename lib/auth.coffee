everyauth = require 'everyauth'
fs        = require 'fs'
helpers   = require './helpers'

exports.requireLogin = (req, res, next) ->
  if not req.loggedIn
    rw = req.headers['x-requested-with']
    req.session.redirectTo = req.url or '/';
    return res.send(401) if rw is "XMLHttpRequest"
    return res.redirect '/login'
  next()


exports.bootApp = (app) ->

  exports.bootEveryauth app

  app.gate =
    requireLogin: exports.requireLogin



exports.bootEveryauth = (app) =>


  ## Helpers for finding-or-creating users from oauth

  findOrCreateGoogleData = (googleData, accessToken, extra, promise) ->
    app.models.User.findOne({email: googleData.email}).exec (err, user) ->
      return promise.fail(err) if err
      if user
        user.token = accessToken
        user.token_type = extra.token_type
        user.refresh_token = extra.refresh_token
        user.save (err) ->
          promise.fulfill user
      else
        user = new app.models.User(
          firstName: googleData.given_name
          lastName: googleData.family_name
          email: googleData.email
        )
        user.token = accessToken
        user.token_type = extra.token_type
        user.refresh_token = extra.refresh_token
        user.save (err) ->
          return promise.fail(err) if err
          promise.fulfill user







  everyauth.everymodule
    .handleLogout( (req, res) ->
      mpId = req.sessionID
      req.logout()
      @.redirect res, this.logoutRedirectPath()
    )
    .findUserById( (userId, callback) ->
      app.models.User.findById userId, callback
    )
    .performRedirect( (res, location) ->
      res.redirect(location, 303)
    )



  everyauth.google
    .appId(app.config.GOOGLE_CLIENT_ID)
    .appSecret(app.config.GOOGLE_CLIENT_SECRET)
    .callbackPath('/oauth2callback')
    .authQueryParam(
      access_type:'offline'
    )
    .alwaysDetectHostname(true)
    .scope(
      [
        'https://www.googleapis.com/auth/glass.timeline'
        'https://www.googleapis.com/auth/userinfo.profile'
      ].join ' '
    )
    .findOrCreateUser( (session, accessToken, extra, googleUser) ->
      promise = @.Promise()
      findOrCreateGoogleData(googleUser, accessToken, extra, promise)
      promise
    )
    .redirectPath('/post-login-check');



