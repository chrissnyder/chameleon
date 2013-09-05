users = require '../lib/users'

TRUSTED_LEVEL = 5
ADMIN_LEVEL = 10

class User
  email: ''
  level: 0
  displayName: ''

  constructor: ({ @displayName, emails}) ->
    @email = emails[0].value

    if @email in users.admin
      @level = ADMIN_LEVEL
    else if @email in users.trusted
      @level = TRUSTED_LEVEL

  isAdmin: ->
    if @level >= ADMIN_LEVEL
      true
    else
      false

  isTrusted: ->
    if @level >= TRUSTED_LEVEL
      true
    else
      false

module.exports = User