express = require 'express'
ECT = require 'ect'
{ flatten, unflatten } = require 'flat'
fs = require 'fs'
path = require 'path'
passport = require 'passport'
GoogleStrategy = require('passport-google').Strategy
{ Db, ObjectID } = require 'mongodb'
url = require 'url'
User = require './models/user'
UserList = require './lib/users'
_ = require 'lodash'

# Random bits of setup
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

{ ensureAuthenticated, ensureAdmin, ensureTrusted, parseUpload } = require './lib/functions'
ensureAuthenticatedStack = [ensureAuthenticated]
ensureAdminStack = [ensureAuthenticated, ensureAdmin]
ensureTrustedStack = [ensureAuthenticated, ensureTrusted]

passport.serializeUser (user, done) ->
  done null, user

passport.deserializeUser (obj, done) ->
  done null, new User obj

app = express()

ectRenderer = ECT
  watch: true
  root: __dirname + '/views'
app.engine '.ect', ectRenderer.render

app.set 'views', __dirname + '/views'

app.use express.static(path.resolve(__dirname, '../public'))
app.use express.bodyParser({uploadDir: __dirname + '/uploads'})
app.use(express.cookieParser())
app.use(express.session({secret: SESSION_SECRET}))
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

app.locals.LanguagesList = LanguagesList = require './lib/static-languages-list'
app.locals.ProjectsList = ProjectsList = require './lib/static-project-list'

Db.connect MONGO_URL, (err, db) ->
  if err then throw err
  console.log 'Connected to Mongo. Continuing setup...'

  siteCollection = db.collection 'language_data'
  stringsCollection = db.collection 'language_strings'

  ###
  # Controllers
  ###
  Application = require './controllers/application'
  Projects = require('./controllers/projects')({ app, db })
  Languages = require('./controllers/languages')({ app, db })

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

  app.get '/', ensureAuthenticatedStack, Application.get
  app.get '/login', Application.login

  app.get '/project/:project', ensureAuthenticatedStack, Projects.get
  app.post '/project/:project', ensureAdminStack, Projects.bootstrap
  app.put '/project/:project/generate', ensureAdminStack, Projects.generateManifest

  app.get '/project/:project/language/:language/translate', ensureAuthenticatedStack, Languages.get
  app.post '/project/:project/language/:language/translate', ensureAuthenticatedStack, Languages.post
  app.get '/project/:project/language/:language/resolve', ensureTrustedStack, Languages.getResolve
  app.post '/project/:project/language/:language/resolve', ensureTrustedStack, Languages.postResolve
  app.put '/project/:project/language/:language/push', ensureAdminStack, Languages.pushLanguage

  app.listen port, ->
    console.log "z8e ready to serve requests on port #{ port }"
