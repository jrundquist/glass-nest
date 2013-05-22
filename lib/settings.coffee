express     = require 'express'
everyauth   = require 'everyauth'
fs          = require 'fs'
url         = require 'url'
redis       = require 'redis'
RedisStore  = require('connect-redis')(express)
helpers     = require './helpers'
google      = require 'googleapis'


exports.boot = (app) ->

  (require './auth').bootApp app

  app.configure ()->

    app.set 'views', __dirname + '/../views'

    app.set 'view engine', 'ejs'

    app.use express.bodyParser()

    app.use express.methodOverride()

    app.use (req,res,next) ->
      res.header("X-powered-by", "Sharks")
      next()

    app.use require('connect-less')(
      src: __dirname + '/../public/'
      compress: true
      yuicompress: true
    )

    app.use require('./coffee-compile')(
      force: true
      src: __dirname + '/../public'
      streamOut: true
    )

    app.use express.compress()

    app.use express.static __dirname + '/../public'

    app.use express.cookieParser app.config.SITE_SECRET

    # Create a redis connection based on our env settings
    redisURL     = url.parse(process.env.REDISCLOUD_URL)
    sessionStore = redis.createClient(redisURL.port, redisURL.hostname, no_ready_check: true)
    sessionStore.auth redisURL.auth?.split(":")[1]

    app.sessionStore = new RedisStore(client: sessionStore)

    app.use express.session(
      secret: app.config.SITE_SECRET
      key: 'glass.sid'
      domain: app.config.DOMAIN
      httpOnly: true
      maxAge: 1000*60*60*24*5
      store: app.sessionStore
    )

    # Bind in the everyauth middleware
    app.use everyauth.middleware(app)

    # Helpers
    helpers.boot app

    # Everyone loves favicons!
    app.use express.favicon()

    # Compress all transactions
    app.use express.compress()

    # And last but not least the routers
    app.use app.router


  app.set 'showStackError', false


  # app.configure 'development', ()->
  #   app.use express.errorHandler
  #     dumpExceptions: true
  #     showStack: true


  app.configure 'staging', ()->
    app.enable 'view cache'


  app.configure 'production', ()->
    app.enable 'view cache'


  try
    gitHead = fs.readFileSync(__dirname+'/../.git/refs/remotes/origin/master', 'utf-8').trim()
    app.set 'revision', gitHead
  catch e
    app.set 'revision', 'r'+(new Date()).getTime()


