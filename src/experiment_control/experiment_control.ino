///////////////////////////////////////////////////////
// Code to control the String Pulling experiment.
///////////////////////////////////////////////////////
// Cowen 2022. 
///////////////////////////////////////////////////////
#define TICS_FOR_REWARD_1 40 // THIS NEEDS TO BE DEFINED BY THE USER!
#define TICS_FOR_REWARD_2 10 // THIS NEEDS TO BE DEFINED BY THE USER!
#define TICS_PER_FULL_ROT 10 // THIS NEEDS TO BE DEFINED BY THE USER!
//#define CM_PER_TIC 0.5 // THIS NEEDS TO BE DEFINED BY THE USER!
#define NOTE_DURATION 500 // THIS NEEDS TO BE DEFINED BY THE USER!
#define FEEDER_OPEN_TIME_MS 200 // THIS NEEDS TO BE DEFINED BY THE USER!

#define encoder1CWPin 8 // ttl indicating if the encoder was triggered
#define encoder1CCWPin 9 // 
#define encoder2CWPin 10 // 
#define encoder2CCWPin 11 // 

#define feederButtonPin 12 // Triggers Feeder

#define feeder1Pin 14 // 
#define feeder2Pin 15 // 

#define TTL_DELAY_MS 2 // Duration the TTL is high. Be sure you data acquisition system can handle the delay. The rise time for arduino is in the 40ns range. More than 2ms might interrupt other processes in this code.
#define DEBOUNCE_DELAY_MS 40 // For cleaning up the button noise.
#define NOTE1 35 // 
#define NOTE2 39 // 
#define NOTE_HELLO 30 // 

// For MIDI board
#include <SoftwareSerial.h>

SoftwareSerial mySerial(2, 3); // RX, TX

byte note = 0; //The MIDI note value to be played
byte resetMIDI = 4; //Tied to VS1053 Reset line
byte ledPin = 13; //MIDI traffic inidicator
int  instrument = 1;

//
int buttonState = 1;
int ledState = HIGH;         // the current state of the output pin
int lastButtonState = 1;
unsigned long lastDebounceTime = 0;  // the last time the output pin was toggled

// For counting
long encoder1Pos = 0; // Total cumulative tics in a single direction.
long encoder2Pos = 0;

long tempEncoder1Pos = 0; // Resets whenever there is food delivered or if there is a CCW pull. This is like a continuous pull.
long tempEncoder2Pos = 0;


// Store the previous state to detect transitions.
byte encoder1CWPinPrev = 0;
byte encoder1CCWPinPrev = 0;
byte encoder2CWPinPrev = 0;
byte encoder2CCWPinPrev = 0;

byte something_happened = 0;
unsigned long currentMillis = 0;

void setup() {
  Serial.begin(115200); // Be sure your com port is set to receive this. The high rate helps if spinning fast perhaps.
  pinMode(encoder1CWPin, INPUT); 
  pinMode(encoder1CCWPin, INPUT); 
  pinMode(encoder2CWPin, INPUT); 
  pinMode(encoder2CCWPin, INPUT); 
  
  pinMode(feederButtonPin, INPUT_PULLUP);
  pinMode(feeder1Pin, OUTPUT);
  pinMode(feeder2Pin, OUTPUT);

  digitalWrite(encoder1CWPin, LOW);
  digitalWrite(encoder1CCWPin, LOW);
  digitalWrite(encoder2CWPin, LOW);
  digitalWrite(encoder2CCWPin, LOW);

  digitalWrite(feeder1Pin, HIGH);
  //digitalWrite(feeder1Pin, LOW); for testing
  digitalWrite(feeder2Pin, HIGH);
  
  // activateFeeder(feeder1Pin); // This works fine. Somehow it does not work with the button but does work with the encoder

  
  //Setup soft serial for MIDI control
  mySerial.begin(31250);

  //Reset the VS1053
  pinMode(resetMIDI, OUTPUT);
  digitalWrite(resetMIDI, LOW);
  delay(100);
  digitalWrite(resetMIDI, HIGH);
  delay(100);
  talkMIDI(0xB0, 0x07, 120); //0xB0 is channel message, set channel volume to near max (127)
  talkMIDI(0xB0, 0, 0x00); //Default bank GM1
  talkMIDI(0xC0, instrument, 0); //Set instrument number. 0xC0 is a 1 data byte command
  noteOn(0, NOTE_HELLO, 60);
  delay(NOTE_DURATION);

  //Turn off the note with a given off/release velocity
  noteOff(0, NOTE_HELLO, 60);
  delay(50);

  Serial.println("completed setup.");
}

