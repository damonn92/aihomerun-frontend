import { useState } from 'react'
import { ChevronLeft, Star, TrendingUp, Dumbbell, ChevronDown, RotateCcw, Users } from 'lucide-react'

/* ─── Circular Score Ring ─────────────────────────────────────────────────── */
function ScoreRing({ score, label, color }) {
  const r    = 34
  const circ = 2 * Math.PI * r
  const offset = circ - (score / 100) * circ

  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
      <div style={{ position: 'relative', width: 88, height: 88 }}>
        <svg width="88" height="88" viewBox="0 0 88 88" style={{ transform: 'rotate(-90deg)' }}>
          <circle cx="44" cy="44" r={r} fill="none" stroke="var(--bg3)" strokeWidth="7" />
          <circle
            cx="44" cy="44" r={r}
            fill="none"
            stroke={color}
            strokeWidth="7"
            strokeLinecap="round"
            strokeDasharray={circ}
            strokeDashoffset={offset}
            className="score-ring-fill"
          />
        </svg>
        <span style={{
          position: 'absolute', inset: 0,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          font: '800 22px/1 -apple-system, sans-serif',
          letterSpacing: '-1px', color: 'var(--label)',
        }}>
          {score}
        </span>
      </div>
      <span style={{
        font: 'var(--text-caption2)', fontWeight: 600,
        letterSpacing: 0.5, textTransform: 'uppercase', color,
      }}>
        {label}
      </span>
    </div>
  )
}

/* ─── Grade config ────────────────────────────────────────────────────────── */
function getGrade(score) {
  if (score >= 90) return { letter: 'A+', color: 'var(--green)' }
  if (score >= 80) return { letter: 'A',  color: 'var(--green)' }
  if (score >= 70) return { letter: 'B',  color: 'var(--blue)' }
  if (score >= 60) return { letter: 'C',  color: 'var(--orange)' }
  return               { letter: 'D',  color: 'var(--red)' }
}

