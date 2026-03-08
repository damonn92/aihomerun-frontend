import { useState, useRef } from 'react'
import { Camera, AlertCircle, CheckCircle, LogOut, ChevronDown } from 'lucide-react'
import { useAuth } from '../contexts/AuthContext'

const API_BASE = import.meta.env.VITE_API_URL || ''

const LOAD_STEPS = [
  { emoji: '🎞️', text: 'Saving your video…' },
  { emoji: '🖼️', text: 'Extracting frames…' },
  { emoji: '🦾', text: 'Analyzing your pose…' },
  { emoji: '🤖', text: 'Generating your report…' },
]

/* ─── Loading Screen ──────────────────────────────────────────────────────── */
function LoadingScreen({ step }) {
  return (
    <div style={{
      background: 'var(--bg)',
      height: '100%',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      padding: '0 32px',
      gap: 0,
    }}>
      <div className="baseball-spin" style={{ marginBottom: 36 }}>⚾</div>

      <h2 style={{
        font: 'var(--text-title2)',
        color: 'var(--label)',
        margin: '0 0 8px',
        textAlign: 'center',
        letterSpacing: '-0.4px',
      }}>
        Analyzing Your Video
      </h2>
      <p style={{
        font: 'var(--text-subhead)',
        color: 'var(--label2)',
        margin: '0 0 48px',
        textAlign: 'center',
      }}>
        Your AI coach is watching…
      </p>

      <div style={{ width: '100%', maxWidth: 300, display: 'flex', flexDirection: 'column', gap: 16 }}>
        {LOAD_STEPS.map((s, i) => {
          const done    = i < step
          const current = i === step
          const pending = i > step
          return (
            <div key={i} style={{
              display: 'flex', alignItems: 'center', gap: 14,
              opacity: pending ? 0.3 : 1,
              transition: 'opacity 0.45s ease',
            }}>
              <div style={{
                width: 32, height: 32, borderRadius: 16, flexShrink: 0,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                background: done ? 'var(--green)' : current ? 'var(--brand)' : 'var(--fill3)',
                transition: 'background 0.4s ease',
                fontSize: done ? 16 : 14,
              }}>
                {done ? '✓' : s.emoji}
              </div>
              <span style={{
                font: current ? 'var(--text-subhead)' : 'var(--text-footnote)',
                fontWeight: current ? 600 : 400,
                color: done ? 'var(--label2)' : current ? 'var(--label)' : 'var(--label3)',
                transition: 'color 0.4s ease',
              }}>
                {s.text}
              </span>
            </div>
          )
        })}
      </div>
    </div>
  )
}

