//
//  MaybeMarkdown.swift
//  T3lepathy
//
//  Created by Mohammed on 8/9/25.
//

import SwiftUI

struct MaybeMarkdown: View {
    let txt: String

    init(_ txt: String) {
        self.txt = txt
    }
    var body: some View {
        if let attributedString = try? AttributedString(
            markdown: txt,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            Text(attributedString)
        } else {
            Text(txt)
        }
    }
}

#Preview {
    MaybeMarkdown("""
~Hey~
_there_,
**world!**
""")
}
