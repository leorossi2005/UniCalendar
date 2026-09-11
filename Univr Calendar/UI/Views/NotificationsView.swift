//
//  NotificationsView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 10/09/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import SwiftData
import UnivrCore

struct NotificationsView: View {
    @State private var notificationManager = NotificationManager.shared
    
    var groupedNotifications: [String: [SavedNotification]] {
        Dictionary(grouping: notificationManager.activeNotifications, by: \.courseId)
    }
    
    var sortedCourseIds: [String] {
        let selectedCourseId = UserSettings.shared.selectedCourse
        
        return groupedNotifications.keys.sorted { id1, id2 in
            if id1 == selectedCourseId { return true }
            if id2 == selectedCourseId { return false }
            
            let name1 = groupedNotifications[id1]?.first?.courseName ?? ""
            let name2 = groupedNotifications[id2]?.first?.courseName ?? ""
            
            if name1 == name2 {
                return id1 < id2
            }
            return name1.localizedStandardCompare(name2) == .orderedAscending
        }
    }
    
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
                ForEach(sortedCourseIds, id: \.self) { courseId in
                    Section {
                        let courseNotifications = (groupedNotifications[courseId] ?? []).sorted(by: { $0.date < $1.date })
                        
                        ForEach(courseNotifications) { notification in
                            notificationRow(for: notification)
                        }
                    } header: {
                        let courseName = groupedNotifications[courseId]?.first?.courseName ?? "Corso Sconosciuto"
                        Text(courseName)
                    }
                }
            }
        }
        .navigationTitle("Notifiche")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await notificationManager.cleanupExpiredNotifications()
            }
        }
    }
    
    private func notificationRow(for notification: SavedNotification) -> some View {
        NavigationLink(destination: EditNotificationView(notification: notification)) {
            HStack(alignment: .top) {
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
                Spacer()
                
                Text(notification.courseYear)
                    .font(.caption2)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            }
            .padding(.vertical, 4)
        }
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
                        courseName: "temp",
                        courseYear: "1 - Anno",
                        lessonName: "Lezione di Test",
                        date: Date().addingTimeInterval(7200),
                        offsetMinutes: 0
                    )
                    await NotificationManager.shared.toggleNotification(notification: saved)
                }
                Task {
                    let saved = SavedNotification(
                        id: "temp2",
                        courseId: "CorsoProva",
                        courseName: "temp2",
                        courseYear: "1 - Anno",
                        lessonName: "Lezione di Test",
                        date: Date().addingTimeInterval(3600),
                        offsetMinutes: 5
                    )
                    await NotificationManager.shared.toggleNotification(notification: saved)
                }
                Task {
                    let saved = SavedNotification(
                        id: "temp3",
                        courseId: "CorsoProva",
                        courseName: "temp2",
                        courseYear: "2 - Anno",
                        lessonName: "Lezione di Test",
                        date: Date().addingTimeInterval(3600),
                        offsetMinutes: 15
                    )
                    await NotificationManager.shared.toggleNotification(notification: saved)
                }
            }
            .task {
                let mockNotificationProvider = NotificationProvider(
                    requestPermission: { true },
                    schedule: { _ in true },
                    cancel: { _ in }
                )
                
                NotificationManager.shared.configure(
                    notificationProvider: mockNotificationProvider,
                    storageProvider: IOSStorageService.createProvider(container: container)
                )
            }
    }
}
