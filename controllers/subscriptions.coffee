nest = require 'unofficial-nest-api'


exports = module.exports = (app) ->
  # Home
  app.get '/subscriptions', (req, res) ->
    user = req.user
    app.mirror.subscriptions.list()
      .withAuthClient(user.credentials(app))
      .execute (err, data) ->
        res.json data || err


  app.get '/subscriptions/:id/remove', app.gate.requireLogin, (req, res) ->
    user = req.user
    app.mirror.subscriptions.delete(id: req.params.id)
      .withAuthClient(user.credentials(app))
      .execute (err, data) ->
        res.json data || err

  app.get '/subscriptions/new', app.gate.requireLogin, (req, res) ->
    user = req.user
    app.mirror.subscriptions.insert(
        resource:
          callbackUrl: process.env.DOMAIN+'/subscription/callback'
          collection: 'timeline'
          operation: []
          userToken: user.id
          verifyToken: process.env.GOOGLE_VERIFY_TOKEN
      )
      .withAuthClient(user.credentials(app))
      .execute (err, data) ->
        res.json data || err


  app.post '/subscription/callback', (req, res) ->
    if req.body.verifyToken is process.env.GOOGLE_VERIFY_TOKEN
      res.send 200
    else
      res.send 401

    return if req.body.operation isnt 'INSERT'

    console.log 'finding one user', req.body.userToken
    app.models.User.findOne _id: req.body.userToken, (err, user) ->
      console.log 'found user?', (err || user)
      return if err or not user

      app.mirror.timeline.get(req.body.itemId)
        .withAuthClient(user.credentials(app))
        .execute (err, data) ->
          console.log "On get of sent card", (err || data)

          response = data

          query = response.text

          app.mirror.timeline.delete(id: req.body.itemId)
            .withAuthClient(user.credentials(app))
            .execute()

          matches = query.match /(?:temp(?:erature)\sto\s([0-9]+)\s)|(?:([0-9]+) degrees)/i
          if matches
            temp = matches[1] || matches[2]
            nest.login user.nestAuth.user, user.nestAuth.pass, (err, data) ->
              nest.setTemperature(user.deviceId, parseInt(temp, 10)) if not err

              user.updateNestCard()


    console.log req.body