#include <AccelStepper.h>
#define HALFSTEP 8

#define mtrPin1  9 
#define mtrPin2  10 
#define mtrPin3  11
#define mtrPin4  12 

int maxDistance = 2000;
int distance = 2000;
int toggleDirection = 1;
int togglePower = 100;

AccelStepper stepper1(HALFSTEP, mtrPin1, mtrPin3, mtrPin2, mtrPin4);

/** 
 *  Serial1 is pins 19 RX and 18 TX
 *  Bluetooth RX goes to Arduino TX
 *  Bluetooth TX goes to Arduino RX
 * 
 */
void setup() {
  stepper1.setMaxSpeed(2000.0);
  stepper1.setAcceleration(8000.0);
  stepper1.setSpeed(2000);
  stepper1.moveTo(distance);

  Serial.begin(9600);
  Serial1.begin(9600);

  Serial.print("Welcome to the Otto Cycle Calculator!");
}

void loop() {

  stepper1.move(distance);
  stepper1.run();

  if (Serial1.available()) {
    int val = Serial1.read();
    int directionL = val / 100;
    int power = val % 100;
    
    if (directionL == 1 && toggleDirection != 1) {
      distance = 2000;
      toggleDirection = 1;
    } else if (directionL == 2 && toggleDirection != 2) {
      distance = -2000;
      toggleDirection = 2;
    }

    if (togglePower != power) {
      if (distance > 0) {
        stepper1.setSpeed(maxDistance * 0.1 * power);
        stepper1.setMaxSpeed(maxDistance * 0.1 * power);
      } else {
        stepper1.setSpeed(-(maxDistance) * 0.1 * power);
        stepper1.setMaxSpeed(-(maxDistance) * 0.1 * power);
      }
      togglePower = power;
    }
  }
}
