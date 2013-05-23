nest = require 'unofficial-nest-api'

exports = module.exports = (app) ->
  # Home
  app.get '/login', (req, res) ->
    res.redirect '/auth/google'

  app.get '/post-login-check', app.gate.requireLogin, (req, res) ->
    console.log req.user.nestAuth
    if req.user.nestAuth?.user and req.user.nestAuth?.pass
      res.redirect '/'
    else
      res.redirect '/nest-auth'

  app.get '/nest-auth', app.gate.requireLogin, (req, res) ->
    res.render 'nest-auth'

  app.post '/nest-auth', app.gate.requireLogin, (req, res) ->
    user = req.user
    nest.login req.body.username, req.body.password, (err, data) ->
      if err
        return res.redirect '/nest-auth?incorrect'

      nest.fetchStatus (data) ->
        console.log data
        user.nestAuth =
          user: req.body.username
          pass: req.body.password
        for deviceId of data.shared
          user.device = deviceId
        for structureId of data.structure
          user.structure = structureId
        user.save (err) ->

          app.mirror.subscriptions.insert(
              resource:
                callbackUrl: process.env.GOOGLE_SUBSCRIPTION_CALLBACK
                collection: 'timeline'
                operation: []
                userToken: user.id
                verifyToken: process.env.GOOGLE_VERIFY_TOKEN
            )
            .withAuthClient(user.credentials(app))
            .execute()

          user.updateNestCard app

        res.redirect '/'

  app.get '/send-card', app.gate.requireLogin, (req, res) ->
    req.user.updateNestCard(app)
    res.send 200




