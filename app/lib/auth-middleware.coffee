User = require '../models/user'

ensureAuthenticated = (req, res, next) ->
  if req.isAuthenticated()
    return next()

  res.redirect '/login'

ensureAdmin = (req, res, next) ->
  if User.isAdmin req.user
    next()
  else
    res.send 403

ensureTrusted = (req, res, next) ->
  if User.isTrusted req.user
    next()
  else
    res.send 403

module.exports =
  authStack: [ensureAuthenticated]
  trustedStack: [ensureAuthenticated, ensureTrusted]
  adminStack: [ensureAuthenticated, ensureAdmin]