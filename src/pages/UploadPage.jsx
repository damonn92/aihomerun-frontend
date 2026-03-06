import { useState, useRef } from 'react'
import { Upload, ChevronDown, Loader2, AlertCircle } from 'lucide-react'

// In dev: Vite proxy forwards to localhost:8000
// In prod: set VITE_API_URL=https://api.aihomerun.app in Vercel env vars
const API_BASE = import.meta.env.VITE_API_URL || ''

export default function UploadPage({ onResult }) {
  const [file, setFile] = useState(null)
  const [preview, setPreview] = useState(null)
  const [actionType, setActionType] = useState('swing')
  const [age, setAge] = useState(10)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)
  const [dragOver, setDragOver] = useState(false)
  const inputRef = useRef(null)

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

  async function handleSubmit(e) {
    e.preventDefault()
    if (!file) return

    setLoading(true)
    setError(null)

    const form = new FormData()
    form.append('file', file)
    form.append('action_type', actionType)
    form.append('age', age)

    try {
      const res = await fetch(`${API_BASE}/analyze`, { method: 'POST', body: form })
      const data = await res.json()
      if (!res.ok) throw new Error(data.detail || 'Analysis failed')
      onResult(data)
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex flex-col">
      {/* Header */}
      <header className="flex items-center gap-3 px-6 py-4 border-b border-slate-800">
        <img src="/logo.png" alt="AIHomeRun" className="w-9 h-9 rounded-xl object-cover" />
        <span className="text-xl font-bold tracking-tight text-white">
          AIHomeRun
        </span>
        <span className="ml-auto text-xs text-slate-500 font-medium uppercase tracking-widest">
          Beta
        </span>
      </header>

      {/* Hero */}
      <main className="flex-1 flex flex-col items-center justify-center px-4 py-12 gap-10">
        <div className="text-center max-w-xl">
          <h1 className="text-4xl font-extrabold text-white mb-3 leading-tight">
            Upload a video.<br />
            <span className="text-red-500">Get instant coaching.</span>
          </h1>
          <p className="text-slate-400 text-base">
            AI analyzes your swing or pitch and gives you a score,
            strengths, and a personalized drill — in seconds.
          </p>
        </div>

        <form onSubmit={handleSubmit} className="w-full max-w-lg flex flex-col gap-5">

          {/* Drop zone */}
          <div
            className={`relative rounded-2xl border-2 border-dashed transition-colors cursor-pointer
              ${dragOver ? 'border-red-500 bg-red-500/10' : 'border-slate-700 hover:border-slate-500'}
              ${preview ? 'border-solid border-slate-600' : ''}`}
            onClick={() => !preview && inputRef.current?.click()}
            onDragOver={e => { e.preventDefault(); setDragOver(true) }}
            onDragLeave={() => setDragOver(false)}
            onDrop={handleDrop}
          >
            {preview ? (
              <div className="relative">
                <video
                  src={preview}
                  className="w-full rounded-2xl max-h-64 object-cover"
                  controls
                  muted
                />
                <button
                  type="button"
                  onClick={() => { setFile(null); setPreview(null) }}
                  className="absolute top-2 right-2 bg-black/60 hover:bg-black/80 text-white rounded-full w-7 h-7 text-sm font-bold flex items-center justify-center"
                >
                  ✕
                </button>
              </div>
            ) : (
              <div className="flex flex-col items-center justify-center py-14 gap-3 text-slate-500">
                <Upload size={36} strokeWidth={1.5} />
                <p className="text-sm font-medium">
                  Drag & drop your video here, or{' '}
                  <span className="text-red-400 underline">browse</span>
                </p>
                <p className="text-xs text-slate-600">MP4, MOV, AVI · Max 100 MB</p>
              </div>
            )}
            <input
              ref={inputRef}
              type="file"
              accept="video/*"
              className="hidden"
              onChange={e => handleFile(e.target.files[0])}
            />
          </div>

          {/* Options row */}
          <div className="flex gap-3">
            {/* Action type */}
            <div className="flex-1 relative">
              <label className="block text-xs text-slate-500 mb-1 font-medium uppercase tracking-wider">
                Action
              </label>
              <div className="relative">
                <select
                  value={actionType}
                  onChange={e => setActionType(e.target.value)}
                  className="w-full appearance-none bg-slate-800 border border-slate-700 rounded-xl px-4 py-3 text-sm text-white focus:outline-none focus:border-red-500"
                >
                  <option value="swing">⚾ Batting Swing</option>
                  <option value="pitch">🤾 Pitching</option>
                </select>
                <ChevronDown size={16} className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 pointer-events-none" />
              </div>
            </div>

            {/* Age */}
            <div className="flex-1">
              <label className="block text-xs text-slate-500 mb-1 font-medium uppercase tracking-wider">
                Player Age
              </label>
              <div className="flex items-center bg-slate-800 border border-slate-700 rounded-xl px-4 py-3 gap-3">
                <button
                  type="button"
                  onClick={() => setAge(a => Math.max(6, a - 1))}
                  className="text-slate-400 hover:text-white font-bold text-lg leading-none"
                >−</button>
                <span className="flex-1 text-center text-sm font-semibold text-white">{age} yrs</span>
                <button
                  type="button"
                  onClick={() => setAge(a => Math.min(18, a + 1))}
                  className="text-slate-400 hover:text-white font-bold text-lg leading-none"
                >+</button>
              </div>
            </div>
          </div>

          {/* Error */}
          {error && (
            <div className="flex items-start gap-2 bg-red-900/30 border border-red-800 rounded-xl px-4 py-3 text-red-400 text-sm">
              <AlertCircle size={16} className="mt-0.5 shrink-0" />
              {error}
            </div>
          )}

          {/* Submit */}
          <button
            type="submit"
            disabled={!file || loading}
            className="w-full py-4 rounded-xl font-bold text-base
              bg-red-600 hover:bg-red-500 disabled:bg-slate-700 disabled:text-slate-500
              text-white transition-colors flex items-center justify-center gap-2"
          >
            {loading ? (
              <>
                <Loader2 size={18} className="animate-spin" />
                Analyzing… this takes ~30s
              </>
            ) : (
              '⚾ Analyze My Video'
            )}
          </button>

          {loading && (
            <p className="text-center text-xs text-slate-500">
              Our AI coach is watching your video and building your report…
            </p>
          )}
        </form>
      </main>
    </div>
  )
}