void loop() {
  updateEncoders();
  checkDistance(); // checks to see if enough distance pulled for reward.
  checkButton();
  // checkSensors(); would go here once it is created.
}


void updateEncoders(){
   if (encoder1CWPinPrev == 0 && digitalRead(encoder1CWPin) == 1){
      encoder1Pos++;
      tempEncoder1Pos++;
      tempEncoder2Pos = 0;
      
      Serial.print("E1,");
      Serial.print(currentMillis);
      Serial.print(",1,");
      Serial.print(encoder1Pos);
      Serial.print(",");
      Serial.println(tempEncoder1Pos);
  }
  encoder1CWPinPrev = digitalRead(encoder1CWPin);

  if (encoder1CCWPinPrev == 0 && digitalRead(encoder1CCWPin) == 1){
      encoder1Pos--;
      tempEncoder1Pos = 0;
      tempEncoder2Pos = 0;
      
      Serial.print("E1,");
      Serial.print(currentMillis);
      Serial.print(",-1,");
      Serial.print(encoder1Pos);
      Serial.print(",");
      Serial.println(tempEncoder1Pos);  
  }
  encoder1CCWPinPrev = digitalRead(encoder1CCWPin);

  if (encoder2CWPinPrev == 0 && digitalRead(encoder2CWPin) == 1){
      encoder2Pos++;
      tempEncoder2Pos++;
      Serial.print("E2,");
      Serial.print(currentMillis);
      Serial.print(",1,");
      Serial.print(encoder2Pos);
      Serial.print(",");
      Serial.println(tempEncoder2Pos);      
  }
  encoder2CWPinPrev = digitalRead(encoder2CWPin);

  if (encoder2CCWPinPrev == 0 && digitalRead(encoder2CCWPin) == 1){
      encoder2Pos--;
      tempEncoder1Pos = 0;
      tempEncoder2Pos = 0;
      Serial.print("E2,");
      Serial.print(currentMillis);
      Serial.print(",-1,");
      Serial.print(encoder2Pos);
      Serial.print(",");
      Serial.println(tempEncoder2Pos);      
  }
  encoder2CCWPinPrev = digitalRead(encoder2CCWPin);
 
}

void checkDistance(){
  if (tempEncoder1Pos >= TICS_FOR_REWARD_1){
      activateFeeder(feeder1Pin);
  }
  
  if (tempEncoder2Pos >= TICS_FOR_REWARD_2){
      activateFeeder(feeder2Pin);
  }
  
}

void checkButton(){
  int reading = digitalRead(feederButtonPin);
  if (reading != lastButtonState) {
    // reset the debouncing timer
    lastDebounceTime = millis();
  }

  if ((millis() - lastDebounceTime) > DEBOUNCE_DELAY_MS) {
    // whatever the reading is at, it's been there for longer than the debounce
    // delay, so take it as the actual current state:
  
    // if the button state has changed:
    if (reading != buttonState) {
      buttonState = reading;
  
      // only toggle the LED if the new button state is HIGH
      if (buttonState == LOW) {
        // DO STUFF HERE
        activateFeeder(feeder1Pin);
        Serial.println("Pressed Button, FEEDING");
      }
    }
  }
  lastButtonState = reading;
  
}

void activateFeeder(byte feederpin){
  digitalWrite(feederpin, LOW); // pulls to ground, completing the circuit.
  delay(FEEDER_OPEN_TIME_MS);
  digitalWrite(feederpin, HIGH);
  
  tempEncoder1Pos = 0;
  tempEncoder2Pos = 0;
  
  ledState = !ledState;
  noteOn(0, NOTE2, 60);
  delay(NOTE_DURATION);
  
  //Turn off the note with a given off/release velocity
  noteOff(0, NOTE2, 60);
  delay(50);

  Serial.print("FEED_");
  Serial.println(feederpin);
}


void noteOn(byte channel, byte note, byte attack_velocity) {
  talkMIDI( (0x90 | channel), note, attack_velocity);
}

//Send a MIDI note-off message.  Like releasing a piano key
void noteOff(byte channel, byte note, byte release_velocity) {
  talkMIDI( (0x80 | channel), note, release_velocity);
}

//Plays a MIDI note. Doesn't check to see that cmd is greater than 127, or that data values are less than 127
void talkMIDI(byte cmd, byte data1, byte data2) {
  digitalWrite(ledPin, HIGH);
  mySerial.write(cmd);
  mySerial.write(data1);

  //Some commands only have one data byte. All cmds less than 0xBn have 2 data bytes 
  //(sort of: http://253.ccarh.org/handout/midiprotocol/)
  if( (cmd & 0xF0) <= 0xB0)
    mySerial.write(data2);

  digitalWrite(ledPin, LOW);
}
