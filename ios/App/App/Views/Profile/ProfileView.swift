import SwiftUI
import Supabase

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = ProfileViewModel()
    @State private var showChildEditor = false
    @State private var editingChild: Child?
    @State private var showSignOutConfirm = false
    @State private var showDeleteAccountConfirm = false
    @State private var isDeletingAccount = false
    @State private var editingName = false
    @State private var newName = ""
    @AppStorage("appTheme") private var appTheme: String = AppTheme.dark.rawValue

    var body: some View {
        NavigationStack {
            ZStack {
                Color.hrBg.ignoresSafeArea()

                if vm.isLoading && vm.profile == nil {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.primary)
                        Text("Loading profile...")
                            .font(.subheadline)
                            .foregroundStyle(.primary.opacity(0.55))
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {

                            if let error = vm.error {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(Color.hrOrange)
                                    Text(error)
                                        .font(.caption)
                                        .foregroundStyle(.primary.opacity(0.70))
                                    Spacer()
                                    Button("Retry") {
                                        if let uid = authVM.user?.id.uuidString {
                                            Task { await vm.load(userId: uid) }
                                        }
                                    }
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.hrBlue)
                                }
                                .padding(12)
                                .background(Color.hrOrange.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }

                            // ── Profile header ─────────────────────────────────
                            profileHeader

                            // ── Personal info ──────────────────────────────────
                            profileSection

                            // ── Account ────────────────────────────────────────
                            accountSection

                            // ── Appearance ────────────────────────────────────
                            appearanceSection

                            // ── Storage ──────────────────────────────────────
                            storageSection

                            // ── Players ────────────────────────────────────────
                            playersSection

                            // ── Sign out ───────────────────────────────────────
                            signOutButton

                            // ── Delete account ───────────────────────────────
                            deleteAccountButton

                            Spacer(minLength: 40)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if let uid = authVM.user?.id.uuidString {
                    Task { await vm.load(userId: uid) }
                }
            }
            .sheet(isPresented: $showChildEditor) {
                if let uid = authVM.user?.id.uuidString {
                    ChildEditorView(
                        parentId: uid,
                        existing: editingChild
                    ) { child in
                        if editingChild != nil {
                            try await vm.updateChild(child)
                        } else {
                            try await vm.addChild(child)
                        }
                    }
                }
            }
            .confirmationDialog(
                "Sign out of AIHomeRun?",
                isPresented: $showSignOutConfirm,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    Task { await authVM.signOut() }
                }
            }
            .confirmationDialog(
                "Delete your account?",
                isPresented: $showDeleteAccountConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete Account", role: .destructive) {
                    Task {
                        isDeletingAccount = true
                        await authVM.deleteAccount()
                        isDeletingAccount = false
                    }
                }
            } message: {
                Text("This will permanently delete your account and all associated data. This action cannot be undone.")
            }
        }
    }

    // MARK: - Profile header

    private var profileHeader: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.hrBlue, Color(red: 0.04, green: 0.36, blue: 0.80)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: Color.hrBlue.opacity(0.4), radius: 12)

                Text(initials)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(vm.profile?.fullName ?? "Player")
                    .font(.title3.bold())
                    .foregroundStyle(.primary)

                Text(authVM.user?.email ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.primary.opacity(0.55))
                    .lineLimit(1)
            }

            Spacer()
        }
        .hrCard()
    }

    // MARK: - Personal info section

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("Personal Information")

            if editingName {
                VStack(spacing: 12) {
                    HRInputContainer(icon: "person.fill") {
                        TextField("Full name", text: $newName)
                            .textInputAutocapitalization(.words)
                    }
                    HStack(spacing: 12) {
                        Button("Cancel") { editingName = false }
                            .font(.subheadline)
                            .foregroundStyle(.primary.opacity(0.55))
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(Color.hrSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                        Button("Save") {
                            Task {
                                guard let uid = authVM.user?.id.uuidString else { return }
                                try? await vm.updateName(newName, userId: uid)
                                editingName = false
                            }
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(Color.hrBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
                .padding(16)
                .background(Color.hrCard)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.hrStroke, lineWidth: 1)
                )
            } else {
                profileRow(icon: "person.fill", label: "Full Name",
                           value: vm.profile?.fullName ?? "Not set") {
                    newName = vm.profile?.fullName ?? ""
                    editingName = true
                }
            }
        }
    }

    // MARK: - Account section

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("Account")

            VStack(spacing: 0) {
                NavigationLink {
                    ChangeEmailView(currentEmail: authVM.user?.email ?? "") { email in
                        try await SupabaseService.shared.updateEmail(newEmail: email)
                    }
                } label: {
                    accountRowLabel(icon: "envelope.fill", title: "Email Address",
                                    value: authVM.user?.email ?? "")
                }
                .buttonStyle(.plain)

                Divider().background(Color.hrSurface).padding(.leading, 52)

                NavigationLink {
                    ChangePasswordView { pass in
                        try await SupabaseService.shared.updatePassword(newPassword: pass)
                    }
                } label: {
                    accountRowLabel(icon: "lock.fill", title: "Password", value: "••••••••")
                }
                .buttonStyle(.plain)
            }
            .background(Color.hrCard)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.hrStroke, lineWidth: 1)
            )
        }
    }

    // MARK: - Appearance section

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("Appearance")

            HStack(spacing: 0) {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            appTheme = theme.rawValue
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: theme.icon)
                                .font(.system(size: 12, weight: .semibold))
                            Text(theme.rawValue)
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(appTheme == theme.rawValue ? Color.white : Color.primary.opacity(0.60))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            appTheme == theme.rawValue
                            ? Color.hrBlue
                            : Color.hrSurface
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.hrStroke, lineWidth: 1)
            )
        }
    }

    // MARK: - Storage section

    @State private var analysisCacheSize: String = "—"
    @State private var analysisCacheCount: Int = 0
    @State private var clearingCache = false

    private var storageSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("Storage")

            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.hrBlue.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: "internaldrive.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.hrBlue)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Analysis Cache")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        Text("\(analysisCacheCount) results \u{00B7} \(analysisCacheSize)")
                            .font(.caption)
                            .foregroundStyle(.primary.opacity(0.55))
                    }

                    Spacer()

                    Button {
                        Task {
                            clearingCache = true
                            await AnalysisResultCache.shared.clearAll()
                            await refreshCacheStats()
                            clearingCache = false
                        }
                    } label: {
                        if clearingCache {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text("Clear")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(analysisCacheCount > 0 ? Color.hrRed : .primary.opacity(0.30))
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(analysisCacheCount == 0 || clearingCache)
                }
                .padding(14)
            }
            .background(Color.hrCard)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.hrStroke, lineWidth: 1)
            )
        }
        .onAppear { Task { await refreshCacheStats() } }
    }

    private func refreshCacheStats() async {
        let cache = AnalysisResultCache.shared
        let bytes = await cache.cacheSize()
        let count = await cache.cacheCount()
        analysisCacheCount = count
        if bytes < 1024 {
            analysisCacheSize = "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            analysisCacheSize = String(format: "%.1f KB", Double(bytes) / 1024.0)
        } else {
            analysisCacheSize = String(format: "%.1f MB", Double(bytes) / (1024.0 * 1024.0))
        }
    }

    // MARK: - Players section

    private var playersSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("My Players")

            VStack(spacing: 0) {
                ForEach(vm.children) { child in
                    Button {
                        editingChild = child
                        showChildEditor = true
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.hrGold.opacity(0.18))
                                    .frame(width: 38, height: 38)
                                Image(systemName: "figure.baseball")
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color.hrGold)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(child.fullName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                if let pos = child.position {
                                    Text(pos)
                                        .font(.caption)
                                        .foregroundStyle(.primary.opacity(0.55))
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.primary.opacity(0.40))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task { try? await vm.deleteChild(id: child.id) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }

                    if child.id != vm.children.last?.id {
                        Divider().background(Color.hrSurface).padding(.leading, 68)
                    }
                }

                // Add player row
                if !vm.children.isEmpty {
                    Divider().background(Color.hrSurface).padding(.leading, 16)
                }

                Button {
                    editingChild = nil
                    showChildEditor = true
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.hrBlue.opacity(0.16))
                                .frame(width: 38, height: 38)
                            Image(systemName: "plus")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.hrBlue)
                        }
                        Text("Add Player")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.hrBlue)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
            .background(Color.hrCard)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.hrStroke, lineWidth: 1)
            )

            Text("Add your players to track their progress across sessions.")
                .font(.caption)
                .foregroundStyle(.primary.opacity(0.40))
                .padding(.horizontal, 4)
                .padding(.top, 6)
        }
    }

    // MARK: - Sign out button

    private var signOutButton: some View {
        Button {
            showSignOutConfirm = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "arrow.backward.circle.fill")
                    .font(.system(size: 16))
                Text("Sign Out")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(Color.hrRed)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.hrRed.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.hrRed.opacity(0.22), lineWidth: 1)
            )
        }
    }

    // MARK: - Delete account button

    private var deleteAccountButton: some View {
        Button {
            showDeleteAccountConfirm = true
        } label: {
            HStack(spacing: 10) {
                if isDeletingAccount {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.primary.opacity(0.40))
                } else {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 14))
                }
                Text("Delete Account")
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(.primary.opacity(0.40))
            .frame(maxWidth: .infinity)
            .frame(height: 44)
        }
        .buttonStyle(.plain)
        .disabled(isDeletingAccount)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(.primary.opacity(0.50))
            .textCase(.uppercase)
            .tracking(0.7)
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
    }

    private func profileRow(icon: String, label: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.hrBlue.opacity(0.18))
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.hrBlue)
                }
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.primary.opacity(0.70))
                Spacer()
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(.primary.opacity(0.55))
                    .lineLimit(1)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary.opacity(0.35))
            }
            .padding(16)
        }
        .buttonStyle(.plain)
        .background(Color.hrCard)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.hrStroke, lineWidth: 1)
        )
    }

    private func accountRowLabel(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.hrBlue.opacity(0.18))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.hrBlue)
            }
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.70))
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.50))
                .lineLimit(1)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary.opacity(0.35))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private var initials: String {
        let name = vm.profile?.fullName ?? authVM.user?.email ?? "?"
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return String((words[0].first ?? "?")) + String((words[1].first ?? "?"))
        }
        return String(name.prefix(2)).uppercased()
    }
}

