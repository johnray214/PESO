const { defineConfig } = require('@vue/cli-service')

// Laravel URL for dev proxy (browser hits :8081; dev server forwards /storage to Laravel).
const apiTarget = process.env.VUE_APP_API_TARGET || 'http://127.0.0.1:8000'

module.exports = defineConfig({
  transpileDependencies: true,
  devServer: {
    historyApiFallback: true,
    proxy: {
      '/storage': {
        target: apiTarget,
        changeOrigin: true,
      },
    },
  },
})