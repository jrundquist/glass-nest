everyauth = require 'everyauth'

exports.boot = module.exports.boot = (app) ->
  app.use (req, res, next) ->

    res.locals.request = req

    res.locals.loggedIn = !!(req.session?.auth?.loggedIn)

    res.locals.domain = process.env.DOMAIN;

    res.locals.path = req.route?.path or "";

    res.locals.base = ('/' == app.route) ? '' : app.route;

    res.locals.revision = app.settings.revision or ''

    res.locals.mode = app.settings.env

    res.locals.distinctId = req.sessionID

    res.locals.user = req.user

    next()



  app.locals.app = app

  app.locals.numberize = (number) ->
    r = number[-1..0]
    if r is '1' then 'st' else if r is '2' then 'nd' else if r is '3' then 'rd' else 'th'