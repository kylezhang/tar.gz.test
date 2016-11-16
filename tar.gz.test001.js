let fs      = require('fs')
let targz   = require('tar.gz')
let md5     = require('md5')
let FTP     = require('ftp')
let moment  = require('moment')

const dataFile                  = 'data.tar.gz'
const md5File                   = 'data.md5'
const successFile               = 'data.success'

const path_prefix                = moment().format('YYYYMMDD')

const compressedFile            = `${path_prefix}/${dataFile}`
const md5WithCompressedFile     = `${path_prefix}/${md5File}`
const successWithMd5File        = `${path_prefix}/${successFile}`

const sourceFilePathArr         = [compressedFile, md5WithCompressedFile, successWithMd5File]

let destFilePathFnArr           = []

const sourceTarget              = '../ftp_test/'
let read                        = targz().createReadStream(sourceTarget)

//create directory
if(!fs.existsSync(path_prefix)){
  fs.mkdirSync(path_prefix)
}

let write                       = fs.createWriteStream(compressedFile)
//compressed file write to local
read.pipe(write)

//md5 context
fs.readFile(compressedFile, (err, buf) => {
  let md5_message = md5(buf)
  console.log('md5_message:', md5_message)

  //md5 file write to local
  fs.writeFile(md5WithCompressedFile, md5_message, (err) => {
    if(err) throw `md5 file wrote error:${err}`
    console.log('md5 file wrote successfully!')

    //success file write to local
    fs.writeFile(successWithMd5File, 'success', (err) => {
      if(err) throw `success file wrote error: ${err}`
      console.log('success file wrote successfully!!')
      
      upload()
    })
  })
})

// use ftp upload 3 files to ftp server
const upload = () => {
  let ftpC = new FTP()

  destFilePathFnArr.push({
    fn : () => {
      ftpC.mkdir(`upload/${path_prefix}`, true, (err) => {
          if(err) throw `created path: upload/${path_prefix} on ftp server fail, ${err}`
          console.log(`created path: upload/${path_prefix} on ftp server successfully!!!`)
    })
    }
  })

  sourceFilePathArr.forEach((item) => {
    destFilePathFnArr.push({
      fn : () => {
        ftpC.on('ready', () => {
          ftpC.put(item, `upload/${item}`, (err) => {
            if(err) throw `upload file ${item} fail,${err}`
            console.log(`${item} uploaded successfully!!!`)
            ftpC.end()
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
    values.forEach(item => {
      item.fn()
    })
  })
  .catch(err => {
    console.log(err)
    ftpC.end()
  })
}