/* ─── Filming Guide Card ──────────────────────────────────────────────────── */
function FilmingGuideCard({ actionType }) {
  const [open, setOpen] = useState(false)
  const isPitch = actionType === 'pitch'

  /* ── Content data ── */
  const angles = isPitch ? [
    {
      label: 'Front View',
      color: '#0A84FF',
      bg: 'rgba(10,132,255,0.1)',
      border: 'rgba(10,132,255,0.2)',
      desc: 'Along the pitcher → home plate line',
      detail: 'Camera behind catcher or behind the pitcher',
    },
    {
      label: 'Side View',
      color: '#30D158',
      bg: 'rgba(48,209,88,0.1)',
      border: 'rgba(48,209,88,0.2)',
      desc: 'Perpendicular to pitch direction',
      detail: 'First-base or third-base side of the mound',
    },
  ] : [
    {
      label: 'Side View',
      color: '#0A84FF',
      bg: 'rgba(10,132,255,0.1)',
      border: 'rgba(10,132,255,0.2)',
      desc: 'Open-stance angle (recommended)',
      detail: 'Stand level with the batter on their open side',
    },
    {
      label: 'Catcher View',
      color: '#BF5AF2',
      bg: 'rgba(191,90,242,0.1)',
      border: 'rgba(191,90,242,0.2)',
      desc: 'Directly behind the batter',
      detail: 'Camera at catcher position, facing pitcher',
    },
  ]

  const checklist = isPitch ? [
    { text: 'Full body in frame — head to toe' },
    { text: 'Distance: 6–10 m (20–33 ft) from pitcher' },
    { text: 'Camera at waist height, level and stable' },
    { text: 'Use a tripod or prop camera on flat surface' },
    { text: 'One pitch per video only' },
  ] : [
    { text: 'One complete swing per video' },
    { text: 'Full body in frame — head to toe' },
    { text: 'Distance: 5–8 m (16–26 ft) from batter' },
    { text: 'Camera at roughly hip height' },
    { text: 'Use a tripod or prop camera on flat surface' },
  ]

  const avoid = isPitch ? [
    'Backlight or sun directly behind the pitcher',
    'Net, fence, or chain-link blocking the view',
    'Busy background (crowds, moving players)',
    'Handheld shaking — even small movement hurts accuracy',
  ] : [
    'Multiple swings in one clip — one rep only',
    'Mixing pitch types (e.g. tee + live in same video)',
    'Backlight or sun directly behind the batter',
    'Net, fence, or chain-link blocking the view',
  ]

  return (
    <div className="ios-card" style={{ marginBottom: 12, overflow: 'hidden' }}>

      {/* ── Header (always visible) ── */}
      <button
        onClick={() => setOpen(o => !o)}
        style={{
          width: '100%', padding: '13px 16px',
          display: 'flex', alignItems: 'center', gap: 12,
          background: 'none', border: 'none', cursor: 'pointer', textAlign: 'left',
        }}
      >
        {/* Icon */}
        <div style={{
          width: 34, height: 34, borderRadius: 10, flexShrink: 0,
          background: 'linear-gradient(135deg, rgba(10,132,255,0.16), rgba(10,132,255,0.07))',
          border: '1px solid rgba(10,132,255,0.18)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 17,
        }}>
          📷
        </div>

        {/* Text */}
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ font: 'var(--text-callout)', fontWeight: 600, color: 'var(--label)' }}>
            Filming Guide
          </div>
          <div style={{ font: 'var(--text-caption1)', color: 'var(--label3)', marginTop: 1 }}>
            {isPitch
              ? 'Camera setup tips for pitching'
              : 'Camera setup tips for batting swing'}
          </div>
        </div>

        {/* Chevron */}
        <ChevronDown
          size={17}
          color="var(--label3)"
          style={{
            flexShrink: 0,
            transform: open ? 'rotate(180deg)' : 'rotate(0deg)',
            transition: 'transform 0.22s ease',
          }}
        />
      </button>

      {/* ── Expanded Body ── */}
      {open && (
        <div style={{
          borderTop: '0.5px solid var(--sep)',
          padding: '16px 16px',
          display: 'flex', flexDirection: 'column', gap: 20,
        }}>

          {/* Camera Angles */}
          <div>
            <p style={{
              font: 'var(--text-caption2)', fontWeight: 700,
              letterSpacing: 0.8, textTransform: 'uppercase',
              color: 'var(--label3)', margin: '0 0 9px',
            }}>
              Recommended Camera Positions
            </p>
            <div style={{ display: 'flex', gap: 8 }}>
              {angles.map((a, i) => (
                <div key={i} style={{
                  flex: 1, borderRadius: 12,
                  background: a.bg, border: `1px solid ${a.border}`,
                  padding: '11px 12px',
                }}>
                  <div style={{
                    display: 'inline-block',
                    fontSize: 10, fontWeight: 700, letterSpacing: 0.5,
                    textTransform: 'uppercase',
                    color: a.color,
                    background: `${a.color}18`,
                    padding: '2px 7px', borderRadius: 4,
                    marginBottom: 7,
                  }}>
                    {a.label}
                  </div>
                  <div style={{ font: 'var(--text-caption1)', fontWeight: 600, color: 'var(--label)', marginBottom: 3 }}>
                    {a.desc}
                  </div>
                  <div style={{ font: 'var(--text-caption2)', color: 'var(--label3)', lineHeight: 1.4 }}>
                    {a.detail}
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Checklist */}
          <div>
            <p style={{
              font: 'var(--text-caption2)', fontWeight: 700,
              letterSpacing: 0.8, textTransform: 'uppercase',
              color: 'var(--label3)', margin: '0 0 9px',
            }}>
              Setup Checklist
            </p>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {checklist.map((item, i) => (
                <div key={i} style={{ display: 'flex', gap: 9, alignItems: 'flex-start' }}>
                  <div style={{
                    width: 18, height: 18, borderRadius: 5, flexShrink: 0,
                    background: 'rgba(48,209,88,0.15)',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    marginTop: 1,
                  }}>
                    <span style={{ color: 'var(--green)', fontSize: 11, fontWeight: 700, lineHeight: 1 }}>✓</span>
                  </div>
                  <span style={{ font: 'var(--text-footnote)', color: 'var(--label2)', lineHeight: 1.5 }}>
                    {item.text}
                  </span>
                </div>
              ))}
            </div>
          </div>

          {/* Avoid */}
          <div>
            <p style={{
              font: 'var(--text-caption2)', fontWeight: 700,
              letterSpacing: 0.8, textTransform: 'uppercase',
              color: 'var(--label3)', margin: '0 0 9px',
            }}>
              Avoid
            </p>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {avoid.map((item, i) => (
                <div key={i} style={{ display: 'flex', gap: 9, alignItems: 'flex-start' }}>
                  <div style={{
                    width: 18, height: 18, borderRadius: 5, flexShrink: 0,
                    background: 'rgba(255,69,58,0.12)',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    marginTop: 1,
                  }}>
                    <span style={{ color: 'var(--red)', fontSize: 11, fontWeight: 700, lineHeight: 1 }}>✕</span>
                  </div>
                  <span style={{ font: 'var(--text-footnote)', color: 'var(--label2)', lineHeight: 1.5 }}>
                    {item}
                  </span>
                </div>
              ))}
            </div>
          </div>

          {/* Pro tip — different for each type */}
          <div style={{
            background: isPitch
              ? 'rgba(48,209,88,0.06)'
              : 'rgba(255,159,10,0.06)',
            border: `1px solid ${isPitch ? 'rgba(48,209,88,0.16)' : 'rgba(255,159,10,0.18)'}`,
            borderRadius: 10, padding: '11px 13px',
            display: 'flex', gap: 9, alignItems: 'flex-start',
          }}>
            <span style={{ fontSize: 15, flexShrink: 0 }}>💡</span>
            <span style={{ font: 'var(--text-caption1)', color: 'var(--label2)', lineHeight: 1.55 }}>
              {isPitch
                ? <>A tripod is strongly recommended — even slight camera movement can reduce pose tracking accuracy.</>
                : <>Tee work, front toss, and live pitching use different AI models. Always upload them as <strong>separate videos</strong> for best results.</>
              }
            </span>
          </div>

        </div>
      )}
    </div>
  )
}

