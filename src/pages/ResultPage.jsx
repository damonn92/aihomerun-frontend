import { ChevronLeft, Star, TrendingUp, Dumbbell, ChevronDown, RotateCcw } from 'lucide-react'

/* ─── Circular Score Ring ─────────────────────────────────────────────────── */
function ScoreRing({ score, label, color }) {
  const r    = 34
  const circ = 2 * Math.PI * r
  const offset = circ - (score / 100) * circ

  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
      <div style={{ position: 'relative', width: 88, height: 88 }}>
        <svg
          width="88" height="88"
          viewBox="0 0 88 88"
          style={{ transform: 'rotate(-90deg)' }}
        >
          {/* Track */}
          <circle
            cx="44" cy="44" r={r}
            fill="none"
            stroke="var(--bg3)"
            strokeWidth="7"
          />
          {/* Fill */}
          <circle
            cx="44" cy="44" r={r}
            fill="none"
            stroke={color}
            strokeWidth="7"
            strokeLinecap="round"
            strokeDasharray={circ}
            strokeDashoffset={offset}
            style={{
              '--ring-circ': circ,
              '--ring-offset': offset,
            }}
            className="score-ring-fill"
          />
        </svg>
        {/* Score number */}
        <span style={{
          position: 'absolute',
          inset: 0,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          font: '800 22px/1 -apple-system, sans-serif',
          letterSpacing: '-1px',
          color: 'var(--label)',
        }}>
          {score}
        </span>
      </div>
      <span style={{
        font: 'var(--text-caption2)',
        fontWeight: 600,
        letterSpacing: 0.5,
        textTransform: 'uppercase',
        color,
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
      style={{
        background: accentBg,
        marginBottom: 12,
        animationDelay: `${delay}ms`,
      }}
    >
      {/* Header */}
      <div style={{
        display: 'flex',
        alignItems: 'center',
        gap: 10,
        padding: '15px 16px 13px',
        borderBottom: '0.5px solid rgba(255,255,255,0.06)',
      }}>
        <div style={{
          width: 30,
          height: 30,
          borderRadius: 8,
          background: 'rgba(255,255,255,0.08)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        }}>
          <Icon size={16} color={iconColor} strokeWidth={2} />
        </div>
        <span style={{
          font: 'var(--text-subhead)',
          fontWeight: 600,
          color: 'var(--label)',
          letterSpacing: '-0.2px',
        }}>
          {title}
        </span>
      </div>
      {/* Body */}
      <div style={{ padding: '14px 16px 16px' }}>
        {children}
      </div>
    </div>
  )
}

/* ─── Bullet Item ─────────────────────────────────────────────────────────── */
function BulletItem({ text, dotColor }) {
  return (
    <div style={{
      display: 'flex',
      alignItems: 'flex-start',
      gap: 10,
      padding: '6px 0',
    }}>
      <div style={{
        width: 6,
        height: 6,
        borderRadius: 3,
        background: dotColor,
        marginTop: 6,
        flexShrink: 0,
      }} />
      <span style={{
        font: 'var(--text-subhead)',
        color: 'var(--label)',
        lineHeight: 1.5,
        flex: 1,
      }}>
        {text}
      </span>
    </div>
  )
}

/* ─── Data Row ────────────────────────────────────────────────────────────── */
function DataRow({ label, value, last }) {
  return (
    <div style={{
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center',
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

/* ─── Result Page ─────────────────────────────────────────────────────────── */
export default function ResultPage({ result, onReset }) {
  const { feedback, metrics, action_type, processing_time_seconds } = result
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
    <div style={{
      background: 'var(--bg)',
      height: '100%',
      display: 'flex',
      flexDirection: 'column',
    }}>

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

          {/* Right placeholder */}
          <div style={{ minWidth: 60 }} />
        </div>
      </nav>

      {/* ── Scrollable Content ── */}
      <div
        className="scroll-content"
        style={{
          flex: 1,
          overflowY: 'auto',
          padding: '20px 16px',
          paddingBottom: 'calc(env(safe-area-inset-bottom, 0px) + 36px)',
          display: 'flex',
          flexDirection: 'column',
          gap: 12,
        }}
      >

        {/* ── Hero Score Card ── */}
        <div
          className="ios-card card-animate"
          style={{
            padding: '28px 20px 24px',
            textAlign: 'center',
            background: 'var(--bg2)',
          }}
        >
          {/* Action label */}
          <span style={{
            font: 'var(--text-caption2)',
            fontWeight: 700,
            letterSpacing: 1.4,
            textTransform: 'uppercase',
            color: 'var(--label3)',
            display: 'block',
            marginBottom: 16,
          }}>
            {actionLabel} Analysis
          </span>

          {/* Grade letter */}
          <div
            className="grade-pop"
            style={{
              font: '900 88px/1 -apple-system, "SF Pro Display", sans-serif',
              letterSpacing: '-4px',
              color: grade.color,
              marginBottom: 8,
            }}
          >
            {grade.letter}
          </div>

          {/* Overall score */}
          <p style={{
            font: 'var(--text-callout)',
            color: 'var(--label2)',
            margin: '0 0 14px',
          }}>
            Overall Score:{' '}
            <strong style={{ color: 'var(--label)' }}>{overall}</strong>
            {' '}/100
          </p>

          {/* Encouragement quote */}
          <div style={{
            background: 'var(--fill4)',
            borderRadius: 'var(--r-md)',
            padding: '12px 16px',
            margin: '0 0 14px',
          }}>
            <p style={{
              font: 'var(--text-subhead)',
              fontStyle: 'italic',
              color: 'var(--label)',
              margin: 0,
              lineHeight: 1.5,
            }}>
              "{feedback.encouragement}"
            </p>
          </div>

          {/* Meta */}
          <p style={{
            font: 'var(--text-caption2)',
            color: 'var(--label4)',
            margin: 0,
          }}>
            {metrics.frames_analyzed} frames analyzed · {processing_time_seconds}s
          </p>
        </div>

        {/* ── Score Rings Card ── */}
        <div
          className="ios-card card-animate"
          style={{
            padding: '22px 16px',
            background: 'var(--bg2)',
            display: 'grid',
            gridTemplateColumns: 'repeat(3, 1fr)',
            gap: 8,
            animationDelay: '60ms',
          }}
        >
          <ScoreRing score={feedback.technique_score} label="Technique" color="var(--blue)" />
          <ScoreRing score={feedback.power_score}     label="Power"     color="var(--red)" />
          <ScoreRing score={feedback.balance_score}   label="Balance"   color="var(--green)" />
        </div>

        {/* ── Strengths ── */}
        <SectionCard
          icon={Star}
          iconColor="var(--yellow)"
          title="What You're Doing Great"
          accentBg="rgba(48,209,88,0.07)"
          delay={120}
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
          delay={180}
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
          delay={240}
        >
          <p style={{
            font: 'var(--text-subhead)',
            color: 'var(--label)',
            margin: 0,
            lineHeight: 1.65,
          }}>
            {feedback.drill}
          </p>
        </SectionCard>

        {/* ── Raw Motion Data ── */}
        <details
          className="ios-card card-animate"
          style={{ animationDelay: '300ms' }}
        >
          <summary style={{
            padding: '14px 16px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            cursor: 'pointer',
            userSelect: 'none',
            listStyle: 'none',
            font: 'var(--text-subhead)',
            fontWeight: 600,
            color: 'var(--label2)',
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

        {/* ── Analyze Again Button ── */}
        <button className="ios-btn-secondary" onClick={onReset}>
          <RotateCcw size={16} />
          Analyze Another Video
        </button>

      </div>
    </div>
  )
}
