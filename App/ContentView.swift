// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (c) 2026 Razvan Cremenescu

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var model: TermModel

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            Divider()
            ZStack {
                ForEach(Array(model.tabs.enumerated()), id: \.element) { _, id in
                    LocalTerminal(isActive: id == model.selected,
                                  fontSize: model.fontSize,
                                  theme: model.theme,
                                  startupDir: model.resolvedStartupDir(),
                                  cursorBlinkSpeed: model.cursorBlinkSpeed,
                                  scrollbackLines: model.scrollbackLines,
                                  onTitleChange: { newTitle in
                                      model.setTitle(newTitle, for: id)
                                  })
                        .opacity(id == model.selected ? 1 : 0)
                        .allowsHitTesting(id == model.selected)
                }
            }
        }
    }

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(Array(model.tabs.enumerated()), id: \.element) { idx, id in
                    HStack(spacing: 6) {
                        Image(systemName: "terminal").font(.caption)
                        Text(model.displayTitle(for: id, index: idx))
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: 240)
                        Button { model.close(id) } label: { Image(systemName: "xmark").font(.caption2) }
                            .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(id == model.selected ? Color.accentColor.opacity(0.22) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .onTapGesture { model.selected = id }
                    .help(model.displayTitle(for: id, index: idx))
                }
                Button { model.newTab() } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .padding(.leading, 4)
                .help("Tab nou (Cmd+T)")
            }
            .padding(.horizontal, 6).padding(.vertical, 4)
        }
    }
}
