import { CheckCircle2, TrendingUp, RotateCcw, Star, Dumbbell, Heart } from 'lucide-react'

function ScoreRing({ score, label, color }) {
  const radius = 36
  const circ = 2 * Math.PI * radius
  const offset = circ - (score / 100) * circ

  const colorMap = {
    red:    { stroke: '#ef4444', text: 'text-red-400' },
    blue:   { stroke: '#3b82f6', text: 'text-blue-400' },
    green:  { stroke: '#22c55e', text: 'text-green-400' },
    yellow: { stroke: '#eab308', text: 'text-yellow-400' },
  }
  const c = colorMap[color] || colorMap.red

  return (
    <div className="flex flex-col items-center gap-2">
      <div className="relative w-24 h-24">
        <svg className="w-full h-full -rotate-90" viewBox="0 0 88 88">
          <circle cx="44" cy="44" r={radius} fill="none" stroke="#1e293b" strokeWidth="8" />
          <circle
            cx="44" cy="44" r={radius} fill="none"
            stroke={c.stroke} strokeWidth="8"
            strokeDasharray={circ}
            strokeDashoffset={offset}
            strokeLinecap="round"
            style={{ transition: 'stroke-dashoffset 0.8s ease' }}
          />
        </svg>
        <span className="absolute inset-0 flex items-center justify-center text-2xl font-black text-white">
          {score}
        </span>
      </div>
      <span className={`text-xs font-semibold uppercase tracking-widest ${c.text}`}>{label}</span>
    </div>
  )
}

function Section({ icon: Icon, title, children, accent }) {
  return (
    <div className={`rounded-2xl border p-5 ${accent}`}>
      <div className="flex items-center gap-2 mb-4">
        <Icon size={18} />
        <h3 className="font-bold text-sm uppercase tracking-widest">{title}</h3>
      </div>
      {children}
    </div>
  )
}

export default function ResultPage({ result, onReset }) {
  const { feedback, metrics, action_type, processing_time_seconds } = result
  const overall = feedback.overall_score

  const grade =
    overall >= 90 ? { letter: 'A+', color: 'text-green-400' } :
    overall >= 80 ? { letter: 'A',  color: 'text-green-400' } :
    overall >= 70 ? { letter: 'B',  color: 'text-blue-400'  } :
    overall >= 60 ? { letter: 'C',  color: 'text-yellow-400'} :
                    { letter: 'D',  color: 'text-red-400'   }

  return (
    <div className="min-h-screen flex flex-col">
      {/* Header */}
      <header className="flex items-center gap-3 px-6 py-4 border-b border-slate-800">
        <img src="/logo.png" alt="AIHomeRun" className="w-9 h-9 rounded-xl object-cover" />
        <span className="text-xl font-bold tracking-tight text-white">AIHomeRun</span>
        <button
          onClick={onReset}
          className="ml-auto flex items-center gap-2 text-sm text-slate-400 hover:text-white transition-colors"
        >
          <RotateCcw size={14} />
          Analyze another video
        </button>
      </header>

      <main className="flex-1 max-w-2xl mx-auto w-full px-4 py-10 flex flex-col gap-6">

        {/* Overall score hero */}
        <div className="rounded-2xl bg-slate-800/60 border border-slate-700 p-6 flex flex-col items-center text-center gap-2">
          <p className="text-xs text-slate-500 uppercase tracking-widest font-medium">
            {action_type === 'swing' ? 'Batting Swing' : 'Pitching'} Analysis
          </p>
          <div className={`text-8xl font-black ${grade.color}`}>{grade.letter}</div>
          <p className="text-slate-300 text-sm font-medium">
            Overall Score: <span className="text-white font-bold">{overall}/100</span>
          </p>
          <p className="text-slate-400 text-sm italic mt-1 max-w-sm">
            "{feedback.encouragement}"
          </p>
          <p className="text-xs text-slate-600 mt-2">
            {metrics.frames_analyzed} frames analyzed · {processing_time_seconds}s
          </p>
        </div>

        {/* Score breakdown */}
        <div className="grid grid-cols-3 gap-4">
          <ScoreRing score={feedback.technique_score} label="Technique" color="blue" />
          <ScoreRing score={feedback.power_score}     label="Power"     color="red" />
          <ScoreRing score={feedback.balance_score}   label="Balance"   color="green" />
        </div>

        {/* Strengths */}
        <Section
          icon={Star}
          title="What You're Doing Great"
          accent="border-green-800/50 bg-green-950/30 text-green-300"
        >
          <ul className="flex flex-col gap-3">
            {feedback.strengths.map((s, i) => (
              <li key={i} className="flex items-start gap-2 text-sm text-green-200">
                <CheckCircle2 size={16} className="mt-0.5 shrink-0 text-green-400" />
                {s}
              </li>
            ))}
          </ul>
        </Section>

        {/* Improvements */}
        <Section
          icon={TrendingUp}
          title="Areas to Improve"
          accent="border-yellow-800/50 bg-yellow-950/30 text-yellow-300"
        >
          <ul className="flex flex-col gap-3">
            {feedback.improvements.map((tip, i) => (
              <li key={i} className="flex items-start gap-2 text-sm text-yellow-200">
                <TrendingUp size={16} className="mt-0.5 shrink-0 text-yellow-400" />
                {tip}
              </li>
            ))}
          </ul>
        </Section>

        {/* Drill */}
        <Section
          icon={Dumbbell}
          title="Your Practice Drill"
          accent="border-blue-800/50 bg-blue-950/30 text-blue-300"
        >
          <p className="text-sm text-blue-200 leading-relaxed">{feedback.drill}</p>
        </Section>

        {/* Raw metrics (collapsed) */}
        <details className="rounded-2xl border border-slate-700 bg-slate-800/40 overflow-hidden">
          <summary className="px-5 py-4 text-xs text-slate-500 font-medium uppercase tracking-widest cursor-pointer select-none hover:text-slate-300">
            Raw Motion Data
          </summary>
          <div className="px-5 pb-5 grid grid-cols-2 gap-2 text-xs text-slate-400">
            {[
              ['Peak Wrist Speed', `${metrics.peak_wrist_speed} px/frame`],
              ['Hip–Shoulder Sep.', `${metrics.hip_shoulder_separation}°`],
              ['Balance Score', metrics.balance_score],
              ['Follow-Through', metrics.follow_through ? 'Yes ✓' : 'No ✗'],
              ['Elbow Angle', `${metrics.joint_angles.elbow_angle}°`],
              ['Shoulder Tilt', `${metrics.joint_angles.shoulder_angle}°`],
              ['Hip Rotation', `${metrics.joint_angles.hip_rotation}°`],
              ['Knee Bend', `${metrics.joint_angles.knee_bend}°`],
            ].map(([label, val]) => (
              <div key={label} className="flex justify-between bg-slate-900/50 rounded-lg px-3 py-2">
                <span className="text-slate-500">{label}</span>
                <span className="text-slate-300 font-mono">{val}</span>
              </div>
            ))}
          </div>
        </details>

        {/* Analyze again */}
        <button
          onClick={onReset}
          className="w-full py-4 rounded-xl font-bold text-base
            bg-red-600 hover:bg-red-500 text-white transition-colors
            flex items-center justify-center gap-2"
        >
          ⚾ Analyze Another Video
        </button>
      </main>
    </div>
  )
}
