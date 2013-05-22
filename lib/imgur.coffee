request = require('request');

api_url = 'https://api.imgur.com/3'

request = request.defaults json: true

class Imgur
  setKey: (key) ->
    @.key = key
    @.authHeader = "Client-ID #{@.key}"



  getGallery: (section, sort, page, showViral, callback ) ->
    if typeof section is 'function'
      callback = section
      section = undefined
    if typeof sort is 'function'
      callback = sort
      sort = undefined
    if typeof page is 'function'
      callback = page
      page = undefined
    if typeof showViral is 'function'
      callback = showViral
      showViral = undefined


    if section is undefined
      section = 'hot'
    if sort is undefined
      sort = 'viral'
    if page is undefined or page < 0
      page = 0
    if showViral is undefined
      showViral = true
    if typeof callback isnt 'function'
      callback = () -> return

    req_opts =
      uri: "#{api_url}/gallery/#{section}/#{sort}/#{page}?showViral=#{!!showViral}"
      headers:
        'Authorization': @.authHeader
      json: true

    request.get req_opts, (err, req, body) ->
      callback(err, body.data || [])



  getGalleryComments: (imageId, callback=(()->)) ->
    req_opts =
      uri: "#{api_url}/gallery/#{imageId}/comments"
      headers:
        'Authorization': @.authHeader
      json: true
    request.get req_opts, (err, req, body) ->
      callback(err, body.data || [])

  upload: (file, callback) ->
    req_opts =
      uri: api_url + 'upload',
      qs:
        key: @.key
      'Authorization': @.authHeader

    req_opts.qs.type = 'base64';
    req_opts.body = file;

    request.post req_opts, (e, r, body) ->
      if e
        callback e
      else if r.statusCode isnt 200 or body.error
        callback body.error
      else
        callback null, body



exports = module.exports = (key) ->
  client = new Imgur
  client.setKey(key)
  client

