import { useState } from 'react'
import { AuthProvider, useAuth } from './contexts/AuthContext'
import UploadPage  from './pages/UploadPage'
import ResultPage  from './pages/ResultPage'
import AuthPage    from './pages/AuthPage'

/* ─── Splash / loading screen ────────────────────────────────────────────── */
function SplashScreen() {
  return (
    <div style={{
      height: '100%',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      background: 'var(--bg)',
      gap: 16,
    }}>
      <span style={{ fontSize: 56, lineHeight: 1 }}>⚾</span>
      <span style={{
        font: 'var(--text-headline)',
        color: 'var(--label2)',
        letterSpacing: '-0.3px',
      }}>
        AIHomeRun
      </span>
    </div>
  )
}

/* ─── Main content (requires auth) ───────────────────────────────────────── */
function AppContent() {
  const [result, setResult] = useState(null)
  const { user, loading }   = useAuth()

  if (loading) return <SplashScreen />
  if (!user)   return <AuthPage />

  return result
    ? <ResultPage result={result} onReset={() => setResult(null)} />
    : <UploadPage onResult={setResult} />
}

/* ─── Root ────────────────────────────────────────────────────────────────── */
export default function App() {
  return (
    <AuthProvider>
      <div className="app-shell">
        <AppContent />
      </div>
    </AuthProvider>
  )
}
