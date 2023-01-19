//Code tracks continuous pulls and distances, for study of placefields along string length
//After pulling to TARDISTONE rat has a certain percent change of a reward (80% as written)
//If TARDISTONE is not rewarded, when rat continues pulling and reaches TARDISTTWO there is a 
//gauranteed reward
//Code shuffles which trials are rewarded, chance can be controlled by setting x/10 indices to one
//For example, 8/10 indices set to one yields an 80% chance of reward for each pull

#define pinA 40
#define pinB 36
#define buttonIN 48 
#define pelout 26
#define TTL 32
#define CAM 52
#define diameter 2.185 //GREEN WHEEL  Diameter of wheel on rotary encoder (inner diameter)
#define pulses 600.000 //Number of rotary encoder C pins
#include <stdio.h>


/////////////////////////////////////////////////////////
//Values to be set before recording
float tardistOne = 208.0; //Target Pull Distance (cm)
float tardistTwo = 250.0; //Target Pull Distance (cm)
int timeout_limit = 60; //Timeout time in seconds
int percentRewarded[] = {1,1,0,1,1,1,1,1,0,1};
/////////////////////////////////////////////////////////

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
unsigned long timeout_start;
unsigned long timeout_end;
unsigned long tics=0;
int j = 0;


void shuffle() {
/*
for (j=0; j<10;j++){
   Serial.print(percentRewarded[j]);
  }
 Serial.println("First");
 */
   for (int a = 0; a<10; a++){
    int r = random(a,9);
    int temp = percentRewarded[a];
    percentRewarded[a] = percentRewarded[r];
    percentRewarded[r] = temp;  
   }

/*
  for (j=0; j<10;j++){
   Serial.print(percentRewarded[j]);
  }
  Serial.println("Second");
  */
  delay(500);
}

void check() {
   for (int k=1; k<10;k++){
      if (percentRewarded[k] == percentRewarded[k-1]){
         if(percentRewarded[k] == 0){
            shuffle(); 
            for (j=0; j<10;j++){
              //Serial.print(percentRewarded[j]);
                }
            //Serial.println("Three");
     }
  }
}
}

void setup() {
  //randomSeed(analogRead(0));
  //randomSeed(1738);
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
  //Serial.print("Start\n");
  //aLS = digitalRead(pinA);
  //aLS = LOW;
  Serial.print("Elapsed_Seconds, Bout_Distance, Total_Distance, Bout_Time\n");
  
  //Calculates pull distance for each rot encoder rotation trigger, starts timer
  ecirc = 2 * 3.14159 * (diameter/2);
  pd = (ecirc / pulses);   //pulse distance variable
  start=millis();
  timeout_start=millis();
  //percentRewarded = random.shuffle(percentRewarded);
  
  shuffle();
  /*
  shuffle();
  shuffle();
  shuffle();
  shuffle();
  shuffle();
  shuffle();
  shuffle();
  */
  check ();
}


//Feed Rat
//Record length of bout in seconds
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

  //Serial.println(rewardNo);
    rewardNo++;
    if (rewardNo == 10){
      shuffle();
       check();
      rewardNo=0;
    }
  
}

void loop() {
  
  cState = digitalRead(buttonIN);
  if (cState != LOW){
    Serial.println(cState);
    delay(450);
    feed();
  }

  aState = digitalRead(pinA);
 //Detects clockwise rotation

 if ((aState != aLS) && (aState == HIGH)){
      if (digitalRead(pinB) != aState ){  
        
        //Increases distance pulled variable
        dist = dist + pd;
        tics++;
        
        if (tics==30){
            //Sends TTL Trigger to INTAN board
            //digitalWriteFast(TTL, HIGH);
            delayMicroseconds(35);
            //digitalWriteFast(TTL, LOW);
            
            tics=0;
            //Serial.println(dist);
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
    //Serial.println(tics);
    //Serial.println(dist);
    dist=0;
    start=millis();
    timeout_start=millis();
  }


  //If appropriate target distance has been reached:
  //Call Feeding/logging function
  if (dist >= tardistTwo){
      
      Serial.println("HIGH");
      //Serial.println(dist);
     // Serial.println(tardistTwo);
     // Serial.println(tardistOne);
      feed();
    }
  else if ((dist >= tardistOne)&& (percentRewarded[rewardNo] == 1)){
    /*
    Serial.print("REward?");
    Serial.println(percentRewarded[rewardNo]);
    */
      feed();
   
  }


  
}
 
