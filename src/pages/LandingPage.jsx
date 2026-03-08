/* ─────────────────────────────────────────────────────────────────────────────
   AIHomeRun — Marketing Landing Page
   High-end app promotion website (NOT the app itself)
───────────────────────────────────────────────────────────────────────────── */

import { useEffect, useState } from 'react'

/* ─── App Store Badge ──────────────────────────────────────────────────────── */
/* Uses the official Apple-provided badge SVG file exactly as-is */
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
      {/* Official Apple badge SVG — downloaded from Apple Marketing Guidelines */}
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
/* Uses the official Google-provided badge SVG file exactly as-is */
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
      {/* Official Google badge SVG — downloaded from Google Play Partner Marketing Hub */}
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

/* ─── Phone Mockup ─────────────────────────────────────────────────────────── */
function PhoneMockup() {
  return (
    <div className="phone-shell" style={{
      position: 'relative', width: 270, height: 554,
      background: 'linear-gradient(160deg, #1a1a1a 0%, #0d0d0d 100%)',
      borderRadius: 46,
      border: '2px solid rgba(255,255,255,0.1)',
      boxShadow: `
        0 0 0 1px rgba(255,255,255,0.04),
        0 40px 100px rgba(0,0,0,0.9),
        0 0 80px rgba(255,69,58,0.12),
        inset 0 1px 0 rgba(255,255,255,0.08)
      `,
      overflow: 'hidden', flexShrink: 0,
    }}>
      {/* Side buttons */}
      <div style={{ position:'absolute', right:-3, top:100, width:3, height:32, background:'rgba(255,255,255,0.08)', borderRadius:'0 2px 2px 0' }}/>
      <div style={{ position:'absolute', left:-3, top:88, width:3, height:24, background:'rgba(255,255,255,0.08)', borderRadius:'2px 0 0 2px' }}/>
      <div style={{ position:'absolute', left:-3, top:120, width:3, height:40, background:'rgba(255,255,255,0.08)', borderRadius:'2px 0 0 2px' }}/>

      {/* Dynamic Island */}
      <div style={{
        position:'absolute', top:12, left:'50%', transform:'translateX(-50%)',
        width:116, height:34, background:'#000', borderRadius:20, zIndex:10,
        border:'1px solid rgba(255,255,255,0.06)',
      }}/>

      {/* Screen */}
      <div style={{
        position:'absolute', inset:0,
        background:'linear-gradient(180deg, #000 0%, #080808 100%)',
        display:'flex', flexDirection:'column',
        padding:'58px 16px 20px', gap:12, overflow:'hidden',
      }}>
        {/* Status bar */}
        <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', padding:'0 4px', marginBottom:4 }}>
          <div style={{ fontSize:12, fontWeight:600, color:'rgba(255,255,255,0.8)' }}>9:41</div>
          <div style={{ display:'flex', gap:5, alignItems:'center' }}>
            {/* Signal bars */}
            <svg width="16" height="12" viewBox="0 0 16 12" fill="rgba(255,255,255,0.8)">
              <rect x="0" y="8" width="3" height="4" rx="1"/>
              <rect x="4.5" y="5" width="3" height="7" rx="1"/>
              <rect x="9" y="2" width="3" height="10" rx="1"/>
              <rect x="13.5" y="0" width="3" height="12" rx="1" opacity="0.3"/>
            </svg>
            {/* Battery */}
            <svg width="22" height="12" viewBox="0 0 22 12" fill="none">
              <rect x="0.5" y="0.5" width="18" height="11" rx="2.5" stroke="rgba(255,255,255,0.6)" strokeWidth="1"/>
              <rect x="2" y="2" width="12" height="8" rx="1.5" fill="rgba(255,255,255,0.8)"/>
              <path d="M20 4.5v3a1.5 1.5 0 000-3z" fill="rgba(255,255,255,0.5)"/>
            </svg>
          </div>
        </div>

        {/* App header */}
        <div style={{ display:'flex', alignItems:'center', gap:10 }}>
          <img
            src="/logo-512.png"
            alt="AIHomeRun"
            style={{ width:38, height:38, borderRadius:10, objectFit:'cover', flexShrink:0, boxShadow:'0 4px 12px rgba(0,0,0,0.4)' }}
          />
          <div>
            <div style={{ fontSize:15, fontWeight:700, color:'#fff', letterSpacing:-0.3 }}>AIHomeRun</div>
            <div style={{ fontSize:11, color:'rgba(255,255,255,0.35)' }}>AI Baseball Coach</div>
          </div>
        </div>

        {/* Upload zone */}
        <div style={{
          background:'rgba(255,69,58,0.07)',
          border:'1.5px dashed rgba(255,69,58,0.35)',
          borderRadius:16, padding:'18px 12px',
          display:'flex', flexDirection:'column',
          alignItems:'center', gap:7,
        }}>
          <div style={{ fontSize:26 }}>📹</div>
          <div style={{ fontSize:11.5, color:'rgba(255,255,255,0.65)', textAlign:'center', fontWeight:500, lineHeight:1.4 }}>
            Upload your swing<br/>or pitch video
          </div>
          <div style={{
            marginTop:2, background:'linear-gradient(135deg, #FF453A, #FF6B35)',
            borderRadius:8, padding:'5px 14px',
            fontSize:11, fontWeight:600, color:'#fff',
          }}>Choose Video</div>
        </div>

        {/* Score row */}
        <div style={{ display:'flex', gap:8 }}>
          {[
            { label:'Overall', score:85, color:'#30D158', bg:'rgba(48,209,88,0.1)' },
            { label:'Technique', score:78, color:'#FF9F0A', bg:'rgba(255,159,10,0.1)' },
          ].map(({ label, score, color, bg }) => (
            <div key={label} style={{
              flex:1, background:bg, borderRadius:12, padding:'9px 11px',
              border:`1px solid ${color}22`,
            }}>
              <div style={{ fontSize:9, color:'rgba(255,255,255,0.4)', textTransform:'uppercase', letterSpacing:0.5, marginBottom:2 }}>{label}</div>
              <div style={{ fontSize:22, fontWeight:700, color, letterSpacing:-0.5 }}>{score}</div>
            </div>
          ))}
          <div style={{
            flex:1, background:'rgba(10,132,255,0.1)', borderRadius:12, padding:'9px 11px',
            border:'1px solid rgba(10,132,255,0.2)',
          }}>
            <div style={{ fontSize:9, color:'rgba(255,255,255,0.4)', textTransform:'uppercase', letterSpacing:0.5, marginBottom:2 }}>Power</div>
            <div style={{ fontSize:22, fontWeight:700, color:'#0A84FF', letterSpacing:-0.5 }}>72</div>
          </div>
        </div>

        {/* Feedback card */}
        <div style={{
          background:'rgba(255,255,255,0.04)', borderRadius:12, padding:'10px 12px',
          border:'1px solid rgba(255,255,255,0.06)',
        }}>
          <div style={{ fontSize:10, color:'rgba(255,255,255,0.35)', marginBottom:5, fontWeight:500, textTransform:'uppercase', letterSpacing:0.4 }}>💡 AI Coaching</div>
          <div style={{ fontSize:11.5, color:'rgba(255,255,255,0.7)', lineHeight:1.5 }}>
            Great hip rotation! Focus on follow-through for more power. Try the tee drill 3x daily.
          </div>
        </div>

        {/* Drill badge */}
        <div style={{
          display:'flex', alignItems:'center', gap:8,
          background:'rgba(191,90,242,0.1)', borderRadius:10, padding:'8px 12px',
          border:'1px solid rgba(191,90,242,0.2)',
        }}>
          <span style={{ fontSize:16 }}>🏋️</span>
          <div>
            <div style={{ fontSize:10, color:'rgba(191,90,242,0.8)', fontWeight:600, textTransform:'uppercase', letterSpacing:0.4 }}>Today's Drill</div>
            <div style={{ fontSize:11, color:'rgba(255,255,255,0.6)' }}>Hip Drive Progression</div>
          </div>
        </div>

        {/* Screen glow */}
        <div style={{
          position:'absolute', bottom:-20, left:-20, right:-20, height:80,
          background:'radial-gradient(ellipse, rgba(255,69,58,0.1) 0%, transparent 70%)',
          pointerEvents:'none',
        }}/>
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

/* ─── Main Landing Page ─────────────────────────────────────────────────────  */
export default function LandingPage() {
  /* Scroll-based navbar opacity */
  const [scrolled, setScrolled] = useState(false)
  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 40)
    window.addEventListener('scroll', onScroll, { passive: true })
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

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

        /* Store badge default height */
        .store-badge-img {
          display: block;
          height: 54px;
          width: auto;
        }

        /* ════════════ RESPONSIVE: MOBILE (≤ 767px) ════════════ */
        @media (max-width: 767px) {

          /* 1. Navbar — hide desktop links, keep logo + CTA only */
          .nav-links { display: none !important; }
          .nav-cta {
            padding: 7px 16px !important;
            font-size: 13px !important;
          }

          /* 2. Hero — reduce vertical space, center phone */
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

          /* 3. Stats bar — 2×2 grid */
          .stats-inner {
            display: grid !important;
            grid-template-columns: 1fr 1fr !important;
            gap: 20px 12px !important;
            justify-items: center;
          }

          /* 4. Sections — tighter padding on mobile */
          .lp-section-pad { padding: 56px 20px !important; }

          /* 5. Step cards — single column */
          .step-cards-flex {
            flex-direction: column !important;
            align-items: stretch !important;
          }
          .step-cards-flex > * { flex: none !important; width: 100% !important; }

          /* 6. Video req checklist — single column */
          .req-box { padding: 20px 16px !important; }
          .req-checklist-grid { grid-template-columns: 1fr !important; }

          /* 7. CTA badges — centered */
          .cta-badges { justify-content: center !important; }

          /* 8. Footer */
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

          /* 9. Store badges slightly smaller on mobile */
          .store-badge-img { height: 46px !important; }

          /* 10. Phone mockup — scale down on very small screens */
          .phone-shell {
            width: 248px !important;
            height: 510px !important;
            border-radius: 40px !important;
          }
        }

        @media (max-width: 390px) {
          .phone-shell {
            width: 228px !important;
            height: 468px !important;
            border-radius: 36px !important;
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
          {/* Brand */}
          <a href="#" style={{ display:'flex', alignItems:'center', gap:10, textDecoration:'none', color:'#fff' }}>
            <img
              src="/logo-512.png"
              alt="AIHomeRun"
              style={{ width: 32, height: 32, borderRadius: 8, objectFit: 'cover' }}
            />
            <span style={{ fontSize: 17, fontWeight: 700, letterSpacing: -0.5 }}>AIHomeRun</span>
          </a>

          {/* Desktop nav links — hidden on mobile */}
          <div className="nav-links" style={{ display: 'flex', alignItems: 'center', gap: 36 }}>
            <a href="#features" className="nav-link-item">Features</a>
            <a href="#how-to-use" className="nav-link-item">How to Use</a>
            <a href="#download" className="nav-link-item">Download</a>
            <a href="mailto:info@aihomerun.app" className="nav-link-item" style={{ fontSize:14 }}>Contact</a>
          </div>

          {/* CTA — always visible */}
          <a href="#download" className="nav-cta" style={{
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
        {/* Top fade */}
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
            {/* Tag */}
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
              Upload a video of your swing or pitch and receive
              instant AI-powered coaching feedback. Professional-grade
              analysis, completely free — for every young athlete.
            </p>

            {/* Store badges */}
            <div id="download" style={{ display: 'flex', gap: 14, flexWrap: 'wrap', marginBottom: 36 }}>
              <AppStoreBadge href="#" comingSoon={false} />
              <GooglePlayBadge comingSoon={true} />
            </div>

            {/* Trust pills */}
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

          {/* Right col — phone */}
          <div className="hero-phone-col" style={{
            flex: '0 0 auto', display: 'flex', justifyContent: 'center', alignItems: 'center',
            animation: 'float-phone 7s ease-in-out infinite, fade-up 0.85s ease 0.15s both',
            filter: 'drop-shadow(0 40px 80px rgba(255,69,58,0.18))',
          }}>
            <PhoneMockup />
          </div>
        </div>
      </section>

      {/* ── STATS BAR ───────────────────────────────────────────────────── */}
      <div style={{
        borderTop: '1px solid rgba(255,255,255,0.05)',
        borderBottom: '1px solid rgba(255,255,255,0.05)',
        background: 'rgba(255,255,255,0.015)',
        padding: '28px 28px',
      }}>
        <div className="stats-inner" style={{
          maxWidth: 1120, margin: '0 auto',
          display: 'flex', justifyContent: 'space-around', flexWrap: 'wrap', gap: 24,
        }}>
          {[
            { num: '20+',     label: 'Biomechanical\ndata points analyzed' },
            { num: '4',       label: 'Performance\ndimensions scored' },
            { num: '<30s',    label: 'Instant AI\nfeedback per video' },
            { num: 'Free',    label: 'Always free\nno hidden fees' },
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

      {/* ── FEATURES ────────────────────────────────────────────────────── */}
      <section id="features" className="lp-section-pad" style={{ padding: 'clamp(70px, 8vw, 110px) 28px', background: '#000' }}>
        <div style={{ maxWidth: 1120, margin: '0 auto' }}>
          <div style={{ textAlign: 'center', marginBottom: 56 }}>
            <SectionLabel>Core Features</SectionLabel>
            <SectionTitle>Everything you need to<br/>level up your game</SectionTitle>
            <p style={{ fontSize: 17, color: 'rgba(255,255,255,0.4)', maxWidth: 520, margin: '0 auto', lineHeight: 1.68, letterSpacing: -0.1 }}>
              AI-powered coaching technology previously available only to
              professional athletes — now free for every young player.
            </p>
          </div>

          <div style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))',
            gap: 18,
          }}>
            <FeatureCard
              icon="🎯"
              title="AI Swing & Pitch Analysis"
              accent="#FF453A"
              desc="Upload any video and our AI instantly analyzes 20+ biomechanical data points — hip rotation, bat path, shoulder alignment, follow-through, weight transfer, and more."
            />
            <FeatureCard
              icon="📊"
              title="Detailed Action Report"
              accent="#FF9F0A"
              desc="Receive a full scorecard with Overall, Technique, Power, and Balance scores. Each session includes strengths, areas to improve, and AI-recommended drills."
            />
            <FeatureCard
              icon="📈"
              title="Before & After Comparison"
              accent="#30D158"
              desc="Upload multiple sessions to visually track your progress over time. See exactly how your mechanics have changed and celebrate measurable improvement."
            />
            <FeatureCard
              icon="🗺️"
              title="Personalized Growth Path"
              accent="#BF5AF2"
              desc="AI-generated training plans tailored to your unique weaknesses. Focused drill recommendations that target exactly what you need to work on most."
            />
          </div>
        </div>
      </section>

      {/* ── HOW TO USE ──────────────────────────────────────────────────── */}
      <section id="how-to-use" className="lp-section-pad" style={{
        padding: 'clamp(70px, 8vw, 110px) 28px',
        background: '#050505',
        borderTop: '1px solid rgba(255,255,255,0.05)',
      }}>
        <div style={{ maxWidth: 1120, margin: '0 auto' }}>
          <div style={{ textAlign: 'center', marginBottom: 56 }}>
            <SectionLabel>How It Works</SectionLabel>
            <SectionTitle>Get AI coaching in<br/>3 simple steps</SectionTitle>
            <p style={{ fontSize: 17, color: 'rgba(255,255,255,0.4)', maxWidth: 480, margin: '0 auto', lineHeight: 1.68 }}>
              No equipment needed. No signup required. Just record, upload, and improve.
            </p>
          </div>

          {/* Step cards */}
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
                'Follow the recommended training drill',
                'Upload again to track your progress over time',
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
      <section className="lp-section-pad" style={{
        padding: 'clamp(70px, 8vw, 110px) 28px',
        background: '#000',
        borderTop: '1px solid rgba(255,255,255,0.05)',
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
              { icon: '⚡', title: 'Session Comparison',    desc: 'Side-by-side video playback to see your technique evolution' },
              { icon: '🏆', title: 'Achievement Badges',    desc: 'Earn milestone rewards as your skills improve session by session' },
              { icon: '👨‍🏫', title: 'Coach Dashboard',      desc: 'Coaches review player sessions and add personal feedback notes' },
              { icon: '👪', title: 'Family Mode',           desc: 'Manage multiple young athletes under one parent account' },
              { icon: '🏟️', title: 'Team Features',         desc: 'Compare performance across a full team roster and track group progress' },
              { icon: '🤖', title: 'Expanded AI Models',    desc: 'Analysis for pitching mechanics, fielding, and more baseball movements' },
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
      <section className="lp-section-pad" style={{
        padding: 'clamp(70px, 8vw, 120px) 28px',
        borderTop: '1px solid rgba(255,255,255,0.05)',
        background: `
          radial-gradient(ellipse 70% 50% at 50% 0%, rgba(255,69,58,0.13) 0%, transparent 55%),
          #000
        `,
        textAlign: 'center',
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
            No subscription. No ads. No hidden fees.<br/>
            Just powerful AI baseball coaching — completely free.
          </p>

          <div className="cta-badges" style={{ display: 'flex', gap: 14, justifyContent: 'center', flexWrap: 'wrap', marginBottom: 28 }}>
            <AppStoreBadge href="#" comingSoon={false} />
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
          {/* Brand */}
          <div style={{ maxWidth: 260 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 9, marginBottom: 12 }}>
              <img
                src="/logo-512.png"
                alt="AIHomeRun"
                style={{ width: 30, height: 30, borderRadius: 8, objectFit: 'cover' }}
              />
              <span style={{ fontSize: 16, fontWeight: 700, letterSpacing: -0.4 }}>AIHomeRun</span>
            </div>
            <div style={{ fontSize: 13, color: 'rgba(255,255,255,0.28)', lineHeight: 1.65 }}>
              AI-powered baseball coaching for youth athletes. Free forever.
            </div>
          </div>

          {/* Links */}
          <div className="footer-links-group" style={{ display: 'flex', gap: 56, flexWrap: 'wrap' }}>
            <div>
              <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1.5, color: 'rgba(255,255,255,0.25)', textTransform: 'uppercase', marginBottom: 14 }}>Product</div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                <a href="#features" className="footer-link">Features</a>
                <a href="#how-to-use" className="footer-link">How to Use</a>
                <a href="#download" className="footer-link">Download App</a>
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

        {/* Bottom bar */}
        <div className="footer-bottom" style={{
          maxWidth: 1120, margin: '32px auto 0',
          paddingTop: 24, borderTop: '1px solid rgba(255,255,255,0.05)',
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          flexWrap: 'wrap', gap: 12,
        }}>
          <div style={{ fontSize: 12.5, color: 'rgba(255,255,255,0.2)' }}>
            © 2026 QING SHEN · AIHomeRun · All rights reserved.
          </div>
          <div style={{ fontSize: 12.5, color: 'rgba(255,255,255,0.2)' }}>
            Made for young athletes everywhere ⚾
          </div>
        </div>
      </footer>
    </div>
  )
}
