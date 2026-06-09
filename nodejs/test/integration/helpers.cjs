'use strict'

const { spawn } = require('node:child_process')

let slsOfflineProcess

exports.startSlsOffline = async function startSlsOffline() {
  return new Promise((resolve, reject) => {
    slsOfflineProcess = spawn("serverless", ["offline", "start"], {cwd: __dirname})

    const output = []

    const onData = (data) => {
      output.push(data.toString())
      if (data.toString().includes('Server ready:')) {
        resolve(slsOfflineProcess)
      }
    }

    slsOfflineProcess.stdout.on('data', onData)
    slsOfflineProcess.stderr.on('data', onData)

    slsOfflineProcess.on('close', (code) => {
      if (code !== 0) {
        reject(new Error(`serverless process exited with code ${code}\n${output.join('')}`))
      }
    })
  })
}

exports.stopSlsOffline = function stopSlsOffline() {
  slsOfflineProcess.kill()
}
