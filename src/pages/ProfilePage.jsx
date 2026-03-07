import { useState, useRef } from 'react'
import {
  User, Mail, Lock, ChevronRight, ChevronDown,
  Plus, Pencil, Trash2, X, Check, AlertCircle,
  LogOut, Baby, Calendar, MapPin,
} from 'lucide-react'
import { useAuth } from '../contexts/AuthContext'
import { useProfile } from '../hooks/useProfile'

/* ─── Helpers ─────────────────────────────────────────────────────────────── */

function getAge(dob) {
  if (!dob) return null
  const today = new Date()
  const birth = new Date(dob)
  let age = today.getFullYear() - birth.getFullYear()
  if (
    today.getMonth() < birth.getMonth() ||
    (today.getMonth() === birth.getMonth() && today.getDate() < birth.getDate())
  ) age--
  return age
}

function getInitials(nameOrEmail) {
  if (!nameOrEmail) return '?'
  const parts = nameOrEmail.trim().split(/\s+/)
  if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase()
  return nameOrEmail[0].toUpperCase()
}

const POSITIONS = [
  'Pitcher', 'Catcher', 'First Base', 'Second Base',
  'Third Base', 'Shortstop', 'Left Field', 'Center Field', 'Right Field',
]

/* ─── Shared UI primitives ────────────────────────────────────────────────── */

function SectionHeader({ title }) {
  return (
    <p style={{
      font: 'var(--text-caption2)',
      fontWeight: 700,
      letterSpacing: 0.7,
      textTransform: 'uppercase',
      color: 'var(--label3)',
      margin: '24px 0 6px',
      paddingLeft: 4,
    }}>
      {title}
    </p>
  )
}

function Card({ children, style }) {
  return (
    <div style={{
      background: 'var(--bg2)',
      borderRadius: 'var(--r-lg)',
      overflow: 'hidden',
      ...style,
    }}>
      {children}
    </div>
  )
}

function Row({ icon, label, value, onPress, danger, last, rightEl }) {
  return (
    <button
      onClick={onPress}
      style={{
        width: '100%',
        display: 'flex',
        alignItems: 'center',
        gap: 14,
        padding: '14px 16px',
        background: 'none',
        border: 'none',
        borderBottom: last ? 'none' : '0.5px solid var(--sep)',
        cursor: onPress ? 'pointer' : 'default',
        textAlign: 'left',
        WebkitTapHighlightColor: 'transparent',
      }}
    >
      {icon && (
        <div style={{
          width: 30, height: 30,
          borderRadius: 8,
          background: danger ? 'rgba(255,69,58,0.14)' : 'rgba(10,132,255,0.13)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          flexShrink: 0,
        }}>
          {icon}
        </div>
      )}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          font: 'var(--text-body)',
          color: danger ? 'var(--red)' : 'var(--label)',
          fontWeight: 500,
        }}>
          {label}
        </div>
        {value && (
          <div style={{
            font: 'var(--text-footnote)',
            color: 'var(--label3)',
            marginTop: 1,
            overflow: 'hidden',
            textOverflow: 'ellipsis',
            whiteSpace: 'nowrap',
          }}>
            {value}
          </div>
        )}
      </div>
      {rightEl || (onPress && <ChevronRight size={16} color="var(--label4)" />)}
    </button>
  )
}

function Field({ label, type = 'text', value, onChange, placeholder, autoComplete, note }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      {label && (
        <label style={{
          font: 'var(--text-caption2)',
          fontWeight: 700,
          letterSpacing: 0.6,
          textTransform: 'uppercase',
          color: 'var(--label3)',
          paddingLeft: 4,
        }}>
          {label}
        </label>
      )}
      <input
        type={type}
        value={value}
        onChange={onChange}
        placeholder={placeholder}
        autoComplete={autoComplete}
        spellCheck={false}
        style={{
          width: '100%',
          background: 'var(--bg3)',
          border: 'none',
          borderRadius: 'var(--r-md)',
          padding: '13px 16px',
          font: 'var(--text-body)',
          color: 'var(--label)',
          outline: 'none',
          WebkitAppearance: 'none',
          boxSizing: 'border-box',
        }}
      />
      {note && (
        <p style={{ font: 'var(--text-caption1)', color: 'var(--label4)', margin: '2px 0 0 4px' }}>
          {note}
        </p>
      )}
    </div>
  )
}

