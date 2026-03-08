import { useState, useEffect } from 'react'
import { Capacitor } from '@capacitor/core'
import { AuthProvider, useAuth } from './contexts/AuthContext'
import UploadPage   from './pages/UploadPage'
import ResultPage   from './pages/ResultPage'
import AuthPage     from './pages/AuthPage'
import ProfilePage  from './pages/ProfilePage'
import PrivacyPage  from './pages/PrivacyPage'
import LandingPage  from './pages/LandingPage'

/* ─── Detect /privacy route (works both as web URL and in-app nav) ────────── */
function useRoute() {
  const [path, setPath] = useState(() => window.location.pathname)
  useEffect(() => {
    const handler = () => setPath(window.location.pathname)
    window.addEventListener('popstate', handler)
    return () => window.removeEventListener('popstate', handler)
  }, [])
  return path
}

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
      <img
        src="/logo-512.png"
        alt="AIHomeRun"
        style={{ width: 96, height: 96, borderRadius: 22, marginBottom: 4 }}
      />
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

/* ─── Bottom tab bar ──────────────────────────────────────────────────────── */
function TabBar({ active, onChange }) {
  const tabs = [
    { id: 'home',    label: '主页',  icon: null },
    { id: 'profile', label: '资料',  icon: '👤' },
  ]
  return (
    <nav style={{
      position: 'fixed',
      bottom: 0,
      left: 0,
      right: 0,
      zIndex: 100,
      display: 'flex',
      background: 'var(--bg-elevated, rgba(255,255,255,0.92))',
      backdropFilter: 'blur(20px)',
      WebkitBackdropFilter: 'blur(20px)',
      borderTop: '0.5px solid var(--sep)',
      paddingBottom: 'env(safe-area-inset-bottom, 0px)',
    }}>
      {tabs.map(tab => {
        const isActive = active === tab.id
        return (
          <button
            key={tab.id}
            onClick={() => onChange(tab.id)}
            style={{
              flex: 1,
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
              gap: 3,
              padding: '8px 0 6px',
              background: 'none',
              border: 'none',
              cursor: 'pointer',
              color: isActive ? 'var(--blue)' : 'var(--label3, #8e8e93)',
              transition: 'color 0.15s',
            }}
          >
            {tab.icon ? (
              <span style={{ fontSize: 22, lineHeight: 1 }}>{tab.icon}</span>
            ) : (
              <img
                src="/logo-512.png"
                alt="Home"
                style={{
                  width: 24, height: 24,
                  borderRadius: 6,
                  objectFit: 'cover',
                  opacity: isActive ? 1 : 0.45,
                  transition: 'opacity 0.15s',
                }}
              />
            )}
            <span style={{
              fontSize: 10,
              fontWeight: isActive ? 600 : 400,
              letterSpacing: '0.1px',
            }}>
              {tab.label}
            </span>
          </button>
        )
      })}
    </nav>
  )
}

/* ─── Main content (requires auth) ───────────────────────────────────────── */
function AppContent() {
  const { user, loading } = useAuth()
  const [result, setResult]       = useState(null)
  const [activeTab, setActiveTab] = useState('home')

  if (loading) return <SplashScreen />
  if (!user)   return <AuthPage />

  const showTabBar = !result

  function handleTabChange(tab) {
    setActiveTab(tab)
    if (tab !== 'home') setResult(null)
  }

  return (
    <>
      <div style={{
        height: '100%',
        paddingBottom: showTabBar ? 'calc(49px + env(safe-area-inset-bottom, 0px))' : 0,
        boxSizing: 'border-box',
        overflowY: 'auto',
      }}>
        {result ? (
          <ResultPage result={result} onReset={() => setResult(null)} />
        ) : activeTab === 'home' ? (
          <UploadPage onResult={setResult} />
        ) : (
          <ProfilePage />
        )}
      </div>

      {showTabBar && (
        <TabBar active={activeTab} onChange={handleTabChange} />
      )}
    </>
  )
}

/* ─── Root ────────────────────────────────────────────────────────────────── */
export default function App() {
  const path = useRoute()

  // Native iOS/Android app → skip landing page, go directly to app
  if (Capacitor.isNativePlatform()) {
    return (
      <AuthProvider>
        <div className="app-shell">
          <AppContent />
        </div>
      </AuthProvider>
    )
  }

  // Web: / → marketing landing page (public)
  if (path === '/' || path === '') return <LandingPage />

  // /privacy is publicly accessible — no auth needed (required for App Store)
  if (path === '/privacy') return <PrivacyPage />

  // /app and everything else → the actual web app (requires auth)
  return (
    <AuthProvider>
      <div className="app-shell">
        <AppContent />
      </div>
    </AuthProvider>
  )
}
