exports = module.exports = (app) ->

  app.get '/locations', (req, res) ->

    user = req.user

    oauth2Client = new app.google.OAuth2Client(
      process.env.GOOGLE_CLIENT_ID,
      process.env.GOOGLE_CLIENT_SECRET,
      process.env.GOOGLE_REDIRECT_URL);
    oauth2Client.credentials =
      token_type: user.token_type
      access_token: user.token,
      refresh_token: user.refresh_token

    app.mirror.locations.list()
      .withAuthClient(oauth2Client)
      .execute (err, data) ->
        res.json data || err