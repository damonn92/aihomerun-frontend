import { useState } from 'react'
import { Eye, EyeOff, AlertCircle, ArrowLeft, Mail } from 'lucide-react'
import { useAuth } from '../contexts/AuthContext'

/* ─── SVG Logos ───────────────────────────────────────────────────────────── */
const AppleLogo = () => (
  <svg width="17" height="20" viewBox="0 0 814 1000" fill="currentColor" aria-hidden>
    <path d="M788.1 340.9c-5.8 4.5-108.2 62.2-108.2 190.5 0 148.4 130.3 200.9 134.2 202.2-.6 3.2-20.7 71.9-68.7 141.9-42.8 61.6-87.5 123.1-155.5 123.1s-85.5-39.5-164-39.5c-76 0-103.7 40.8-165.9 40.8s-105-57.9-155.5-127.4C46 376.4 0 209.4 0 62.5c0-91.5 31.6-140 100.8-200 58.1-50.5 166.7-93.8 234.3-93.8 13 0 36 3.2 66.7 9.7 34.8 7.1 64.3 27.3 85.5 50.5 53.8-58.4 125.7-93.8 218-93.8 22.5 0 119.9 4.5 198.4 73.8C846.3 151.9 876 215.7 876 340.9zm-249.2-152.5c-52.7-59.4-127-98.2-196.3-98.2-14 0-43.5 7.7-73.5 17.8-34.8 11.9-64.3 27-87.5 37.9-23.2-11-52.7-27-87.5-37.9-30-10.1-59.5-17.8-73.5-17.8-69.3 0-143.6 38.8-196.3 98.2-49.4 56-68.7 125.7-68.7 204.4 0 80 18.3 155.1 55.6 218.6 32.3 55.6 80.4 105.1 140.7 136.7 26.9 14 56.7 21.1 86.2 21.1 24.4 0 46.5-4.9 66.7-14 14.6-6.4 29.9-9.7 45.2-9.7 15.3 0 30.6 3.3 45.2 9.7 20.2 9.1 42.3 14 66.7 14 29.5 0 59.3-7.1 86.2-21.1 60.3-31.6 108.4-81.1 140.7-136.7 37.3-63.5 55.6-138.6 55.6-218.6 0-78.7-19.3-148.4-68.7-204.4z" />
  </svg>
)

const GoogleLogo = () => (
  <svg width="18" height="18" viewBox="0 0 24 24" aria-hidden>
    <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
    <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
    <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
    <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
  </svg>
)

/* ─── Input Field ─────────────────────────────────────────────────────────── */
function Input({ label, type = 'text', value, onChange, placeholder, autoComplete, suffix }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      {label && (
        <label style={{
          font: 'var(--text-caption2)',
          fontWeight: 600,
          letterSpacing: 0.6,
          textTransform: 'uppercase',
          color: 'var(--label3)',
          paddingLeft: 4,
        }}>
          {label}
        </label>
      )}
      <div style={{ position: 'relative' }}>
        <input
          type={type}
          value={value}
          onChange={onChange}
          placeholder={placeholder}
          autoComplete={autoComplete}
          spellCheck={false}
          autoCapitalize="none"
          style={{
            width: '100%',
            background: 'var(--bg3)',
            border: 'none',
            borderRadius: 'var(--r-md)',
            padding: '15px 16px',
            paddingRight: suffix ? 48 : 16,
            font: 'var(--text-body)',
            color: 'var(--label)',
            outline: 'none',
            WebkitAppearance: 'none',
            boxSizing: 'border-box',
          }}
        />
        {suffix && (
          <div style={{
            position: 'absolute',
            right: 14,
            top: '50%',
            transform: 'translateY(-50%)',
          }}>
            {suffix}
          </div>
        )}
      </div>
    </div>
  )
}

