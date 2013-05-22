exports = module.exports = (app) ->
  # Home
  app.get '/login', (req, res) ->
    res.redirect '/auth/google'
