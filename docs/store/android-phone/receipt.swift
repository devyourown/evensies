// Renders a made-up restaurant receipt to receipt.jpg (for the receipt-scan screenshot; added with simctl addmedia).
// Usage: swift receipt.swift <out.jpg>
import AppKit

let rows: [(String, String)] = [
  ("Caldo verde x2", "9.00"),
  ("Polvo a lagareiro", "18.50"),
  ("Bitoque", "13.90"),
  ("Arroz de marisco", "24.00"),
  ("Salada mista", "5.50"),
  ("Agua 1.5L", "3.20"),
  ("Vinho da casa", "12.00"),
  ("Pastel de nata x3", "4.50"),
]
let w = 900.0, h = 1500.0
let img = NSImage(size: NSSize(width: w, height: h))
img.lockFocus()
NSColor(calibratedRed: 0.98, green: 0.97, blue: 0.94, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: w, height: h).fill()
let mono = NSFont(name: "Courier-Bold", size: 40)!
let big = NSFont(name: "Courier-Bold", size: 56)!
let ink = NSColor(calibratedWhite: 0.12, alpha: 1)
var y = h - 120.0
func center(_ s: String, _ f: NSFont) {
  let a = NSAttributedString(string: s, attributes: [.font: f, .foregroundColor: ink])
  a.draw(at: NSPoint(x: (w - a.size().width) / 2, y: y)); y -= a.size().height + 14
}
func row(_ l: String, _ r: String, _ f: NSFont = mono) {
  let attrs: [NSAttributedString.Key: Any] = [.font: f, .foregroundColor: ink]
  NSAttributedString(string: l, attributes: attrs).draw(at: NSPoint(x: 70, y: y))
  let ra = NSAttributedString(string: r, attributes: attrs)
  ra.draw(at: NSPoint(x: w - 70 - ra.size().width, y: y)); y -= ra.size().height + 18
}
center("TASCA ANDORINHA", big)
center("Lisboa", mono)
center("04/10/2026  21:47", mono)
y -= 40
for (l, r) in rows { row(l, r) }
y -= 20
row("Subtotal", "90.60")
row("Service", "4.50")
y -= 10
row("TOTAL EUR", "95.10", big)
y -= 60
center("Obrigado!", mono)
img.unlockFocus()
let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
try! rep.representation(using: .jpeg, properties: [.compressionFactor: 0.9])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
