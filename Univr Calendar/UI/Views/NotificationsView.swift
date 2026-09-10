import SwiftUI
import SwiftData
import UnivrCore

struct NotificationsView: View {
    @State private var notificationManager = NotificationManager.shared
    
    var body: some View {
        List {
            if notificationManager.activeNotifications.isEmpty {
                ContentUnavailableView(
                    "Nessuna notifica",
                    systemImage: "bell.slash",
                    description: Text("Non hai ancora programmato alcuna notifica per le tue lezioni.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(notificationManager.activeNotifications.sorted(by: { $0.date < $1.date })) { notification in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(notification.lessonName)
                            .font(.headline)
                        
                        Text(notification.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                            Text(notification.offsetMinutes == 0 ? "Suona all'inizio della lezione" : "Suona \(notification.offsetMinutes) minuti prima")
                        }
                        .font(.caption)
                        .foregroundStyle(.blue)
                    }
                    .padding(.vertical, 4)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task {
                                await notificationManager.removeNotification(id: notification.id)
                            }
                        } label: {
                            Label("Elimina", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("Notifiche")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    @Previewable @State var container = try! ModelContainer(
        for: NotificationRecord.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    NavigationStack {
        NotificationsView()
            .modelContainer(container)
            .onAppear {
                Task {
                    let saved = SavedNotification(
                        id: "temp1",
                        courseId: "CorsoProva",
                        lessonName: "Lezione di Test",
                        date: Date().addingTimeInterval(7200), // Tra un'ora
                        offsetMinutes: 0
                    )
                    await NotificationManager.shared.toggleNotification(notification: saved)
                }
                Task {
                    let saved = SavedNotification(
                        id: "temp2",
                        courseId: "CorsoProva",
                        lessonName: "Lezione di Test",
                        date: Date().addingTimeInterval(3600), // Tra un'ora
                        offsetMinutes: 5
                    )
                    await NotificationManager.shared.toggleNotification(notification: saved)
                }
                Task {
                    let saved = SavedNotification(
                        id: "temp3",
                        courseId: "CorsoProva",
                        lessonName: "Lezione di Test",
                        date: Date().addingTimeInterval(3600), // Tra un'ora
                        offsetMinutes: 15
                    )
                    await NotificationManager.shared.toggleNotification(notification: saved)
                }
            }
            .task {
                // Il nostro finto Provider per le Previews! Bypassa i limiti di iOS
                let mockNotificationProvider = NotificationProvider(
                    requestPermission: { true }, // Permessi sempre accordati
                    schedule: { _ in true },     // Programmazione fittizia sempre ok
                    cancel: { _ in }
                )
                
                NotificationManager.shared.configure(
                    notificationProvider: mockNotificationProvider,
                    storageProvider: IOSStorageService.createProvider(container: container)
                )
            }
    }
}
