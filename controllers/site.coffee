exports = module.exports = (app) ->
  # Home
  app.get '/', (req, res) ->
    res.render 'index'

  app.get '/new-card', (req, res) ->

    app.oauth2Client.credentials = {
      token_type: req.user.token_type
      access_token: req.user.token,
      refresh_token: req.user.refresh_token
    };

    app.mirror.timeline.insert({"resource":{"text":"Hello from the app!!"}})
      .withAuthClient(app.oauth2Client)
      .execute (err, data) ->
        console.log err, data
        req.user.timelineItems.push(data) if not err
        req.user.save () ->
          res.json data || err



  app.get '/cards', (req, res) ->

    app.oauth2Client.credentials = {
      token_type: req.user.token_type
      access_token: req.user.token,
      refresh_token: req.user.refresh_token
    };

    app.mirror.timeline.list()
      .withAuthClient(app.oauth2Client)
      .execute (err, data) ->
        res.json data || err


  app.get '/del', (req, res) ->

    app.oauth2Client.credentials = {
      token_type: req.user.token_type
      access_token: req.user.token,
      refresh_token: req.user.refresh_token
    };

    idToDelete = req.query.id || "b8738397-ff75-4cae-9041-d005cc26d125"

    app.mirror.timeline.delete({"id":idToDelete})
      .withAuthClient(app.oauth2Client)
      .execute (err, data) ->
        return res.json err if err
        req.user.timelineItems = req.user.timelineItems.filter( (t) -> t.id isnt idToDelete )
        req.user.save () ->
          res.json data || err

# {
# "kind": "mirror#timelineItem",
# "id": "b8738397-ff75-4cae-9041-d005cc26d125",
# "created": "2013-05-17T04:44:54.834Z",
# "updated": "2013-05-17T04:44:54.834Z",
# "etag": "\"r3ghbVW9Rp1kDP4UexS05_pFx4E/gjP6rOMcNEXDlKK8Fbm8JVgtf_M\"",
# "text": "Hello from the app!!"
# }