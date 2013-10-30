{spawn, exec} = require 'child_process'
 
task 'start', 'Compile JS/CSS and start server.', (options) ->
  runCommand = (name, args...) ->
    proc =           spawn name, args
    proc.stderr.on   'data', (buffer) -> console.log buffer.toString()
    proc.stdout.on   'data', (buffer) -> console.log buffer.toString()
    proc.on          'exit', (status) -> process.exit(1) if status isnt 0
  
  runCommand 'coffee', '-wc', '-o', 'public/scripts/', 'public/scripts/src/'
  runCommand 'node_modules/stylus/bin/stylus', '-u', './node_modules/nib/lib/nib', '-w', 'public/styles/src/application.styl', '-o', 'public/styles/'
  runCommand 'coffee', './app/server.coffee'
