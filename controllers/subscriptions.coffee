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
    res.send 200
    console.log req.body