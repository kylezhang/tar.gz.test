# lib模块
path   = require 'path'
mkdirp = require 'mkdirp'

resultDir = (dirname) ->
  dir = path.join __dirname, "../tmp/results/#{dirname}"
  try
    mkdirp.sync dir
    dir 
  catch error
    console.log error
    no

taskFilePath = (task, audienX = false) ->
  str = if audienX then 'task/audienX' else 'task'
  dir = resultDir str

  if audienX
    path.join dir, "task_#{task.name}_#{task.id}.csv"
  else
    path.join dir, "task_#{task.name}_#{task.id}.log"

module.exports = { resultDir, taskFilePath }