/* ─── Social Button ───────────────────────────────────────────────────────── */
function SocialButton({ icon, label, onClick, loading, style: extraStyle }) {
  return (
    <button
      onClick={onClick}
      disabled={loading}
      style={{
        width: '100%',
        padding: '15px 20px',
        borderRadius: 'var(--r-md)',
        border: 'none',
        font: 'var(--text-callout)',
        fontWeight: 600,
        letterSpacing: '-0.1px',
        cursor: loading ? 'not-allowed' : 'pointer',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 10,
        transition: 'transform 0.1s var(--ease), opacity 0.15s var(--ease)',
        opacity: loading ? 0.5 : 1,
        ...extraStyle,
      }}
      onMouseDown={e => { if (!loading) e.currentTarget.style.transform = 'scale(0.97)' }}
      onMouseUp={e => e.currentTarget.style.transform = 'scale(1)'}
      onTouchStart={e => { if (!loading) e.currentTarget.style.transform = 'scale(0.97)' }}
      onTouchEnd={e => e.currentTarget.style.transform = 'scale(1)'}
    >
      {icon}
      {label}
    </button>
  )
}

/* ─── Divider ─────────────────────────────────────────────────────────────── */
function Divider() {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, margin: '4px 0' }}>
      <div style={{ flex: 1, height: '0.5px', background: 'var(--sep)' }} />
      <span style={{ font: 'var(--text-caption1)', color: 'var(--label3)' }}>or</span>
      <div style={{ flex: 1, height: '0.5px', background: 'var(--sep)' }} />
    </div>
  )
}

/* ─── Check Email Screen ──────────────────────────────────────────────────── */
function CheckEmailScreen({ email, onBack }) {
  return (
    <div style={{
      flex: 1,
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      padding: '0 32px',
      textAlign: 'center',
      gap: 16,
    }}>
      {/* Mail icon */}
      <div style={{
        width: 72, height: 72,
        borderRadius: 22,
        background: 'rgba(10,132,255,0.12)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        marginBottom: 8,
      }}>
        <Mail size={34} color="var(--blue)" strokeWidth={1.5} />
      </div>

      <h2 style={{
        font: 'var(--text-title2)',
        letterSpacing: '-0.5px',
        color: 'var(--label)',
        margin: 0,
      }}>
        Check your email
      </h2>

      <p style={{
        font: 'var(--text-subhead)',
        color: 'var(--label2)',
        margin: 0,
        lineHeight: 1.5,
        maxWidth: 280,
      }}>
        We sent a verification link to{' '}
        <strong style={{ color: 'var(--label)' }}>{email}</strong>.
        Click it to activate your account.
      </p>

      <p style={{
        font: 'var(--text-footnote)',
        color: 'var(--label3)',
        margin: '8px 0 0',
      }}>
        Didn't get it? Check your spam folder.
      </p>

      <button
        onClick={onBack}
        style={{
          marginTop: 24,
          font: 'var(--text-subhead)',
          fontWeight: 600,
          color: 'var(--blue)',
          background: 'none',
          border: 'none',
          cursor: 'pointer',
          padding: '8px 16px',
        }}
      >
        ← Back to Sign In
      </button>
    </div>
  )
}

