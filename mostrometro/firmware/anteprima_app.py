#!/usr/bin/env python3
"""Genera mostrometro/app_anteprima.html: la pagina del telefono (quella che sta dentro mostrometro.ino)
con un Mostrometro SIMULATO dietro, cosi' si puo' provare subito nel browser, senza la scheda.
Uso:  python3 anteprima_app.py
"""
import json, os, re, sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "carte"))
from azioni import AZIONI, PUNTI_CARTA
from genera_carte import codice

BASE = os.path.dirname(os.path.abspath(__file__))
INO = os.path.join(BASE, "mostrometro", "mostrometro.ino")
USCITA = os.path.join(BASE, "..", "app_anteprima.html")

ino = open(INO, encoding="utf8").read()
pagina = re.search(r'R"=====\((.*?)\)====="', ino, re.S).group(1)
stile = re.search(r"<style>(.*?)</style>", pagina, re.S).group(1)
corpo = re.search(r"<body>(.*?)</body>", pagina, re.S).group(1)
html_main, js = corpo.split("<script>", 1)
js = js.rsplit("</script>", 1)[0]

BANNER = ('<div class="anteprima"><b>Anteprima.</b> Qui il Mostrometro è simulato, con tre persone di esempio (Papa, Mamma, Sasha). '
          'L\'urlo dà punti a caso. Sul mostro vero questa stessa pagina compare quando ti colleghi al suo WiFi.</div>')
BANNER = BANNER.replace('</div>', '<div class="prove"><button id="simCarta">&#127183; Scansiona una carta a caso</button>'
                        '<button id="simSupremo">Carta 57: Mostro Supremo</button></div></div>', 1)
html_main = html_main.replace("<main>", "<main>" + BANNER, 1)
CARTE = [{"t": t, "c": c, "s": 1 if e.get("speciale") == "mostro_supremo" else 0, "k": codice(i)}
         for i, (g, t, c, e) in enumerate(AZIONI, start=1)]

