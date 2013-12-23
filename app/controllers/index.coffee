module.exports = ({ app, db }) ->
  Application: require('./application')({ app, db })
  Projects: require('./projects')({ app, db })
  Languages: require('./languages')({ app, db })
