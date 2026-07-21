import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { HashRouter } from 'react-router-dom'
import './index.css'
import App from './App.jsx'

// HashRouter (not BrowserRouter): the app runs inside a Capacitor WebView served
// from https://localhost with no server-side routing, so path-based routes can
// fail to resolve. Hash routing keeps all navigation client-side and also makes
// route refreshes work on the Spring-served web build.
createRoot(document.getElementById('root')).render(
  <StrictMode>
    <HashRouter>
      <App />
    </HashRouter>
  </StrictMode>,
)
