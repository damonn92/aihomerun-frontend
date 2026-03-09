export default function PrivacyPage() {
  const updated = 'March 7, 2026'

  return (
    <div style={{
      maxWidth: 680,
      margin: '0 auto',
      padding: '48px 24px 80px',
      color: 'var(--label, #1c1c1e)',
      fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
      lineHeight: 1.7,
    }}>
      {/* Back navigation */}
      <button
        onClick={() => window.history.length > 1 ? window.history.back() : (window.location.href = '/')}
        style={{
          display: 'inline-flex', alignItems: 'center', gap: 4,
          marginBottom: 16, padding: '6px 0',
          background: 'none', border: 'none', cursor: 'pointer',
          font: 'var(--text-body, 17px -apple-system, sans-serif)',
          color: 'var(--blue, #007aff)',
        }}
      >
        &larr; Back
      </button>

      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginBottom: 32 }}>
        <img src="/logo-512.png" alt="AIHomeRun" style={{ width: 52, height: 52, borderRadius: 12 }} />
        <div>
          <h1 style={{ margin: 0, fontSize: 26, fontWeight: 700, letterSpacing: '-0.5px' }}>
            Privacy Policy
          </h1>
          <p style={{ margin: 0, fontSize: 13, color: 'var(--label2, #636366)' }}>
            Last updated: {updated}
          </p>
        </div>
      </div>

      <Section title="1. Overview">
        AIHomeRun ("we", "us", or "our") is an AI-powered baseball coaching application. This Privacy
        Policy explains how we collect, use, and protect your personal information when you use our
        iOS application and website at <a href="https://www.aihomerun.app" style={{ color: '#007aff' }}>www.aihomerun.app</a>.
        <br /><br />
        By using AIHomeRun, you agree to the collection and use of information as described in this policy.
      </Section>

      <Section title="2. Information We Collect">
        <b>Account Information</b>
        <ul>
          <li>Email address (required for registration)</li>
          <li>Full name (optional, for your profile)</li>
          <li>Phone number (optional)</li>
          <li>Password (stored securely via Supabase Auth — we never see your plaintext password)</li>
        </ul>

        <b>Children's Information</b>
        <ul>
          <li>Child's name, date of birth, gender (optional)</li>
          <li>Baseball position and coaching notes (optional)</li>
          <li>This information is provided voluntarily by parents/guardians to personalize coaching feedback</li>
        </ul>

        <b>Video Content</b>
        <ul>
          <li>Baseball swing or pitch videos you upload for AI analysis</li>
          <li>Videos are transmitted securely for analysis and are not permanently stored</li>
        </ul>

        <b>Usage Data</b>
        <ul>
          <li>App usage patterns and feature interactions (anonymous)</li>
          <li>Device type and operating system version</li>
        </ul>
      </Section>

      <Section title="3. How We Use Your Information">
        <ul>
          <li>To provide AI-powered baseball coaching analysis</li>
          <li>To maintain and display your profile and children's information</li>
          <li>To send account-related emails (verification, password reset)</li>
          <li>To improve our AI models and app functionality</li>
          <li>To comply with legal obligations</li>
        </ul>
        We do <b>not</b> sell your personal data to third parties.
      </Section>

      <Section title="4. Children's Privacy (COPPA)">
        AIHomeRun is designed for parents and coaches of youth baseball players.
        <br /><br />
        <b>We do not knowingly collect personal information directly from children under 13.</b>
        All account registration requires an adult (parent or guardian) to create the account.
        Information about children (name, DOB, position) is entered by the parent/guardian account holder.
        <br /><br />
        If you believe we have inadvertently collected information from a child under 13 without parental
        consent, please contact us at <a href="mailto:privacy@aihomerun.app" style={{ color: '#007aff' }}>privacy@aihomerun.app</a> and
        we will delete it promptly.
      </Section>

      <Section title="5. Data Storage and Security">
        <ul>
          <li>Account data is stored securely in <a href="https://supabase.com" style={{ color: '#007aff' }}>Supabase</a> (PostgreSQL) with row-level security</li>
          <li>Authentication is handled by Supabase Auth with industry-standard encryption</li>
          <li>Video analysis is processed by our AI backend hosted on Railway</li>
          <li>All data transmissions use HTTPS/TLS encryption</li>
          <li>We implement access controls so only you can access your data</li>
        </ul>
      </Section>

      <Section title="6. Third-Party Services">
        We use the following third-party services:
        <ul>
          <li><b>Supabase</b> — database, authentication, and file storage (<a href="https://supabase.com/privacy" style={{ color: '#007aff' }}>Privacy Policy</a>)</li>
          <li><b>Railway</b> — AI analysis backend hosting</li>
          <li><b>Google Sign In</b> — optional OAuth login (<a href="https://policies.google.com/privacy" style={{ color: '#007aff' }}>Privacy Policy</a>)</li>
          <li><b>Apple Sign In</b> — optional OAuth login (<a href="https://www.apple.com/legal/privacy/" style={{ color: '#007aff' }}>Privacy Policy</a>)</li>
          <li><b>Vercel</b> — web hosting</li>
        </ul>
      </Section>

      <Section title="7. Your Rights">
        You have the right to:
        <ul>
          <li><b>Access</b> — view all data we hold about you (available in your Profile page)</li>
          <li><b>Correct</b> — update your name, email, and children's information in the app</li>
          <li><b>Delete</b> — request deletion of your account and all associated data</li>
          <li><b>Portability</b> — request an export of your data</li>
        </ul>
        To exercise these rights, contact us at{' '}
        <a href="mailto:privacy@aihomerun.app" style={{ color: '#007aff' }}>privacy@aihomerun.app</a>.
      </Section>

      <Section title="8. Data Retention">
        We retain your account data for as long as your account is active. If you delete your account,
        we will delete your personal data within 30 days, except where required by law to retain it longer.
        Uploaded videos are processed in real time and not retained after analysis is complete.
      </Section>

      <Section title="9. Changes to This Policy">
        We may update this Privacy Policy from time to time. We will notify you of significant changes
        by email or via an in-app notice. Continued use of AIHomeRun after changes constitutes acceptance
        of the updated policy.
      </Section>

      <Section title="10. Contact Us">
        If you have questions about this Privacy Policy, please contact us:
        <br /><br />
        📧 <a href="mailto:privacy@aihomerun.app" style={{ color: '#007aff' }}>privacy@aihomerun.app</a>
        <br />
        🌐 <a href="https://www.aihomerun.app" style={{ color: '#007aff' }}>www.aihomerun.app</a>
      </Section>
    </div>
  )
}

function Section({ title, children }) {
  return (
    <div style={{ marginBottom: 32 }}>
      <h2 style={{
        fontSize: 18,
        fontWeight: 600,
        letterSpacing: '-0.3px',
        margin: '0 0 10px',
        color: 'var(--label, #1c1c1e)',
      }}>
        {title}
      </h2>
      <div style={{ fontSize: 15, color: 'var(--label, #3a3a3c)' }}>
        {children}
      </div>
    </div>
  )
}
