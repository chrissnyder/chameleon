users = require './users'

User = require '../models/user'

TRUSTED_LEVEL = 5
ADMIN_LEVEL = 10

# exports.setPermissions = (req, res, next) ->
#   { user } = req
#   email = user.emails[0].value

#   req.userLevel = 0

#   if email in users.admin
#     req.userLevel = ADMIN_LEVEL
#   else if email in users.trusted
#     req.userLevel = TRUSTED_LEVEL

#   next()

exports.ensureAuthenticated = (req, res, next) ->
  if req.isAuthenticated()
    return next()

  res.redirect '/login'

exports.ensureAdmin = (req, res, next) ->
  if req.userLevel >= ADMIN_LEVEL
    next()
  else
    res.send 401

exports.isAdmin = (req, res, next) ->
  if req.userLevel >= ADMIN_LEVEL
    req.isAdmin = true
  else
    req.isAdmin = false

  next()

exports.ensureTrusted = (req, res, next) ->
  if req.userLevel >= TRUSTED_LEVEL
    next()
  else
    res.send 401

exports.isTrusted = (req, res, next) ->
  if req.userLevel >= TRUSTED_LEVEL
    req.isAdmin = true
  else
    req.isAdmin = false

  next()
