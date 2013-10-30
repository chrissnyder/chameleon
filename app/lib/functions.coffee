coffee = require 'coffee-script'
fs = require 'fs'
path = require 'path'
User = require '../models/user'

module.exports = 
  ensureAuthenticated: (req, res, next) ->
    if req.isAuthenticated()
      return next()

    res.redirect '/login'

  ensureAdmin: (req, res, next) ->
    if User.isAdmin req.user
      next()
    else
      res.send 403

  ensureTrusted: (req, res, next) ->
    if User.isTrusted req.user
      next()
    else
      res.send 403

  parseUpload: (fileObject) ->
    try
      switch path.extname fileObject.name
        when ".json"
          rawStrings = JSON.parse fs.readFileSync fileObject.path
        when ".coffee"
          rawFile = fs.readFileSync fileObject.path
          rawStrings = coffee.eval rawFile.toString()
        else
          throw new Error 'File extension not supported.'
    catch e
      console.log 'e', e
      return false

    rawStrings
