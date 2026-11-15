// Trasforma stampa.html in carte_da_stampare.pdf (A4, 9 carte per foglio).
// Uso: python3 stampa.py && node fai_pdf.js
const {chromium} = require('playwright');
const path = require('path');
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage();
  const ing = process.argv[2] || 'stampa.html', usc = process.argv[3] || 'carte_da_stampare.pdf';
  await p.goto('file://' + path.join(__dirname, ing));
  await p.evaluate(() => document.fonts.ready);
  const out = path.join(__dirname, usc);
  await p.pdf({path: out, format: 'A4', printBackground: true, preferCSSPageSize: true});
  console.log('scritto', out);
  await b.close();
})();
