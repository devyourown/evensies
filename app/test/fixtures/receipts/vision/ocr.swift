// Draws two made-up receipts (Korean card terminal, Japanese supermarket) as PNGs, reads them with Apple Vision the way
// AppDelegate.swift does on iOS 16+, and writes the recognized lines as parser fixtures (../kr_cafe_card.json,
// ../jp_supermarket.json) with the draft each receipt should give. Real OCR output: spacing, split lines and misreads
// ("·" for ￥) are Vision's, so the expected names are spelled as Vision reads them.
// Usage (macOS 13+, from app/): swift test/fixtures/receipts/vision/ocr.swift test/fixtures/receipts
import AppKit
import Vision

struct Receipt {
  let file, name, font, language: String
  let header: [String]  // centred
  let body: [[String]]  // a row: left text, then right-aligned columns; [] is a rule
  let footer: [String]
  let expected: [String: Any]
}

let receipts = [
  Receipt(
    file: "kr_cafe_card",
    name: "KRW café, card terminal (real Vision OCR): name, unit price, qty, amount columns; spaced 합 계",
    font: "AppleSDGothicNeo-Medium", language: "ko-KR",
    header: ["카페 온새미로 역삼점", "사업자번호 214-86-12345  대표 김하늘", "서울 강남구 테헤란로 152, 1층", "TEL 02-555-0142",
             "[영수증]  2026-10-12 13:45:21"],
    body: [[], ["상품명", "단가", "수량", "금액"], [],
           ["아메리카노", "4,500", "2", "9,000"], ["카페라떼", "5,000", "1", "5,000"], ["바닐라라떼", "5,500", "1", "5,500"],
           ["치즈케이크", "6,800", "1", "6,800"], ["크루아상", "3,900", "1", "3,900"], [],
           ["공급가액", "", "", "27,455"], ["부  가  세", "", "", "2,745"], ["합      계", "", "", "30,200"], [],
           ["받을금액", "", "", "30,200"], ["신용카드", "", "", "30,200"], ["카드번호  9410-61**-****-123*"],
           ["승인번호  30012345   일시불"], ["승인일시  2026-10-12 13:45:21"], []],
    footer: ["이용해 주셔서 감사합니다"],
    expected: ["lines": [["name": "2x 아메리카노", "amount": 9000], ["name": "카페라떼", "amount": 5000],
                         ["name": "바닐라라떼", "amount": 5500], ["name": "치즈케이크", "amount": 6800],
                         ["name": "크루아상", "amount": 3900]],
               "tax": 0, "tip": 0, "discount": 0, "total": 30200, "merchant": "카페 온새미로 역삼점"]),
  Receipt(
    file: "jp_supermarket",
    name: "JPY supermarket (real Vision OCR): ￥ prices with 軽, a 2コ X 単 line, 外税 at two rates",
    font: "HiraginoSans-W4", language: "ja-JP",
    header: ["スーパーさくら 中野店", "東京都中野区中野5-12-3", "電話 03-3381-0000", "2026年10月12日(月) 18:42",
             "登録番号 T1234567890123"],
    body: [[], ["牛乳 1000ml", "￥238軽"], ["食パン 6枚切", "￥168軽"], ["バナナ", "￥198軽"], ["ヨーグルト", "￥256軽"],
           ["    2コ X 単128"], ["台所用洗剤", "￥298"], [],
           ["小計", "￥1,158"], ["外税8%対象額", "￥860"], ["外税8%", "￥68"], ["外税10%対象額", "￥298"],
           ["外税10%", "￥29"], ["合計", "￥1,255"], ["お預り", "￥2,000"], ["お釣り", "￥745"], []],
    footer: ["軽は軽減税率対象商品です"],
    expected: ["lines": [["name": "牛乳 1000ml", "amount": 238], ["name": "食パン6枚切", "amount": 168],
                         ["name": "バナナ", "amount": 198], ["name": "ヨーグルト", "amount": 256],
                         ["name": "台所用洗剤", "amount": 298]],
               "tax": 97, "tip": 0, "discount": 0, "total": 1255, "merchant": "スーパーさくら 中野店"]),
]

let out = URL(fileURLWithPath: CommandLine.arguments[1])
let here = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
for r in receipts {
  // Thermal paper, 900 px wide, tilted half a degree like a photo.
  let w = 900, h = 120 + (r.header.count + r.body.count + r.footer.count) * 52 + 80
  let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                      space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)!
  ctx.setFillColor(gray: 0.96, alpha: 1)
  ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
  ctx.translateBy(x: CGFloat(w) / 2, y: CGFloat(h) / 2)
  ctx.rotate(by: 0.5 * .pi / 180)
  ctx.translateBy(x: -CGFloat(w) / 2, y: -CGFloat(h) / 2)
  NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
  let attrs: [NSAttributedString.Key: Any] = [.font: NSFont(name: r.font, size: 30)!,
                                              .foregroundColor: NSColor(calibratedWhite: 0.15, alpha: 1)]
  var y = CGFloat(h - 100)
  func draw(_ s: String, right: CGFloat? = nil, centre: Bool = false) {
    let a = NSAttributedString(string: s, attributes: attrs)
    let x = centre ? (CGFloat(w) - a.size().width) / 2 : right.map { $0 - a.size().width } ?? 60
    a.draw(at: NSPoint(x: x, y: y))
  }
  for s in r.header { draw(s, centre: true); y -= 52 }
  for row in r.body {
    if row.isEmpty { draw(String(repeating: "-", count: 46)) }
    for (i, s) in row.enumerated() where !s.isEmpty {
      // Two columns: text and price; four: name, unit price, qty, amount.
      if i == 0 { draw(s) } else { draw(s, right: row.count == 2 ? 840 : [0, 520, 640, 840][i]) }
    }
    y -= 52
  }
  for s in r.footer { draw(s, centre: true); y -= 52 }
  let image = ctx.makeImage()!
  try! NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!
    .write(to: here.appendingPathComponent("\(r.file).png"))

  let request = VNRecognizeTextRequest()
  request.recognitionLevel = .accurate
  request.usesLanguageCorrection = false
  request.automaticallyDetectsLanguage = true
  request.recognitionLanguages = [r.language, "en-US"]
  try! VNImageRequestHandler(cgImage: image).perform([request])
  let lines: [[String: Any]] = (request.results ?? []).compactMap { o in
    guard let text = o.topCandidates(1).first?.string else { return nil }
    let b = o.boundingBox  // normalized, origin bottom left
    return ["text": text, "left": Int(b.minX * Double(w)), "right": Int(b.maxX * Double(w)),
            "top": Int((1 - b.maxY) * Double(h)), "bottom": Int((1 - b.minY) * Double(h))]
  }
  let fixture: [String: Any] = [
    "_doc": "Recognized by Apple Vision (accurate, \(r.language) first) from vision/\(r.file).png, a made-up receipt "
      + "drawn by vision/ocr.swift, for parseReceipt (app/lib/domain/receipt_parser.dart). Boxes in pixels.",
    "name": r.name, "decimals": 0, "lines": lines, "expected": r.expected,
  ]
  try! JSONSerialization.data(withJSONObject: fixture, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
    .write(to: out.appendingPathComponent("\(r.file).json"))
  print(r.file, lines.map { $0["text"]! })
}
