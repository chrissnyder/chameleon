users = require './users'

User = require '../models/user'

exports.ensureAuthenticated = (req, res, next) ->
  if req.isAuthenticated()
    return next()

  res.redirect '/login'

exports.ensureAdmin = (req, res, next) ->
  if req.user.isAdmin()
    next()
  else
    res.send 403

exports.ensureTrusted = (req, res, next) ->
  if req.user.isTrusted()
    next()
  else
    res.send 403
