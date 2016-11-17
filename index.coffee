file      = require './src/file_tar_gz_md5'

console.log file
file.main null, (err, data) ->
  if err
    console.log err
  console.log 'success:', data