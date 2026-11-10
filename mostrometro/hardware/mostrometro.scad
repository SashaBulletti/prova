// MOSTROMETRO - custodia stampabile in 3D, in due gusci (fronte + retro)
// Unita': mm.  Apri con OpenSCAD, scegli `forma` e `parte` e premi F6 -> Esporta STL.
//
//   forma = "A"  -> mostro tondo con braccia e piedi (come nel disegno A)
//   forma = "B"  -> totem col sorriso, alto e stretto (come nel disegno B)
//
//   parte = "fronte"      -> guscio anteriore (stampalo con la faccia esterna sul piatto)
//   parte = "retro"       -> guscio posteriore (stampalo con la faccia esterna sul piatto)
//   parte = "piedistallo" -> base per il totem B (da solo e' troppo alto e stretto per stare in piedi)
//   parte = "stampa"      -> i due gusci affiancati
//   parte = "assemblato"  -> anteprima chiusa (per controllare che combacino)
//
// Ordine come nel disegno, dall'alto: occhi, schermo lungo, bottone-naso. Le proporzioni sono quelle
// del disegno, scalate perche' lo schermo vero e' lungo 83 mm.
// La presa USB-C e' IN CIMA alla testa (in basso il corpo del bottone bloccherebbe il cavo).
//
// NON STAMPARE SUBITO: misura la tua scheda, il tuo bottone e la tua batteria e correggi i
// parametri qui sotto. Fai prima una prova veloce (strati da 0,3 mm, 10% di riempimento).
// Dopo aver cambiato qualcosa riesporta gli STL e lancia  python3 bake_modello.py  per il 3D della pagina.

parte = "assemblato";
forma = "B";
$fn = 96;

isA = forma == "A";

// ---------- forma ----------
body_w = isA ? 110 : 70;     // larghezza del corpo
body_h = 170;                // altezza del corpo
r_top  = isA ? 40 : 14;      // arrotondamento degli angoli in alto
r_bot  = isA ? 40 : 6;       // e in basso
y0     = isA ? 10 : 0;       // dove inizia il corpo (nella A i piedi stanno sotto)
top_y  = y0 + body_h;        // cima del corpo
horn_h = 23;                 // quanto sporgono le corna sopra il corpo
depth  = 30;                 // spessore totale (fronte + retro)
wall   = 2.4;                // spessore pareti

// ---------- scheda: LilyGO T-Display S3 Long (schermo lungo + ESP32-S3 + ricarica USB-C) ----------
// MISURA LA TUA: i negozi indicano 92 x 28 mm e 14-16 mm di spessore.
brd_w = 28;
brd_l = 92;
win_w = 24.4;                // finestra: area visibile dello schermo (circa 23,4 x 83 mm)
win_h = 83.6;
win_r = 4;                   // angoli arrotondati della finestra
win_cy = isA ? y0 + 77 : y0 + 82;     // altezza del centro dello schermo
clear = 0.4;                 // gioco intorno alla scheda

// ---------- bottone arcade da 30 mm: e' il naso, in basso ----------
btn_d = 24.2;                // foro (corpo sotto pannello circa 21 mm)
btn_y = isA ? y0 + 18 : 22;

// ---------- batteria LiPo piatta (es. 603048: 6 x 30 x 48 mm), dietro la scheda ----------
bat_w = 30;
bat_l = 48;

// ---------- presa USB-C: tacca in cima alla testa ----------
usb_w = 12;

// ---------- occhi (occhietti adesivi) ----------
eye_x = isA ? 22 : 15.5;
eye_d = isA ? 24 : 19;
eye_y = isA ? top_y - 32.5 : top_y - 27.3;

// ---------- viti M3 x 25 (3 pezzi) ----------
screw_pilot = 2.6;
screw_hole  = 3.4;
screw_head  = 6.4;
post_d      = 7;
post_x      = body_w / 2 - 11;
posts = [[-post_x, win_cy + 13], [post_x, win_cy + 13], [-13, top_y - 18]];

half = depth / 2;

// ---------- profilo 2D ----------
module outline_A() {        // mostro tondo
    union() {
        hull() {
            translate([-body_w/2 + r_top, top_y - r_top]) circle(r = r_top);
            translate([ body_w/2 - r_top, top_y - r_top]) circle(r = r_top);
            translate([-body_w/2 + r_bot, y0 + r_bot]) circle(r = r_bot);
            translate([ body_w/2 - r_bot, y0 + r_bot]) circle(r = r_bot);
        }
        for (s = [-1, 1]) {
            translate([s * (body_w/2 + 4), y0 + 79]) circle(r = 12);                          // braccia
            translate([s * 30, 0]) hull() {                                                   // piedi
                translate([-12, 5]) circle(r = 5);
                translate([ 12, 5]) circle(r = 5);
                translate([-17, 10]) square([34, 8]);
            }
            polygon([[s * 37, top_y - 10], [s * 11, top_y - 10], [s * 29, top_y + horn_h]]);  // corna
        }
    }
}

