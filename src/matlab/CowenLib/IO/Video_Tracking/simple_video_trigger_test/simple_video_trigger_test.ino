int CAMERA_FRAME_SIGNALOUT_PIN = 13;
int BEHAVIOR_SIG_OUT_PIN = 8;
int BEHAVIOR_SYNC_OUT_PIN = 9; 

volatile uint8_t frameup = 0;

void setup() {
  // put your setup code here, to run once:
  pinMode(CAMERA_FRAME_SIGNALOUT_PIN, OUTPUT);
  pinMode(BEHAVIOR_SIG_OUT_PIN, OUTPUT);
  pinMode(BEHAVIOR_SYNC_OUT_PIN, OUTPUT);
}

void loop() {
  // put your main code here, to run repeatedly:
  delay(100);
  frameup = !digitalRead(CAMERA_FRAME_SIGNALOUT_PIN);
  digitalWrite(BEHAVIOR_SYNC_OUT_PIN, HIGH);
  digitalWrite(BEHAVIOR_SIG_OUT_PIN, HIGH);

  digitalWrite(CAMERA_FRAME_SIGNALOUT_PIN, frameup);
  delay(100);
  digitalWrite(BEHAVIOR_SIG_OUT_PIN, LOW);
  digitalWrite(BEHAVIOR_SYNC_OUT_PIN, LOW);

}
