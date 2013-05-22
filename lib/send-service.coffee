cronJob = require('cron').CronJob


exports = module.exports = (app) ->

  return

  ######
  # This seems to be broken / not running?
  #####

  console.log '[starting cron service]'

  job = new cronJob(
      cronTime: '0 */2 * * * *'
      onTick: runPushTopGallery
      start: true
  )
  job.start();

  runPushTopGallery = () ->
    console.log "Running pushTopGallery"
    app.imgur.getGallery (err, r, body) ->
      gallery = body.data

      i = 0
      while gallery[i].is_album is true
        i++

      image = gallery[i]

      res.json(image)

      app.models.User.find (err, users) ->
        for user in users
          oauth2Client = new app.google.OAuth2Client(
            process.env.GOOGLE_CLIENT_ID,
            process.env.GOOGLE_CLIENT_SECRET,
            process.env.GOOGLE_REDIRECT_URL);
          oauth2Client.credentials =
            token_type: user.token_type
            access_token: user.token,
            refresh_token: user.refresh_token


          already = user.timelineItems.filter (card) -> return (!!card.html.match(new RegExp(image.link)))
          if already.length > 0
            console.log "skipping #{user.name} - already pushed card"
            continue

          app.mirror.timeline.insert(
            resource:
              html:
                "<article class=\"photo\">\n\
                  <img src=\"#{image.link}\" width=\"100%\">\n\
                  <div class=\"photo-overlay\"></div>\n\
                  <section>\n\
                    <p class=\"text-auto-size\">#{image.title}</p>\n\
                  </section>\n\
                  <footer>\n\
                    <div>\n\
                      <img src=\"http://s.imgur.com/images/imgurlogo-header.png\">\n\
                    </div>\n\
                  </footer>\n\
                </article>\n"
              menuItems: [
                {
                  id: 1
                  action: "DELETE"
                }
              ]
              notification:
                level: "DEFAULT"
            )
            .withAuthClient(oauth2Client)
            .execute (err, data) ->
              console.log err, data
              user.timelineItems.push(data) if not err
              user.save()




