///////////////////////////////////////////////////////
// Code to sense a rotary encoder and send signals out the serial and digital outputs.
//
// LPD3806 – Optical Rotary Encoder
// If you use a different encoder, you should just need to adjust the two TICS 
// constants for your particular encoder and it should work.
//
// The serial out is formatted for a csv file that has the... 
//    time(ms), direction, tic, full rotation.
///////////////////////////////////////////////////////
// Cowen 2022 and also help from
// https://www.instructables.com/Tutorial-of-Rotary-Encoder-With-Arduino/
// https://www.circuitschools.com/rotary-encoder-with-arduino-in-detail-with-example-codes/
///////////////////////////////////////////////////////

#define encoderPinA 2 // Needs to be the interrupt pin on the Arduino
#define encoderPinB 3 // Second signal line from encoder
#define outPinTic 4 // Sends a signal for each Tic
#define outPinDirection 5 // 1 if CW, 0 if CCW
#define outPinFullTic 6 // Sends a pulse for each full rotation.
#define TTL_DELAY_MS 2 // Duration the TTL is high. Be sure you data acquisition system can handle the delay.
#define TICS_PER_SIGNAL 100 // Send a signal every xx Tics. Many acquisition systems have a hard time keeping up with the full tic rate (up to 5000 tics/second) so we only send a signal every xx tics.
#define TICS_PER_ROTATION 600 // Tics for a full 360degrees rotation.

long encoderPos = 0;
int tempEncoderPos = 0;
int tempEncoderPosFullRot = 0;
int ticCountCW = 0;
int ticCountCCW = 0;

void setup() {
  Serial.begin(115200); // Be sure your com port is set to receive this. The high rate helps if spinning fast perhaps.
  pinMode(encoderPinA, INPUT_PULLUP);
  pinMode(encoderPinB, INPUT_PULLUP);
  pinMode(outPinTic, OUTPUT);
  pinMode(outPinDirection, OUTPUT);
  digitalWrite(outPinTic, 0);
  digitalWrite(outPinDirection, 0);
  attachInterrupt(0, doEncoder, RISING); // Must be rising
}

long lastValRotary;
int send_signal = 0;
int send_full_rot_signal = 0;
unsigned long currentMillis = 0;

void loop() {
  
  if (send_signal > 0 ) {
    currentMillis = millis();
    send_signal = 0;
    digitalWrite(outPinTic, HIGH);
    Serial.print(currentMillis);
    
    if (encoderPos > lastValRotary) {
      digitalWrite(outPinDirection, HIGH);
      Serial.print(",1");
    }else if (encoderPos < lastValRotary)  {
      digitalWrite(outPinDirection, LOW);
      Serial.print(",-1");
    }else {
      // This should rarely if ever happen.
      Serial.print(",0");
    }
    lastValRotary = encoderPos;
    
    delay(TTL_DELAY_MS); // A possible alternative would be to do this asynchronously.
    digitalWrite(outPinTic, LOW); // ensures the direction signal and tic overlap.
    
    Serial.print(",");
    Serial.print(encoderPos);

    if (send_full_rot_signal == 1) {
      send_full_rot_signal = 0;
      digitalWrite(outPinFullTic, HIGH);
      delay(TTL_DELAY_MS);
      digitalWrite(outPinFullTic, LOW);
      Serial.print(",1");
    }else{
      Serial.print(",0");
    }
    
    Serial.println();

  }

}

void doEncoder()
{ // Only runs on rising edge

  if (digitalRead(encoderPinA) != digitalRead(encoderPinB))
  {
    encoderPos++;
    tempEncoderPos++;
    tempEncoderPosFullRot++;
    //ticCountCW++;
    //ticCountCCW = 0;
  } else {
    encoderPos--;
    tempEncoderPos--;
    tempEncoderPosFullRot--;
    // ticCountCCW++;
    // ticCountCW = 0;
  }

  if (abs(tempEncoderPos) >= TICS_PER_SIGNAL) {
    tempEncoderPos = 0;
    send_signal = 1;
  }

  if (abs(tempEncoderPosFullRot) >= TICS_PER_ROTATION) {
    tempEncoderPosFullRot = 0;
    send_full_rot_signal = 1;
  }

}
