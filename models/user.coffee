crypto = require('crypto')
algorithm = "aes256"
key = "qCi5zPedUoS6Yrl"
nest = require 'unofficial-nest-api'


mongoose = require('mongoose')
Schema = mongoose.Schema

# Schema Setup
UserSchema = new Schema(
  email:
    type: String
    index: true
  firstName: String
  lastName: String
  oauthInfo: {}
  token: String
  token_type: String
  refresh_token: String

  celcius:
    type: Boolean
    default: false

  card: String

  _nestAuth: String
  _structure: String
  _device: String
)


UserSchema.virtual('password')
  .get( () -> this._password )
  .set( (pass) ->
    @.setPassword(pass)
    @._password = pass
  )


UserSchema.virtual('structure')
  .get( ()->
    if @._structure
      return JSON.parse(@.decryptSecure @._structure)
    undefined
  )
  .set( (obj)->
    @._structure = @.encryptSecure JSON.stringify(obj)
  )

UserSchema.virtual('device')
  .get( ()->
    if @._device
      return JSON.parse(@.decryptSecure @._device)
    undefined
  )
  .set( (obj)->
    @._device = @.encryptSecure JSON.stringify(obj)
  )

UserSchema.virtual('nestAuth')
  .get( ()->
    if @._nestAuth
      return JSON.parse(@.decryptSecure @._nestAuth)
    undefined
  )
  .set( (obj) ->
    this._nestAuth = @.encryptSecure JSON.stringify(obj)
  )


UserSchema.method('encryptSecure', (text) ->
  cipher = crypto.createCipher algorithm, key
  cipher.update(text, 'utf8', 'hex') + cipher.final('hex')
)
UserSchema.method('decryptSecure', (encrypted)->
  decipher = crypto.createDecipher algorithm, key
  decipher.update(encrypted, 'hex', 'utf8') + decipher.final('utf8')
)

UserSchema.method('localTemp', (c) ->
  return c if @.celcius
  Math.round(c * (9 / 5.0) + 32.0)
)


UserSchema.method('updateNestCard', (app) ->
  nest.login @.nestAuth.user, @.nestAuth.pass, (err, data) =>
    return if err
    nest.fetchStatus (data) =>
      shared = data.shared[@.device]
      device = data.device[@.device]
      structure = data.structure[@.structure]

      targetTemp  = @.localTemp(shared.target_temperature)
      currentTemp = @.localTemp(shared.current_temperature)
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


      html = "<article>\n\
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

      if @.card
        app.mirror.timeline.patch(
          id: @.card
          resource:
            html: html
          )
          .withAuthClient(@.credentials(app))
          .execute (err, res) =>
            if err and err.code is 404
              @.card = undefined
              @.updateNestCard(app)
      else
        app.mirror.timeline.insert(
          resource:
            html: html
            notification:
              level: "DEFAULT"
            menuItems: [
              {
                id: 0
                action: "REPLY"
              }
              {
                id: 1
                action: "CUSTOM"
                values: [
                  {
                    state: "DEFAULT",
                    displayName: "Update",
                    iconUrl: "http://i.imgur.com/DRZUngH.png"
                  }
                ]
              },
              {
                id: 2,
                action: "TOGGLE_PINNED"
              }
            ]
          )
          .withAuthClient(@.credentials(app))
          .execute (err, data) =>
            @.card = data.id if not err
            @.save(err)
)




UserSchema.virtual('id')
  .get( () -> this._id.toHexString() )

UserSchema.virtual('name')
  .get( () -> "#{@.firstName} #{@.lastName}".trim() )
  .set( (fullName) ->
    p = fullName.split ' '
    @.firstName = p[0]
    @.lastName = p[1]
  )

UserSchema.method('credentials', (app) ->
    oauth2Client = new app.google.OAuth2Client(
      process.env.GOOGLE_CLIENT_ID,
      process.env.GOOGLE_CLIENT_SECRET,
      process.env.GOOGLE_REDIRECT_URL);
    oauth2Client.credentials =
      token_type: @.token_type
      access_token: @.token,
      refresh_token: @.refresh_token
    oauth2Client
  )



UserSchema.pre 'save', (next) ->
  @.modified = Date.now()
  next()



# Exports
exports.UserSchema = module.exports.UserSchema = UserSchema
exports.boot = module.exports.boot = (app) ->
  mongoose.model 'User', UserSchema
  app.models.User = mongoose.model 'User'


