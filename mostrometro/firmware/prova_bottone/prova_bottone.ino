// PROVA DEL BOTTONE: carica questo programma per controllare che le saldature del bottone siano a posto,
// PRIMA di montare tutto. Non serve nient'altro: ne' schermo ne' batteria.
//
// Il bottone grosso e' collegato tra la piazzola "1" (GPIO1) e la piazzola "G" (massa).
// Apri il Monitor Seriale (Strumenti > Monitor Seriale, velocita' 115200): ogni volta che premi il bottone
// deve comparire "PREMUTO!". Se non compare niente, una saldatura non e' buona (vedi la guida, "Se qualcosa non va").

#define PIN_BOTTONE 1

void setup() {
  Serial.begin(115200);
  pinMode(PIN_BOTTONE, INPUT_PULLUP);       // il pin sta a "alto" da solo; premendo il bottone va a massa
  delay(1500);
  Serial.println("Prova del bottone: premilo!");
}

void loop() {
  static bool prima = false;
  bool premuto = digitalRead(PIN_BOTTONE) == LOW;
  if (premuto && !prima) Serial.println("PREMUTO!");
  if (!premuto && prima) Serial.println("rilasciato");
  prima = premuto;
  delay(20);
}
