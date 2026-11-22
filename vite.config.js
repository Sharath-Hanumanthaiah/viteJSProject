import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
// VITE_API_PROXY_TARGET: env seam for CodeValid mock server (default: real backend)
const apiProxyTarget = process.env.VITE_API_PROXY_TARGET || 'http://localhost:5001'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    host: process.env.VITE_HOST || 'localhost',
    proxy: {
      '/api': {
        target: apiProxyTarget,
        changeOrigin: true,
        secure: false,
      }
    }
  }
})
