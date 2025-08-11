'use strict'

const path = require('path')
const webpack = require('webpack')

module.exports = {
  entry: './node_modules/newrelic/index.js',
  target: 'node',
  mode: 'production',
  externalsPresets: { node: true }, // in order to ignore built-in modules like path, fs, etc.
  externals: [
    // Only externalize things that shouldn't be bundled
    'import-in-the-middle',
    'split', // Optional dependency used by newrelic tracetractor tool
    'bufferutil',
    'utf-8-validate',
  ],

  output: {
    path: path.resolve('./nodejs/node_modules/newrelic'),
    filename: 'index.js',
    library: {
      type: 'commonjs2',
    }
  },
  
  resolve: {
    extensions: ['.js', '.mjs', '.json'],
    modules: [
      path.resolve('./src'),
      'node_modules',
    ],
  },
  module: {
    rules: [
      {
        test: /\.m?js$/,
        type: 'javascript/auto',
        resolve: {
          fullySpecified: false
        }
      },
      {
        test: /\.json$/,
        type: 'json'
      },
    ],
  },
  optimization: {
    minimize: true,
    providedExports: true,
    usedExports: true,
  },
  
  plugins: [
    // This is the single plugin you need to replace all OTEL modules
    // with our stub file. Your IgnorePlugin for non-code files is good practice.
    new webpack.NormalModuleReplacementPlugin(
      /^@opentelemetry\//,
      require.resolve('./otel-stubs.js')
    ),
   new webpack.IgnorePlugin({
      checkResource(resource) {
        const base = resource.replace(/^.*[\\/]/, '')
        return (
          /\.(md|proto|txt|html|css|scss|less)$/i.test(base) ||
          /^(LICENSE|THIRD_PARTY_NOTICES\.md|README\.md|NEWS\.md)$/i.test(base)
        )
      }
    })
  ],
}
