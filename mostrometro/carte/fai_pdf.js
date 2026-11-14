// Trasforma stampa.html in carte_da_stampare.pdf (A4, 9 carte per foglio).
// Uso: python3 stampa.py && node fai_pdf.js
const {chromium} = require('playwright');
const path = require('path');
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage();
  await p.goto('file://' + path.join(__dirname, 'stampa.html'));
  await p.evaluate(() => document.fonts.ready);
  const out = path.join(__dirname, 'carte_da_stampare.pdf');
  await p.pdf({path: out, format: 'A4', printBackground: true, preferCSSPageSize: true});
  console.log('scritto', out);
  await b.close();
})();
