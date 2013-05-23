crypto = require('crypto')
algorithm = "aes256"
key = "qCi5zPedUoS6Yrl"

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
    default: true

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


