// google_sign_in_web adds Google's sign-in script as the app starts (plugin registration, before main()), on every
// page. It waits here until the sign-in page asks for it (sign_in_web.dart loadGoogleSignIn, only when the server
// offers Google sign-in), so other pages and servers without Google sign-in never contact Google.
(() => {
  const head = document.head, append = head.appendChild.bind(head);
  let held = null, wanted = false;
  head.appendChild = (node) => {
    if (!wanted && node instanceof HTMLScriptElement && node.src.startsWith('https://accounts.google.com/gsi/')) {
      held = node;
      return node;
    }
    return append(node);
  };
  window.evensiesLoadGoogle = () => {
    wanted = true;
    if (held) append(held);
    held = null;
  };
})();
