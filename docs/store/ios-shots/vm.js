// Evaluates a Dart expression in a running debug app through the VM service (no taps needed).
// Usage: node vm.js <ws-uri> <library-uri> '<dart expression>'
const [ws, libUri, expr] = process.argv.slice(2);
const sock = new WebSocket(ws);
let id = 0;
const pending = new Map();
const rpc = (method, params = {}) => new Promise((res, rej) => {
  const i = String(++id);
  pending.set(i, { res, rej });
  sock.send(JSON.stringify({ jsonrpc: '2.0', id: i, method, params }));
});
sock.onmessage = (m) => {
  const d = JSON.parse(m.data);
  const p = pending.get(d.id);
  if (!p) return;
  pending.delete(d.id);
  d.error ? p.rej(new Error(JSON.stringify(d.error))) : p.res(d.result);
};
sock.onopen = async () => {
  try {
    const vm = await rpc('getVM');
    const iso = vm.isolates.find((i) => i.name.includes('main')) || vm.isolates[0];
    const isolate = await rpc('getIsolate', { isolateId: iso.id });
    const lib = isolate.libraries.find((l) => l.uri === libUri);
    if (!lib) throw new Error('no library ' + libUri);
    const r = await rpc('evaluate', { isolateId: iso.id, targetId: lib.id, expression: expr, disableBreakpoints: true });
    if (r.type === '@Error' || r.type === 'Error') { console.error('ERROR', r.message); process.exitCode = 1; }
    else if (r.kind === 'String') console.log(r.valueAsString);
    else console.log(r.kind, r.valueAsString ?? r.class?.name ?? '');
  } catch (e) { console.error('ERR', e.message); process.exitCode = 1; }
  sock.close();
};
