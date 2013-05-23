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

    payload = req.body

    if payload.verifyToken is process.env.GOOGLE_VERIFY_TOKEN
      res.send 200
    else
      return res.send 401

    ## Gret the user from the payload
    app.models.User.findOne( _id: payload.userToken ).exec (err, user) ->
      return if err or not user

      ## Check if we got a 'reply' message back
      if payload.operation is 'INSERT'
        app.mirror.timeline.get(id: payload.itemId)
          .withAuthClient(user.credentials(app))
          .execute (err, data) ->
            # data is now the response card
            response = data

            # Grab the string from the response card
            query = response.text
            return if not query

            ## Remove thise card now that we have the string
            app.mirror.timeline.delete(id: payload.itemId)
              .withAuthClient(user.credentials(app))
              .execute () ->
                user.updateNestCard app


            ## Parse for degrees
            # 'temperature to XX'
            # 'XX degrees'
            matches = query.match /(?:temp(?:erature)\sto\s([0-9]+)\s)|(?:([0-9]+) degrees)/i
            if matches
              temp = matches[1] || matches[2]
              nest.login user.nestAuth.user, user.nestAuth.pass, (err, data) ->
                nest.fetchStatus (data) ->
                  nest.setTemperature(user.device, parseInt(temp, 10)) if not err

      else if payload.operation is 'UPDATE'
        # Update the user's card
        user.updateNestCard app




