fs        = require 'fs'
targz     = require 'tar.gz'
md5       = require 'md5'
moment    = require 'moment'
async     = require 'async'
ftp       = require './ftp'
util      = require '../lib'

# 统一log风格
success                   = "[SUCCESS]:"
fail                      = "[FAIL]:"

# 可以约定的upload files name
dataFile                  = 'data.tar.gz'
md5File                   = 'data.md5'
successFile               = 'data.success'

# 以每天为目录存放upload files，格式：YYYYMMDD
path_prefix                = moment().format('YYYYMMDD')

# 约定父母目录为upload
upload                    = 'upload'

# 多文件上传使用
sourceFilePathArr         = ["#{dataFile}", "#{md5File}", "#{successFile}"]

# create tar.gz file with raw log file
createTarGzFileWithRawLogFile = (cb) ->
  # 获取原文，production call api
  sourceTarget              = 'test/raw/ssh/'     #临时测试
  # sourceTarget              = filepath     #临时测试
  read                      = targz().createReadStream(sourceTarget)

  # 在当前worker同级目录下创建results/upload/YYYYMMDD 的层级目录
  writePath = util.resultDir("#{upload}/#{path_prefix}")
  write     = fs.createWriteStream("#{writePath}/#{dataFile}")

  #compressed file write to local
  read.pipe write
  console.log "#{success} wrote file #{dataFile} to #{writePath}"

  cb null, writePath

# md5 targz file and create md5 context
createMd5File = (writePath, cb) ->
  # read .tar.gz file
  fs.readFile "#{writePath}/#{dataFile}", (err, buf) ->
    if err
      return cb "#{fail} #{err}", null
    console.log "#{success} read file #{writePath}/#{dataFile}"
    
    # md5 .tar.gz
    md5_message = md5 buf

    #create and write .md5 file to local
    fs.writeFile "#{writePath}/#{md5File}", md5_message, (err) ->
      if err
        return cb "#{fail} #{err}", null
      
      console.log "#{success} wrote md5 file #{md5File} to #{writePath}"
      cb null, writePath

#create and write .success file to local
createSuccessFile = (writePath, cb) ->
  fs.writeFile "#{writePath}/#{successFile}", "success", (err) ->
    if err
      return cb "#{fail} #{err}", null
    
    console.log "#{success} wrote success file #{successFile} to #{writePath}"
    cb null, writePath

# call ftp api to upload files
uploadFiles = (writePath, cb) ->
  # set ftp connection config
  ftp.setConfig 'convertionMaster'

  # ftp upload
  ftp.mput "#{writePath}", "upload/#{path_prefix}", sourceFilePathArr, (err, data) -> 
    cb err, data

# main
main = (args, callback) ->
  async.waterfall [
    createTarGzFileWithRawLogFile,
    createMd5File,
    createSuccessFile,
    uploadFiles
  ], (err, data) ->
    # 返回
    callback err, data

module.exports = { main }