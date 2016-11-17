ftp     = require 'ftp'
_       = require 'lodash'
conf    = require '../config/config'
fs      = require 'fs'
path    = require 'path'

class ftpLib

  constructor: (args) ->
    @config = conf.default
    # body...

  get: (remoteFile, localFile, callback) ->
    config   = @getConfig()
    localDir = path.dirname localFile
    return callback Error 'local dir not exists', null if not (fs.existsSync localDir)

    client  = new ftp()

    client.on 'error', (err)->
      console.log "ftp #{err}"

    client.on 'ready', ->
      console.log 'ftp connected.'
      client.get remoteFile, (err, stream) ->
        if err
          return callback err, null if callback

        stream.once 'close', ->
          client.end()

        stream.pipe fs.createWriteStream(localFile)
        callback null, "get ok"

    client.connect config

  ###
  # callback返回err, remoteFile path 
  ###
  put: (remoteFile, localFile, callback) ->
    client = new ftp()
    config = @getConfig()

    client.on 'error', (err)->
      console.log "ftp #{err}"
      callback err, null if callback

    client.on 'ready', ->
      console.log 'ftp connected.'
      client.put localFile, remoteFile, (err) ->
        if err
          return callback err, null if callback

        client.end()
        ret = 
          status: 'OK'
          file: "ftp://#{config.host}/#{remoteFile}"
        callback null, ret

    client.connect config
    
  ###
  # 多文件上传,
  # @remotePath: String, ftp目录
  # @localPath: String, local目录
  # @localFilesArr: Array, 本地文件目录和文件
  # @callback: err: String, error message, ret: Array, 每个任务的成功信息
  ###
  mput : (localPath, remotePath, localFilesArr, callback) ->
    return callback new Error "First argument is localPath required." if not localPath

    return callback new Error "Seconde argument is remotePath required." if not remotePath

    if not localPath or not _.isArray localFilesArr
      return callback new Error "Third argument is localFilesArr required and must be a local files name Array." 

    return callback new Error "Fourth argument is a callback required" if not _.isFunction callback

    success                   = "[SUCCESS]:"
    fail                      = "[FAIL]:"

    client = new ftp()
    config = @getConfig()

    destFilePathFnArr = []

    # 将mkdirP封装到 
    destFilePathFnArr.push(
      new Promise((resolve, reject) ->
        client.mkdir remotePath, true, (err) ->
          if err
            reject "#{fail} created path #{remotePath} on ftp server #{err}", null
          resolve null, "#{success} created path #{remotePath} on ftp server "
      )
    )
    localFilesArr.forEach (item) ->
      destFilePathFnArr.push(
        new Promise((resolve, reject) ->
          client.on "ready", () ->
            client.put "#{localPath}/#{item}", "#{remotePath}/#{item}", (err) ->
              if err
                reject "#{fail} upload file #{localPath}/#{item} #{err}", null

              client.end()
              console.log "#{success} uploaded file #{localPath}/#{item} to ftp server"
              resolve null, "#{success} uploaded file #{localPath}/#{item} to ftp server"
        )
      )
    
    # connect ftp server
    client.connect config

    #execut ftp action 
    Promise.all destFilePathFnArr
    .then (values) -> 
      callback(null, values);
    .catch (err) ->
      client.end()
      callback err, null

  #设置ftp 链接信息
  setConfig: (name) ->
    @config = conf[name] if conf[name]
    yes

  #获取ftp 链接信息
  getConfig: ->
    @config

  #在ftp server上创建目录
  mkdir: ( path, recursion, cb )->
    config = @getConfig()
    client = new ftp()
    client.connect config

    client.on 'error', (err)->
      console.log "ftp #{err}"
      cb && cb err

    client.on 'ready', ->
      console.log 'ftp connected.'
      client.mkdir path, recursion, ( err )->
        client.end()
        cb && cb err

module.exports = new ftpLib()