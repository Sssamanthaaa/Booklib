import SwiftUI

/// Face-out generated cover (used on Today and as a mini cover on the book page).
struct BookCover: View {
    let book: Book
    var selected = false
    var width: CGFloat = 104
    var height: CGFloat = 164

    var body: some View {
        let fg = Color.readable(on: book.colorHex)
        VStack(alignment: .leading, spacing: 6) {
            Text(book.title.uppercased())
                .font(.system(size: width < 80 ? 10 : 14, weight: .heavy))
                .lineLimit(4)
                .minimumScaleFactor(0.7)
            if width >= 80 {
                Text(book.author.uppercased())
                    .font(.system(size: 8, weight: .semibold))
                    .opacity(0.8)
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(fg)
        .padding(10)
        .frame(width: width, height: height, alignment: .topLeading)
        .background(
            Color(hex: book.colorHex),
            in: UnevenRoundedRectangle(topLeadingRadius: 2, bottomLeadingRadius: 2,
                                       bottomTrailingRadius: 5, topTrailingRadius: 5)
        )
        .overlay(alignment: .topTrailing) {
            if book.status == .reading, width >= 80 {
                Text("\(book.percent)%")
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(.black.opacity(0.45), in: Capsule())
                    .foregroundStyle(.white)
                    .padding(5)
            }
        }
        .overlay {
            if selected { RoundedRectangle(cornerRadius: 6).stroke(Theme.lime, lineWidth: 3) }
        }
        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 4)
    }
}

/// Typographic book spine for the library shelves. Width follows page count, height follows title
/// length, and one of six lettering styles is picked from a stable hash of the title.
/// NOTE: written without Xcode available, so expect to tune sizes visually on a device.
struct SpineView: View {
    let book: Book

    private var hash: Int { StableHash.of(book.title + book.author) }
    private var variant: Int { hash % 6 }

    private var width: CGFloat {
        let base = max(30, min(54, CGFloat(20 + book.pages / 12)))
        return base + (variant == 3 ? 6 : 0)
    }
    private var height: CGFloat {
        min(262, max(170, 140 + CGFloat(book.title.count) * 8.5)) + CGFloat(hash % 12)
    }
    /// Shrink type for long titles so they fit.
    private var scale: CGFloat { book.title.count > 20 ? 0.66 : book.title.count > 14 ? 0.8 : 1 }

    /// Tallest spine in a list, used to size the shelf so it hugs the books.
    static func height(of book: Book) -> CGFloat { SpineView(book: book).height }
    static func width(of book: Book) -> CGFloat { SpineView(book: book).width }

    var body: some View {
        let bookColor = Color(hex: book.colorHex)
        let onBook = Color.readable(on: book.colorHex)
        let cream = variant == 1 || variant == 4

        ZStack {
            // background
            Rectangle().fill(cream ? Theme.cream : bookColor)
            if variant == 1 { VStack { Rectangle().fill(bookColor).frame(height: 16); Spacer() } }
            if variant == 4 { VStack { Spacer(); Rectangle().fill(bookColor).frame(height: 18) } }
            if variant == 5 {
                VStack(spacing: 0) { Spacer(); Rectangle().fill(.black.opacity(0.35)).frame(height: height * 0.28) }
            }

            // lettering
            VStack(spacing: 6) {
                vertical(titleText, font: titleFont, length: height - 108)
                Spacer(minLength: 0)
                vertical(book.author.uppercased(), font: .system(size: 8, weight: .semibold), length: 60)
                    .opacity(0.75)
            }
            .padding(.vertical, 14)
            .foregroundStyle(cream ? Theme.ink : onBook)
        }
        .frame(width: width, height: height)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 2, topTrailingRadius: 2))
        .overlay(alignment: .top) {
            if book.status == .reading {
                // bookmark ribbon
                Rectangle().fill(Color.red).frame(width: 8, height: 20)
                    .clipShape(Ribbon())
            }
        }
        .offset(y: book.status == .reading ? -14 : 0)
        .saturation(book.status == .finished ? 0.75 : 1)
        .rotationEffect(.degrees(leans ? 7 : 0), anchor: .bottomLeading)
        .padding(.trailing, leans ? 16 : 0)
    }

    private var leans: Bool { book.status == .want && hash % 4 == 0 }

    private var titleText: String {
        switch variant {
        case 0, 2, 3, 4: book.title.uppercased()
        case 5: book.title.lowercased()
        default: book.title
        }
    }

    private var titleFont: Font {
        switch variant {
        case 0: .system(size: 13 * scale, weight: .heavy)
        case 1: .system(size: 14 * scale, weight: .semibold, design: .serif).italic()
        case 2: .system(size: 12 * scale, weight: .bold, design: .monospaced)
        case 3: .system(size: 17 * scale, weight: .black)
        case 4: .system(size: 15 * scale, weight: .regular, design: .serif)
        default: .system(size: 14 * scale, weight: .semibold)
        }
    }

    /// Text laid out horizontally at the spine's length, then rotated to read top to bottom.
    private func vertical(_ s: String, font: Font, length: CGFloat) -> some View {
        Text(s)
            .font(font)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(width: max(length, 20), height: width, alignment: .leading)
            .rotationEffect(.degrees(90))
            .frame(width: width, height: max(length, 20))
    }
}

private struct Ribbon: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: 0))
        p.addLine(to: CGPoint(x: rect.width, y: 0))
        p.addLine(to: CGPoint(x: rect.width, y: rect.height))
        p.addLine(to: CGPoint(x: rect.width / 2, y: rect.height * 0.75))
        p.addLine(to: CGPoint(x: 0, y: rect.height))
        p.closeSubpath()
        return p
    }
}
