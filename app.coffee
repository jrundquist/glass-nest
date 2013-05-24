# Main application file
#   Kicks off the whole show
#
app      = (require 'express')()
port     = process.env.PORT or 8080
mongoose = require 'mongoose'
settings = require './lib/settings'
errors   = require './lib/error-handler'
google   = require 'googleapis'


console.log "\n\nStarting in mode:", app.settings.env

app.config = process.env

app.google = google

mongoose.connection.on 'open', ()->


  google
    .discover('mirror', 'v1' )
    .execute (err,client) ->
      app.mirror = client.mirror

  OAuth2Client = google.OAuth2Client;

  app.oauth2Client = new OAuth2Client(
    process.env.GOOGLE_CLIENT_ID,
    process.env.GOOGLE_CLIENT_SECRET,
    process.env.GOOGLE_REDIRECT_URL);


  # Configuration
  settings.boot(app);

  # Error Handler
  errors.boot(app)


  # Bootstrap models
  app.models = {}
  model_loc = __dirname + '/models'
  model_files = (require 'fs').readdirSync model_loc
  model_files.forEach (file) ->
    (require model_loc + '/' + file).boot(app)


  # Bootstrap controllers
  controller_loc = __dirname + '/controllers'
  controller_files = (require 'fs').readdirSync controller_loc
  controller_files.forEach (file) ->
    (require controller_loc + '/' + file)(app)



  errors.setup404(app)


  # Start the app by listening on <port>
  server = app.listen port
  console.log "Glass-nest started on port #{port}"




mongoose.connect app.config.MONGOHQ_URL||'mongodb://localhost/test'