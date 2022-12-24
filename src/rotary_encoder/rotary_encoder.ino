///////////////////////////////////////////////////////
// Code to sense a rotary encoder.
// LPD3806 – Optical Rotary Encoder
//
///////////////////////////////////////////////////////
// Cowen and also code from 
// https://www.instructables.com/Tutorial-of-Rotary-Encoder-With-Arduino/
// https://www.circuitschools.com/rotary-encoder-with-arduino-in-detail-with-example-codes/
///////////////////////////////////////////////////////

#define encoder0PinA 2
#define encoder0PinB 3
#define outPinTic 4
#define outPinDirection 5
#define TTL_DELAY_MS 2
#define TICS_PER_SIGNAL 100

int encoderPos = 0;
int tempEncoderPos = 0;
int ticCountCW = 0;
int ticCountCCW = 0;

void setup() {
  Serial.begin(115200);
  pinMode(encoder0PinA, INPUT_PULLUP);
  pinMode(encoder0PinB, INPUT_PULLUP);
  pinMode(outPinTic, OUTPUT);
  pinMode(outPinDirection, OUTPUT);
  digitalWrite(outPinTic,0);
  digitalWrite(outPinDirection,0);
  attachInterrupt(0, doEncoder, RISING); // Must be rising
}
int lastValRotary;
int valRotary;
int send_signal = 0;
void loop() {
  if (send_signal > 0 ){
    send_signal = 0;
    digitalWrite(outPinTic,HIGH);
    delay(TTL_DELAY_MS);
    digitalWrite(outPinTic,LOW);
    if(valRotary>lastValRotary) {
      digitalWrite(outPinDirection, HIGH);
      Serial.print(" CW ");
      // Serial.print(ticCountCW);
    }
    if(valRotary<lastValRotary)  {
      digitalWrite(outPinDirection, LOW);
      Serial.print(" CCW ");
      //Serial.print(ticCountCCW);
    }
    Serial.print(" re ");
    Serial.print(valRotary);
    Serial.println(" ");
  }
  lastValRotary = valRotary;
}
void doEncoder()
{ // Only runs on rising edge   
    if (digitalRead(encoder0PinA) != digitalRead(encoder0PinB))
    {
      encoderPos++;
      tempEncoderPos++;
      //ticCountCW++;
      //ticCountCCW = 0;
    }else{
      encoderPos--;
      tempEncoderPos--;
      // ticCountCCW++;
      // ticCountCW = 0;
    }
    valRotary = encoderPos;
    if (abs(tempEncoderPos) >= TICS_PER_SIGNAL){
      tempEncoderPos = 0;
      send_signal = 1;
    }
}