/* ─── Auth Page ───────────────────────────────────────────────────────────── */
export default function AuthPage() {
  const { signIn, signUp, signInWithGoogle, signInWithApple, resetPassword } = useAuth()

  // view: 'signIn' | 'signUp' | 'forgot' | 'checkEmail'
  const [view,        setView]        = useState('signIn')
  const [email,       setEmail]       = useState('')
  const [password,    setPassword]    = useState('')
  const [confirmPwd,  setConfirmPwd]  = useState('')
  const [showPwd,     setShowPwd]     = useState(false)
  const [loading,     setLoading]     = useState(false)
  const [socialLoad,  setSocialLoad]  = useState(null) // 'google' | 'apple' | null
  const [error,       setError]       = useState(null)
  const [checkEmail,  setCheckEmail]  = useState('')  // email for check-email screen

  function clearForm() {
    setEmail('')
    setPassword('')
    setConfirmPwd('')
    setError(null)
    setShowPwd(false)
  }

  function switchView(v) {
    clearForm()
    setView(v)
  }

  async function handleSubmit() {
    setError(null)
    if (!email) return setError('Please enter your email address.')
    if (!password) return setError('Please enter your password.')

    if (view === 'signUp') {
      if (password.length < 8) return setError('Password must be at least 8 characters.')
      if (password !== confirmPwd) return setError('Passwords do not match.')
    }

    setLoading(true)
    try {
      if (view === 'signIn') {
        await signIn(email, password)
      } else {
        await signUp(email, password)
        setCheckEmail(email)
        setView('checkEmail')
      }
    } catch (err) {
      setError(err.message || 'Something went wrong. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  async function handleForgot() {
    if (!email) return setError('Please enter your email address.')
    setLoading(true)
    setError(null)
    try {
      await resetPassword(email)
      setCheckEmail(email)
      setView('checkEmail')
    } catch (err) {
      setError(err.message || 'Failed to send reset email.')
    } finally {
      setLoading(false)
    }
  }

  async function handleGoogle() {
    setSocialLoad('google')
    setError(null)
    try {
      await signInWithGoogle()
    } catch (err) {
      setError(err.message)
      setSocialLoad(null)
    }
  }

  async function handleApple() {
    setSocialLoad('apple')
    setError(null)
    try {
      await signInWithApple()
    } catch (err) {
      setError(err.message)
      setSocialLoad(null)
    }
  }

  /* ── Check-email screen ── */
  if (view === 'checkEmail') {
    return (
      <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: 'var(--bg)' }}>
        <CheckEmailScreen email={checkEmail} onBack={() => switchView('signIn')} />
      </div>
    )
  }

  const isForgot = view === 'forgot'

  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: 'var(--bg)' }}>

      {/* ── Top safe area + back ── */}
      <div style={{ padding: '16px 20px 0', minHeight: 44, display: 'flex', alignItems: 'center' }}>
        {isForgot && (
          <button
            onClick={() => switchView('signIn')}
            style={{
              display: 'flex', alignItems: 'center', gap: 4,
              font: 'var(--text-body)', color: 'var(--blue)',
              background: 'none', border: 'none', cursor: 'pointer', padding: '4px 0',
            }}
          >
            <ArrowLeft size={18} strokeWidth={2.5} /> Back
          </button>
        )}
      </div>

      {/* ── Scrollable form ── */}
      <div
        className="scroll-content"
        style={{ flex: 1, overflowY: 'auto', padding: '16px 24px', paddingBottom: 40 }}
      >

        {/* Branding */}
        <div style={{ textAlign: 'center', marginBottom: 36 }}>
          <div style={{ fontSize: 52, lineHeight: 1, marginBottom: 12 }}>⚾</div>
          <h1 style={{
            font: 'var(--text-title1)',
            letterSpacing: '-0.7px',
            color: 'var(--label)',
            margin: '0 0 6px',
          }}>
            {isForgot ? 'Reset Password' : 'AIHomeRun'}
          </h1>
          <p style={{
            font: 'var(--text-subhead)',
            color: 'var(--label2)',
            margin: 0,
          }}>
            {isForgot
              ? 'Enter your email to receive a reset link'
              : 'AI Baseball Coaching'}
          </p>
        </div>

        {/* ── Tab switcher (Sign In / Sign Up) ── */}
        {!isForgot && (
          <div className="ios-seg" style={{ marginBottom: 28 }}>
            {[['signIn', 'Sign In'], ['signUp', 'Sign Up']].map(([v, label]) => (
              <button
                key={v}
                className={`ios-seg-item ${view === v ? 'active' : ''}`}
                onClick={() => switchView(v)}
              >
                {label}
              </button>
            ))}
          </div>
        )}

        {/* ── Form fields ── */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>

          <Input
            label="Email"
            type="email"
            value={email}
            onChange={e => setEmail(e.target.value)}
            placeholder="you@example.com"
            autoComplete="email"
          />

          {!isForgot && (
            <Input
              label="Password"
              type={showPwd ? 'text' : 'password'}
              value={password}
              onChange={e => setPassword(e.target.value)}
              placeholder={view === 'signUp' ? 'Min 8 characters' : '••••••••'}
              autoComplete={view === 'signIn' ? 'current-password' : 'new-password'}
              suffix={
                <button
                  onClick={() => setShowPwd(p => !p)}
                  style={{
                    background: 'none', border: 'none', cursor: 'pointer',
                    padding: 0, color: 'var(--label3)', display: 'flex',
                  }}
                >
                  {showPwd
                    ? <EyeOff size={18} strokeWidth={1.8} />
                    : <Eye size={18} strokeWidth={1.8} />}
                </button>
              }
            />
          )}

          {view === 'signUp' && (
            <Input
              label="Confirm Password"
              type={showPwd ? 'text' : 'password'}
              value={confirmPwd}
              onChange={e => setConfirmPwd(e.target.value)}
              placeholder="Repeat password"
              autoComplete="new-password"
            />
          )}
        </div>

        {/* Forgot password link */}
        {view === 'signIn' && (
          <div style={{ textAlign: 'right', marginTop: 8 }}>
            <button
              onClick={() => switchView('forgot')}
              style={{
                font: 'var(--text-footnote)',
                color: 'var(--blue)',
                background: 'none', border: 'none',
                cursor: 'pointer', padding: '4px 0',
              }}
            >
              Forgot password?
            </button>
          </div>
        )}

        {/* Error */}
        {error && (
          <div style={{
            marginTop: 12,
            background: 'rgba(255,69,58,0.10)',
            border: '1px solid rgba(255,69,58,0.28)',
            borderRadius: 'var(--r-md)',
            padding: '11px 14px',
            display: 'flex', alignItems: 'flex-start', gap: 10,
          }}>
            <AlertCircle size={15} color="var(--red)" style={{ marginTop: 2, flexShrink: 0 }} />
            <span style={{ font: 'var(--text-footnote)', color: 'var(--red)', lineHeight: 1.45 }}>
              {error}
            </span>
          </div>
        )}

        {/* Primary Button */}
        <button
          className="ios-btn-primary"
          onClick={isForgot ? handleForgot : handleSubmit}
          disabled={loading}
          style={{ marginTop: 20 }}
        >
          {loading ? (
            <span style={{ opacity: 0.7 }}>
              {isForgot ? 'Sending…' : view === 'signIn' ? 'Signing in…' : 'Creating account…'}
            </span>
          ) : (
            isForgot ? 'Send Reset Link'
              : view === 'signIn' ? 'Sign In'
                : 'Create Account'
          )}
        </button>

        {/* Social buttons (not shown for forgot) */}
        {!isForgot && (
          <>
            <Divider />

            {/* Sign in with Apple */}
            <SocialButton
              icon={<AppleLogo />}
              label="Continue with Apple"
              onClick={handleApple}
              loading={socialLoad === 'apple'}
              style={{
                background: '#fff',
                color: '#000',
                marginBottom: 10,
              }}
            />

            {/* Sign in with Google */}
            <SocialButton
              icon={<GoogleLogo />}
              label="Continue with Google"
              onClick={handleGoogle}
              loading={socialLoad === 'google'}
              style={{
                background: 'var(--bg3)',
                color: 'var(--label)',
              }}
            />
          </>
        )}

        {/* Toggle sign in / sign up */}
        {!isForgot && (
          <p style={{
            textAlign: 'center',
            marginTop: 28,
            font: 'var(--text-footnote)',
            color: 'var(--label3)',
          }}>
            {view === 'signIn' ? "Don't have an account? " : 'Already have an account? '}
            <button
              onClick={() => switchView(view === 'signIn' ? 'signUp' : 'signIn')}
              style={{
                font: 'inherit', fontWeight: 600,
                color: 'var(--blue)',
                background: 'none', border: 'none',
                cursor: 'pointer', padding: 0,
              }}
            >
              {view === 'signIn' ? 'Sign Up' : 'Sign In'}
            </button>
          </p>
        )}

        {/* Legal */}
        <p style={{
          textAlign: 'center',
          marginTop: 20,
          font: 'var(--text-caption2)',
          color: 'var(--label4)',
          lineHeight: 1.5,
        }}>
          By continuing, you agree to our Terms of Service and Privacy Policy.
        </p>

      </div>
    </div>
  )
}