module outline_B() {        // totem
    union() {
        hull() {
            translate([-body_w/2 + r_top, top_y - r_top]) circle(r = r_top);
            translate([ body_w/2 - r_top, top_y - r_top]) circle(r = r_top);
            translate([-body_w/2 + r_bot, y0 + r_bot]) circle(r = r_bot);
            translate([ body_w/2 - r_bot, y0 + r_bot]) circle(r = r_bot);
        }
        for (s = [-1, 1])
            polygon([[s * 30, top_y - 12], [s * 10.5, top_y - 12], [s * 24.7, top_y + horn_h]]);   // corna
    }
}

module outline() {
    if (isA) outline_A(); else outline_B();
}

module ring(a, b) {            // corona tra offset -a e offset -b (a<b)
    difference() {
        offset(r = -a) outline();
        offset(r = -b) outline();
    }
}

module rrect(w, h, r) {
    offset(r = r) offset(delta = -r) square([w, h], center = true);
}

module shell() {
    difference() {
        linear_extrude(half) outline();
        translate([0, 0, wall]) linear_extrude(half) offset(r = -wall) outline();
    }
}

module posts_solid() {
    for (p = posts)
        translate([p[0], p[1], wall - 0.01]) cylinder(d = post_d, h = half - wall + 0.01);
}

// tacche della scala 0-100% ai lati dello schermo (lo schermo disegna il resto)
module ticks() {
    for (i = [0:10]) {
        y = win_cy - win_h/2 + i * win_h / 10;
        len = (i % 5 == 0) ? 6 : 3.5;
        for (s = [-1, 1])
            translate([s * (win_w/2 + 2.3 + len/2), y, 0.3]) cube([len, 1, 1.2], center = true);
    }
}

module fronte() {
    difference() {
        union() {
            shell();
            translate([0, 0, half]) linear_extrude(2) ring(0.6, 1.8);   // linguetta
            posts_solid();
        }
        for (p = posts) translate([p[0], p[1], half - 10]) cylinder(d = screw_pilot, h = 11);
        // finestra schermo + nicchia della scheda (resta 1 mm di bordo davanti)
        translate([0, win_cy, -1]) linear_extrude(wall + 2) rrect(win_w, win_h, win_r);
        translate([-(brd_w + clear)/2, win_cy - (brd_l + clear)/2, wall - 1.4]) cube([brd_w + clear, brd_l + clear, 4]);
        // foro bottone
        translate([0, btn_y, -1]) cylinder(d = btn_d, h = wall + 2);
        // sedi occhietti (e sopracciglia arrabbiate nella A)
        for (s = [-1, 1]) {
            translate([s * eye_x, eye_y, -0.01]) cylinder(d = eye_d, h = 1);
            if (isA)
                translate([s * eye_x, eye_y + eye_d/2 + 5, 0]) rotate([0, 0, -s * 18]) translate([-8, -0.7, -0.01]) cube([16, 1.4, 0.7]);
        }
        ticks();
        // presa USB-C in cima (meta' della tacca)
        translate([-usb_w/2, top_y - wall - 1, half - 10]) cube([usb_w, wall + 2, 11]);
    }
}

module retro() {
    difference() {
        union() {
            shell();
            posts_solid();
            // alloggio per la batteria, dietro alla scheda
            for (sx = [-1, 1], sy = [-1, 1])
                translate([sx * (bat_w/2 + 0.8), win_cy + sy * (bat_l/2 - 6), wall + 3]) cube([1.6, 6, 6], center = true);
        }
        translate([0, 0, half - 2.2]) linear_extrude(3) ring(0.5, 1.9);     // scanalatura
        for (p = posts) {
            translate([p[0], p[1], -1]) cylinder(d = screw_hole, h = half + 2);
            translate([p[0], p[1], -0.01]) cylinder(d = screw_head, h = wall - 0.4);
        }
        // presa USB-C in cima (altra meta' della tacca)
        translate([-usb_w/2, top_y - wall - 1, half - 4]) cube([usb_w, wall + 2, 5]);
    }
}

// base per il totem B: il corpo ci entra e resta dritto
module piedistallo() {
    sw = body_w + 34; sd = depth + 34; sh = 16;
    difference() {
        translate([0, 0, 0]) linear_extrude(sh) offset(r = 6) offset(delta = -6) square([sw, sd], center = true);
        translate([-(body_w + 0.8)/2, -(depth + 0.8)/2, 4]) cube([body_w + 0.8, depth + 0.8, sh]);
    }
}

if (parte == "fronte") fronte();
else if (parte == "retro") retro();
else if (parte == "piedistallo") piedistallo();
else if (parte == "stampa") {
    translate([-60, 0, 0]) fronte();
    translate([ 60, 0, 0]) retro();
} else {
    fronte();
    translate([0, 0, depth]) mirror([0, 0, 1]) retro();
}
