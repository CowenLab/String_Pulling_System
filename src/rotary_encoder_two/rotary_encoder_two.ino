///////////////////////////////////////////////////////
// Code to sense two rotary encoders simultaneously and send signals 
// out the serial and digital outputs.
//
// Three DIGITAL IO OUTPUTs for each encoder (so 6 total + ground): 
//
// direction (high=cw), tic, full rotation
//
// The serial out is formatted for a csv file that has the... 
//    Code,time(ms), direction, tic, full rotation.
//
// LPD3806 – Optical Rotary Encoder
// If you use a different encoder, you should just need to adjust the two TICS 
// constants for your particular encoder and it should work.
//
// NOTE: Arduinos have 2 interrupts so 2 rot encoders is the max for this code at least.
///////////////////////////////////////////////////////
// Cowen 2022. Ideas from Gianna Jordan. Ideas from these sites...
// https://www.instructables.com/Tutorial-of-Rotary-Encoder-With-Arduino/
// https://www.circuitschools.com/rotary-encoder-with-arduino-in-detail-with-example-codes/
// 
///////////////////////////////////////////////////////

#define encoder1PinA 2 // Needs to be the interrupt pin on the Arduino
#define encoder2PinA 3 // Needs to be the interrupt pin on the Arduino
#define encoder1PinB 4 // Second signal line from encoder
#define encoder2PinB 5 // Second signal line from encoder
#define outPinTic1 6 // Sends a signal for each Tic
#define outPinDirection1 7 // 1 if CW, 0 if CCW
#define outPinFullTic1 8 // Sends a pulse for each full rotation.
#define outPinTic2 9 // Sends a signal for each Tic
#define outPinDirection2 10 // 1 if CW, 0 if CCW
#define outPinFullTic2 11 // Sends a pulse for each full rotation.

#define TTL_DELAY_MS 2 // Duration the TTL is high. Be sure you data acquisition system can handle the delay. The rise time for arduino is in the 40ns range. More than 2ms might interrupt other processes in this code.
#define TICS_PER_SIGNAL 20 // Send a signal every xx Tics. Many acquisition systems have a hard time keeping up with the full tic rate (up to 5000 tics/second) so we only send a signal every xx tics.
#define TICS_PER_ROTATION 600 // Tics for a full 360degrees rotation.

long encoder1Pos = 0;
long encoder2Pos = 0;
int tempEncoder1Pos = 0;
int tempEncoder1PosFullRot = 0;
int tempEncoder2Pos = 0;
int tempEncoder2PosFullRot = 0;

void setup() {
  Serial.begin(115200); // Be sure your com port is set to receive this. The high rate helps if spinning fast perhaps.
  pinMode(encoder1PinA, INPUT_PULLUP);
  pinMode(encoder1PinB, INPUT_PULLUP);
  pinMode(encoder2PinA, INPUT_PULLUP);
  pinMode(encoder2PinB, INPUT_PULLUP);
  
  pinMode(outPinTic1, OUTPUT);
  pinMode(outPinDirection1, OUTPUT);
  pinMode(outPinFullTic1, OUTPUT);
  pinMode(outPinTic2, OUTPUT);
  pinMode(outPinDirection2, OUTPUT);
  pinMode(outPinFullTic2, OUTPUT);

  digitalWrite(outPinTic1, 0);
  digitalWrite(outPinDirection1, 0);
  digitalWrite(outPinFullTic1, 0);
  digitalWrite(outPinTic2, 0);
  digitalWrite(outPinDirection2, 0);
  digitalWrite(outPinFullTic2, 0);
  
  attachInterrupt(0, doEncoder1, RISING); // Must be rising
  attachInterrupt(1, doEncoder2, RISING); // Must be rising
}

long lastValRotary1 = 0;
long lastValRotary2 = 0;
int send_rotary_signal1 = 0;
int send_rotary_signal2 = 0;
int send_full_rot_signal1 = 0;
int send_full_rot_signal2 = 0;

unsigned long currentMillis = 0;

