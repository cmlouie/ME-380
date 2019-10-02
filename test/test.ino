#include <AccelStepper.h>
#define HALFSTEP 8

#define mtrPin1  22 
#define mtrPin2  23
#define mtrPin3  24
#define mtrPin4  25

#define mtrPin5  26 
#define mtrPin6  27
#define mtrPin7  28
#define mtrPin8  29 

#define mtrPin9  30 
#define mtrPin10  31
#define mtrPin11  32
#define mtrPin12  33 

#define mtrPin13  34 
#define mtrPin14  35
#define mtrPin15  36
#define mtrPin16  37 

#define mtrPin17  38 
#define mtrPin18  39
#define mtrPin19  40
#define mtrPin20  41 

#define mtrPin21  42 
#define mtrPin22  43
#define mtrPin23  44
#define mtrPin24  45 

int distance = 2000;
int togglePower = 100;
int toggleDirection = 1;
int newVal = 0;
int oldHello = 0;

const byte numChars = 20;
char receivedChars[numChars];
boolean newData = false;

AccelStepper stepper1(HALFSTEP, mtrPin1, mtrPin3, mtrPin2, mtrPin4);
AccelStepper stepper2(HALFSTEP, mtrPin5, mtrPin6, mtrPin7, mtrPin8);
AccelStepper stepper3(HALFSTEP, mtrPin9, mtrPin10, mtrPin11, mtrPin12);
AccelStepper stepper4(HALFSTEP, mtrPin13, mtrPin14, mtrPin15, mtrPin16);
AccelStepper stepper5(HALFSTEP, mtrPin17, mtrPin18, mtrPin19, mtrPin20);
AccelStepper stepper6(HALFSTEP, mtrPin21, mtrPin22, mtrPin23, mtrPin24);

/** 
 *  Serial1 is pins 19 RX and 18 TX
 *  Bluetooth RX goes to Arduino TX
 *  Bluetooth TX goes to Arduino RX
 * 
 */
void setup() {
  stepper1.setMaxSpeed(2000.0);
  stepper1.setAcceleration(8000.0);

  stepper2.setMaxSpeed(2000.0);
  stepper2.setAcceleration(8000.0);

  stepper3.setMaxSpeed(2000.0);
  stepper3.setAcceleration(8000.0);

  stepper4.setMaxSpeed(2000.0);
  stepper4.setAcceleration(8000.0);

  stepper5.setMaxSpeed(2000.0);
  stepper5.setAcceleration(8000.0);

  stepper6.setMaxSpeed(2000.0);
  stepper6.setAcceleration(8000.0);

  Serial.begin(9600);
  Serial1.begin(9600);

  Serial.print("Welcome to the Otto Cycle Calculator!");
}

void loop() {
  recvWithStartEndMarkers();
  moveMotors();
}

void recvWithStartEndMarkers() {
    static boolean recvInProgress = false;
    static byte ndx = 0;
    char startMarker = '<';
    char endMarker = '>';
    char rc;
 
    while (Serial1.available() > 0 && newData == false) {
        rc = Serial1.read();

        if (recvInProgress == true) {
            if (rc != endMarker) {
                receivedChars[ndx] = rc - 48;
                ndx++;
                if (ndx >= numChars) {
                    ndx = numChars - 1;
                }
            }
            else {
                receivedChars[ndx] = '\0'; // terminate the string
                recvInProgress = false;
                ndx = 0;
                newData = true;
            }
        }

        else if (rc == startMarker) {
            recvInProgress = true;
        }
    }
}

void moveMotors() {
    if (newData == false) {
      return;
    }

    for (int i = 0; i < 6; i++) {
      int motorDegree = 0;
      for (int j = 0; j < 3; j ++) {
        motorDegree += receivedChars[3 * i + j] * pow(10, 2 -j );
      }
      
    }
}
   
