AWS = require 'aws-sdk'
{ flatten } = require 'flat'
shortId = require 'shortid'
_ = require 'lodash'

module.exports = ({ app, db }) ->
  ProjectsList = app.locals.ProjectsList
  siteCollection = db.collection 'language_data'
  stringsCollection = db.collection 'language_strings'

  get: (req, res) ->
    { language, project } = req.params

    siteCollection.findOne { project }, (err, projectDoc) ->
      if err
        console.log 'Error', err
        res.send 500
        return

      enStrings = flatten projectDoc.languages.en
      nonEnStrings = flatten _.merge projectDoc.languages.en, projectDoc.languages[language]

      opts =
        project: project
        language: language
        en: enStrings
        strings: nonEnStrings

      res.render 'translate.ect', opts

  post: (req, res) ->
    { language, project } = req.params
    { name, value } = req.body

    unless name and value
      res.send 400
      return

    stringObj = {}
    stringObj[name] = value

    obj = {}
    obj["string"] = stringObj
    obj["id"] = shortId.generate()

    stringsCollection.update { project, language }, { $push: { strings: obj } }, { upsert: true, w: 1 }, (err, updatedDoc) ->
      if err
        res.send 400
        return

      res.send 200

  getResolve: (req, res) ->
    { language, project } = req.params

    stringsCollection.findOne { project, language }, (err, doc) ->
      { strings } = doc || []

      opts =
        project: project
        language: language
        strings: strings

      res.render 'resolver.ect', opts

  postResolve: (req, res) ->
    { language, project } = req.params
    { accept, id, name, value } = req.body

    updateQuery = 
      project: project
      language: language

    updateAction =
      $pull:
        "strings":
          id: id

    stringsCollection.update updateQuery, updateAction, (err, result) ->
      unless accept is "true"
        res.send 200
      else
        obj = {}
        obj["languages.#{ language }.#{ name }"] = value

        updateAction =
          $set: obj

        siteCollection.update { project }, updateAction, (err, doc) ->
          res.send 200

  pushLanguage: (req, res) ->
    { project, language } = req.params

    siteCollection.findOne { project }, (err, projectDoc) ->
      projectDoc.languages[language] ?= {}
      exportedLanguage = _.merge projectDoc.languages.en, projectDoc.languages[language]

      buffer = new Buffer JSON.stringify exportedLanguage
      key = "/translations/#{ language }.json"

      if ProjectsList[project].prefix
        key = "#{ ProjectsList[project].prefix }" + key

      bucket = ProjectsList[project].bucket

      s3 = new AWS.S3
        accessKeyId: process.env.AMAZON_ACCESS_KEY_ID
        secretAccessKey: process.env.AMAZON_SECRET_ACCESS_KEY
        region: 'us-east-1'

      s3.putObject
        Bucket: bucket
        Key: key
        Body: buffer
        ACL: 'public-read'
        ContentType: 'application/json'
        (err, s3Res) ->
          if err
            console.log err
            res.send 400
          else
            res.send 200
