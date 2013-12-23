module.exports = ({ app, db }) ->
  get: (req, res) ->
    res.render 'index.ect'

  login: (req, res) ->
    res.render 'login.ect'