let fs      = require('fs')
let targz   = require('tar.gz')
let md5     = require('md5')
let FTP     = require('ftp')
let moment  = require('moment')

let read    = targz().createReadStream('../ftp_test/')

const compressedFile            = '../20161115/data.tar.gz'
const md5FileWithCompressedFile = '../20161115/data.md5'
const successFile               = '../20161115/data.success'

const path_prefix = moment().format('YYYYMMDD')
const destFilePathArr = [`${path_prefix}/data.tar.gz`, `${path_prefix}/data.md5`, `${path_prefix}/data.success`]
let destFilePathFnArr = []

let write   = fs.createWriteStream(compressedFile)

//compressed file write to local
read.pipe(write)

//md5 context
fs.readFile(compressedFile, (err, buf) => {
  let md5_message = md5(buf)
  console.log('md5_message:', md5_message)

  //md5 file write to local
  fs.writeFile(md5FileWithCompressedFile, md5_message, (err) => {
    if(err) throw `md5 file wrote error:${err}`
    console.log('md5 file wrote successfully!')

    //success file write to local
    fs.writeFile(successFile, (err) => {
      if(err) throw `success file wrote error: ${err}`
      console.log('success file wrote successfully!!')
      upload()
    })
  })
})

// use ftp upload 3 files to ftp server
const upload = () => {
  let ftpC = new FTP()

  destFilePathArr.forEach((item) => {
    destFilePathFnArr.push({
      key : () => {
        ftpC.on('ready', () => {
          ftpC.put(item, item, (err) => {
            if(err) throw `upload file ${item} fail,${err}`
          })
        })
      }
      })
  })

  ftpC.connect({
    host : 'localhost',
    user: 'kai',
    password: '123456a?'
  })

  Promise.all(destFilePathFnArr).then(values => {
    console.log(values)
    values.forEach(item => {
      item.key()
    })
  }).catch(err => {
    console.log(err)
    ftpC.end()
    ftpC.close()
  })
}
