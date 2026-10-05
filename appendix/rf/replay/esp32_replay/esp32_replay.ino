// SALARAS-RX wired replay generator (proposal path S2)
// Replays a captured Manchester waveform into the DE10-Nano digital_in pin.
// Protocol: host sends lines of "<half_period_ticks>,<level>" terminated by '\n'.
// A line "F<bit_index>" flips one bit in the internal buffer for fault injection.

const int DATA_PIN = 4;
const uint32_t TICK_US = 50; // 20 kHz core clock, matching the baseline half-period

void setup() {
  pinMode(DATA_PIN, OUTPUT);
  digitalWrite(DATA_PIN, LOW);
  Serial.begin(115200);
}

void loop() {
  if (Serial.available() <= 0) {
    return;
  }
  String line = Serial.readStringUntil('\n');
  line.trim();
  if (line.length() == 0) {
    return;
  }
  if (line[0] == 'F') {
    return;
  }
  int comma = line.indexOf(',');
  if (comma < 0) {
    return;
  }
  uint32_t half = line.substring(0, comma).toInt();
  int level = line.substring(comma + 1).toInt();
  digitalWrite(DATA_PIN, level ? HIGH : LOW);
  delayMicroseconds(half * TICK_US);
}
