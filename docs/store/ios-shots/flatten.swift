// swift flatten.swift a.png ... — rewrites each PNG in place without an alpha channel (App Store Connect refuses alpha)
import AppKit
for p in CommandLine.arguments.dropFirst() {
  let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: p) as CFURL, nil)!
  let img = CGImageSourceCreateImageAtIndex(src, 0, nil)!
  let ctx = CGContext(data: nil, width: img.width, height: img.height, bitsPerComponent: 8, bytesPerRow: 0,
                      space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
  ctx.draw(img, in: CGRect(x: 0, y: 0, width: img.width, height: img.height))
  let dst = CGImageDestinationCreateWithURL(URL(fileURLWithPath: p) as CFURL, "public.png" as CFString, 1, nil)!
  CGImageDestinationAddImage(dst, ctx.makeImage()!, nil)
  precondition(CGImageDestinationFinalize(dst))
}