/* ─── Upload Page ─────────────────────────────────────────────────────────── */
export default function UploadPage({ onResult }) {
  const { user, signOut, getAccessToken } = useAuth()

  const [file, setFile]             = useState(null)
  const [preview, setPreview]       = useState(null)
  const [actionType, setActionType] = useState('swing')
  const [age, setAge]               = useState(10)
  const [loading, setLoading]       = useState(false)
  const [loadStep, setLoadStep]     = useState(0)
  const [error, setError]           = useState(null)
  const [dragOver, setDragOver]     = useState(false)

  const inputRef     = useRef(null)
  const stepTimerRef = useRef(null)

  function handleFile(f) {
    if (!f) return
    setFile(f)
    setError(null)
    setPreview(URL.createObjectURL(f))
  }

  function handleDrop(e) {
    e.preventDefault()
    setDragOver(false)
    handleFile(e.dataTransfer.files[0])
  }

  function startSteps() {
    let s = 0
    setLoadStep(0)
    stepTimerRef.current = setInterval(() => {
      s = Math.min(s + 1, LOAD_STEPS.length - 1)
      setLoadStep(s)
      if (s >= LOAD_STEPS.length - 1) clearInterval(stepTimerRef.current)
    }, 1600)
  }

  async function handleSubmit() {
    if (!file) return
    setLoading(true)
    setError(null)
    startSteps()

    const form = new FormData()
    form.append('file', file)
    form.append('action_type', actionType)
    form.append('age', age)

    try {
      const token = getAccessToken()
      const headers = token ? { Authorization: `Bearer ${token}` } : {}
      const res  = await fetch(`${API_BASE}/analyze`, { method: 'POST', body: form, headers })
      const data = await res.json()
      if (!res.ok) throw new Error(data.detail || 'Analysis failed')
      onResult(data)
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
      clearInterval(stepTimerRef.current)
    }
  }

  if (loading) return <LoadingScreen step={loadStep} />

  return (
    <div style={{ background: 'var(--bg)', height: '100%', display: 'flex', flexDirection: 'column' }}>

      {/* ── Navigation Bar ── */}
      <nav className="ios-navbar">
        <div className="ios-navbar-inner" style={{ justifyContent: 'space-between' }}>
          {/* Left: logo */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <span style={{ fontSize: 26, lineHeight: 1 }}>⚾</span>
            <span style={{
              font: 'var(--text-headline)',
              letterSpacing: '-0.4px',
              color: 'var(--label)',
            }}>
              AIHomeRun
            </span>
          </div>

          {/* Right: user avatar + logout */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{
              width: 30, height: 30, borderRadius: 15,
              background: 'var(--fill2)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              overflow: 'hidden',
            }}>
              {user?.user_metadata?.avatar_url
                ? <img src={user.user_metadata.avatar_url} style={{ width: '100%', height: '100%', objectFit: 'cover' }} alt="" />
                : <span style={{ font: 'var(--text-caption1)', fontWeight: 700, color: 'var(--label2)' }}>
                    {(user?.email?.[0] || '?').toUpperCase()}
                  </span>
              }
            </div>
            <button
              onClick={signOut}
              title="Sign out"
              style={{
                background: 'none', border: 'none', cursor: 'pointer',
                color: 'var(--label3)', padding: '4px',
                display: 'flex', alignItems: 'center',
              }}
            >
              <LogOut size={17} strokeWidth={1.8} />
            </button>
          </div>
        </div>
      </nav>

      {/* ── Scrollable Content ── */}
      <div
        className="scroll-content"
        style={{ flex: 1, overflowY: 'auto', padding: '28px 16px', paddingBottom: 'calc(env(safe-area-inset-bottom, 0px) + 32px)' }}
      >

        {/* Hero */}
        <div style={{ marginBottom: 32 }}>
          <h1 style={{
            font: 'var(--text-lg-title)',
            letterSpacing: '-1px',
            color: 'var(--label)',
            margin: '0 0 10px',
            lineHeight: 1.08,
          }}>
            Upload a video.<br />
            <span style={{ color: 'var(--brand)' }}>Get instant coaching.</span>
          </h1>
          <p style={{
            font: 'var(--text-subhead)',
            color: 'var(--label2)',
            margin: 0,
            lineHeight: 1.5,
          }}>
            AI analyzes your swing or pitch and delivers a personalized coaching report.
          </p>
        </div>

        {/* ── Upload Card ── */}
        <div
          className="ios-card"
          onDragOver={e => { e.preventDefault(); setDragOver(true) }}
          onDragLeave={() => setDragOver(false)}
          onDrop={handleDrop}
          onClick={() => !preview && inputRef.current?.click()}
          style={{
            marginBottom: 12,
            cursor: preview ? 'default' : 'pointer',
            border: dragOver
              ? '1.5px dashed var(--brand)'
              : preview
                ? 'none'
                : '1.5px dashed var(--sep)',
            minHeight: preview ? 'auto' : 200,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            transition: 'border-color 0.15s var(--ease)',
          }}
        >
          {preview ? (
            <div style={{ width: '100%' }}>
              <div style={{ position: 'relative' }}>
                <video
                  src={preview}
                  style={{ width: '100%', display: 'block', maxHeight: 260, objectFit: 'cover' }}
                  controls muted playsInline
                />
                <button
                  onClick={e => { e.stopPropagation(); setFile(null); setPreview(null) }}
                  style={{
                    position: 'absolute', top: 10, right: 10,
                    background: 'rgba(0,0,0,0.72)',
                    backdropFilter: 'blur(8px)', WebkitBackdropFilter: 'blur(8px)',
                    color: '#fff', border: 'none', borderRadius: '50%',
                    width: 30, height: 30, fontSize: 13, fontWeight: 600,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    cursor: 'pointer',
                  }}
                >✕</button>
              </div>
              <div style={{
                padding: '12px 16px', display: 'flex',
                alignItems: 'center', justifyContent: 'space-between',
                borderTop: '0.5px solid var(--sep)',
              }}>
                <span style={{ font: 'var(--text-footnote)', color: 'var(--label2)' }}>
                  📹 {file?.name?.length > 28 ? file.name.slice(0, 28) + '…' : file?.name}
                </span>
                <span style={{
                  font: 'var(--text-footnote)', fontWeight: 600, color: 'var(--green)',
                  display: 'flex', alignItems: 'center', gap: 4,
                }}>
                  <CheckCircle size={13} /> Ready
                </span>
              </div>
            </div>
          ) : (
            <div style={{
              display: 'flex', flexDirection: 'column', alignItems: 'center',
              gap: 12, padding: '36px 24px',
            }}>
              <div style={{
                width: 64, height: 64, borderRadius: 18,
                background: 'var(--fill3)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <Camera size={30} color="var(--label3)" strokeWidth={1.5} />
              </div>
              <div style={{ textAlign: 'center' }}>
                <p style={{ font: 'var(--text-callout)', fontWeight: 600, color: 'var(--label)', margin: '0 0 5px' }}>
                  Tap to Upload Video
                </p>
                <p style={{ font: 'var(--text-caption1)', color: 'var(--label3)', margin: 0 }}>
                  MP4 · MOV · AVI · Max 100 MB
                </p>
              </div>
            </div>
          )}
        </div>

        <input
          ref={inputRef}
          type="file"
          accept="video/*"
          style={{ display: 'none' }}
          onChange={e => handleFile(e.target.files[0])}
        />

        {/* ── Options Card — iOS Grouped List ── */}
        <div className="ios-card" style={{ marginBottom: 12 }}>

          {/* Action Type — Segmented Control */}
          <div style={{ padding: '14px 16px' }}>
            <div style={{
              font: 'var(--text-caption2)', fontWeight: 600,
              letterSpacing: 0.8, textTransform: 'uppercase',
              color: 'var(--label3)', marginBottom: 10,
            }}>
              Action Type
            </div>
            <div className="ios-seg">
              {[
                ['swing', '⚾ Batting Swing'],
                ['pitch', '🤾 Pitching'],
              ].map(([val, label]) => (
                <button
                  key={val}
                  className={`ios-seg-item ${actionType === val ? 'active' : ''}`}
                  onClick={() => setActionType(val)}
                >
                  {label}
                </button>
              ))}
            </div>
          </div>

          {/* Age Stepper */}
          <div className="ios-row" style={{ borderTop: '0.5px solid var(--sep)' }}>
            <span className="ios-row-label">Player Age</span>
            <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
              <button
                onClick={() => setAge(a => Math.max(6, a - 1))}
                style={{
                  width: 30, height: 30, borderRadius: 15,
                  background: 'var(--fill1)', color: 'var(--label)',
                  fontSize: 20, fontWeight: 300,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  transition: 'opacity 0.1s',
                }}
                onMouseDown={e => e.currentTarget.style.opacity = '0.6'}
                onMouseUp={e => e.currentTarget.style.opacity = '1'}
              >−</button>
              <span style={{
                font: 'var(--text-headline)', color: 'var(--label)',
                minWidth: 52, textAlign: 'center',
              }}>
                {age} yrs
              </span>
              <button
                onClick={() => setAge(a => Math.min(18, a + 1))}
                style={{
                  width: 30, height: 30, borderRadius: 15,
                  background: 'var(--fill1)', color: 'var(--label)',
                  fontSize: 20, fontWeight: 300,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  transition: 'opacity 0.1s',
                }}
                onMouseDown={e => e.currentTarget.style.opacity = '0.6'}
                onMouseUp={e => e.currentTarget.style.opacity = '1'}
              >+</button>
            </div>
          </div>
        </div>

        {/* ── Filming Guide Card ── */}
        <FilmingGuideCard actionType={actionType} />

        {/* Error */}
        {error && (
          <div style={{
            background: 'rgba(255,69,58,0.10)',
            border: '1px solid rgba(255,69,58,0.28)',
            borderRadius: 'var(--r-md)',
            padding: '12px 14px',
            display: 'flex', alignItems: 'flex-start', gap: 10,
            marginBottom: 12,
          }}>
            <AlertCircle size={16} color="var(--red)" style={{ marginTop: 2, flexShrink: 0 }} />
            <span style={{ font: 'var(--text-footnote)', color: 'var(--red)', lineHeight: 1.45 }}>
              {error}
            </span>
          </div>
        )}

        {/* ── Analyze Button ── */}
        <button
          className="ios-btn-primary"
          onClick={handleSubmit}
          disabled={!file}
        >
          ⚾ Analyze My Video
        </button>

        {/* Footer */}
        <p style={{
          textAlign: 'center', marginTop: 24,
          font: 'var(--text-caption2)', color: 'var(--label4)', letterSpacing: 0.2,
        }}>
          Powered by Claude AI · MediaPipe Pose
        </p>
      </div>
    </div>
  )
}
