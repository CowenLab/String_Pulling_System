#Code to track pulls and reward continuous pulls of varrying distances
#For pins, reference Mega Circuit Diagram in documentation


#define pinA 40
#define pinB 36
#define buttonIN 48
#define pelout 26
#define TTL 32
#define CAM 52
#define diameter 2.185 //GREEN WHEEL  Diameter of wheel on rotary encoder (inner diameter)
#define pulses 600.000 //Number of rotary encoder C pins
#include <stdio.h>
#include <digitalWriteFast.h>
//#define diameter 2.525 //BLACK WHEEL

//////////////////////////////////////////////////////////
//Array of target distances - to be set before recording
int tardist[]={200,200,200,200,200,200,200,200,200,200,200,200,200,200,200};
int timeout_limit = 60; //Timeout time in seconds
//////////////////////////////////////////////////////////




int aState;
int bState;
int cState;
int aLS;
int bLS;
int rewardNo=0;
const int targets = sizeof(tardist)/sizeof(tardist[0]);
float pd;
float dist;
float ecirc;
float total_dist=0;
float BoutLength;
long chance_var;
unsigned long start;
unsigned long current;
unsigned long timeout_start;
unsigned long timeout_end;
unsigned long tics=0;




void setup() {
  //initialize rot encoder pins as input and pellet dispenser + INTAN TTL pins as output
  pinMode (pinA, INPUT);
  pinMode (pinB, INPUT);
  pinMode (buttonIN, INPUT);
  pinMode(pelout, OUTPUT);
  pinMode(CAM, OUTPUT);
  pinMode(TTL, OUTPUT);
  digitalWrite(pelout, HIGH);
  digitalWrite(CAM, HIGH);
  Serial.begin(9600); //was 9600
  Serial.print("Elapsed_Seconds, Bout_Distance, Total_Distance, Bout_Time\n");
  
  //Calculates pull distance for each rot encoder rotation trigger, starts timer
  ecirc = 2 * 3.14159 * (diameter/2);
  pd = (ecirc / pulses);   //pulse distance variable
  start=millis();
  timeout_start=millis();

}


//Record length of bout in seconds
//Feed Rat
//Update next target distance
//Reset bout distance pulled and bout timer
void feed(){
  BoutLength = (millis()-start)/1000;
  //Low voltage triggers pellet dispenser
  digitalWrite(pelout, HIGH);


  //update total distance pulled
  total_dist+=dist;
  
  //Logging information
  Serial.print(millis()/1000);
  Serial.print(',');
  Serial.print(dist);
  Serial.print(',');
  Serial.print(total_dist);
  Serial.print(',');
  Serial.print(BoutLength);
  Serial.print('\n');
  

  //testing flow
  //1.6 ml/s
  //time for .2ml reward
  delay(125);
  digitalWrite(pelout, LOW);
  
  dist = 0;
  start = millis(); 
  timeout_start=millis();
  
}

void loop() {
  
  
  cState = digitalRead(buttonIN);
  if (cState != LOW){
    Serial.println(cState);
    delay(450);
    feed();
  }

  aState = digitalRead(pinA);
 //Detects rotation
 if ((aState != aLS) && (aState == HIGH)){
      if (digitalRead(pinB) != aState ){  
        
        //Increases distance pulled variable
        dist = dist + pd;
        tics++;
        

        if (tics==30){
            //Sends TTL Trigger to INTAN board
            digitalWriteFast(TTL, HIGH);
            delayMicroseconds(35);
            digitalWriteFast(TTL, LOW);
            tics=0;
        }
        
       timeout_start=millis(); 
      }
  }
   aLS = aState;
  //Checks time passed since last target distance reached
  //Reset pull distance after period of inactivity of length specified in TIMEOUT variable
  timeout_end = millis()-timeout_start;
  if (timeout_end >= timeout_limit * 1000){
    //Serial.println("Taking too long, resetting timer \n");
    dist=0;
    start=millis();
    timeout_start=millis();
  }


  //If appropriate target distance has been reached:
  //Call feed/logging function
  if (dist >= tardist[rewardNo]){
    feed();
    if (rewardNo != targets){
      rewardNo++;
    }
  }
}
 
