//
//  ChatsView.swift
//  PersonaChat
//
//  Created by Mohammed on 8/12/25.
//
import SwiftUI
import SwiftData

struct ChatsView: View {
    @Environment(\.modelContext)
    private var modelContext

    @Query
    private var chats: [Chat]

    var body: some View {
        NavigationStack {
            List {
                ForEach(chats) { chat in

                    NavigationLink {
                        ChatView(chat: chat)
                            .navigationTitle(chat.title)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(chat.title)

                            Text(chat.date, style: .date)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem {
                    Button("Add", systemImage: "plus") {
                        addItem()
                    }
                }
            }


        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Chat("New Chat")
            modelContext.insert(newItem)
        }
    }
}

#Preview {
    ChatsView()
        .modelContainer(for: DataSchema.models, inMemory: true)
}
