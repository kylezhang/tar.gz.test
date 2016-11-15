let request     = require('request')
let targz       = require('tar.gz')

let read        = request.get(`https://nodejs.org/dist/v7.1.0/node-v7.1.0.tar.gz`)

let write       = targz().createWriteStream('./')

read.pipe(write)