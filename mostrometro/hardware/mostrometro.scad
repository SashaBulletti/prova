// MOSTROMETRO - custodia stampabile in 3D, in due gusci (fronte + retro)
// Unita': mm.  Apri con OpenSCAD, scegli `parte` e premi F6 -> Esporta STL.
//
//   parte = "fronte"      -> guscio anteriore (stampalo con la faccia esterna sul piatto)
//   parte = "retro"       -> guscio posteriore (stampalo con la faccia esterna sul piatto)
//   parte = "stampa"      -> i due gusci affiancati
//   parte = "assemblato"  -> anteprima chiusa (per controllare che combacino)
//
// NON STAMPARE SUBITO: misura il tuo schermo, la tua ESP32 e il tuo bottone
// e correggi i parametri qui sotto. Fai prima una prova veloce (layer alto, 10% infill).

parte = "assemblato";
$fn = 96;

// ---------- forma del termometro ----------
bulb_d = 70;      // diametro del bulbo
tube_w = 42;      // larghezza del tubo
tube_h = 150;     // altezza del tubo (dal centro del bulbo)
depth  = 40;      // spessore totale (fronte + retro)
wall   = 2.4;     // spessore pareti
flat   = 6;       // quanto e' appiattito il fondo del bulbo (cosi' sta in piedi)

// ---------- schermo: ST7789 1.3" 240x240 (MISURA IL TUO MODULO!) ----------
pcb_w = 28;       // larghezza del circuito stampato dello schermo
pcb_h = 34;       // altezza del circuito stampato
win_w = 24.6;     // finestra visibile (area attiva ~23.4 mm)
win_h = 24.6;
screen_y = 116;   // altezza del centro dello schermo sul tubo

// ---------- bottone ----------
btn_d = 24.2;     // foro per bottone arcade da 30 mm (corpo sotto pannello ~ 21 mm)

// ---------- ESP32 (scheda tipo DevKit 38 pin) ----------
esp_w = 29;       // larghezza scheda
esp_l = 53;       // lunghezza scheda (con porta USB)
esp_y0 = 40;      // dove inizia la scheda (porta USB rivolta verso il basso)

// ---------- decorazioni ----------
eye_d = 12;       // sede per occhietti adesivi (googly eyes)
eye_x = 8.5;
eye_y = tube_h - 2;

// ---------- viti M3 (3 pezzi, lunghezza 30) ----------
screw_pilot = 2.6;
screw_hole  = 3.4;
screw_head  = 6.4;
post_d      = 7;
posts = [[-26, 0], [26, 0], [0, tube_h - 10]];

half = depth / 2;

// ---------- profilo 2D ----------
module outline() {
    intersection() {
        union() {
            circle(d = bulb_d);
            translate([-tube_w/2, 0]) square([tube_w, tube_h]);
            translate([0, tube_h]) circle(d = tube_w);
        }
        translate([-100, -bulb_d/2 + flat]) square([200, 400]);
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

// tacche della scala 0-100% incise ai lati dello schermo
module ticks() {
    for (i = [0:10]) {
        y = 34 + i * 10;
        len = (i % 5 == 0) ? 6 : 3.5;
        for (s = [-1, 1])
            translate([s * (14.5 + len/2), y, 0.3]) cube([len, 1, 1.2], center = true);
    }
}

module fronte() {
    difference() {
        union() {
            shell();
            translate([0, 0, half]) linear_extrude(2) ring(0.6, 1.8);   // linguetta
            posts_solid();
        }
        // viti: foro pilota nel piantone
        for (p = posts) translate([p[0], p[1], half - 10]) cylinder(d = screw_pilot, h = 11);
        // finestra schermo + sede del circuito (resta 1 mm di bordo davanti)
        translate([-win_w/2, screen_y - win_h/2, -1]) cube([win_w, win_h, wall + 2]);
        translate([-pcb_w/2, screen_y - pcb_h/2, wall - 1.4]) cube([pcb_w, pcb_h, 4]);
        // foro bottone
        translate([0, 0, -1]) cylinder(d = btn_d, h = wall + 2);
        // sedi occhietti
        for (s = [-1, 1]) translate([s * eye_x, eye_y, -0.01]) cylinder(d = eye_d, h = 1);
        ticks();
    }
}

module retro() {
    difference() {
        union() {
            shell();
            posts_solid();
            // gabbietta per l'ESP32
            for (sx = [-1, 1], yy = [esp_y0 + 3, esp_y0 + esp_l - 3])
                translate([sx * (esp_w/2 + 0.8), yy, wall + 3.5]) cube([1.6, 6, 7], center = true);
        }
        // scanalatura per la linguetta del fronte
        translate([0, 0, half - 2.2]) linear_extrude(3) ring(0.5, 1.9);
        // viti passanti con sede della testa
        for (p = posts) {
            translate([p[0], p[1], -1]) cylinder(d = screw_hole, h = half + 2);
            translate([p[0], p[1], -0.01]) cylinder(d = screw_head, h = wall - 0.4);
        }
        // uscita del cavo USB, in basso
        translate([-6, -bulb_d/2 + flat - 1, half - 7]) cube([12, wall + 2, 8]);
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
