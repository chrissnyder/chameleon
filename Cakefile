{spawn, exec} = require 'child_process'
 
task 'watch', 'Watch source files and build JS & CSS', (options) ->
  runCommand = (name, args...) ->
    proc =           spawn name, args
    proc.stderr.on   'data', (buffer) -> console.log buffer.toString()
    proc.stdout.on   'data', (buffer) -> console.log buffer.toString()
    proc.on          'exit', (status) -> process.exit(1) if status isnt 0
  
  runCommand 'coffee', '-wc', '-o', 'public/scripts/', 'public/scripts/src/'
  runCommand 'node_modules/stylus/bin/stylus', '-w', 'public/stylesheets/src/', '-o', 'public/stylesheets/'
  runCommand 'coffee', 'server.coffee'
