exports = module.exports = (app) ->
  # Home

  app.get '/remove', (req, res) ->
    res.send 200
    app.models.User.find (err, users) ->
      for user in users
        do (user) ->
          credentials = user.credentials(app)


          app.mirror.timeline.list()
            .withAuthClient(credentials)
            .execute (err, data) ->
              for card in data.items
                do (card) ->

                  console.log card
                  app.mirror.timeline.delete( id: card.id )
                    .withAuthClient(credentials)
                    .execute (err, data) ->
                      user.timelineItems = user.timelineItems.filter (c) -> c.id isnt card.id
                      user.save()


  app.get '/imgur', (req, res) ->
    app.imgur.getGallery 'hot', 'time', (err, gallery) ->
      i = 0
      while gallery[i].is_album is true
        i++

      image = gallery[i]
      app.imgur.getGalleryComments image.id, (err, comments) ->
        commentsFiltered = comments[0..2]
        res.json(commentsFiltered)

        app.models.User.find (err, users) ->
          for user in users
            do (user) ->
              if user.timelineItems.length > 0
                already = user.timelineItems.filter (card) -> return (!!card.html?.match(new RegExp(image.link)))
                if already.length > 0
                  return

              bundle = "igb-"+image.id

              for card in user.timelineItems
                do (card) ->
                  app.mirror.timeline.delete(card.id)
                    .withAuthClient(user.credentials(app))
                    .execute (err, data) ->
                      user.timelineItems = user.timelineItems.filter (c) -> c.id isnt card.id
                      user.save()

              for comment in commentsFiltered.reverse()
                app.mirror.timeline.insert(
                  resource:
                    bundleId: bundle
                    isBundleCover: false
                    text: comment.comment
                    speakableText: comment.comment+'. Upvoted '+comment.ups+' times'
                    menuItems: [
                      {
                        id: 0
                        action: "READ_ALOUD"
                      }
                      {
                        id: 1
                        action: "DELETE"
                      }
                    ]
                    datetime: (new Date(comment.datetime*1000)).toISOString()
                )
                .withAuthClient(user.credentials(app))
                .execute (err, data) ->
                  console.log err if err
                  user.timelineItems.push(data) if not err
                  user.save()

              app.mirror.timeline.insert(
                resource:
                  bundleId: bundle
                  isBundleCover: true
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
                .withAuthClient(user.credentials(app))
                .execute (err, data) ->
                  console.log err if err
                  user.timelineItems.push(data) if not err
                  user.save (err) ->
                    console.log err if err




