/*
 * Tracks tics and outputs distance. Only resets distance when >= tardist and laser has been tripped. 
 * 
 */

#define pinA 40
#define pinB 36
#define buttonIN 48 
#define pelout 26 
#define TTL 32
#define clockPin 22
#define signalPin 24
#define CAM 52
#define diameter 2.185 //GREEN WHEEL  Diameter of wheel on rotary encoder (inner diameter)
#define pulses 600.0 //Number of rotary encoder C pins
#include <stdio.h>
#include <digitalWriteFast.h>
//#define diameter 2.185 //cm
//#define diameter 2.525 //BLACK WHEEL
#define laser_pin 13 // pin for laser 1


/////////////////////////////////////////////////////////
//Values to be set before recording
#define feed_time 110 // 120 for EXPERIMENT && 10000 for CLEANING ONLY 
int tardist = 250; //Target Pull Distance (cm)
int probedist = 312; // Longer target pull distance for probe trials
int randomPercent = 20; // 20 for 20%. 50 for 50%. 
bool randomMode = false; // true if you want to have random mode after a certain amt of times pulled
int timesPulledThreshold = 10; // the number of times youwant rat to pull string at default amt before doing random distances
/////////////////////////////////////////////////////////


int timesPulled = 0;
int aState;
int bState;
int cState;
int aLS;
int bLS;
int rewardNo=0;
float pd;
float dist;
float ecirc;
float total_dist=0;
float BoutLength;
long chance_var;
unsigned long start;
unsigned long current;
unsigned long timeout_end;
unsigned long tics=0;
long randNumber;
int randomRange = 100/randomPercent;
bool laser_off;
int state = 1; // 0 is not counting distance since rat hasn't eaten yet. 1 is counting distance.
bool fed_already = false;

void setup() {
  //initialize rot encoder pins as input and pellet dispenser + INTAN TTL pins as output
  pinMode (pinA, INPUT);
  pinMode (pinB, INPUT);
  pinMode (buttonIN, INPUT);
  pinMode(pelout, OUTPUT);
  pinMode(CAM, OUTPUT);
  pinMode(TTL, OUTPUT);
  pinMode(signalPin, OUTPUT);
  pinMode(clockPin, OUTPUT);
  digitalWrite(pelout, LOW); // Is high open or closd
  digitalWrite(CAM, HIGH);
  pinMode (laser_pin, INPUT);
  Serial.begin(115200); //was 9600
  // print headers to file
  //Serial.println("Time,signal,distance,target distance,times pulled,random range,random number");
  Serial.println("Time,signal");
  //Calculates pull distance for each rot encoder rotation trigger, starts timer
  ecirc = 2.0 * 3.14159 * (diameter/2);
  pd = (ecirc / pulses);   //pulse distance variable
  start=millis(); 
}


/** 
 *  This is the main function of this program which tracks if the laser has been 
 *  tripped as well as tracks rotations of the rotary encoder. 
 *  Includes manual button press for feed and tracks rotary encoder for distance
 * Once the threshold distance is passed then feed is dispensed via the feed
 * function. 
 * 
*/
void loop() {

  // This allows user to press the button to manually dispense feed
  cState = digitalRead(buttonIN);
  if (cState != LOW){
    feed();
  }

  // Prints for laser on and when laser is off
  laser_off = digitalRead(laser_pin);
  if (!laser_off) {
    printData(2);
    while (!laser_off){
     // Here so l print isn't all the time
     laser_off = digitalRead(laser_pin);
    }
    printData(3);
    //resets distance once >= tardist AND laser has been tripped
    if (dist >= tardist){
      dist = 0;
      fed_already = false;
    }
  }

  //increments distance variable
  aState = digitalRead(pinA);
  if ((aState != aLS) && (aState == HIGH)){
      if (digitalRead(pinB) != aState ){            
        dist = dist + pd;
        tics++;
        if (tics==30){
            //Sends TTL Trigger to INTAN board every 30 tiks of rotary encode. 
            Serial.print(millis()); Serial.print(",");  Serial.println("t");
            //600 / 30 => every 20th turn of the encode
            digitalWriteFast(TTL, HIGH);
            delayMicroseconds(35);
            digitalWriteFast(TTL, LOW);
            tics=0;
        }
      }  
   }
   aLS = aState;
  
  // If appropriate target distance has been reached then the rat is fed
  if (dist >= tardist){
    
    //Send data point of time of  feeding
    if (!fed_already) {
      feed();
      fed_already = true;
      timesPulled = timesPulled + 1;
      if (randomMode && timesPulled > timesPulledThreshold){
        checkRandom(); 
      }
    }
  } 
}

// function to dispense food
void feed(){
  printData(1);
  digitalWrite(pelout, HIGH);
  delay(feed_time); //1.6 ml/s is time for .2ml reward
  digitalWrite(pelout, LOW);
}

void checkRandom(){
  // 1/20 times distance will be 300cm
  randNumber = random(randomRange);
  if (randNumber == 0){
    tardist = probedist; 
  }
  else {
    tardist = 208; 
    }
}

//TODO: Make clock signal so we can differentiate betweeen different TTL pulses
void printData(int message_type){
  int sendingSignal[4] = {0, 0, 0, 0};
   switch (message_type) {
    case 1:  // your hand is on the sensor
      sendingSignal[3] = 1; // 0 0 0 1
      break;
    case 2:  // your hand is close to the sensor
      sendingSignal[2] = 1; // 0 0 1 0
      break;
    case 3:  // your hand is close to the sensor
      sendingSignal[2] = 1; 
      sendingSignal[3] = 1; // 0 0 1 1
      break;
  }

  // Syncs short clk and signal   
  for (byte i = 0; i < 3; i = i+1){
    if (sendingSignal[i] == 1) {
      digitalWriteFast(signalPin, HIGH);
    }
    else{
      digitalWriteFast(signalPin, LOW);
    }
    digitalWriteFast(clockPin, HIGH);
    delayMicroseconds(35);
    digitalWriteFast(signalPin, LOW);
    digitalWriteFast(clockPin, LOW);
    delayMicroseconds(35);
  }
  //Serial.print(millis());
  //Serial.print(",");  Serial.print(message_type);
  /**
  Serial.print(",");  Serial.print(dist);
  Serial.print(",");  Serial.print(tardist);
  Serial.print(",");  Serial.print(timesPulled);
  Serial.print(",");  Serial.print(randomRange);
  Serial.print(",");  Serial.print(randNumber);
   */
  Serial.println();
  
  }
/*
192 399 597 789
207
198  
192

203 cm for 1 loop = 197.25 tics 
4.9 turns for 1 meter
1 meteer = 971.7 tics = 972
1.03 cm / tic
*/