function InlineError({ msg }) {
  if (!msg) return null
  return (
    <div style={{
      display: 'flex', alignItems: 'flex-start', gap: 8,
      background: 'rgba(255,69,58,0.10)',
      border: '1px solid rgba(255,69,58,0.28)',
      borderRadius: 'var(--r-md)',
      padding: '10px 12px',
    }}>
      <AlertCircle size={14} color="var(--red)" style={{ marginTop: 2, flexShrink: 0 }} />
      <span style={{ font: 'var(--text-caption1)', color: 'var(--red)', lineHeight: 1.4 }}>{msg}</span>
    </div>
  )
}

function InlineSuccess({ msg }) {
  if (!msg) return null
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 8,
      background: 'rgba(48,209,88,0.12)',
      border: '1px solid rgba(48,209,88,0.3)',
      borderRadius: 'var(--r-md)',
      padding: '10px 12px',
    }}>
      <Check size={14} color="var(--green)" />
      <span style={{ font: 'var(--text-caption1)', color: 'var(--green)', lineHeight: 1.4 }}>{msg}</span>
    </div>
  )
}

/* ─── Expandable edit sections ────────────────────────────────────────────── */

function EditSection({ title, isOpen, onToggle, children }) {
  return (
    <div style={{
      borderTop: '0.5px solid var(--sep)',
    }}>
      <button
        onClick={onToggle}
        style={{
          width: '100%',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          padding: '14px 16px',
          background: 'none',
          border: 'none',
          cursor: 'pointer',
          font: 'var(--text-body)',
          color: 'var(--blue)',
          fontWeight: 500,
        }}
      >
        {title}
        {isOpen
          ? <ChevronDown size={16} color="var(--blue)" />
          : <ChevronRight size={16} color="var(--blue)" />}
      </button>
      {isOpen && (
        <div style={{ padding: '0 16px 16px', display: 'flex', flexDirection: 'column', gap: 12 }}>
          {children}
        </div>
      )}
    </div>
  )
}

/* ─── Child Modal ─────────────────────────────────────────────────────────── */

