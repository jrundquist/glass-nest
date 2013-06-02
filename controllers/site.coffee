nest = require 'unofficial-nest-api'

exports = module.exports = (app) ->
  # Home
  app.get '/', (req, res) ->
    if req.user
      user = req.user
      user.cardHtml (err, html) ->
        return res.send(err) if err
        res.render 'account', card: html
    else
      res.render 'index'


  app.get '/about', (req, res) ->
    res.render 'about'


  app.get '/settings', app.gate.requireLogin, (req, res) ->
    nest.login req.user.nestAuth?.user, req.user.nestAuth?.pass, (err, data) ->
      return res.render 'account/settings-no-nest' if err
      nest.fetchStatus (data) ->
        devices = []
        structures = []
        for deviceId, deviceInfo of data.shared
          devices.push
            id: deviceId
            name: deviceInfo.name
            current_temperature: deviceInfo.current_temperature
        for structureId, structureInfo of data.structure
          structures.push
            id: structureId
            name: structureInfo.name
        res.render 'account/settings', devices: devices, structures: structures


  app.post '/settings', app.gate.requireLogin, (req, res) ->
    req.user.structure = req.body.structure
    req.user.device = req.body.device
    req.user.celcius = req.body.celcius is 'true'
    req.user.save()
    req.user.updateNestCard app
    res.redirect '/'

  app.get '/current-temp.:format?', app.gate.requireLogin, (req, res) ->
    u = req.user
    nest.login u.nestAuth?.user, u.nestAuth?.pass, (err, data) ->
      if err
        return res.redirect '/nest-auth?incorrect'
      nest.fetchStatus (data) ->
        return res.json data if req.params.format is 'raw'

        shared=data.shared[u.device]
        device=data.device[u.device]
        structure=data.structure[u.structure]

        res.render 'info',
          targetTemp: u.localTemp(shared.target_temperature)
          currentTemp: u.localTemp(shared.current_temperature)
          currentHumidity: device.target_humidity
          leaf: device.leaf
          timeToTarget: device.time_to_target
          away: structure.away
          #   nest.setTemperature(deviceId, nest.ftoc(70))






