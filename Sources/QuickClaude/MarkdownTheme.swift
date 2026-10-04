import MarkdownUI
import SwiftUI

extension MarkdownUI.Theme {
    static let claude = MarkdownUI.Theme.gitHub
        .text {
            FontFamily(.system(.serif))
            FontSize(14)
            ForegroundColor(Theme.text)
            BackgroundColor(nil)
        }
        .code {
            FontFamilyVariant(.monospaced)
            FontSize(.em(0.88))
            BackgroundColor(Theme.code)
        }
        .link {
            ForegroundColor(Theme.accent)
        }
        .heading1 { $0.label.markdownMargin(top: 14, bottom: 8).markdownTextStyle { FontWeight(.semibold); FontSize(.em(1.4)) } }
        .heading2 { $0.label.markdownMargin(top: 14, bottom: 8).markdownTextStyle { FontWeight(.semibold); FontSize(.em(1.25)) } }
        .heading3 { $0.label.markdownMargin(top: 12, bottom: 6).markdownTextStyle { FontWeight(.semibold); FontSize(.em(1.1)) } }
        .paragraph { configuration in
            configuration.label
                .fixedSize(horizontal: false, vertical: true)
                .relativeLineSpacing(.em(0.2))
                .markdownMargin(top: 0, bottom: 10)
        }
        .blockquote { configuration in
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2).fill(Theme.border).frame(width: 3)
                configuration.label
                    .markdownTextStyle { ForegroundColor(Theme.secondary) }
                    .padding(.leading, 10)
            }
            .fixedSize(horizontal: false, vertical: true)
            .markdownMargin(top: 0, bottom: 10)
        }
        .codeBlock { configuration in
            if configuration.language == "math" {
                MathBlock(latex: configuration.content)
            } else {
                ScrollView(.horizontal) {
                    configuration.label
                        .fixedSize(horizontal: false, vertical: true)
                        .relativeLineSpacing(.em(0.2))
                        .markdownTextStyle {
                            FontFamilyVariant(.monospaced)
                            FontSize(.em(0.85))
                        }
                        .padding(10)
                }
                .background(Theme.code)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .markdownMargin(top: 0, bottom: 10)
            }
        }
        .table { configuration in
            configuration.label
                .fixedSize(horizontal: false, vertical: true)
                .markdownTableBorderStyle(.init(color: Theme.border))
                .markdownTableBackgroundStyle(.alternatingRows(Color.clear, Theme.code))
                .markdownMargin(top: 0, bottom: 10)
        }
        .tableCell { configuration in
            configuration.label
                .markdownTextStyle {
                    if configuration.row == 0 { FontWeight(.semibold) }
                    BackgroundColor(nil)
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
        }
        .thematicBreak {
            Divider().overlay(Theme.border).markdownMargin(top: 12, bottom: 12)
        }
}
