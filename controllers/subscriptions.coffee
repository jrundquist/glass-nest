exports = module.exports = (app) ->
  # Home
  app.get '/subscriptions', (req, res) ->

    user = req.user

    app.mirror.subscriptions.list()
      .withAuthClient(user.credentials(app))
      .execute (err, data) ->
        res.json data || err


  app.get '/subscriptions/new', (req, res) ->
    user = req.user
    app.mirror.subscriptions.insert(
        resource:
          callbackUrl: 'https://'+process.env.DOMAIN
      )
      .withAuthClient(user.credentials(app))
      .execute (err, data) ->
        res.json data || err