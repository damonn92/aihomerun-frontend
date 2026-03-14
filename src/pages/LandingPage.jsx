/* ─────────────────────────────────────────────────────────────────────────────
   AIHomeRun — Marketing Landing Page
   High-end app promotion website (NOT the app itself)
───────────────────────────────────────────────────────────────────────────── */

import { useEffect, useState, useCallback } from 'react'

/* ─── Scroll-triggered Fade-In Hook ──────────────────────────────────────── */
function useFadeIn(threshold = 0.12) {
  const [ref, setRef] = useState(null)
  const [visible, setVisible] = useState(false)

  useEffect(() => {
    if (!ref) return
    const obs = new IntersectionObserver(
      ([entry]) => { if (entry.isIntersecting) { setVisible(true); obs.disconnect() } },
      { threshold }
    )
    obs.observe(ref)
    return () => obs.disconnect()
  }, [ref, threshold])

  return {
    ref: setRef,
    style: {
      opacity: visible ? 1 : 0,
      transform: visible ? 'translateY(0)' : 'translateY(32px)',
      transition: 'opacity 0.75s ease, transform 0.75s ease',
    },
  }
}

/* ─── App Store Badge ──────────────────────────────────────────────────────── */
function AppStoreBadge({ href = '#', comingSoon = false }) {
  const [hovered, setHovered] = useState(false)
  return (
    <a
      href={comingSoon ? undefined : href}
      target={!comingSoon && href !== '#' ? '_blank' : undefined}
      rel="noopener noreferrer"
      onMouseEnter={() => !comingSoon && setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      title={comingSoon ? 'Coming soon to the App Store' : 'Download on the App Store'}
      style={{
        display: 'inline-block', position: 'relative',
        cursor: comingSoon ? 'default' : 'pointer',
        opacity: comingSoon ? 0.55 : 1,
        transform: hovered ? 'translateY(-3px)' : 'translateY(0)',
        transition: 'transform 0.2s ease, filter 0.2s ease',
        userSelect: 'none', flexShrink: 0,
        filter: hovered ? 'brightness(1.12) drop-shadow(0 8px 16px rgba(0,0,0,0.6))' : 'none',
      }}
    >
      <img
        src="/badge-app-store.svg"
        alt="Download on the App Store"
        className="store-badge-img"
      />
      {comingSoon && (
        <span style={{
          position: 'absolute', top: -7, right: -4,
          background: '#FF9500', color: '#fff',
          fontSize: 9, fontWeight: 700, letterSpacing: 0.6,
          padding: '2px 6px', borderRadius: 4,
          textTransform: 'uppercase', pointerEvents: 'none',
        }}>Soon</span>
      )}
    </a>
  )
}

/* ─── Google Play Badge ────────────────────────────────────────────────────── */
function GooglePlayBadge({ href = '#', comingSoon = true }) {
  const [hovered, setHovered] = useState(false)
  return (
    <a
      href={comingSoon ? undefined : href}
      target={!comingSoon && href !== '#' ? '_blank' : undefined}
      rel="noopener noreferrer"
      onMouseEnter={() => !comingSoon && setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      title={comingSoon ? 'Coming soon on Google Play' : 'Get it on Google Play'}
      style={{
        display: 'inline-block', position: 'relative',
        cursor: comingSoon ? 'default' : 'pointer',
        opacity: comingSoon ? 0.5 : 1,
        transform: hovered ? 'translateY(-3px)' : 'translateY(0)',
        transition: 'transform 0.2s ease, filter 0.2s ease',
        userSelect: 'none', flexShrink: 0,
        filter: hovered ? 'brightness(1.12) drop-shadow(0 8px 16px rgba(0,0,0,0.6))' : 'none',
      }}
    >
      <img
        src="/badge-google-play.svg"
        alt="Get it on Google Play"
        className="store-badge-img"
      />
      {comingSoon && (
        <span style={{
          position: 'absolute', top: -7, right: -4,
          background: '#FF9500', color: '#fff',
          fontSize: 9, fontWeight: 700, letterSpacing: 0.6,
          padding: '2px 6px', borderRadius: 4,
          textTransform: 'uppercase', pointerEvents: 'none',
        }}>Soon</span>
      )}
    </a>
  )
}

/* ─── Screenshot Phone Mockup (iPhone 15 Pro Max frame) ───────────────────── */
/* iPhone 15 Pro Max: 159.9×76.7mm, 6.7" display, screen ratio ~1:2.163
   Frame adds ~4px bezel on each side. Corner radius matches real device (55pt). */
function ScreenshotPhone({ src, alt = 'App screenshot', size = 'normal', className = '' }) {
  // iPhone 15 Pro Max proportions — bezel and radius scale with CSS overrides
  const isSmall = size === 'small'
  const bezel = isSmall ? 4 : 5

  return (
    <div className={`phone-shell ${isSmall ? 'phone-small' : ''} ${className}`} style={{
      position: 'relative',
      width: isSmall ? 200 : 260,
      height: isSmall ? 433 : 563,
      background: '#1a1a1a',
      borderRadius: isSmall ? 44 : 55,
      border: '1.5px solid rgba(255,255,255,0.15)',
      boxShadow: `
        0 0 0 0.5px rgba(255,255,255,0.06),
        0 40px 100px rgba(0,0,0,0.9),
        0 0 60px rgba(255,69,58,0.1),
        inset 0 0.5px 0 rgba(255,255,255,0.1)
      `,
      overflow: 'hidden',
      flexShrink: 0,
    }}>
      {/* Side buttons — power (right), volume + silent switch (left) */}
      <div style={{ position:'absolute', right:-2.5, top:'28%', width:2.5, height:28, background:'rgba(255,255,255,0.1)', borderRadius:'0 2px 2px 0' }}/>
      <div style={{ position:'absolute', left:-2.5, top:'18%', width:2.5, height:18, background:'rgba(255,255,255,0.1)', borderRadius:'2px 0 0 2px' }}/>
      <div style={{ position:'absolute', left:-2.5, top:'25%', width:2.5, height:36, background:'rgba(255,255,255,0.1)', borderRadius:'2px 0 0 2px' }}/>
      <div style={{ position:'absolute', left:-2.5, top:'33%', width:2.5, height:36, background:'rgba(255,255,255,0.1)', borderRadius:'2px 0 0 2px' }}/>

      {/* Screen area — uses right/bottom so it auto-adjusts when CSS overrides shell size */}
      <div className="phone-screen" style={{
        position: 'absolute',
        top: bezel,
        left: bezel,
        right: bezel,
        bottom: bezel,
        borderRadius: isSmall ? 38 : 48,
        overflow: 'hidden',
        background: '#000',
      }}>
        <img
          src={src}
          alt={alt}
          loading="lazy"
          style={{
            width: '100%',
            height: '100%',
            objectFit: 'cover',
            display: 'block',
          }}
        />
      </div>
    </div>
  )
}

/* ─── Feature Card ─────────────────────────────────────────────────────────── */
function FeatureCard({ icon, title, desc, accent = '#FF453A' }) {
  const [hov, setHov] = useState(false)
  return (
    <div
      onMouseEnter={() => setHov(true)}
      onMouseLeave={() => setHov(false)}
      style={{
        background: hov ? 'rgba(255,255,255,0.06)' : 'rgba(255,255,255,0.03)',
        border: `1px solid ${hov ? 'rgba(255,69,58,0.25)' : 'rgba(255,255,255,0.07)'}`,
        borderRadius: 20, padding: '28px 24px',
        transform: hov ? 'translateY(-4px)' : 'translateY(0)',
        transition: 'all 0.25s ease',
        cursor: 'default',
      }}
    >
      <div style={{
        width: 52, height: 52, borderRadius: 14,
        background: `linear-gradient(135deg, ${accent}22, ${accent}10)`,
        border: `1px solid ${accent}33`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 26, marginBottom: 18,
      }}>{icon}</div>
      <div style={{ fontSize: 18, fontWeight: 700, color: '#fff', marginBottom: 10, letterSpacing: -0.3 }}>{title}</div>
      <div style={{ fontSize: 14, color: 'rgba(255,255,255,0.48)', lineHeight: 1.7 }}>{desc}</div>
    </div>
  )
}

/* ─── Step Card ────────────────────────────────────────────────────────────── */
function StepCard({ num, title, items }) {
  return (
    <div style={{
      flex: '1 1 280px',
      background: 'rgba(255,255,255,0.025)',
      border: '1px solid rgba(255,255,255,0.07)',
      borderRadius: 20, padding: '28px 26px',
    }}>
      <div style={{
        width: 40, height: 40, borderRadius: 12,
        background: 'linear-gradient(135deg, #FF453A, #FF6B35)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 16, fontWeight: 800, color: '#fff', marginBottom: 18,
        boxShadow: '0 4px 14px rgba(255,69,58,0.35)',
      }}>{num}</div>
      <div style={{ fontSize: 17, fontWeight: 700, color: '#fff', marginBottom: 14, letterSpacing: -0.3 }}>{title}</div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        {items.map((item, i) => (
          <div key={i} style={{ display: 'flex', gap: 8, alignItems: 'flex-start' }}>
            <span style={{ color: '#FF453A', fontWeight: 700, marginTop: 1, flexShrink: 0, fontSize: 13 }}>›</span>
            <span style={{ fontSize: 13.5, color: 'rgba(255,255,255,0.5)', lineHeight: 1.65 }}>{item}</span>
          </div>
        ))}
      </div>
    </div>
  )
}

/* ─── Section Label ────────────────────────────────────────────────────────── */
function SectionLabel({ children }) {
  return (
    <div style={{
      display: 'inline-block',
      fontSize: 11, fontWeight: 700, letterSpacing: 2.5,
      color: '#FF453A', textTransform: 'uppercase', marginBottom: 14,
    }}>{children}</div>
  )
}

/* ─── Section Title ────────────────────────────────────────────────────────── */
function SectionTitle({ children }) {
  return (
    <h2 style={{
      fontSize: 'clamp(30px, 4.5vw, 48px)', fontWeight: 800,
      letterSpacing: -1.5, margin: '0 0 16px', lineHeight: 1.08,
      background: 'linear-gradient(180deg, #fff 55%, rgba(255,255,255,0.45) 100%)',
      WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundClip: 'text',
    }}>{children}</h2>
  )
}

/* ─── Features Showcase (Tab-based phone viewer) ──────────────────────────── */
function FeaturesShowcase() {
  const [activeTab, setActiveTab] = useState(0)
  const fadeIn = useFadeIn()

  const screenshots = [
    { src: '/screenshots/home.jpg',      label: 'AI Analysis',   desc: 'Upload any swing or pitch video and get instant AI-powered scores with radar charts, metric gauges, and professional-grade biomechanics data.' },
    { src: '/screenshots/training.jpg',  label: 'Training',      desc: 'Track your health and fitness with HealthKit integration — steps, heart rate, calories, weekly workout progress, and Apple Watch connectivity.' },
    { src: '/screenshots/watch.jpg',     label: 'Apple Watch',   desc: 'Track real-time swing metrics with Apple Watch — hand speed, rotational acceleration, swing scores, and heart rate during practice.' },
    { src: '/screenshots/ai-coach.jpg',  label: 'AI Coach',      desc: 'Chat one-on-one with your personal AI coach for biomechanics advice and personalized training tips.' },
    { src: '/screenshots/rankings.jpg',  label: 'Rankings',      desc: 'See how you stack up against other players and stay motivated by climbing the leaderboard.' },
    { src: '/screenshots/fields.jpg',    label: 'Find Fields',   desc: 'Discover nearby baseball fields and batting cages with integrated maps and directions.' },
  ]

  // For the 3-phone display: previous, active, next indices
  const prevIdx = (activeTab - 1 + screenshots.length) % screenshots.length
  const nextIdx = (activeTab + 1) % screenshots.length

  return (
    <section id="showcase" className="lp-section-pad" ref={fadeIn.ref} style={{
      padding: 'clamp(70px, 8vw, 110px) 28px',
      background: '#050505',
      borderTop: '1px solid rgba(255,255,255,0.05)',
      ...fadeIn.style,
    }}>
      <div style={{ maxWidth: 1120, margin: '0 auto' }}>
        <div style={{ textAlign: 'center', marginBottom: 48 }}>
          <SectionLabel>App Preview</SectionLabel>
          <SectionTitle>See AIHomeRun in action</SectionTitle>
          <p style={{ fontSize: 17, color: 'rgba(255,255,255,0.4)', maxWidth: 480, margin: '0 auto', lineHeight: 1.68 }}>
            Explore the key features that make AIHomeRun your ultimate baseball training companion.
          </p>
        </div>

        {/* Tab buttons */}
        <div className="showcase-tabs" style={{
          display: 'flex', justifyContent: 'center', gap: 8,
          marginBottom: 48, flexWrap: 'wrap',
        }}>
          {screenshots.map((s, i) => (
            <button
              key={i}
              onClick={() => setActiveTab(i)}
              style={{
                padding: '10px 22px', borderRadius: 24, border: 'none',
                background: i === activeTab
                  ? 'linear-gradient(135deg, rgba(255,69,58,0.2), rgba(255,107,53,0.15))'
                  : 'rgba(255,255,255,0.04)',
                color: i === activeTab ? '#FF6B35' : 'rgba(255,255,255,0.45)',
                fontSize: 14, fontWeight: 600, cursor: 'pointer',
                transition: 'all 0.3s ease',
                outline: 'none',
                boxShadow: i === activeTab ? '0 0 0 1px rgba(255,69,58,0.3)' : '0 0 0 1px rgba(255,255,255,0.08)',
                whiteSpace: 'nowrap',
              }}
            >
              {s.label}
            </button>
          ))}
        </div>

        {/* Phone display area */}
        <div className="showcase-phones" style={{
          display: 'flex', justifyContent: 'center', alignItems: 'center',
          gap: 28, perspective: '1200px', minHeight: 460,
        }}>
          {/* Left phone (previous) */}
          <div className="showcase-side-phone" style={{
            transform: 'rotateY(12deg) scale(0.85)',
            opacity: 0.4,
            transition: 'all 0.5s ease',
            filter: 'blur(1px)',
          }}>
            <ScreenshotPhone src={screenshots[prevIdx].src} alt={screenshots[prevIdx].label} size="small" />
          </div>

          {/* Center phone (active) */}
          <div style={{
            transform: 'scale(1)',
            transition: 'all 0.5s ease',
            zIndex: 2,
          }}>
            <ScreenshotPhone src={screenshots[activeTab].src} alt={screenshots[activeTab].label} size="normal" />
          </div>

          {/* Right phone (next) */}
          <div className="showcase-side-phone" style={{
            transform: 'rotateY(-12deg) scale(0.85)',
            opacity: 0.4,
            transition: 'all 0.5s ease',
            filter: 'blur(1px)',
          }}>
            <ScreenshotPhone src={screenshots[nextIdx].src} alt={screenshots[nextIdx].label} size="small" />
          </div>
        </div>

        {/* Active feature description */}
        <div style={{ textAlign: 'center', marginTop: 36 }}>
          <div style={{
            fontSize: 22, fontWeight: 700, color: '#fff',
            letterSpacing: -0.3, marginBottom: 8,
            transition: 'all 0.3s ease',
          }}>
            {screenshots[activeTab].label}
          </div>
          <div style={{
            fontSize: 15, color: 'rgba(255,255,255,0.45)',
            maxWidth: 420, margin: '0 auto', lineHeight: 1.65,
            transition: 'all 0.3s ease',
          }}>
            {screenshots[activeTab].desc}
          </div>
        </div>
      </div>
    </section>
  )
}

/* ─── Apple Watch Section ──────────────────────────────────────────────────── */
function AppleWatchSection() {
  const fadeIn = useFadeIn()
  const [hoveredMetric, setHoveredMetric] = useState(null)

  const watchMetrics = [
    { icon: '⚡', label: 'Hand Speed', value: '68 mph', desc: 'Real-time hand speed measured via accelerometer during each swing', color: '#FF453A' },
    { icon: '🔄', label: 'Rotational Accel.', value: '1,240 rad/s²', desc: 'Angular acceleration from rotation rate sensors — measures bat whip speed', color: '#FF8C00' },
    { icon: '📐', label: 'Attack Angle', value: '12.3°', desc: 'Estimated bat attack angle at contact zone from gyroscope trajectory', color: '#0A84FF' },
    { icon: '⏱️', label: 'Time to Contact', value: '0.18s', desc: 'Milliseconds from swing start to impact — faster means better reaction', color: '#BF5AF2' },
    { icon: '💯', label: 'Swing Score', value: '85/100', desc: 'Composite weighted score combining all metrics with age-based normalization', color: '#30D158' },
    { icon: '❤️', label: 'Heart Rate', value: '142 bpm', desc: 'Live heart rate tracking from Apple Watch during practice sessions', color: '#FF2D55' },
  ]

  return (
    <section id="apple-watch" className="lp-section-pad" ref={fadeIn.ref} style={{
      padding: 'clamp(80px, 9vw, 120px) 28px',
      background: '#000',
      borderTop: '1px solid rgba(255,255,255,0.05)',
      position: 'relative',
      overflow: 'hidden',
      ...fadeIn.style,
    }}>
      {/* Background glow */}
      <div style={{
        position: 'absolute', top: '20%', left: '50%', transform: 'translateX(-50%)',
        width: 600, height: 600, borderRadius: '50%',
        background: 'radial-gradient(circle, rgba(48,209,88,0.08) 0%, transparent 70%)',
        pointerEvents: 'none',
      }} />

      <div style={{ maxWidth: 1120, margin: '0 auto', position: 'relative' }}>
        <div style={{ textAlign: 'center', marginBottom: 56 }}>
          <SectionLabel>Apple Watch</SectionLabel>
          <SectionTitle>Train smarter with<br/>your wrist</SectionTitle>
          <p style={{ fontSize: 17, color: 'rgba(255,255,255,0.4)', maxWidth: 560, margin: '0 auto', lineHeight: 1.68 }}>
            Pair your Apple Watch for real-time swing tracking that rivals $100+ dedicated sensors.
            No extra hardware needed — just your watch and your bat.
          </p>
        </div>

        {/* Watch hero + metrics */}
        <div className="watch-hero-flex" style={{
          display: 'flex', alignItems: 'center', gap: 60, flexWrap: 'wrap',
          justifyContent: 'center',
        }}>

          {/* Left: Watch illustration */}
          <div style={{
            flex: '0 0 auto', position: 'relative',
            width: 280, height: 340,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            {/* Watch body */}
            <div style={{
              width: 180, height: 220,
              background: 'linear-gradient(145deg, #1a1a1a, #2d2d2d)',
              borderRadius: 44,
              border: '2px solid rgba(255,255,255,0.12)',
              boxShadow: '0 30px 80px rgba(0,0,0,0.8), 0 0 40px rgba(48,209,88,0.1), inset 0 1px 0 rgba(255,255,255,0.1)',
              display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
              padding: 16, position: 'relative',
            }}>
              {/* Watch band top */}
              <div style={{
                position: 'absolute', top: -32, left: '50%', transform: 'translateX(-50%)',
                width: 100, height: 36, borderRadius: '12px 12px 0 0',
                background: 'linear-gradient(180deg, #333, #1a1a1a)',
                border: '1px solid rgba(255,255,255,0.08)',
                borderBottom: 'none',
              }} />
              {/* Watch band bottom */}
              <div style={{
                position: 'absolute', bottom: -32, left: '50%', transform: 'translateX(-50%)',
                width: 100, height: 36, borderRadius: '0 0 12px 12px',
                background: 'linear-gradient(180deg, #1a1a1a, #333)',
                border: '1px solid rgba(255,255,255,0.08)',
                borderTop: 'none',
              }} />
              {/* Crown */}
              <div style={{
                position: 'absolute', right: -6, top: '35%',
                width: 6, height: 24, borderRadius: 3,
                background: 'linear-gradient(180deg, #555, #333)',
              }} />

              {/* Screen content */}
              <div style={{
                fontSize: 11, fontWeight: 600, color: '#30D158',
                letterSpacing: 0.5, marginBottom: 6,
              }}>AIHomeRun</div>
              <div style={{
                fontSize: 36, fontWeight: 800, color: '#fff',
                lineHeight: 1, marginBottom: 2,
                fontFamily: '-apple-system, "SF Pro Display", sans-serif',
              }}>68</div>
              <div style={{ fontSize: 10, color: 'rgba(255,255,255,0.5)', marginBottom: 10 }}>mph Hand Speed</div>

              {/* Mini stats row */}
              <div style={{ display: 'flex', gap: 12 }}>
                <div style={{ textAlign: 'center' }}>
                  <div style={{ fontSize: 14, fontWeight: 700, color: '#FF8C00' }}>85</div>
                  <div style={{ fontSize: 8, color: 'rgba(255,255,255,0.4)' }}>Score</div>
                </div>
                <div style={{ width: 1, height: 24, background: 'rgba(255,255,255,0.1)' }} />
                <div style={{ textAlign: 'center' }}>
                  <div style={{ fontSize: 14, fontWeight: 700, color: '#FF2D55' }}>142</div>
                  <div style={{ fontSize: 8, color: 'rgba(255,255,255,0.4)' }}>BPM</div>
                </div>
                <div style={{ width: 1, height: 24, background: 'rgba(255,255,255,0.1)' }} />
                <div style={{ textAlign: 'center' }}>
                  <div style={{ fontSize: 14, fontWeight: 700, color: '#30D158' }}>12</div>
                  <div style={{ fontSize: 8, color: 'rgba(255,255,255,0.4)' }}>Swings</div>
                </div>
              </div>
            </div>

            {/* Pulsing ring around watch */}
            <div style={{
              position: 'absolute', inset: 20,
              border: '1px solid rgba(48,209,88,0.15)',
              borderRadius: 60, animation: 'pulse-glow 3s ease-in-out infinite',
              boxShadow: '0 0 30px rgba(48,209,88,0.08)',
            }} />
          </div>

          {/* Right: Metrics grid */}
          <div style={{
            flex: '1 1 480px',
            display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)',
            gap: 14,
          }}>
            {watchMetrics.map((m, i) => (
              <div
                key={i}
                onMouseEnter={() => setHoveredMetric(i)}
                onMouseLeave={() => setHoveredMetric(null)}
                style={{
                  background: hoveredMetric === i ? 'rgba(255,255,255,0.05)' : 'rgba(255,255,255,0.02)',
                  border: `1px solid ${hoveredMetric === i ? m.color + '33' : 'rgba(255,255,255,0.06)'}`,
                  borderRadius: 16, padding: '18px 16px',
                  transition: 'all 0.25s ease',
                  transform: hoveredMetric === i ? 'translateY(-2px)' : 'none',
                  cursor: 'default',
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8 }}>
                  <span style={{ fontSize: 20 }}>{m.icon}</span>
                  <div>
                    <div style={{ fontSize: 13, fontWeight: 700, color: 'rgba(255,255,255,0.85)', letterSpacing: -0.2 }}>{m.label}</div>
                    <div style={{ fontSize: 18, fontWeight: 800, color: m.color, letterSpacing: -0.5, fontFamily: '-apple-system, "SF Pro Display", sans-serif' }}>{m.value}</div>
                  </div>
                </div>
                <div style={{ fontSize: 12, color: 'rgba(255,255,255,0.35)', lineHeight: 1.55 }}>{m.desc}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Bottom callout: comparison with Blast */}
        <div style={{
          marginTop: 56, textAlign: 'center',
          background: 'linear-gradient(135deg, rgba(48,209,88,0.06), rgba(0,122,255,0.04))',
          border: '1px solid rgba(48,209,88,0.15)',
          borderRadius: 20, padding: '28px 32px',
          maxWidth: 700, margin: '56px auto 0',
        }}>
          <div style={{ fontSize: 18, fontWeight: 700, color: '#fff', marginBottom: 10, letterSpacing: -0.3 }}>
            Why pay $100+ for a dedicated sensor?
          </div>
          <div style={{ fontSize: 14, color: 'rgba(255,255,255,0.45)', lineHeight: 1.7, marginBottom: 16 }}>
            Blast Baseball and other sensor-based systems charge $100+ for a bat-mounted sensor.
            AIHomeRun uses the Apple Watch you already own to deliver comparable swing metrics —
            hand speed, rotational acceleration, swing scores, and more — completely free.
          </div>
          <div style={{ display: 'flex', justifyContent: 'center', gap: 32, flexWrap: 'wrap' }}>
            {[
              { label: 'AIHomeRun', price: 'Free', sub: 'Uses your Apple Watch', color: '#30D158' },
              { label: 'Blast Baseball', price: '$100+', sub: 'Requires dedicated sensor', color: 'rgba(255,255,255,0.3)' },
            ].map(c => (
              <div key={c.label} style={{ textAlign: 'center' }}>
                <div style={{ fontSize: 13, fontWeight: 600, color: c.color, marginBottom: 4 }}>{c.label}</div>
                <div style={{ fontSize: 24, fontWeight: 800, color: c.color, letterSpacing: -0.5 }}>{c.price}</div>
                <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.3)', marginTop: 2 }}>{c.sub}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Air swing mode callout */}
        <div style={{
          display: 'flex', justifyContent: 'center', gap: 28, marginTop: 36, flexWrap: 'wrap',
        }}>
          {[
            { icon: '🏏', title: 'Standard Mode', desc: 'Full swing detection with ball impact tracking' },
            { icon: '💨', title: 'Air Swing Mode', desc: 'Practice without a ball — detects swing motion only' },
            { icon: '📱', title: 'Live Sync', desc: 'Real-time metrics stream to your iPhone during practice' },
          ].map(item => (
            <div key={item.title} style={{
              textAlign: 'center', flex: '0 1 200px',
            }}>
              <div style={{ fontSize: 28, marginBottom: 8 }}>{item.icon}</div>
              <div style={{ fontSize: 14, fontWeight: 700, color: 'rgba(255,255,255,0.8)', marginBottom: 4 }}>{item.title}</div>
              <div style={{ fontSize: 12, color: 'rgba(255,255,255,0.35)', lineHeight: 1.5 }}>{item.desc}</div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}

/* ─── Main Landing Page ─────────────────────────────────────────────────────  */
export default function LandingPage() {
  const [scrolled, setScrolled] = useState(false)
  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 40)
    window.addEventListener('scroll', onScroll, { passive: true })
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  /* Fade-in hooks for each section */
  const statsFade     = useFadeIn()
  const featuresFade  = useFadeIn()
  const howToFade     = useFadeIn()
  const roadmapFade   = useFadeIn()
  const ctaFade       = useFadeIn()
  // watchFade is handled inside AppleWatchSection

  const base = {
    fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Display", "Helvetica Neue", Arial, sans-serif',
    WebkitFontSmoothing: 'antialiased',
    MozOsxFontSmoothing: 'grayscale',
  }

  return (
    <div style={{ minHeight: '100vh', background: '#000', color: '#fff', overflowX: 'hidden', ...base }}>

      {/* ── Global CSS ──────────────────────────────────────────────────── */}
      <style>{`
        *, *::before, *::after { box-sizing: border-box; }
        html { scroll-behavior: smooth; }
        body { margin: 0; }

        @keyframes float-phone {
          0%, 100% { transform: translateY(0px) rotate(-1deg); }
          50%       { transform: translateY(-18px) rotate(-1deg); }
        }
        @keyframes fade-up {
          from { opacity: 0; transform: translateY(28px); }
          to   { opacity: 1; transform: translateY(0); }
        }
        @keyframes pulse-glow {
          0%, 100% { box-shadow: 0 0 30px rgba(255,69,58,0.15); }
          50%       { box-shadow: 0 0 60px rgba(255,69,58,0.35); }
        }

        .nav-link-item {
          color: rgba(255,255,255,0.55);
          text-decoration: none;
          font-size: 15px;
          font-weight: 500;
          transition: color 0.2s;
          letter-spacing: -0.2px;
        }
        .nav-link-item:hover { color: #fff; }

        .footer-link {
          font-size: 13.5px;
          color: rgba(255,255,255,0.45);
          text-decoration: none;
          transition: color 0.2s;
        }
        .footer-link:hover { color: rgba(255,255,255,0.85); }

        .coming-card:hover {
          background: rgba(255,255,255,0.05) !important;
          border-color: rgba(255,69,58,0.2) !important;
        }

        .store-badge-img {
          display: block;
          height: 54px;
          width: auto;
        }

        /* ════════════ RESPONSIVE: MOBILE (≤ 767px) ════════════ */
        @media (max-width: 767px) {

          .nav-links { display: none !important; }
          .nav-cta {
            padding: 7px 16px !important;
            font-size: 13px !important;
          }

          .hero-section {
            min-height: 0 !important;
            padding: 84px 20px 60px !important;
          }
          .hero-flex {
            flex-direction: column !important;
            gap: 40px !important;
            align-items: flex-start !important;
          }
          .hero-text-col { flex: none !important; width: 100% !important; }
          .hero-phone-col {
            flex: none !important;
            width: 100% !important;
            display: flex !important;
            justify-content: center !important;
            animation: none !important;
            filter: drop-shadow(0 20px 40px rgba(255,69,58,0.15)) !important;
          }
          .hero-trust { gap: 8px 14px !important; }

          .stats-inner {
            display: grid !important;
            grid-template-columns: 1fr 1fr !important;
            gap: 20px 12px !important;
            justify-items: center;
          }

          .lp-section-pad { padding: 56px 20px !important; }

          .step-cards-flex {
            flex-direction: column !important;
            align-items: stretch !important;
          }
          .step-cards-flex > * { flex: none !important; width: 100% !important; }

          .req-box { padding: 20px 16px !important; }
          .req-checklist-grid { grid-template-columns: 1fr !important; }

          .cta-badges { justify-content: center !important; }

          .footer-main {
            flex-direction: column !important;
            align-items: flex-start !important;
            gap: 28px !important;
          }
          .footer-links-group { gap: 28px !important; }
          .footer-bottom {
            flex-direction: column !important;
            align-items: center !important;
            text-align: center !important;
            gap: 4px !important;
          }

          .store-badge-img { height: 46px !important; }

          .phone-shell {
            width: 248px !important;
            height: 510px !important;
            border-radius: 40px !important;
          }
          .phone-screen {
            border-radius: 34px !important;
          }

          /* Showcase: hide side phones, show only center */
          .showcase-side-phone {
            display: none !important;
          }
          .showcase-phones {
            gap: 0 !important;
            min-height: 420px !important;
          }
          .showcase-tabs {
            flex-wrap: wrap !important;
            justify-content: center !important;
            gap: 8px !important;
            padding: 0 !important;
          }
          .showcase-tabs button {
            padding: 9px 16px !important;
            font-size: 13px !important;
          }

          /* Features grid: single column */
          .features-grid-top,
          .features-grid-bottom {
            grid-template-columns: 1fr !important;
            max-width: 100% !important;
          }

          /* Watch section: stack vertically */
          .watch-hero-flex {
            flex-direction: column !important;
            gap: 36px !important;
          }
          .watch-hero-flex > div:last-child {
            grid-template-columns: 1fr !important;
          }
        }

        @media (max-width: 390px) {
          .phone-shell {
            width: 228px !important;
            height: 468px !important;
            border-radius: 36px !important;
          }
          .phone-screen {
            border-radius: 30px !important;
          }
        }
      `}</style>

      {/* ── NAVBAR ──────────────────────────────────────────────────────── */}
      <nav style={{
        position: 'fixed', top: 0, left: 0, right: 0, zIndex: 1000,
        height: 64,
        background: scrolled ? 'rgba(0,0,0,0.82)' : 'rgba(0,0,0,0.4)',
        backdropFilter: 'blur(24px)', WebkitBackdropFilter: 'blur(24px)',
        borderBottom: scrolled ? '1px solid rgba(255,255,255,0.07)' : '1px solid transparent',
        transition: 'all 0.3s ease',
        display: 'flex', alignItems: 'center', padding: '0 28px',
      }}>
        <div style={{
          maxWidth: 1120, width: '100%', margin: '0 auto',
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        }}>
          <a href="#" style={{ display:'flex', alignItems:'center', gap:10, textDecoration:'none', color:'#fff' }}>
            <img src="/logo-512.png" alt="AIHomeRun" style={{ width: 32, height: 32, borderRadius: 8, objectFit: 'cover' }} />
            <span style={{ fontSize: 17, fontWeight: 700, letterSpacing: -0.5 }}>AIHomeRun</span>
          </a>

          <div className="nav-links" style={{ display: 'flex', alignItems: 'center', gap: 36 }}>
            <a href="#showcase" className="nav-link-item">Preview</a>
            <a href="#apple-watch" className="nav-link-item">Apple Watch</a>
            <a href="#features" className="nav-link-item">Features</a>
            <a href="#how-to-use" className="nav-link-item">How to Use</a>
            <a href="https://apps.apple.com/app/aihomerun/id6760232096" target="_blank" rel="noopener noreferrer" className="nav-link-item">Download</a>
          </div>

          <a href="https://apps.apple.com/app/aihomerun/id6760232096" target="_blank" rel="noopener noreferrer" className="nav-cta" style={{
            background: 'linear-gradient(135deg, #FF453A, #FF6B35)',
            color: '#fff', borderRadius: 20, padding: '8px 22px',
            fontSize: 14, fontWeight: 600, textDecoration: 'none',
            letterSpacing: -0.2,
            boxShadow: '0 4px 14px rgba(255,69,58,0.3)',
            transition: 'all 0.2s ease',
            whiteSpace: 'nowrap',
          }}
          onMouseEnter={e => { e.currentTarget.style.opacity='0.85'; e.currentTarget.style.transform='translateY(-1px)' }}
          onMouseLeave={e => { e.currentTarget.style.opacity='1'; e.currentTarget.style.transform='translateY(0)' }}
          >Download Free</a>
        </div>
      </nav>

      {/* ── HERO ────────────────────────────────────────────────────────── */}
      <section className="hero-section" style={{
        minHeight: '100vh',
        display: 'flex', alignItems: 'center',
        padding: 'clamp(100px, 12vw, 140px) 28px 80px',
        position: 'relative', overflow: 'hidden',
        background: `
          radial-gradient(ellipse 80% 60% at 70% 40%, rgba(255,69,58,0.11) 0%, transparent 55%),
          radial-gradient(ellipse 60% 50% at 20% 70%, rgba(255,107,53,0.06) 0%, transparent 50%),
          #000
        `,
      }}>
        {/* Grid overlay */}
        <div style={{
          position: 'absolute', inset: 0, pointerEvents: 'none',
          backgroundImage: `
            linear-gradient(rgba(255,255,255,0.018) 1px, transparent 1px),
            linear-gradient(90deg, rgba(255,255,255,0.018) 1px, transparent 1px)
          `,
          backgroundSize: '64px 64px',
        }}/>
        <div style={{
          position:'absolute', top:0, left:0, right:0, height:200,
          background:'linear-gradient(180deg, #000 0%, transparent 100%)',
          pointerEvents:'none',
        }}/>

        <div className="hero-flex" style={{
          maxWidth: 1120, width: '100%', margin: '0 auto',
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          gap: 60, flexWrap: 'wrap',
        }}>
          {/* Left col */}
          <div className="hero-text-col" style={{ flex: '1 1 440px', animation: 'fade-up 0.85s ease both' }}>
            <div style={{
              display: 'inline-flex', alignItems: 'center', gap: 7,
              background: 'rgba(255,69,58,0.1)', border: '1px solid rgba(255,69,58,0.28)',
              borderRadius: 20, padding: '6px 16px',
              fontSize: 12, fontWeight: 700, color: '#FF6B35',
              marginBottom: 28, letterSpacing: 0.2,
            }}>
              <span>⚾</span>
              <span>NOW AVAILABLE · 100% FREE · NO ADS</span>
            </div>

            <h1 style={{
              fontSize: 'clamp(44px, 6vw, 72px)', fontWeight: 800,
              letterSpacing: -2.5, lineHeight: 1.03, margin: '0 0 22px',
              background: 'linear-gradient(180deg, #ffffff 50%, rgba(255,255,255,0.42) 100%)',
              WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundClip: 'text',
            }}>
              AI Baseball<br/>Coach for<br/>
              <span style={{
                background: 'linear-gradient(135deg, #FF453A 0%, #FF8C00 100%)',
                WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundClip: 'text',
              }}>Young Players</span>
            </h1>

            <p style={{
              fontSize: 18, color: 'rgba(255,255,255,0.5)', lineHeight: 1.72,
              maxWidth: 460, margin: '0 0 42px', letterSpacing: -0.1,
            }}>
              Upload a video for instant AI analysis, pair your Apple Watch for
              real-time swing tracking, chat with your AI coach, and climb the rankings.
              Professional-grade baseball training — completely free.
            </p>

            <div id="download" style={{ display: 'flex', gap: 14, flexWrap: 'wrap', marginBottom: 36 }}>
              <AppStoreBadge href="https://apps.apple.com/app/aihomerun/id6760232096" comingSoon={false} />
              <GooglePlayBadge comingSoon={true} />
            </div>

            <div className="hero-trust" style={{ display: 'flex', gap: 20, flexWrap: 'wrap' }}>
              {[
                { icon: '✓', text: '100% Free Forever' },
                { icon: '✓', text: 'No Subscription' },
                { icon: '✓', text: 'Instant AI Analysis' },
                { icon: '✓', text: 'No Ads' },
              ].map(({ icon, text }) => (
                <div key={text} style={{ display: 'flex', alignItems: 'center', gap: 5, fontSize: 13, color: 'rgba(255,255,255,0.38)' }}>
                  <span style={{ color: '#30D158', fontSize: 11, fontWeight: 700 }}>{icon}</span>
                  {text}
                </div>
              ))}
            </div>
          </div>

          {/* Right col — phone with real screenshot */}
          <div className="hero-phone-col" style={{
            flex: '0 0 auto', display: 'flex', justifyContent: 'center', alignItems: 'center',
            animation: 'float-phone 7s ease-in-out infinite, fade-up 0.85s ease 0.15s both',
            filter: 'drop-shadow(0 40px 80px rgba(255,69,58,0.18))',
          }}>
            <ScreenshotPhone src="/screenshots/home.jpg" alt="AIHomeRun analyze screen" />
          </div>
        </div>
      </section>

      {/* ── STATS BAR ───────────────────────────────────────────────────── */}
      <div ref={statsFade.ref} style={{
        borderTop: '1px solid rgba(255,255,255,0.05)',
        borderBottom: '1px solid rgba(255,255,255,0.05)',
        background: 'rgba(255,255,255,0.015)',
        padding: '28px 28px',
        ...statsFade.style,
      }}>
        <div className="stats-inner" style={{
          maxWidth: 1120, margin: '0 auto',
          display: 'flex', justifyContent: 'space-around', flexWrap: 'wrap', gap: 24,
        }}>
          {[
            { num: '7',       label: 'Pro features\nin one free app' },
            { num: '30+',     label: 'Biomechanical\ndata points analyzed' },
            { num: '<30s',    label: 'Instant AI\nfeedback per video' },
            { num: '100%',    label: 'Free forever\nno ads, no fees' },
          ].map(({ num, label }) => (
            <div key={num} style={{ textAlign: 'center', padding: '0 20px' }}>
              <div style={{
                fontSize: 'clamp(28px, 3.5vw, 36px)', fontWeight: 800, letterSpacing: -1,
                background: 'linear-gradient(135deg, #FF453A, #FF8C00)',
                WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundClip: 'text',
                lineHeight: 1,
              }}>{num}</div>
              <div style={{ fontSize: 12, color: 'rgba(255,255,255,0.35)', marginTop: 6, lineHeight: 1.5, whiteSpace: 'pre-line' }}>{label}</div>
            </div>
          ))}
        </div>
      </div>

      {/* ── FEATURES SHOWCASE (Tab-based phone viewer) ─────────────────── */}
      <FeaturesShowcase />

      {/* ── APPLE WATCH SECTION ────────────────────────────────────────── */}
      <AppleWatchSection />

      {/* ── FEATURES ────────────────────────────────────────────────────── */}
      <section id="features" className="lp-section-pad" ref={featuresFade.ref} style={{
        padding: 'clamp(70px, 8vw, 110px) 28px',
        background: '#000',
        borderTop: '1px solid rgba(255,255,255,0.05)',
        ...featuresFade.style,
      }}>
        <div style={{ maxWidth: 1120, margin: '0 auto' }}>
          <div style={{ textAlign: 'center', marginBottom: 56 }}>
            <SectionLabel>Core Features</SectionLabel>
            <SectionTitle>Everything you need to<br/>level up your game</SectionTitle>
            <p style={{ fontSize: 17, color: 'rgba(255,255,255,0.4)', maxWidth: 520, margin: '0 auto', lineHeight: 1.68, letterSpacing: -0.1 }}>
              AI-powered coaching technology previously available only to
              professional athletes — now free for every young player.
            </p>
          </div>

          {/* Row 1: 3 feature cards */}
          <div className="features-grid-top" style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(3, 1fr)',
            gap: 18,
            marginBottom: 18,
          }}>
            <FeatureCard
              icon="🎯"
              title="AI Video Analysis"
              accent="#FF453A"
              desc="Upload any video and get instant AI-powered scores with radar charts, metric gauges, and bar indicators. Analyze hip rotation, bat path, shoulder alignment, plane efficiency, and 30+ data points."
            />
            <FeatureCard
              icon="⌚"
              title="Apple Watch Integration"
              accent="#30D158"
              desc="Pair your Apple Watch for real-time swing detection with hand speed, rotational acceleration, composite swing scores, and heart rate tracking. Air Swing mode lets you practice without a ball."
            />
            <FeatureCard
              icon="🤖"
              title="AI Coach Chat"
              accent="#0A84FF"
              desc="Chat one-on-one with your personal AI coach. Get biomechanics advice, training tips, and answers personalized to your analysis history — like having a private coach 24/7."
            />
          </div>

          {/* Row 2: 3 feature cards */}
          <div className="features-grid-bottom" style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(3, 1fr)',
            gap: 18,
            maxWidth: '100%',
            margin: '0 auto',
          }}>
            <FeatureCard
              icon="🏆"
              title="Player Rankings"
              accent="#FFD60A"
              desc="See where you stand among other players on the leaderboard. Compare your scores, track your position, and stay motivated by competing with athletes nationwide."
            />
            <FeatureCard
              icon="📍"
              title="Find Baseball Fields"
              accent="#30D158"
              desc="Discover nearby baseball fields and batting cages with integrated maps. Get directions, see facility details, and find the perfect place to practice."
            />
            <FeatureCard
              icon="📊"
              title="Pro Analytics & Progress"
              accent="#BF5AF2"
              desc="Track your complete history with radar charts, trend lines, and metric breakdowns. Compare sessions side by side and see how far you've come with professional-grade visualizations."
            />
          </div>
        </div>
      </section>

      {/* ── HOW TO USE ──────────────────────────────────────────────────── */}
      <section id="how-to-use" className="lp-section-pad" ref={howToFade.ref} style={{
        padding: 'clamp(70px, 8vw, 110px) 28px',
        background: '#050505',
        borderTop: '1px solid rgba(255,255,255,0.05)',
        ...howToFade.style,
      }}>
        <div style={{ maxWidth: 1120, margin: '0 auto' }}>
          <div style={{ textAlign: 'center', marginBottom: 56 }}>
            <SectionLabel>How It Works</SectionLabel>
            <SectionTitle>Get AI coaching in<br/>3 simple steps</SectionTitle>
            <p style={{ fontSize: 17, color: 'rgba(255,255,255,0.4)', maxWidth: 480, margin: '0 auto', lineHeight: 1.68 }}>
              No equipment needed. No signup required. Just record, upload, and improve.
            </p>
          </div>

          <div className="step-cards-flex" style={{ display: 'flex', gap: 20, flexWrap: 'wrap', justifyContent: 'center', marginBottom: 48 }}>
            <StepCard
              num="1"
              title="Record Your Video"
              items={[
                'Full body must be visible — head to toe',
                'Face the camera directly (front-facing view)',
                'Use good, even lighting — avoid harsh shadows',
                'Keep camera stable at waist height, 10–15 ft away',
                'Video length: 3 to 15 seconds',
                'Outdoors in natural daylight works best',
              ]}
            />
            <StepCard
              num="2"
              title="Upload to AIHomeRun"
              items={[
                'Download the free app on your iPhone',
                'Select your action type: Swing or Pitch',
                'Tap the upload button and choose your video',
                'Wait under 30 seconds for analysis to complete',
              ]}
            />
            <StepCard
              num="3"
              title="Review & Improve"
              items={[
                'View your scores across all 4 dimensions',
                'Read AI-generated strengths and coaching tips',
                'Chat with AI Coach for personalized training advice',
                'Find nearby fields to practice your new drills',
                'Upload again to track progress and climb the rankings',
              ]}
            />
          </div>

          {/* Video requirements highlight */}
          <div className="req-box" style={{
            background: 'rgba(255,69,58,0.06)',
            border: '1px solid rgba(255,69,58,0.18)',
            borderRadius: 22, padding: '28px 36px',
            display: 'flex', gap: 20, alignItems: 'flex-start',
            maxWidth: 780, margin: '0 auto',
          }}>
            <div style={{
              width: 44, height: 44, borderRadius: 12, flexShrink: 0,
              background: 'rgba(255,69,58,0.12)', border: '1px solid rgba(255,69,58,0.2)',
              display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 22,
            }}>📋</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 16, fontWeight: 700, color: '#fff', marginBottom: 10, letterSpacing: -0.3 }}>
                Video Requirements Checklist
              </div>
              <div className="req-checklist-grid" style={{
                display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '6px 24px',
              }}>
                {[
                  'Full body in frame (head to toe)',
                  'Front-facing or slight side angle',
                  'Stable camera, no handheld shake',
                  'Good, even lighting (no silhouettes)',
                  'Plain or clear background preferred',
                  '3–15 seconds duration',
                  'Landscape or portrait mode both OK',
                  'Standard video format (MP4, MOV)',
                ].map((req, i) => (
                  <div key={i} style={{ display: 'flex', gap: 7, alignItems: 'center' }}>
                    <span style={{ color: '#30D158', fontSize: 12, fontWeight: 700, flexShrink: 0 }}>✓</span>
                    <span style={{ fontSize: 13, color: 'rgba(255,255,255,0.5)', lineHeight: 1.5 }}>{req}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── COMING SOON ─────────────────────────────────────────────────── */}
      <section className="lp-section-pad" ref={roadmapFade.ref} style={{
        padding: 'clamp(70px, 8vw, 110px) 28px',
        background: '#000',
        borderTop: '1px solid rgba(255,255,255,0.05)',
        ...roadmapFade.style,
      }}>
        <div style={{ maxWidth: 1120, margin: '0 auto' }}>
          <div style={{ textAlign: 'center', marginBottom: 52 }}>
            <SectionLabel>Roadmap</SectionLabel>
            <SectionTitle>What's coming next</SectionTitle>
            <p style={{ fontSize: 17, color: 'rgba(255,255,255,0.4)', maxWidth: 480, margin: '0 auto', lineHeight: 1.68 }}>
              We're continuously building new features to help every young
              athlete reach their full potential.
            </p>
          </div>

          <div style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(210px, 1fr))',
            gap: 16,
          }}>
            {[
              { icon: '🏆', title: 'Achievement Badges',    desc: 'Earn milestone rewards as your skills improve session by session' },
              { icon: '👨‍🏫', title: 'Coach Dashboard',      desc: 'Coaches review player sessions and add personal feedback notes' },
              { icon: '👪', title: 'Family Mode',           desc: 'Manage multiple young athletes under one parent account' },
              { icon: '🏟️', title: 'Team Features',         desc: 'Compare performance across a full team roster and track group progress' },
              { icon: '📅', title: 'Training Programs',     desc: 'Multi-week structured training plans generated by AI, tailored to your specific improvement areas' },
              { icon: '🤖', title: 'Smart Bat Sensor',      desc: 'Optional Bluetooth bat sensor integration for even more precise bat speed and impact data' },
            ].map(({ icon, title, desc }) => (
              <div key={title} className="coming-card" style={{
                background: 'rgba(255,255,255,0.02)',
                border: '1px solid rgba(255,255,255,0.06)',
                borderRadius: 18, padding: '22px 20px',
                position: 'relative', overflow: 'hidden',
                transition: 'all 0.2s ease',
                cursor: 'default',
              }}>
                <div style={{
                  position: 'absolute', top: 14, right: 14,
                  fontSize: 9, fontWeight: 700, letterSpacing: 0.7,
                  color: 'rgba(255,159,10,0.9)', background: 'rgba(255,159,10,0.1)',
                  padding: '3px 7px', borderRadius: 5, textTransform: 'uppercase',
                }}>Soon</div>
                <div style={{ fontSize: 30, marginBottom: 12, lineHeight: 1 }}>{icon}</div>
                <div style={{ fontSize: 14.5, fontWeight: 700, color: 'rgba(255,255,255,0.82)', marginBottom: 7, letterSpacing: -0.2 }}>{title}</div>
                <div style={{ fontSize: 12.5, color: 'rgba(255,255,255,0.32)', lineHeight: 1.6 }}>{desc}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── DOWNLOAD CTA ────────────────────────────────────────────────── */}
      <section className="lp-section-pad" ref={ctaFade.ref} style={{
        padding: 'clamp(70px, 8vw, 120px) 28px',
        borderTop: '1px solid rgba(255,255,255,0.05)',
        background: `
          radial-gradient(ellipse 70% 50% at 50% 0%, rgba(255,69,58,0.13) 0%, transparent 55%),
          #000
        `,
        textAlign: 'center',
        ...ctaFade.style,
      }}>
        <div style={{ maxWidth: 580, margin: '0 auto' }}>
          <img
            src="/logo-512.png"
            alt="AIHomeRun"
            style={{
              width: 88, height: 88, borderRadius: 22, margin: '0 auto 28px',
              objectFit: 'cover', display: 'block',
              boxShadow: '0 20px 60px rgba(255,69,58,0.35)',
              animation: 'pulse-glow 3s ease-in-out infinite',
            }}
          />

          <SectionTitle>
            Start your free<br/>analysis today
          </SectionTitle>

          <p style={{
            fontSize: 18, color: 'rgba(255,255,255,0.45)', lineHeight: 1.72,
            margin: '0 0 42px', letterSpacing: -0.1,
          }}>
            AI video analysis, Apple Watch swing tracking, personal coaching,
            player rankings, and field finder — all completely free. No subscription. No ads.
          </p>

          <div className="cta-badges" style={{ display: 'flex', gap: 14, justifyContent: 'center', flexWrap: 'wrap', marginBottom: 28 }}>
            <AppStoreBadge href="https://apps.apple.com/app/aihomerun/id6760232096" comingSoon={false} />
            <GooglePlayBadge comingSoon={true} />
          </div>

          <div style={{ fontSize: 13, color: 'rgba(255,255,255,0.25)' }}>
            Questions? Email us at{' '}
            <a href="mailto:info@aihomerun.app" style={{ color: 'rgba(255,69,58,0.7)', textDecoration: 'none' }}>
              info@aihomerun.app
            </a>
          </div>
        </div>
      </section>

      {/* ── FOOTER ──────────────────────────────────────────────────────── */}
      <footer style={{
        padding: '44px 28px',
        borderTop: '1px solid rgba(255,255,255,0.06)',
        background: '#000',
      }}>
        <div className="footer-main" style={{
          maxWidth: 1120, margin: '0 auto',
          display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start',
          flexWrap: 'wrap', gap: 32,
        }}>
          <div style={{ maxWidth: 260 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 9, marginBottom: 12 }}>
              <img src="/logo-512.png" alt="AIHomeRun" style={{ width: 30, height: 30, borderRadius: 8, objectFit: 'cover' }} />
              <span style={{ fontSize: 16, fontWeight: 700, letterSpacing: -0.4 }}>AIHomeRun</span>
            </div>
            <div style={{ fontSize: 13, color: 'rgba(255,255,255,0.28)', lineHeight: 1.65 }}>
              AI-powered baseball coaching for youth athletes. Free forever.
            </div>
          </div>

          <div className="footer-links-group" style={{ display: 'flex', gap: 56, flexWrap: 'wrap' }}>
            <div>
              <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1.5, color: 'rgba(255,255,255,0.25)', textTransform: 'uppercase', marginBottom: 14 }}>Product</div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                <a href="#showcase" className="footer-link">App Preview</a>
                <a href="#apple-watch" className="footer-link">Apple Watch</a>
                <a href="#features" className="footer-link">Features</a>
                <a href="#how-to-use" className="footer-link">How to Use</a>
                <a href="https://apps.apple.com/app/aihomerun/id6760232096" target="_blank" rel="noopener noreferrer" className="footer-link">Download App</a>
              </div>
            </div>
            <div>
              <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1.5, color: 'rgba(255,255,255,0.25)', textTransform: 'uppercase', marginBottom: 14 }}>Support</div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                <a href="mailto:info@aihomerun.app" className="footer-link">info@aihomerun.app</a>
              </div>
            </div>
            <div>
              <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1.5, color: 'rgba(255,255,255,0.25)', textTransform: 'uppercase', marginBottom: 14 }}>Legal</div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                <a href="/privacy" className="footer-link">Privacy Policy</a>
              </div>
            </div>
          </div>
        </div>

        <div className="footer-bottom" style={{
          maxWidth: 1120, margin: '32px auto 0',
          paddingTop: 24, borderTop: '1px solid rgba(255,255,255,0.05)',
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          flexWrap: 'wrap', gap: 12,
        }}>
          <div style={{ fontSize: 12.5, color: 'rgba(255,255,255,0.2)' }}>
            © 2026 AIHomeRun · All rights reserved.
          </div>
          <div style={{ fontSize: 12.5, color: 'rgba(255,255,255,0.2)' }}>
            Made for young athletes everywhere ⚾
          </div>
        </div>
      </footer>
    </div>
  )
}
