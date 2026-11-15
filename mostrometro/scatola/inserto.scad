// MOSTROMETRO - inserto per la scatola (stampa 3D)
// Due pezzi che stanno affiancati nel fondo della scatola:
//   parte = "mostro" -> vassoio con la sagoma del Mostrometro (forma A, sdraiato a pancia in su)
//   parte = "carte"  -> vassoio con due vani da 50 carte l'uno (63 x 88 mm, anche con le bustine)
//   parte = "insieme"-> i due pezzi affiancati, come nella scatola (solo per vedere)
// Ogni pezzo sta su un piatto da 220 x 220 mm. Stampa senza supporti, 0,28 mm, 10-15% di riempimento.
// Unita': mm.

parte = "insieme";
$fn = 72;

// ---------- misure ----------
alto   = 33;      // altezza dell'inserto (il Mostrometro e' spesso 30)
fondo  = 2;       // spessore del fondo
muro   = 3;       // spessore dei bordi
gioco  = 1.2;     // spazio intorno al Mostrometro
carta_w = 68;     // vano carta: 63 x 88 + spazio per le bustine (66 x 91)
carta_l = 93;
dito_r = 11;      // incavi per prendere le cose con le dita

// ---------- sagoma del Mostrometro (forma A), copiata da hardware/mostrometro.scad ----------
body_w = 110; body_h = 170; r_c = 40; y0 = 10; top_y = y0 + body_h; horn_h = 23;
module sagoma() {
    union() {
        hull() {
            translate([-body_w/2 + r_c, top_y - r_c]) circle(r = r_c);
            translate([ body_w/2 - r_c, top_y - r_c]) circle(r = r_c);
            translate([-body_w/2 + r_c, y0 + r_c]) circle(r = r_c);
            translate([ body_w/2 - r_c, y0 + r_c]) circle(r = r_c);
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
// la sagoma va da x = -71 a 71 e da y = 0 a 203
sag_w = 142; sag_h = 203;

A_w = sag_w + 2 * (gioco + muro);        // vassoio del mostro
A_h = sag_h + 2 * (gioco + muro);
B_w = carta_w + 2 * muro;                // vassoio delle carte, alto come l'altro
B_h = A_h;

module arrotondato(w, h, r = 4) {
    hull() for (x = [r, w - r], y = [r, h - r]) translate([x, y]) circle(r = r);
}

module vassoio_mostro() {
    difference() {
        linear_extrude(alto) arrotondato(A_w, A_h);
        // la sagoma, scavata fino al fondo
        translate([A_w / 2, muro + gioco, fondo])
            linear_extrude(alto) offset(r = gioco) sagoma();
        // due incavi ai lati della testa, per sollevarlo con le dita
        for (s = [-1, 1])
            translate([A_w / 2 + s * (body_w / 2 + 2), muro + gioco + 150, fondo + 6])
                cylinder(r = dito_r, h = alto);
        // scritta sotto, per riconoscerlo
        translate([A_w / 2, A_h / 2, -0.01]) linear_extrude(0.6) mirror([1, 0])
            text("MOSTROMETRO", size = 9, halign = "center", valign = "center", font = "Liberation Sans:style=Bold");
    }
}

module vassoio_carte() {
    passo = (B_h - 2 * carta_l) / 3;     // muri tra i vani (si allargano se il vassoio e' piu' alto)
    difference() {
        linear_extrude(alto) arrotondato(B_w, B_h);
        for (i = [0, 1]) {
            y = passo + i * (carta_l + passo);
            translate([muro, y, fondo]) linear_extrude(alto) arrotondato(carta_w, carta_l, 2);
            // incavo per le dita sul lato lungo esterno, a meta' del vano
            translate([B_w, y + carta_l / 2, fondo + 4]) cylinder(r = dito_r, h = alto);
        }
    }
}

if (parte == "mostro") vassoio_mostro();
else if (parte == "carte") vassoio_carte();
else {
    color("#8a5cf0") vassoio_mostro();
    color("#ffd84a") translate([A_w + 1, 0, 0]) vassoio_carte();
}

echo(str("vassoio mostro: ", A_w, " x ", A_h, " mm; vassoio carte: ", B_w, " x ", B_h, " mm; altezza ", alto, " mm"));
echo(str("tutto l'inserto: ", A_w + 1 + B_w, " x ", A_h, " mm"));
