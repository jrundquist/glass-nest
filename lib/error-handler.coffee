
exports.boot = (app) ->

  app.log = app.log || () -> console.log.apply(console.log, arguments);

  logErrors = (err, req, res, next) ->
    app.log({message: '500 error: '+err.message, err: err})
    next(err)

  clientErrors = (err, req, res, next) ->
    console.log(2);
    if req.xhr
      res.send 500, error: err.message
    else
      next(err)

  allErrors = (err, req, res, next) ->
    console.log(3);
    res.status(500);
    res.render 'errors/index', error: err

  app.use(logErrors)
  app.use(clientErrors)
  app.use(allErrors)

exports.setup404 = (app) ->

  error404 = (req, res, next) ->
    app.log({message: '404: '+req.url})
    res.status 404
    if req.xhr
      req.send 404
    else
      res.render 'errors/404'


  app.use(error404);