/* ─── Section Card ────────────────────────────────────────────────────────── */
function SectionCard({ icon: Icon, iconColor, title, accentBg, children, delay = 0 }) {
  return (
    <div
      className="ios-card card-animate"
      style={{ background: accentBg, marginBottom: 12, animationDelay: `${delay}ms` }}
    >
      <div style={{
        display: 'flex', alignItems: 'center', gap: 10,
        padding: '15px 16px 13px',
        borderBottom: '0.5px solid rgba(255,255,255,0.06)',
      }}>
        <div style={{
          width: 30, height: 30, borderRadius: 8,
          background: 'rgba(255,255,255,0.08)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <Icon size={16} color={iconColor} strokeWidth={2} />
        </div>
        <span style={{ font: 'var(--text-subhead)', fontWeight: 600, color: 'var(--label)', letterSpacing: '-0.2px' }}>
          {title}
        </span>
      </div>
      <div style={{ padding: '14px 16px 16px' }}>
        {children}
      </div>
    </div>
  )
}

/* ─── Bullet Item ─────────────────────────────────────────────────────────── */
function BulletItem({ text, dotColor }) {
  return (
    <div style={{ display: 'flex', alignItems: 'flex-start', gap: 10, padding: '6px 0' }}>
      <div style={{
        width: 6, height: 6, borderRadius: 3,
        background: dotColor, marginTop: 6, flexShrink: 0,
      }} />
      <span style={{ font: 'var(--text-subhead)', color: 'var(--label)', lineHeight: 1.5, flex: 1 }}>
        {text}
      </span>
    </div>
  )
}

/* ─── Data Row ────────────────────────────────────────────────────────────── */
function DataRow({ label, value, last }) {
  return (
    <div style={{
      display: 'flex', justifyContent: 'space-between', alignItems: 'center',
      padding: '10px 16px',
      borderBottom: last ? 'none' : '0.5px solid var(--sep2)',
    }}>
      <span style={{ font: 'var(--text-subhead)', color: 'var(--label2)' }}>{label}</span>
      <span style={{ font: 'var(--text-subhead)', fontWeight: 500, color: 'var(--label)', letterSpacing: '-0.2px' }}>
        {value}
      </span>
    </div>
  )
}

/* ─── Delta Badge ─────────────────────────────────────────────────────────── */
function DeltaBadge({ delta }) {
  if (delta === 0) return (
    <span style={{ font: 'var(--text-caption1)', color: 'var(--label3)', fontWeight: 600 }}>—</span>
  )
  const up = delta > 0
  return (
    <span style={{
      font: 'var(--text-caption1)', fontWeight: 700,
      color: up ? 'var(--green)' : 'var(--red)',
    }}>
      {up ? '↑' : '↓'}{Math.abs(delta)}
    </span>
  )
}

/* ─── Before/After Comparison Card ───────────────────────────────────────── */
function CompareCard({ current, previous, delay = 0 }) {
  const rows = [
    { key: 'overall_score',   label: 'Overall' },
    { key: 'technique_score', label: 'Technique' },
    { key: 'power_score',     label: 'Power' },
    { key: 'balance_score',   label: 'Balance' },
  ]

  // Find most improved metric (excluding overall)
  let bestDelta = 0
  let bestLabel = ''
  rows.slice(1).forEach(r => {
    const d = current[r.key] - previous[r.key]
    if (d > bestDelta) { bestDelta = d; bestLabel = r.label }
  })

  // Format session date
  const prevDate = previous.session_date
    ? new Date(previous.session_date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
    : 'Last session'

  return (
    <div className="ios-card card-animate" style={{ marginBottom: 12, animationDelay: `${delay}ms` }}>
      {/* Header */}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 10,
        padding: '15px 16px 12px',
        borderBottom: '0.5px solid rgba(255,255,255,0.06)',
      }}>
        <div style={{
          width: 30, height: 30, borderRadius: 8,
          background: 'rgba(255,255,255,0.08)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <TrendingUp size={16} color="var(--blue)" strokeWidth={2} />
        </div>
        <div>
          <div style={{ font: 'var(--text-subhead)', fontWeight: 600, color: 'var(--label)' }}>
            vs. Last Session
          </div>
          <div style={{ font: 'var(--text-caption2)', color: 'var(--label3)', marginTop: 1 }}>
            Compared to {prevDate}
          </div>
        </div>
      </div>

      {/* Score grid */}
      <div style={{ padding: '12px 16px' }}>
        {rows.map((r, i) => {
          const cur = current[r.key]
          const prv = previous[r.key]
          const delta = cur - prv
          return (
            <div key={r.key} style={{
              display: 'flex', alignItems: 'center', justifyContent: 'space-between',
              padding: '8px 0',
              borderBottom: i < rows.length - 1 ? '0.5px solid var(--sep2)' : 'none',
            }}>
              <span style={{ font: 'var(--text-footnote)', color: 'var(--label2)', minWidth: 70 }}>
                {r.label}
              </span>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <span style={{ font: 'var(--text-footnote)', color: 'var(--label3)' }}>{prv}</span>
                <span style={{ font: 'var(--text-caption2)', color: 'var(--label4)' }}>→</span>
                <span style={{ font: 'var(--text-footnote)', fontWeight: 600, color: 'var(--label)', minWidth: 22, textAlign: 'right' }}>{cur}</span>
                <div style={{ minWidth: 32, textAlign: 'right' }}>
                  <DeltaBadge delta={delta} />
                </div>
              </div>
            </div>
          )
        })}
      </div>

      {/* Most improved callout */}
      {bestDelta > 0 && (
        <div style={{
          margin: '0 12px 12px',
          background: 'rgba(48,209,88,0.08)',
          border: '1px solid rgba(48,209,88,0.18)',
          borderRadius: 8, padding: '9px 12px',
          display: 'flex', gap: 8, alignItems: 'center',
        }}>
          <span style={{ fontSize: 14 }}>🏆</span>
          <span style={{ font: 'var(--text-caption1)', color: 'var(--label2)', lineHeight: 1.4 }}>
            <strong style={{ color: 'var(--green)' }}>{bestLabel}</strong> improved the most — up {bestDelta} points!
          </span>
        </div>
      )}
    </div>
  )
}

/* ─── Sparkline Growth Chart ──────────────────────────────────────────────── */
function GrowthChart({ history, delay = 0 }) {
  if (!history || history.length < 2) return null

  const scores  = history.map(h => h.overall_score)
  const dates   = history.map(h => {
    try {
      return new Date(h.session_date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
    } catch { return '' }
  })
  const n       = scores.length
  const minS    = Math.max(0,   Math.min(...scores) - 10)
  const maxS    = Math.min(100, Math.max(...scores) + 10)
  const W       = 280
  const H       = 64

  const xOf = i => (i / (n - 1)) * (W - 24) + 12
  const yOf = s => H - ((s - minS) / (maxS - minS + 1e-6)) * (H - 16) - 4

  const polyline = scores.map((s, i) => `${xOf(i).toFixed(1)},${yOf(s).toFixed(1)}`).join(' ')

  // Trend: last vs first
  const trend = scores[n - 1] - scores[0]
  const trendColor = trend > 0 ? 'var(--green)' : trend < 0 ? 'var(--red)' : 'var(--label3)'
  const trendLabel = trend > 0 ? `↑ Up ${trend} pts` : trend < 0 ? `↓ Down ${Math.abs(trend)} pts` : '→ Holding steady'

  return (
    <div className="ios-card card-animate" style={{ marginBottom: 12, animationDelay: `${delay}ms` }}>
      {/* Header */}
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        padding: '15px 16px 12px',
        borderBottom: '0.5px solid rgba(255,255,255,0.06)',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{
            width: 30, height: 30, borderRadius: 8,
            background: 'rgba(255,255,255,0.08)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 15,
          }}>
            📈
          </div>
          <span style={{ font: 'var(--text-subhead)', fontWeight: 600, color: 'var(--label)' }}>
            Growth Trend
          </span>
        </div>
        <span style={{ font: 'var(--text-caption1)', fontWeight: 600, color: trendColor }}>
          {trendLabel}
        </span>
      </div>

      {/* Chart */}
      <div style={{ padding: '14px 12px 8px' }}>
        <svg
          viewBox={`0 0 ${W} ${H}`}
          style={{ width: '100%', height: H, display: 'block' }}
          preserveAspectRatio="none"
        >
          {/* Horizontal guide lines */}
          {[25, 50, 75].map(v => {
            const y = yOf(v)
            if (y < 0 || y > H) return null
            return (
              <line
                key={v}
                x1="0" y1={y.toFixed(1)} x2={W} y2={y.toFixed(1)}
                stroke="rgba(255,255,255,0.06)" strokeWidth="1"
              />
            )
          })}

          {/* Gradient fill under line */}
          <defs>
            <linearGradient id="sparkGrad" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="var(--blue)" stopOpacity="0.25" />
              <stop offset="100%" stopColor="var(--blue)" stopOpacity="0" />
            </linearGradient>
          </defs>
          <polygon
            points={`12,${H} ${polyline} ${xOf(n - 1).toFixed(1)},${H}`}
            fill="url(#sparkGrad)"
          />

          {/* Line */}
          <polyline
            points={polyline}
            fill="none"
            stroke="var(--blue)"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />

          {/* Dots */}
          {scores.map((s, i) => (
            <circle
              key={i}
              cx={xOf(i).toFixed(1)}
              cy={yOf(s).toFixed(1)}
              r={i === n - 1 ? 4 : 3}
              fill={i === n - 1 ? 'var(--blue)' : 'var(--bg2)'}
              stroke="var(--blue)"
              strokeWidth="2"
            />
          ))}

          {/* Score labels at first and last */}
          <text x={xOf(0)} y={yOf(scores[0]) - 7} textAnchor="middle"
            fontSize="10" fill="var(--label3)" fontWeight="600">
            {scores[0]}
          </text>
          <text x={xOf(n - 1)} y={yOf(scores[n - 1]) - 7} textAnchor="middle"
            fontSize="10" fill="var(--blue)" fontWeight="700">
            {scores[n - 1]}
          </text>
        </svg>

        {/* Date labels */}
        <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 4 }}>
          <span style={{ font: 'var(--text-caption2)', color: 'var(--label4)' }}>{dates[0]}</span>
          <span style={{ font: 'var(--text-caption2)', color: 'var(--label3)', fontWeight: 600 }}>
            Today
          </span>
        </div>
        <p style={{ font: 'var(--text-caption2)', color: 'var(--label4)', textAlign: 'center', margin: '6px 0 0' }}>
          {n} session{n !== 1 ? 's' : ''} · overall score
        </p>
      </div>
    </div>
  )
}

/* ─── Parent Tip Card ─────────────────────────────────────────────────────── */
function ParentTipCard({ tip, delay = 0 }) {
  if (!tip) return null
  return (
    <div
      className="ios-card card-animate"
      style={{
        background: 'rgba(48,209,88,0.07)',
        marginBottom: 12,
        animationDelay: `${delay}ms`,
      }}
    >
      <div style={{
        display: 'flex', alignItems: 'center', gap: 10,
        padding: '15px 16px 13px',
        borderBottom: '0.5px solid rgba(255,255,255,0.06)',
      }}>
        <div style={{
          width: 30, height: 30, borderRadius: 8,
          background: 'rgba(255,255,255,0.08)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 16,
        }}>
          🏠
        </div>
        <div>
          <span style={{ font: 'var(--text-subhead)', fontWeight: 600, color: 'var(--label)' }}>
            Today's Practice (≤ 10 min)
          </span>
        </div>
      </div>
      <div style={{ padding: '14px 16px 16px' }}>
        <p style={{
          font: 'var(--text-subhead)', color: 'var(--label)',
          margin: 0, lineHeight: 1.6,
        }}>
          {tip}
        </p>
      </div>
    </div>
  )
}

/* ─── Result Page ─────────────────────────────────────────────────────────── */
export default function ResultPage({ result, onReset }) {
  const [parentMode, setParentMode] = useState(false)

  const { feedback, metrics, action_type, processing_time_seconds, previous_session, history } = result
  const overall     = feedback.overall_score
  const grade       = getGrade(overall)
  const actionLabel = action_type === 'swing' ? 'Batting Swing' : 'Pitching'

  const rawData = [
    { label: 'Peak Wrist Speed',   value: `${metrics.peak_wrist_speed.toFixed(1)} px/frame` },
    { label: 'Hip–Shoulder Sep.',  value: `${metrics.hip_shoulder_separation.toFixed(1)}°` },
    { label: 'Balance',            value: metrics.balance_score.toFixed(2) },
    { label: 'Follow-Through',     value: metrics.follow_through ? 'Yes ✓' : 'No ✗' },
    { label: 'Elbow Angle',        value: `${metrics.joint_angles.elbow_angle.toFixed(1)}°` },
    { label: 'Shoulder Tilt',      value: `${metrics.joint_angles.shoulder_angle.toFixed(1)}°` },
    { label: 'Hip Rotation',       value: `${metrics.joint_angles.hip_rotation.toFixed(1)}°` },
    { label: 'Knee Bend',          value: `${metrics.joint_angles.knee_bend.toFixed(1)}°` },
  ]

  return (
    <div style={{ background: 'var(--bg)', height: '100%', display: 'flex', flexDirection: 'column' }}>

      {/* ── Navigation Bar ── */}
      <nav className="ios-navbar">
        <div className="ios-navbar-inner">
          {/* Back */}
          <button className="ios-back-btn" onClick={onReset}>
            <ChevronLeft size={20} strokeWidth={2.5} />
            Back
          </button>

          {/* Title */}
          <span className="ios-navbar-title" style={{ flex: 1, textAlign: 'center' }}>
            Results
          </span>

          {/* Parent Mode Toggle */}
          <button
            onClick={() => setParentMode(p => !p)}
            title={parentMode ? 'Switch to Player View' : 'Switch to Parent View'}
            style={{
              display: 'flex', alignItems: 'center', gap: 5,
              padding: '5px 10px', borderRadius: 20,
              background: parentMode ? 'var(--green)' : 'var(--fill2)',
              border: 'none', cursor: 'pointer',
              font: 'var(--text-caption2)',
              fontWeight: 600,
              color: parentMode ? '#fff' : 'var(--label2)',
              transition: 'background 0.18s, color 0.18s',
              flexShrink: 0,
            }}
          >
            <Users size={12} />
            {parentMode ? 'Parent' : 'Player'}
          </button>
        </div>
      </nav>

      {/* ── Scrollable Content ── */}
      <div
        className="scroll-content"
        style={{ flex: 1, overflowY: 'auto' }}
      >
      <div style={{
        padding: '20px 16px',
        paddingBottom: 'calc(env(safe-area-inset-bottom, 0px) + 36px)',
        display: 'flex', flexDirection: 'column', gap: 12,
      }}>

        {/* ── Parent Mode Banner ── */}
        {parentMode && (
          <div style={{
            background: 'rgba(48,209,88,0.1)',
            border: '1px solid rgba(48,209,88,0.22)',
            borderRadius: 'var(--r-md)',
            padding: '10px 14px',
            display: 'flex', gap: 9, alignItems: 'center',
          }}>
            <span style={{ fontSize: 15 }}>👋</span>
            <span style={{ font: 'var(--text-footnote)', color: 'var(--label2)', lineHeight: 1.4 }}>
              <strong style={{ color: 'var(--label)' }}>Parent View</strong> — plain English summary + a quick home practice plan.
            </span>
          </div>
        )}

        {/* ── Hero Score Card ── */}
        <div
          className="ios-card card-animate"
          style={{ padding: '28px 20px 24px', textAlign: 'center', background: 'var(--bg2)' }}
        >
          {/* Action label */}
          <span style={{
            font: 'var(--text-caption2)', fontWeight: 700, letterSpacing: 1.4,
            textTransform: 'uppercase', color: 'var(--label3)',
            display: 'block', marginBottom: 16,
          }}>
            {actionLabel} Analysis
          </span>

          {/* Grade letter */}
          <div
            className="grade-pop"
            style={{
              font: '900 88px/1 -apple-system, "SF Pro Display", sans-serif',
              letterSpacing: '-4px', color: grade.color, marginBottom: 8,
            }}
          >
            {grade.letter}
          </div>

          {/* Overall score */}
          <p style={{ font: 'var(--text-callout)', color: 'var(--label2)', margin: '0 0 14px' }}>
            Overall Score:{' '}
            <strong style={{ color: 'var(--label)' }}>{overall}</strong>
            {' '}/100
          </p>

          {/* Plain summary (if available) — shown in both modes */}
          {feedback.plain_summary ? (
            <div style={{
              background: 'rgba(10,132,255,0.09)',
              border: '1px solid rgba(10,132,255,0.18)',
              borderRadius: 'var(--r-md)', padding: '12px 16px', margin: '0 0 14px',
            }}>
              <p style={{
                font: 'var(--text-subhead)', color: 'var(--label)',
                margin: 0, lineHeight: 1.55,
              }}>
                {feedback.plain_summary}
              </p>
            </div>
          ) : (
            /* Fallback to encouragement if plain_summary not present */
            <div style={{
              background: 'var(--fill4)', borderRadius: 'var(--r-md)',
              padding: '12px 16px', margin: '0 0 14px',
            }}>
              <p style={{
                font: 'var(--text-subhead)', fontStyle: 'italic',
                color: 'var(--label)', margin: 0, lineHeight: 1.5,
              }}>
                "{feedback.encouragement}"
              </p>
            </div>
          )}

          {/* Encouragement (player mode only) */}
          {!parentMode && feedback.plain_summary && (
            <p style={{
              font: 'var(--text-footnote)', fontStyle: 'italic',
              color: 'var(--label3)', margin: '0 0 12px', lineHeight: 1.4,
            }}>
              "{feedback.encouragement}"
            </p>
          )}

          {/* Meta */}
          <p style={{ font: 'var(--text-caption2)', color: 'var(--label4)', margin: 0 }}>
            {metrics.frames_analyzed} frames analyzed · {processing_time_seconds}s
          </p>
        </div>

        {/* ── Parent Tip Card (parent mode only) ── */}
        {parentMode && <ParentTipCard tip={feedback.parent_tip} delay={60} />}

        {/* ── Score Rings Card (player mode only) ── */}
        {!parentMode && (
          <div
            className="ios-card card-animate"
            style={{
              padding: '22px 16px', background: 'var(--bg2)',
              display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)',
              gap: 8, animationDelay: '60ms',
            }}
          >
            <ScoreRing score={feedback.technique_score} label="Technique" color="var(--blue)" />
            <ScoreRing score={feedback.power_score}     label="Power"     color="var(--red)" />
            <ScoreRing score={feedback.balance_score}   label="Balance"   color="var(--green)" />
          </div>
        )}

        {/* ── Before/After Comparison (if previous session available) ── */}
        {previous_session && (
          <CompareCard
            current={{
              overall_score:   feedback.overall_score,
              technique_score: feedback.technique_score,
              power_score:     feedback.power_score,
              balance_score:   feedback.balance_score,
            }}
            previous={previous_session}
            delay={120}
          />
        )}

        {/* ── Growth Trend Chart ── */}
        {history && history.length >= 2 && (
          <GrowthChart history={history} delay={150} />
        )}

        {/* ── Strengths ── */}
        <SectionCard
          icon={Star}
          iconColor="var(--yellow)"
          title="What You're Doing Great"
          accentBg="rgba(48,209,88,0.07)"
          delay={previous_session ? 180 : 120}
        >
          {feedback.strengths.map((s, i) => (
            <BulletItem key={i} text={s} dotColor="var(--green)" />
          ))}
        </SectionCard>

        {/* ── Improvements ── */}
        <SectionCard
          icon={TrendingUp}
          iconColor="var(--orange)"
          title="Areas to Improve"
          accentBg="rgba(255,159,10,0.07)"
          delay={previous_session ? 220 : 160}
        >
          {feedback.improvements.map((tip, i) => (
            <BulletItem key={i} text={tip} dotColor="var(--orange)" />
          ))}
        </SectionCard>

        {/* ── Practice Drill ── */}
        <SectionCard
          icon={Dumbbell}
          iconColor="var(--blue)"
          title="Your Practice Drill"
          accentBg="rgba(10,132,255,0.07)"
          delay={previous_session ? 260 : 200}
        >
          <p style={{ font: 'var(--text-subhead)', color: 'var(--label)', margin: 0, lineHeight: 1.65 }}>
            {feedback.drill}
          </p>
        </SectionCard>

        {/* ── Raw Motion Data (player mode only, collapsed by default) ── */}
        {!parentMode && (
          <details className="ios-card card-animate" style={{ animationDelay: '300ms' }}>
            <summary style={{
              padding: '14px 16px',
              display: 'flex', alignItems: 'center', justifyContent: 'space-between',
              cursor: 'pointer', userSelect: 'none', listStyle: 'none',
              font: 'var(--text-subhead)', fontWeight: 600, color: 'var(--label2)',
            }}>
              <span>Raw Motion Data</span>
              <ChevronDown size={16} color="var(--label3)" />
            </summary>
            <div>
              {rawData.map(({ label, value }, i) => (
                <DataRow key={label} label={label} value={value} last={i === rawData.length - 1} />
              ))}
            </div>
          </details>
        )}

        {/* ── Analyze Again Button ── */}
        <button className="ios-btn-secondary" onClick={onReset} style={{ marginTop: 4 }}>
          <RotateCcw size={16} />
          Analyze Another Video
        </button>

      </div>{/* end inner layout div */}
      </div>{/* end scroll-content */}
    </div>
  )
}
