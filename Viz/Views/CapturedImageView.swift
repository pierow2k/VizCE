import SwiftUI

struct CapturedImageView: View {
    let image: NSImage

    var body: some View {
        Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 480, height: 360)
            .background(Color.black)
    }
}