SIMULATORE = r"""
(function(){
  var KEY='mostrometro_anteprima_v1';
  var CARTE=__CARTE__,PC=__PC__;
  var S={chi:'',val:-1,misurando:false,bat:87,fam:null,carte:{}};
  try{var j=JSON.parse(localStorage.getItem(KEY)||'null');if(j&&Array.isArray(j.fam)){S.chi=j.chi||'';S.val=j.val;S.fam=j.fam;S.carte=j.carte||{}}}catch(e){}
  function base(n){var h=2166136261;n=n.toLowerCase();for(var i=0;i<n.length;i++){h^=n.charCodeAt(i);h=Math.imul(h,16777619)>>>0}return 10+(h>>>0)%56}
  if(!S.fam){S.fam=[{n:'Papa',bonus:8,v:base('Papa')},{n:'Mamma',bonus:0,v:base('Mamma')},{n:'Sasha',bonus:0,v:base('Sasha')}]}
  function save(){try{localStorage.setItem(KEY,JSON.stringify({chi:S.chi,val:S.val,fam:S.fam,carte:S.carte}))}catch(e){}}
  function trova(n){return S.fam.find(function(f){return f.n.toLowerCase()===n.toLowerCase()})}
  function crea(n){var p={n:n,bonus:0,v:-1};S.fam.push(p);if(S.fam.length>12)S.fam.shift();return p}
  function att(p){return Math.min(100,base(p.n)+p.bonus)}
  function carteDi(n){return Object.keys(S.carte).filter(function(k){return S.carte[k].toLowerCase()===n.toLowerCase()}).length}
  function stato(){return{bat:S.bat,chi:S.chi,val:S.val,misurando:S.misurando,carte:Object.keys(S.carte).length,nc:CARTE.length,
    fam:S.fam.map(function(f){return{n:f.n,v:f.v,p:(f.v>=0&&att(f)>f.v)?att(f)-f.v:0,c:carteDi(f.n)}})}}
  function valida(u){var n=parseInt(u.searchParams.get('n'),10);var c=CARTE[n-1];return c&&(u.searchParams.get('k')||'').toUpperCase()===c.k?n:0}
  function pul(x){return (x||'').replace(/[^\x20-\x7e]/g,'').replace(/[:;"\\<>&'%]/g,'').trim().slice(0,14)}
  window.simulaCarta=function(n){if(!n){var libere=[];for(var i=1;i<=CARTE.length;i++)if(!S.carte[i])libere.push(i);
    n=libere.length?libere[Math.floor(Math.random()*libere.length)]:1}apriCarta(n,CARTE[n-1].k)};
  function risposta(o,st){return new Response(JSON.stringify(o),{status:st||200,headers:{'Content-Type':'application/json'}})}
  var nome=function(u){return (u.searchParams.get('nome')||'').replace(/[^\x20-\x7e]/g,'').replace(/[:;"\\<>&'%]/g,'').trim().slice(0,14)};
  window.confirm=function(){return true};              // nell'anteprima i pulsanti X tolgono subito la persona
  window.fetch=function(url){
    var u=new URL(url,location.href),p=u.pathname.replace(/^.*\/api\//,'/api/');
    if(p==='/api/stato')return Promise.resolve(risposta(stato()));
    if(p==='/api/chi'){S.chi=nome(u);save();return Promise.resolve(risposta({ok:true}))}
    if(p==='/api/misura'||p==='/api/urlo'){
      if(S.misurando)return Promise.resolve(risposta({ok:false},409));
      S.misurando=true;var urlo=p==='/api/urlo',n=S.chi||'Ospite';
      setTimeout(function(){
        var f=trova(n)||crea(n);
        if(urlo){f.bonus=Math.min(100,f.bonus+Math.min(10,Math.round(Math.random()*Math.random()*14)))}
        else{var t=att(f);f.v=t;S.val=t}
        S.misurando=false;save()},urlo?3500:3200);
      return Promise.resolve(risposta({ok:true}))}
    if(p==='/api/aggiungi'){
      var n4=nome(u);if(!n4)return Promise.resolve(risposta({ok:false},400));
      if(!trova(n4)){if(S.fam.length>=12)return Promise.resolve(risposta({ok:false,pieno:true},409));S.fam.push({n:n4,bonus:0,v:-1});save()}
      return Promise.resolve(risposta({ok:true}))}
    if(p==='/api/azione'){
      var n2=nome(u);if(!n2)return Promise.resolve(risposta({ok:false},400));
      var f2=trova(n2)||crea(n2);var pt=Math.max(-10,Math.min(10,parseInt(u.searchParams.get('punti'),10)||0));
      f2.bonus=Math.max(0,Math.min(100,f2.bonus+pt));save();return Promise.resolve(risposta({ok:true}))}
    if(p==='/api/carta'){var n5=valida(u);if(!n5)return Promise.resolve(risposta({ok:false},404));var c5=CARTE[n5-1];
      return Promise.resolve(risposta({ok:true,n:n5,titolo:c5.t,come:c5.c,punti:PC,speciale:c5.s,da:S.carte[n5]||''}))}
    if(p==='/api/gioca'){var n6=valida(u);if(!n6)return Promise.resolve(risposta({ok:false},404));
      if(S.carte[n6])return Promise.resolve(risposta({ok:false,usata:true,da:S.carte[n6]},409));
      var chi6=nome(u);if(!chi6)return Promise.resolve(risposta({ok:false},400));
      var pt6=PC,pa6=0,al6=pul(u.searchParams.get('altro'));
      if(CARTE[n6-1].s){if(u.searchParams.get('artigli')==='1'&&al6&&al6.toLowerCase()!==chi6.toLowerCase())pa6=PC;else pt6=2}
      var nuovi=(trova(chi6)?0:1)+(pa6&&!trova(al6)?1:0);if(S.fam.length+nuovi>12)return Promise.resolve(risposta({ok:false,pieno:true},409));
      var f6=trova(chi6)||crea(chi6);f6.bonus=Math.min(100,f6.bonus+pt6);
      if(pa6){var g6=trova(al6)||crea(al6);g6.bonus=Math.min(100,g6.bonus+pa6);al6=g6.n}
      S.carte[n6]=f6.n;save();
      return Promise.resolve(risposta({ok:true,nome:f6.n,punti:pt6,altro:pa6?al6:'',puntiAltro:pa6}))}
    if(p==='/api/nuovaserata'){S.carte={};save();return Promise.resolve(risposta({ok:true}))}
    if(p==='/api/elimina'){var n3=nome(u).toLowerCase();S.fam=S.fam.filter(function(f){return f.n.toLowerCase()!==n3});save();return Promise.resolve(risposta({ok:true}))}
    return Promise.resolve(risposta({ok:false},404))};
})();
"""

EXTRA = """
:root{color-scheme:dark}
body{padding-left:max(16px,env(safe-area-inset-left,0px));padding-right:max(16px,env(safe-area-inset-right,0px));padding-block:0}
main{padding-left:0;padding-right:0}
.prove{display:flex;flex-wrap:wrap;gap:8px;margin-top:8px}.prove button{width:auto;margin:0;padding:9px 12px;font-size:.9rem;background:#5a4410;color:#ffd84a}
.anteprima{background:#33260a;color:#ffd84a;border-radius:12px;padding:10px 12px;margin:12px 0 4px;font-size:.9rem;line-height:1.4}
"""

out = ('<title>App Mostrometro</title>\n<meta name="claude:viewport-fit-sides" content="cover">\n<style>'
       + stile + EXTRA + "</style>\n" + html_main + "\n<script>" + SIMULATORE + "</script>\n<script>" + js
       + "\ndocument.getElementById('simCarta').onclick=function(){simulaCarta(0)};document.getElementById('simSupremo').onclick=function(){simulaCarta(57)};</script>\n")
out = out.replace("__CARTE__", json.dumps(CARTE, ensure_ascii=False)).replace("__PC__", str(PUNTI_CARTA))
open(USCITA, "w", encoding="utf8").write(out)
print("scritto", os.path.abspath(USCITA), len(out) // 1024, "KB")
