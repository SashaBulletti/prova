// Fotografa ogni carta di carte.html in un PNG a 300 dpi (63 x 88 mm = circa 744 x 1039 pixel).
// Uso: node fai_png.js [cartella_uscita]
const {chromium} = require('playwright');
const path = require('path');
const fs = require('fs');
(async () => {
  const out = process.argv[2] || path.join(__dirname, 'png');
  fs.mkdirSync(out, {recursive: true});
  const b = await chromium.launch();
  const p = await b.newPage({viewport: {width: 1400, height: 1000}, deviceScaleFactor: 300 / 96});
  await p.goto('file://' + path.join(__dirname, 'carte.html'));
  await p.evaluate(() => document.fonts.ready);
  const carte = await p.$$('.carta');
  for (const c of carte) {
    const id = await c.getAttribute('id');
    await c.screenshot({path: path.join(out, id + '.png')});
  }
  console.log(carte.length, 'carte salvate in', out);
  await b.close();
})();
