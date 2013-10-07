users = require '../lib/users'

TRUSTED_LEVEL = 5
ADMIN_LEVEL = 10

class User
  @isAdmin: ({ level }) ->
    if level >= ADMIN_LEVEL
      true
    else
      false

  @isTrusted: ({ level }) ->
    if level >= TRUSTED_LEVEL
      true
    else
      false
      
  email: ''
  level: 0
  displayName: ''

  constructor: ({ @displayName, emails}) ->
    @email = emails[0].value

    if @email in users.admin
      @level = ADMIN_LEVEL
    else if @email in users.trusted
      @level = TRUSTED_LEVEL

  isAdmin: -> @constructor.isAdmin @
  isTrusted: -> @constructor.isTrusted @

module.exports = User
