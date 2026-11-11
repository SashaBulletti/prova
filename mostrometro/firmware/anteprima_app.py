#!/usr/bin/env python3
"""Genera mostrometro/app_anteprima.html: la pagina del telefono (quella che sta dentro mostrometro.ino)
con un Mostrometro SIMULATO dietro, cosi' si puo' provare subito nel browser, senza la scheda.
Uso:  python3 anteprima_app.py
"""
import os, re

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
html_main = html_main.replace("<main>", "<main>" + BANNER, 1)

SIMULATORE = r"""
(function(){
  var KEY='mostrometro_anteprima_v1';
  var S={chi:'',val:-1,misurando:false,bat:87,fam:null};
  try{var j=JSON.parse(localStorage.getItem(KEY)||'null');if(j&&Array.isArray(j.fam)){S.chi=j.chi||'';S.val=j.val;S.fam=j.fam}}catch(e){}
  function base(n){var h=2166136261;n=n.toLowerCase();for(var i=0;i<n.length;i++){h^=n.charCodeAt(i);h=Math.imul(h,16777619)>>>0}return 10+(h>>>0)%56}
  if(!S.fam){S.fam=[{n:'Papa',bonus:8,v:base('Papa')},{n:'Mamma',bonus:0,v:base('Mamma')},{n:'Sasha',bonus:0,v:base('Sasha')}]}
  function save(){try{localStorage.setItem(KEY,JSON.stringify({chi:S.chi,val:S.val,fam:S.fam}))}catch(e){}}
  function trova(n){return S.fam.find(function(f){return f.n.toLowerCase()===n.toLowerCase()})}
  function crea(n){var p={n:n,bonus:0,v:-1};S.fam.push(p);if(S.fam.length>12)S.fam.shift();return p}
  function att(p){return Math.min(100,base(p.n)+p.bonus)}
  function stato(){return{bat:S.bat,chi:S.chi,val:S.val,misurando:S.misurando,fam:S.fam.map(function(f){return{n:f.n,v:f.v,p:(f.v>=0&&att(f)>f.v)?att(f)-f.v:0}})}}
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
    if(p==='/api/elimina'){var n3=nome(u).toLowerCase();S.fam=S.fam.filter(function(f){return f.n.toLowerCase()!==n3});save();return Promise.resolve(risposta({ok:true}))}
    return Promise.resolve(risposta({ok:false},404))};
})();
"""

EXTRA = """
:root{color-scheme:dark}
body{padding-left:max(16px,env(safe-area-inset-left,0px));padding-right:max(16px,env(safe-area-inset-right,0px));padding-block:0}
main{padding-left:0;padding-right:0}
.anteprima{background:#33260a;color:#ffd84a;border-radius:12px;padding:10px 12px;margin:12px 0 4px;font-size:.9rem;line-height:1.4}
"""

out = ('<title>App Mostrometro</title>\n<meta name="claude:viewport-fit-sides" content="cover">\n<style>'
       + stile + EXTRA + "</style>\n" + html_main + "\n<script>" + SIMULATORE + "</script>\n<script>" + js + "</script>\n")
open(USCITA, "w", encoding="utf8").write(out)
print("scritto", os.path.abspath(USCITA), len(out) // 1024, "KB")
