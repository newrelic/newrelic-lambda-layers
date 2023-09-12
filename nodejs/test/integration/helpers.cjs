'use strict'

const { spawn } = require('node:child_process')

let slsOfflineProcess

exports.startSlsOffline = async function startSlsOffline() {
  return new Promise((resolve) => {
    slsOfflineProcess = spawn("serverless", ["offline", "start"], {cwd: __dirname})

    slsOfflineProcess.stderr.on('data', (err) => {
      if (err.toString().includes('Server ready:')) {
        resolve(slsOfflineProcess)
      }
    })
  })
}

exports.stopSlsOffline = function stopSlsOffline() {
  slsOfflineProcess.kill()
}
