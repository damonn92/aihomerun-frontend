import { useState, useEffect, useCallback } from 'react'
import { supabase } from '../lib/supabase'
import { useAuth } from '../contexts/AuthContext'

export function useProfile() {
  const { user } = useAuth()
  const [profile,  setProfile]  = useState(null)
  const [children, setChildren] = useState([])
  const [loading,  setLoading]  = useState(true)

  const loadProfile = useCallback(async () => {
    if (!user) return
    const { data } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .maybeSingle()
    setProfile(data)
  }, [user])

  const loadChildren = useCallback(async () => {
    if (!user) return
    const { data } = await supabase
      .from('children')
      .select('*')
      .eq('parent_id', user.id)
      .order('created_at', { ascending: true })
    setChildren(data || [])
  }, [user])

  useEffect(() => {
    if (user) {
      setLoading(true)
      Promise.all([loadProfile(), loadChildren()]).finally(() => setLoading(false))
    } else {
      setProfile(null)
      setChildren([])
      setLoading(false)
    }
  }, [user, loadProfile, loadChildren])

  /* ── Profile ──────────────────────────────────────────── */

  async function updateProfile(data) {
    const { error } = await supabase
      .from('profiles')
      .upsert({ id: user.id, ...data, updated_at: new Date().toISOString() })
    if (error) throw error
    await loadProfile()
  }

  /* ── Auth ─────────────────────────────────────────────── */

  async function updateEmail(email) {
    const { error } = await supabase.auth.updateUser({ email })
    if (error) throw error
  }

  async function updatePassword(password) {
    const { error } = await supabase.auth.updateUser({ password })
    if (error) throw error
  }

  /* ── Children ─────────────────────────────────────────── */

  async function addChild(data) {
    const { error } = await supabase
      .from('children')
      .insert({ parent_id: user.id, ...data })
    if (error) throw error
    await loadChildren()
  }

  async function updateChild(id, data) {
    const { error } = await supabase
      .from('children')
      .update({ ...data, updated_at: new Date().toISOString() })
      .eq('id', id)
      .eq('parent_id', user.id)
    if (error) throw error
    await loadChildren()
  }

  async function deleteChild(id) {
    const { error } = await supabase
      .from('children')
      .delete()
      .eq('id', id)
      .eq('parent_id', user.id)
    if (error) throw error
    await loadChildren()
  }

  return {
    profile,
    children,
    loading,
    updateProfile,
    updateEmail,
    updatePassword,
    addChild,
    updateChild,
    deleteChild,
    reload: () => Promise.all([loadProfile(), loadChildren()]),
  }
}
