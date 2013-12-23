express = require 'express'
ECT = require 'ect'
{ Db, ObjectID } = require 'mongodb'
path = require 'path'

User = require './models/user'

port = process.env.PORT || 3002

if process.env.PORT
  MONGO_URL = "mongodb://#{ process.env.MONGO_USER }:#{ process.env.MONGO_PASSWORD }@paulo.mongohq.com:10057/app18536257"
  SESSION_SECRET = process.env.SESSION_SECRET
  RETURN_URL = "http://z8e.herokuapp.com/auth/google/return"
  REALM = "http://z8e.herokuapp.com/"
else
  MONGO_URL = "mongodb://localhost:27017/translations"
  SESSION_SECRET = "bacon-cereal-tempest-1266"
  RETURN_URL = "http://localhost:#{ port }/auth/google/return"
  REALM = "http://localhost:#{ port }/"

## Express setup
app = express()

ectRenderer = ECT
  watch: true
  root: __dirname + '/views'
app.engine '.ect', ectRenderer.render

app.set 'views', __dirname + '/views'

app.use express.static path.resolve __dirname, '../public'
app.use express.bodyParser { uploadDir: path.resolve __dirname, '../uploads' }
app.use express.cookieParser()
app.use express.session { secret: SESSION_SECRET }

## Auth
passport = require 'passport'
GoogleStrategy = require('passport-google').Strategy

{ authStack, trustedStack, adminStack } = require './lib/auth-middleware'

passport.serializeUser (user, done) ->
  done null, user

passport.deserializeUser (obj, done) ->
  done null, new User obj

app.use passport.initialize()
app.use passport.session()

app.use (req, res, next) ->
  res.locals.user = req.user if req.user?
  next()

passport.use new GoogleStrategy
  returnURL: RETURN_URL
  realm: REALM
  (identifier, profile, done) ->
    process.nextTick ->
      profile.identifier = identifier
      user = new User {displayName: profile.displayName, email: profile.emails[0].value}
      done null, user

## Locals
app.locals.LanguagesList = LanguagesList = require './lib/static-languages-list'
app.locals.ProjectsList = ProjectsList = require './lib/static-project-list'

## Go
Db.connect MONGO_URL, (err, db) ->
  if err then throw err
  console.log 'Connected to Mongo. Continuing setup...'

  { Application, Projects, Languages } = require('./controllers')({ app, db })

  # Authentication Routes
  app.get(
    '/auth/google'
    passport.authenticate 'google', { failureRedirect: '/login' }
    (req, res) ->
      res.redirect '/'
  )

  app.get(
    '/auth/google/return'
    passport.authenticate 'google', { failureRedirect: '/login' }
    (req, res) ->
      res.redirect '/'
  )

  app.get '/', authStack, Application.get
  app.get '/login', Application.login

  app.get '/project/:project', authStack, Projects.get
  app.post '/project/:project', adminStack, Projects.bootstrap
  app.put '/project/:project/generate', adminStack, Projects.generateManifest

  app.get '/project/:project/language/:language/translate', authStack, Languages.get
  app.post '/project/:project/language/:language/translate', authStack, Languages.post
  app.get '/project/:project/language/:language/resolve', trustedStack, Languages.getResolve
  app.post '/project/:project/language/:language/resolve', trustedStack, Languages.postResolve
  app.put '/project/:project/language/:language/push', adminStack, Languages.pushLanguage

  app.listen port, ->
    console.log "z8e ready to serve requests on port #{ port }"
