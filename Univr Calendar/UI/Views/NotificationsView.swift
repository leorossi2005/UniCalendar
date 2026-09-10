import SwiftUI
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
                        
                        Text(notification.offsetMinutes == 0 ? "Suona all'inizio della lezione" : "Suona \(notification.offsetMinutes) minuti prima")
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
    NavigationStack {
        NotificationsView()
    }
}