void loop() {
  
  if (send_rotary_signal1 > 0 ) {
    currentMillis = millis();
    send_rotary_signal1 = 0;
    Serial.print("A,"); // for parsing the file later, this can be used to parse out the rows for the rotary encoder in case this code is added to a larger set of code that has different serial outputs interleaved with this output.
    Serial.print(currentMillis);
    digitalWrite(outPinTic1, HIGH);   
    if (encoder1Pos > lastValRotary1) {
      digitalWrite(outPinDirection1, HIGH);
      Serial.print(",1");
    }else if (encoder1Pos < lastValRotary1)  {
      digitalWrite(outPinDirection1, LOW);
      Serial.print(",-1");
    }else {
      // This should rarely if ever happen.
      Serial.print(",0");
    }
    lastValRotary1 = encoder1Pos;
    
    delay(TTL_DELAY_MS); // A possible alternative would be to do this asynchronously.
    digitalWrite(outPinTic1, LOW); // ensures the direction signal and tic overlap.
    
    Serial.print(",");
    Serial.print(encoder1Pos);

    if (send_full_rot_signal1 == 1) {
      send_full_rot_signal1 = 0;
      digitalWrite(outPinFullTic1, HIGH);
      delay(TTL_DELAY_MS);
      digitalWrite(outPinFullTic1, LOW);
      Serial.print(",1");
    }else{
      Serial.print(",0");
    }
    
    Serial.println();

  }


  // Do the same for the second encoder (just change the 1 to a 2 in the vbl names)
  
  if (send_rotary_signal2 > 0 ) {
    currentMillis = millis();
    send_rotary_signal2 = 0;
    Serial.print("B,"); // for parsing the file later, this can be used to parse out the rows for the rotary encoder in case this code is added to a larger set of code that has different serial outputs interleaved with this output.
    Serial.print(currentMillis);
    digitalWrite(outPinTic2, HIGH);   
    if (encoder2Pos > lastValRotary2) {
      digitalWrite(outPinDirection2, HIGH);
      Serial.print(",1");
    }else if (encoder2Pos < lastValRotary2)  {
      digitalWrite(outPinDirection2, LOW);
      Serial.print(",-1");
    }else {
      // This should rarely if ever happen.
      Serial.print(",0");
    }
    lastValRotary2 = encoder2Pos;
    
    delay(TTL_DELAY_MS); // A possible alternative would be to do this asynchronously.
    digitalWrite(outPinTic2, LOW); // ensures the direction signal and tic overlap.
    
    Serial.print(",");
    Serial.print(encoder2Pos);

    if (send_full_rot_signal2 == 1) {
      send_full_rot_signal2 = 0;
      digitalWrite(outPinFullTic2, HIGH);
      delay(TTL_DELAY_MS);
      digitalWrite(outPinFullTic2, LOW);
      Serial.print(",1");
    }else{
      Serial.print(",0");
    }
    
    Serial.println();

  }
  // This is where I would put the asynchronous timer to take the place of delay 
  // if I ever become concerned about delay choking the processing of rotary encoder input.
  // e.g. if cumulative_delay1_ms > TTL_DELAY_MS then turn output pin off.

}

void doEncoder1()
{ // Only runs on rising edge

  if (digitalRead(encoder1PinA) != digitalRead(encoder1PinB))
  {
    encoder1Pos++;
    tempEncoder1Pos++;
    tempEncoder1PosFullRot++;
  } else {
    encoder1Pos--;
    tempEncoder1Pos--;
    tempEncoder1PosFullRot--;
  }

  if (abs(tempEncoder1Pos) >= TICS_PER_SIGNAL) {
    tempEncoder1Pos = 0;
    send_rotary_signal1 = 1;
  }

  if (abs(tempEncoder1PosFullRot) >= TICS_PER_ROTATION) {
    tempEncoder1PosFullRot = 0;
    send_full_rot_signal1 = 1;
  }

}


void doEncoder2()
{ // Only runs on rising edge

  if (digitalRead(encoder2PinA) != digitalRead(encoder2PinB))
  {
    encoder2Pos++;
    tempEncoder2Pos++;
    tempEncoder2PosFullRot++;
  } else {
    encoder2Pos--;
    tempEncoder2Pos--;
    tempEncoder2PosFullRot--;
  }

  if (abs(tempEncoder2Pos) >= TICS_PER_SIGNAL) {
    tempEncoder2Pos = 0;
    send_rotary_signal2 = 1;
  }

  if (abs(tempEncoder2PosFullRot) >= TICS_PER_ROTATION) {
    tempEncoder2PosFullRot = 0;
    send_full_rot_signal2 = 1;
  }

}
