import { useState } from 'react'
import { Eye, EyeOff, AlertCircle, ArrowLeft, Mail } from 'lucide-react'
import { useAuth } from '../contexts/AuthContext'

/* ─── SVG Logos ───────────────────────────────────────────────────────────── */
const AppleLogo = () => (
  <svg width="17" height="20" viewBox="0 0 814 1000" fill="currentColor" aria-hidden>
    <path d="M788.1 340.9c-5.8 4.5-108.2 62.2-108.2 190.5 0 148.4 130.3 200.9 134.2 202.2-.6 3.2-20.7 71.9-68.7 141.9-42.8 61.6-87.5 123.1-155.5 123.1s-85.5-39.5-164-39.5c-76 0-103.7 40.8-165.9 40.8s-105-57.9-155.5-127.4C46 376.4 0 209.4 0 62.5c0-91.5 31.6-140 100.8-200 58.1-50.5 166.7-93.8 234.3-93.8 13 0 36 3.2 66.7 9.7 34.8 7.1 64.3 27.3 85.5 50.5 53.8-58.4 125.7-93.8 218-93.8 22.5 0 119.9 4.5 198.4 73.8C846.3 151.9 876 215.7 876 340.9zm-249.2-152.5c-52.7-59.4-127-98.2-196.3-98.2-14 0-43.5 7.7-73.5 17.8-34.8 11.9-64.3 27-87.5 37.9-23.2-11-52.7-27-87.5-37.9-30-10.1-59.5-17.8-73.5-17.8-69.3 0-143.6 38.8-196.3 98.2-49.4 56-68.7 125.7-68.7 204.4 0 80 18.3 155.1 55.6 218.6 32.3 55.6 80.4 105.1 140.7 136.7 26.9 14 56.7 21.1 86.2 21.1 24.4 0 46.5-4.9 66.7-14 14.6-6.4 29.9-9.7 45.2-9.7 15.3 0 30.6 3.3 45.2 9.7 20.2 9.1 42.3 14 66.7 14 29.5 0 59.3-7.1 86.2-21.1 60.3-31.6 108.4-81.1 140.7-136.7 37.3-63.5 55.6-138.6 55.6-218.6 0-78.7-19.3-148.4-68.7-204.4z" />
  </svg>
)

const GoogleIcon = () => (
  <svg version="1.1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" style={{ display: 'block', width: 20, height: 20 }}>
    <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
    <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
    <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
    <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
    <path fill="none" d="M0 0h48v48H0z"/>
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
        <div style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          textAlign: 'center',
          marginBottom: 36,
          gap: 10,
        }}>
          {/* Logo + title on one row */}
          <div style={{
            display: 'flex',
            alignItems: 'center',
            gap: 14,
          }}>
            <img
              src="/logo-512.png"
              alt="AIHomeRun"
              style={{ width: 64, height: 64, borderRadius: 16, objectFit: 'cover', flexShrink: 0 }}
            />
            <h1 style={{
              font: 'var(--text-title1)',
              letterSpacing: '-0.7px',
              color: 'var(--label)',
              margin: 0,
            }}>
              {isForgot ? 'Reset Password' : 'AIHomeRun'}
            </h1>
          </div>
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

            {/* Sign in with Google — official gsi-material-button */}
            <button
              className="gsi-material-button"
              onClick={handleGoogle}
              disabled={socialLoad === 'google'}
            >
              <div className="gsi-material-button-state" />
              <div className="gsi-material-button-content-wrapper">
                <div className="gsi-material-button-icon">
                  <GoogleIcon />
                </div>
                <span className="gsi-material-button-contents">
                  {socialLoad === 'google' ? 'Signing in…' : 'Sign in with Google'}
                </span>
                <span style={{ display: 'none' }}>Sign in with Google</span>
              </div>
            </button>
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
