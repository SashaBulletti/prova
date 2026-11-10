// MOSTROMETRO - custodia stampabile in 3D: un "totem" col sorriso, in due gusci (fronte + retro)
// Unita': mm.  Apri con OpenSCAD, scegli `parte` e premi F6 -> Esporta STL.
//
//   parte = "fronte"      -> guscio anteriore (stampalo con la faccia esterna sul piatto)
//   parte = "retro"       -> guscio posteriore (stampalo con la faccia esterna sul piatto)
//   parte = "stampa"      -> i due gusci affiancati
//   parte = "assemblato"  -> anteprima chiusa (per controllare che combacino)
//
// NON STAMPARE SUBITO: misura la tua scheda, il tuo bottone e la tua batteria e correggi i
// parametri qui sotto. Fai prima una prova veloce (strati da 0,3 mm, 10% di riempimento).
// Dopo aver cambiato qualcosa riesporta gli STL e lancia  python3 bake_modello.py  per il 3D della pagina.

parte = "assemblato";
$fn = 96;

// ---------- forma del totem ----------
body_w = 60;      // larghezza del corpo
body_h = 170;     // altezza del corpo (le corna sono in piu')
r_top  = 12;      // arrotondamento degli angoli in alto
base_w = 76;      // larghezza della base (i "piedi": serve perche' stia in piedi)
base_h = 10;      // altezza della base
horn_w = 18;      // larghezza alla base delle corna
horn_h = 16;      // altezza delle corna
horn_x = 15;      // distanza delle corna dal centro
depth  = 30;      // spessore totale (fronte + retro)
wall   = 2.4;     // spessore pareti

// ---------- scheda: LilyGO T-Display S3 Long (schermo lungo + ESP32-S3 + ricarica USB-C) ----------
// MISURA LA TUA: i negozi indicano 92 x 28 mm e 14-16 mm di spessore.
brd_w = 28;       // larghezza della scheda
brd_l = 92;       // lunghezza della scheda
brd_y0 = 3;       // dove inizia dal basso (la presa USB-C e' in basso)
win_w = 24.4;     // finestra: area visibile dello schermo (circa 23,4 x 83 mm)
win_h = 83.6;
clear = 0.4;      // gioco intorno alla scheda

// ---------- bottone arcade da 30 mm: e' il "naso" ----------
btn_d = 24.2;     // foro (corpo sotto pannello circa 21 mm)
btn_y = 122;

// ---------- batteria LiPo piatta (es. 603048: 6 x 30 x 48 mm), dietro la scheda ----------
bat_w = 30;
bat_l = 48;

// ---------- presa USB-C (in basso) ----------
usb_w = 12;       // larghezza della tacca. Controlla dove sta la presa sulla TUA scheda.

// ---------- decorazioni ----------
eye_d = 14;       // sede per occhietti adesivi
eye_x = 13;
eye_y = 150;

// ---------- viti M3 x 25 (3 pezzi) ----------
screw_pilot = 2.6;
screw_hole  = 3.4;
screw_head  = 6.4;
post_d      = 7;
posts = [[-23.5, 45], [23.5, 45], [0, 150]];

half  = depth / 2;
win_y = brd_y0 + brd_l / 2;       // centro dello schermo dal basso

// ---------- profilo 2D ----------
module outline() {
    union() {
        hull() {                                            // corpo
            translate([-body_w/2 + r_top, body_h - r_top]) circle(r = r_top);
            translate([ body_w/2 - r_top, body_h - r_top]) circle(r = r_top);
            translate([-body_w/2, 0]) square([body_w, 1]);
        }
        hull() {                                            // base larga, angoli in basso tondi
            translate([-base_w/2 + 6, 6]) circle(r = 6);
            translate([ base_w/2 - 6, 6]) circle(r = 6);
            translate([-base_w/2, base_h - 1]) square([base_w, 1]);
        }
        for (s = [-1, 1])                                   // corna
            polygon([[s*(horn_x + horn_w/2), body_h - 6], [s*(horn_x - horn_w/2), body_h - 6],
                     [s*(horn_x + 2), body_h + horn_h]]);
    }
}

module ring(a, b) {            // corona tra offset -a e offset -b (a<b)
    difference() {
        offset(r = -a) outline();
        offset(r = -b) outline();
    }
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
        y = win_y - win_h/2 + i * win_h / 10;
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
        translate([-win_w/2, win_y - win_h/2, -1]) cube([win_w, win_h, wall + 2]);
        translate([-(brd_w + clear)/2, win_y - (brd_l + clear)/2, wall - 1.4]) cube([brd_w + clear, brd_l + clear, 4]);
        // foro bottone
        translate([0, btn_y, -1]) cylinder(d = btn_d, h = wall + 2);
        // sedi occhietti e sopracciglia arrabbiate
        for (s = [-1, 1]) {
            translate([s * eye_x, eye_y, -0.01]) cylinder(d = eye_d, h = 1);
            translate([s * eye_x, eye_y + 11, 0]) rotate([0, 0, -s * 18]) translate([-6, -0.7, -0.01]) cube([12, 1.4, 0.7]);
        }
        ticks();
        // presa USB-C (meta' della tacca)
        translate([-usb_w/2, -1, half - 10]) cube([usb_w, wall + 2, 11]);
    }
}

module retro() {
    difference() {
        union() {
            shell();
            posts_solid();
            // alloggio per la batteria, dietro alla scheda
            for (sx = [-1, 1], sy = [-1, 1])
                translate([sx * (bat_w/2 + 0.8), win_y + sy * (bat_l/2 - 6), wall + 3]) cube([1.6, 6, 6], center = true);
        }
        translate([0, 0, half - 2.2]) linear_extrude(3) ring(0.5, 1.9);     // scanalatura
        for (p = posts) {
            translate([p[0], p[1], -1]) cylinder(d = screw_hole, h = half + 2);
            translate([p[0], p[1], -0.01]) cylinder(d = screw_head, h = wall - 0.4);
        }
        // presa USB-C (altra meta' della tacca)
        translate([-usb_w/2, -1, half - 4]) cube([usb_w, wall + 2, 5]);
    }
}

if (parte == "fronte") fronte();
else if (parte == "retro") retro();
else if (parte == "stampa") {
    translate([-60, 0, 0]) fronte();
    translate([ 60, 0, 0]) retro();
} else {
    fronte();
    translate([0, 0, depth]) mirror([0, 0, 1]) retro();
}
