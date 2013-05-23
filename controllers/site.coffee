nest = require 'unofficial-nest-api'

exports = module.exports = (app) ->
  # Home
  app.get '/', (req, res) ->
    if req.user
      user = req.user
      nest.login user.nestAuth.user, user.nestAuth.pass, (err, data) =>
        res.redirect('/nest-auth') if err
        nest.fetchStatus (data) =>
          shared = data.shared[user.device]
          device = data.device[user.device]
          structure = data.structure[user.structure]

          targetTemp  = user.localTemp(shared.target_temperature)
          currentTemp = user.localTemp(shared.current_temperature)
          leaf        = device.leaf
          away        = structure.away

          if leaf
            leafText = "<img src=\"http://i.imgur.com/57lfBl8.png\" width=\"60\" height=\"61\" style=\"margin: 5px 0 0px 0\">\n"
          else
            leafText = '\n'

          if away
            awayText = "<p class=\"text-x-small\">away</p>"
          else
            awayText = "\n"

          html = "<article class=\"glass-view\">\n\
                      <section>\n\
                        <div class=\"layout-figure\">\n\
                          <div class=\"align-center\">\n\
                            <p class=\"text-x-large\">#{currentTemp}</p>\n\
                            #{leafText}\
                          </div>\n\
                          <div>\n\
                            <div class=\"text-normal align-center\">\n\
                              <p>Target Temp</p>\n\
                              <p style=\"font-size:130px;line-height:1.5em;font-weight:300;\"\">#{targetTemp}<sup>&deg;</sup></p>\n\
                            </div>\n\
                          </div>\n\
                        </div>\n\
                      </section>\n\
                      <footer>\n\
                        <img src=\"http://i.imgur.com/lBERcCp.png\" height=\"25px\" />\n\
                      </footer>\n\
                    </article>"
          res.render 'account', card: html
    else
      res.render 'index'

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






