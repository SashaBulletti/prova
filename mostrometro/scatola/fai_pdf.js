// Trasforma una pagina HTML della scatola in PDF.  Uso: node fai_pdf.js scatola_A3.html scatola_A3.pdf
const {chromium} = require('playwright');
const path = require('path');
(async () => {
  const [ing, usc] = process.argv.slice(2);
  const b = await chromium.launch();
  const p = await b.newPage();
  await p.goto('file://' + path.join(__dirname, ing));
  await p.evaluate(() => document.fonts.ready);
  await p.pdf({path: path.join(__dirname, usc), printBackground: true, preferCSSPageSize: true});
  console.log('scritto', usc);
  await b.close();
})();