function ChildModal({ child, onSave, onClose }) {
  const isEdit = !!child
  const [name,     setName]     = useState(child?.full_name      || '')
  const [dob,      setDob]      = useState(child?.date_of_birth  || '')
  const [gender,   setGender]   = useState(child?.gender         || '')
  const [position, setPosition] = useState(child?.position       || '')
  const [notes,    setNotes]    = useState(child?.notes          || '')
  const [saving,   setSaving]   = useState(false)
  const [error,    setError]    = useState(null)

  async function handleSave() {
    if (!name.trim()) return setError('Please enter the child\'s name.')
    setError(null)
    setSaving(true)
    try {
      await onSave({
        full_name:     name.trim(),
        date_of_birth: dob || null,
        gender:        gender || null,
        position:      position || null,
        notes:         notes.trim() || null,
      })
      onClose()
    } catch (err) {
      setError(err.message || 'Failed to save. Please try again.')
    } finally {
      setSaving(false)
    }
  }

  return (
    /* Backdrop */
    <div
      onClick={onClose}
      style={{
        position: 'fixed', inset: 0, zIndex: 1000,
        background: 'rgba(0,0,0,0.5)',
        display: 'flex', alignItems: 'flex-end',
      }}
    >
      {/* Sheet */}
      <div
        onClick={e => e.stopPropagation()}
        style={{
          width: '100%',
          background: 'var(--bg)',
          borderRadius: '20px 20px 0 0',
          padding: '20px 20px 40px',
          display: 'flex',
          flexDirection: 'column',
          gap: 16,
          maxHeight: '90vh',
          overflowY: 'auto',
        }}
      >
        {/* Handle */}
        <div style={{
          width: 36, height: 4, borderRadius: 2,
          background: 'var(--label4)',
          alignSelf: 'center',
          marginBottom: 4,
        }} />

        {/* Header */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <h3 style={{ font: 'var(--text-title3)', letterSpacing: '-0.3px', color: 'var(--label)', margin: 0 }}>
            {isEdit ? 'Edit Child' : 'Add Child'}
          </h3>
          <button onClick={onClose} style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 4 }}>
            <X size={20} color="var(--label3)" />
          </button>
        </div>

        <InlineError msg={error} />

        <Field
          label="Name *"
          value={name}
          onChange={e => setName(e.target.value)}
          placeholder="Child's full name"
        />

        <Field
          label="Date of Birth"
          type="date"
          value={dob}
          onChange={e => setDob(e.target.value)}
        />

        {/* Gender */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          <label style={{
            font: 'var(--text-caption2)', fontWeight: 700,
            letterSpacing: 0.6, textTransform: 'uppercase',
            color: 'var(--label3)', paddingLeft: 4,
          }}>
            Gender
          </label>
          <div style={{ display: 'flex', gap: 8 }}>
            {[['male', '👦 Boy'], ['female', '👧 Girl'], ['other', '🧒 Other']].map(([val, lbl]) => (
              <button
                key={val}
                onClick={() => setGender(g => g === val ? '' : val)}
                style={{
                  flex: 1, padding: '10px 8px',
                  borderRadius: 'var(--r-md)',
                  border: '1.5px solid',
                  borderColor: gender === val ? 'var(--blue)' : 'transparent',
                  background: gender === val ? 'rgba(10,132,255,0.12)' : 'var(--bg3)',
                  font: 'var(--text-footnote)',
                  fontWeight: gender === val ? 600 : 400,
                  color: gender === val ? 'var(--blue)' : 'var(--label2)',
                  cursor: 'pointer',
                }}
              >
                {lbl}
              </button>
            ))}
          </div>
        </div>

        {/* Position */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          <label style={{
            font: 'var(--text-caption2)', fontWeight: 700,
            letterSpacing: 0.6, textTransform: 'uppercase',
            color: 'var(--label3)', paddingLeft: 4,
          }}>
            Baseball Position
          </label>
          <select
            value={position}
            onChange={e => setPosition(e.target.value)}
            style={{
              width: '100%',
              background: 'var(--bg3)',
              border: 'none',
              borderRadius: 'var(--r-md)',
              padding: '13px 16px',
              font: 'var(--text-body)',
              color: position ? 'var(--label)' : 'var(--label4)',
              outline: 'none',
              WebkitAppearance: 'none',
            }}
          >
            <option value="">Select position (optional)</option>
            {POSITIONS.map(p => <option key={p} value={p}>{p}</option>)}
          </select>
        </div>

        {/* Notes */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          <label style={{
            font: 'var(--text-caption2)', fontWeight: 700,
            letterSpacing: 0.6, textTransform: 'uppercase',
            color: 'var(--label3)', paddingLeft: 4,
          }}>
            Notes
          </label>
          <textarea
            value={notes}
            onChange={e => setNotes(e.target.value)}
            placeholder="Allergies, special notes…"
            rows={3}
            style={{
              width: '100%',
              background: 'var(--bg3)',
              border: 'none',
              borderRadius: 'var(--r-md)',
              padding: '13px 16px',
              font: 'var(--text-body)',
              color: 'var(--label)',
              outline: 'none',
              resize: 'none',
              boxSizing: 'border-box',
            }}
          />
        </div>

        <button
          className="ios-btn-primary"
          onClick={handleSave}
          disabled={saving}
          style={{ marginTop: 4 }}
        >
          {saving ? 'Saving…' : isEdit ? 'Save Changes' : 'Add Child'}
        </button>
      </div>
    </div>
  )
}

/* ─── Child Card ──────────────────────────────────────────────────────────── */

function ChildCard({ child, onEdit, onDelete }) {
  const age = getAge(child.date_of_birth)
  const [confirmDelete, setConfirmDelete] = useState(false)

  return (
    <div style={{
      background: 'var(--bg3)',
      borderRadius: 'var(--r-md)',
      padding: '14px 16px',
      display: 'flex',
      alignItems: 'center',
      gap: 12,
    }}>
      {/* Avatar */}
      <div style={{
        width: 44, height: 44,
        borderRadius: '50%',
        background: 'rgba(10,132,255,0.15)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        flexShrink: 0,
        fontSize: 20,
      }}>
        {child.gender === 'female' ? '👧' : child.gender === 'other' ? '🧒' : '👦'}
      </div>

      {/* Info */}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ font: 'var(--text-callout)', fontWeight: 600, color: 'var(--label)' }}>
          {child.full_name}
        </div>
        <div style={{ font: 'var(--text-caption1)', color: 'var(--label3)', marginTop: 2 }}>
          {age !== null ? `${age} yrs old` : ''}
          {age !== null && child.position ? ' · ' : ''}
          {child.position || ''}
          {!age && !child.position && 'No info added'}
        </div>
      </div>

      {/* Actions */}
      {confirmDelete ? (
        <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
          <span style={{ font: 'var(--text-caption1)', color: 'var(--red)' }}>Delete?</span>
          <button
            onClick={() => onDelete(child.id)}
            style={{
              padding: '5px 10px', borderRadius: 8,
              background: 'var(--red)', color: '#fff',
              border: 'none', cursor: 'pointer',
              font: 'var(--text-caption1)', fontWeight: 600,
            }}
          >
            Yes
          </button>
          <button
            onClick={() => setConfirmDelete(false)}
            style={{
              padding: '5px 10px', borderRadius: 8,
              background: 'var(--bg2)', color: 'var(--label)',
              border: 'none', cursor: 'pointer',
              font: 'var(--text-caption1)',
            }}
          >
            No
          </button>
        </div>
      ) : (
        <div style={{ display: 'flex', gap: 4 }}>
          <button
            onClick={() => onEdit(child)}
            style={{
              width: 34, height: 34, borderRadius: 10,
              background: 'rgba(10,132,255,0.12)',
              border: 'none', cursor: 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}
          >
            <Pencil size={15} color="var(--blue)" />
          </button>
          <button
            onClick={() => setConfirmDelete(true)}
            style={{
              width: 34, height: 34, borderRadius: 10,
              background: 'rgba(255,69,58,0.12)',
              border: 'none', cursor: 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}
          >
            <Trash2 size={15} color="var(--red)" />
          </button>
        </div>
      )}
    </div>
  )
}

/* ─── Profile Page ────────────────────────────────────────────────────────── */

export default function ProfilePage() {
  const { user, signOut } = useAuth()
  const {
    profile, children, loading,
    updateProfile, updateEmail, updatePassword,
    addChild, updateChild, deleteChild,
  } = useProfile()

  // Expand states
  const [openSection, setOpenSection] = useState(null) // 'name' | 'email' | 'password'
  const toggle = (s) => setOpenSection(o => o === s ? null : s)

  // Name
  const [newName, setNewName]     = useState('')
  const [nameSaving, setNameSaving] = useState(false)
  const [nameErr, setNameErr]     = useState(null)
  const [nameOk, setNameOk]       = useState(false)

  // Email
  const [newEmail, setNewEmail]   = useState('')
  const [emailSaving, setEmailSaving] = useState(false)
  const [emailErr, setEmailErr]   = useState(null)
  const [emailOk, setEmailOk]     = useState(false)

  // Password
  const [newPwd,  setNewPwd]      = useState('')
  const [confPwd, setConfPwd]     = useState('')
  const [pwdSaving, setPwdSaving] = useState(false)
  const [pwdErr, setPwdErr]       = useState(null)
  const [pwdOk, setPwdOk]         = useState(false)

  // Children modal
  const [childModal, setChildModal] = useState(null) // null | { mode:'add' } | { mode:'edit', child }

  const displayName = profile?.full_name || user?.user_metadata?.name || user?.user_metadata?.full_name || ''
  const displayEmail = user?.email || ''
  const initials = getInitials(displayName || displayEmail)
  const isEmailUser = user?.app_metadata?.provider === 'email' || !user?.app_metadata?.provider

  /* ── Handlers ── */

  async function handleSaveName() {
    if (!newName.trim()) return setNameErr('Name cannot be empty.')
    setNameErr(null); setNameSaving(true)
    try {
      await updateProfile({ full_name: newName.trim() })
      setNameOk(true); setTimeout(() => setNameOk(false), 3000)
      setOpenSection(null)
    } catch (e) { setNameErr(e.message) }
    finally { setNameSaving(false) }
  }

  async function handleSaveEmail() {
    if (!newEmail.trim()) return setEmailErr('Please enter an email address.')
    if (!newEmail.includes('@')) return setEmailErr('Please enter a valid email address.')
    setEmailErr(null); setEmailSaving(true)
    try {
      await updateEmail(newEmail.trim())
      setEmailOk(true); setNewEmail('')
      setOpenSection(null)
    } catch (e) { setEmailErr(e.message) }
    finally { setEmailSaving(false) }
  }

  async function handleSavePassword() {
    if (newPwd.length < 8) return setPwdErr('Password must be at least 8 characters.')
    if (newPwd !== confPwd) return setPwdErr('Passwords do not match.')
    setPwdErr(null); setPwdSaving(true)
    try {
      await updatePassword(newPwd)
      setPwdOk(true); setNewPwd(''); setConfPwd('')
      setOpenSection(null)
      setTimeout(() => setPwdOk(false), 4000)
    } catch (e) { setPwdErr(e.message) }
    finally { setPwdSaving(false) }
  }

  async function handleDeleteChild(id) {
    try { await deleteChild(id) }
    catch (e) { alert('Failed to delete: ' + e.message) }
  }

  if (loading) {
    return (
      <div style={{
        height: '100%', display: 'flex',
        alignItems: 'center', justifyContent: 'center',
        background: 'var(--bg)',
      }}>
        <div style={{ font: 'var(--text-body)', color: 'var(--label3)' }}>Loading…</div>
      </div>
    )
  }

  return (
    <>
      {/* ── Child modal ── */}
      {childModal && (
        <ChildModal
          child={childModal.mode === 'edit' ? childModal.child : null}
          onSave={childModal.mode === 'edit'
            ? (data) => updateChild(childModal.child.id, data)
            : (data) => addChild(data)}
          onClose={() => setChildModal(null)}
        />
      )}

      <div
        className="scroll-content"
        style={{
          height: '100%',
          overflowY: 'auto',
          background: 'var(--bg)',
          padding: '16px 20px 100px',
        }}
      >
        {/* ── Avatar + name ── */}
        <div style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          padding: '24px 0 20px',
          gap: 10,
        }}>
          <div style={{
            width: 80, height: 80,
            borderRadius: '50%',
            background: 'var(--blue)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 28,
            fontWeight: 700,
            color: '#fff',
            letterSpacing: '-0.5px',
          }}>
            {initials}
          </div>
          <div style={{ textAlign: 'center' }}>
            <div style={{
              font: 'var(--text-title3)',
              fontWeight: 700,
              color: 'var(--label)',
              letterSpacing: '-0.3px',
            }}>
              {displayName || 'Your Account'}
            </div>
            <div style={{ font: 'var(--text-footnote)', color: 'var(--label3)', marginTop: 2 }}>
              {displayEmail}
            </div>
          </div>
        </div>

        {/* ── Personal Info ── */}
        <SectionHeader title="Personal Information" />
        <Card>
          <Row
            icon={<User size={15} color="var(--blue)" />}
            label="Full Name"
            value={displayName || 'Not set'}
            onPress={() => { setNewName(displayName); toggle('name') }}
          />

          <EditSection
            title="Change Name"
            isOpen={openSection === 'name'}
            onToggle={() => toggle('name')}
          >
            <Field
              label="New Name"
              value={newName}
              onChange={e => setNewName(e.target.value)}
              placeholder="Your full name"
              autoComplete="name"
            />
            <InlineError msg={nameErr} />
            <InlineSuccess msg={nameOk ? 'Name updated successfully!' : null} />
            <button
              className="ios-btn-primary"
              onClick={handleSaveName}
              disabled={nameSaving}
            >
              {nameSaving ? 'Saving…' : 'Save Name'}
            </button>
          </EditSection>
        </Card>

        {/* ── Account Settings ── */}
        <SectionHeader title="Account Settings" />
        <Card>
          {/* Change Email */}
          <div>
            <Row
              icon={<Mail size={15} color="var(--blue)" />}
              label="Email Address"
              value={displayEmail}
              onPress={() => { setNewEmail(''); toggle('email') }}
            />
            <EditSection
              title="Change Email"
              isOpen={openSection === 'email'}
              onToggle={() => toggle('email')}
            >
              <Field
                label="New Email"
                type="email"
                value={newEmail}
                onChange={e => setNewEmail(e.target.value)}
                placeholder="new@example.com"
                autoComplete="email"
                note="A confirmation link will be sent to your new email."
              />
              <InlineError msg={emailErr} />
              <InlineSuccess msg={emailOk ? 'Confirmation email sent! Check your inbox.' : null} />
              <button
                className="ios-btn-primary"
                onClick={handleSaveEmail}
                disabled={emailSaving}
              >
                {emailSaving ? 'Sending…' : 'Update Email'}
              </button>
            </EditSection>
          </div>

          {/* Change Password */}
          <div>
            <Row
              icon={<Lock size={15} color="var(--blue)" />}
              label={isEmailUser ? 'Change Password' : 'Set Password'}
              value={isEmailUser ? 'Update your login password' : 'Add a password to your account'}
              onPress={() => { setNewPwd(''); setConfPwd(''); toggle('password') }}
            />
            <EditSection
              title={isEmailUser ? 'Change Password' : 'Set Password'}
              isOpen={openSection === 'password'}
              onToggle={() => toggle('password')}
            >
              <Field
                label="New Password"
                type="password"
                value={newPwd}
                onChange={e => setNewPwd(e.target.value)}
                placeholder="Min 8 characters"
                autoComplete="new-password"
              />
              <Field
                label="Confirm Password"
                type="password"
                value={confPwd}
                onChange={e => setConfPwd(e.target.value)}
                placeholder="Repeat password"
                autoComplete="new-password"
              />
              <InlineError msg={pwdErr} />
              <InlineSuccess msg={pwdOk ? 'Password updated successfully!' : null} />
              <button
                className="ios-btn-primary"
                onClick={handleSavePassword}
                disabled={pwdSaving}
              >
                {pwdSaving ? 'Saving…' : 'Update Password'}
              </button>
            </EditSection>
          </div>
        </Card>

        {/* ── My Children ── */}
        <SectionHeader title="My Children" />

        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {children.length === 0 ? (
            <div style={{
              background: 'var(--bg2)',
              borderRadius: 'var(--r-lg)',
              padding: '28px 20px',
              textAlign: 'center',
            }}>
              <div style={{ fontSize: 36, marginBottom: 8 }}>⚾</div>
              <div style={{ font: 'var(--text-callout)', color: 'var(--label2)', fontWeight: 500 }}>
                No children added yet
              </div>
              <div style={{ font: 'var(--text-footnote)', color: 'var(--label3)', marginTop: 4 }}>
                Add your child's info to personalize their AI coaching.
              </div>
            </div>
          ) : (
            children.map(child => (
              <ChildCard
                key={child.id}
                child={child}
                onEdit={(c) => setChildModal({ mode: 'edit', child: c })}
                onDelete={handleDeleteChild}
              />
            ))
          )}

          {/* Add Child Button */}
          <button
            onClick={() => setChildModal({ mode: 'add' })}
            style={{
              width: '100%',
              padding: '14px',
              borderRadius: 'var(--r-lg)',
              border: '1.5px dashed var(--sep)',
              background: 'none',
              cursor: 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
              font: 'var(--text-callout)',
              fontWeight: 600,
              color: 'var(--blue)',
            }}
          >
            <Plus size={18} />
            Add Child
          </button>
        </div>

        {/* ── Sign Out ── */}
        <SectionHeader title="Account" />
        <Card>
          <Row
            icon={<LogOut size={15} color="var(--red)" />}
            label="Sign Out"
            danger
            last
            onPress={signOut}
          />
        </Card>

        {/* App version */}
        <p style={{
          textAlign: 'center',
          marginTop: 32,
          font: 'var(--text-caption2)',
          color: 'var(--label4)',
        }}>
          AIHomeRun · v1.0
        </p>
      </div>
    </>
  )
}
