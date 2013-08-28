users = require '../lib/users'

TRUSTED_LEVEL = 5
ADMIN_LEVEL = 10

class User
  email: ''
  userLevel: 0
  displayName: ''

  constructor: (rawUser) ->
    @displayName = rawUser.displayName
    @email = rawUser.emails[0].value

    if @email in users.admin
      @userLevel = ADMIN_LEVEL
    else if @email in users.trusted
      @userLevel = TRUSTED_LEVEL

  isAdmin: ->
    if @userLevel >= ADMIN_LEVEL
      true
    else
      false

  isTrusted: ->
    if @userLevel >= TRUSTED_LEVEL
      true
    else
      false

module.exports = User