// MARK: - Change Email

struct ChangeEmailView: View {
    let currentEmail: String
    let onSave: (String) async throws -> Void

    @Environment(\.dismiss) var dismiss
    @State private var newEmail = ""
    @State private var isSaving = false
    @State private var saved = false
    @State private var error: String?

    var body: some View {
        ZStack {
            Color.hrBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 6) {
                        Image(systemName: "envelope.circle.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(Color.hrBlue)
                        Text("Change Email")
                            .font(.title2.bold())
                            .foregroundStyle(.primary)
                        Text("Current: \(currentEmail)")
                            .font(.subheadline)
                            .foregroundStyle(.primary.opacity(0.55))
                    }
                    .padding(.top, 24)

                    if let error {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(Color.hrRed)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if saved {
                        Text("Confirmation email sent. Check your inbox.")
                            .font(.footnote)
                            .foregroundStyle(Color.hrGreen)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    HRInputContainer(icon: "envelope.fill") {
                        TextField("New email address", text: $newEmail)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }

                    Button {
                        Task {
                            isSaving = true
                            do { try await onSave(newEmail); saved = true }
                            catch { self.error = error.localizedDescription }
                            isSaving = false
                        }
                    } label: {
                        ZStack {
                            if isSaving { ProgressView().tint(.white) }
                            else { Text("Update Email").font(.headline).foregroundStyle(.white) }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(newEmail.isEmpty ? Color.hrStroke : Color.hrBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(newEmail.isEmpty || isSaving)
                }
                .padding(24)
            }
        }
        .navigationTitle("Change Email")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Change Password

struct ChangePasswordView: View {
    let onSave: (String) async throws -> Void

    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isSaving = false
    @State private var saved = false
    @State private var error: String?

    private var valid: Bool { newPassword.count >= 8 && newPassword == confirmPassword }

    var body: some View {
        ZStack {
            Color.hrBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 6) {
                        Image(systemName: "lock.circle.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(Color.hrBlue)
                        Text("Change Password")
                            .font(.title2.bold())
                            .foregroundStyle(.primary)
                    }
                    .padding(.top, 24)

                    if let error {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(Color.hrRed)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if saved {
                        Text("Password updated successfully.")
                            .font(.footnote)
                            .foregroundStyle(Color.hrGreen)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    HRInputContainer(icon: "lock.fill") {
                        SecureField("New password (8+ chars)", text: $newPassword)
                            .textContentType(.newPassword)
                    }

                    HRInputContainer(icon: "lock.fill") {
                        SecureField("Confirm new password", text: $confirmPassword)
                            .textContentType(.newPassword)
                    }

                    Button {
                        Task {
                            guard newPassword == confirmPassword else {
                                error = "Passwords don't match"
                                return
                            }
                            isSaving = true
                            do { try await onSave(newPassword); saved = true }
                            catch { self.error = error.localizedDescription }
                            isSaving = false
                        }
                    } label: {
                        ZStack {
                            if isSaving { ProgressView().tint(.white) }
                            else { Text("Update Password").font(.headline).foregroundStyle(.white) }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(valid ? Color.hrBlue : Color.hrStroke)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(!valid || isSaving)
                }
                .padding(24)
            }
        }
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
    }
}
