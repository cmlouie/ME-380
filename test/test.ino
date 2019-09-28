<<<<<<< HEAD
#include <Servo.h>

int ledPin = 13;
int servoPin = 8;
int toggle = 0;
=======
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
>>>>>>> 1b0856f688d2e64ad1749f7ca12d5eef312d0dd8

Servo servo1;

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

<<<<<<< HEAD
void setup()
{
    Serial.begin(9600); // opens serial port, sets data rate to 9600 bps
    Serial1.begin(9600);
    
//    Serial.setTimeout(1); // sets the timeout time when reading bytes. If this time passes and the arduino is still reading we stop reading bytes
//    Serial1.setTimeout(1); // deafault value is 1000ms
    
    Serial.println("Running example: Deans list!");
    pinMode(ledPin, OUTPUT);

    servo1.attach(servoPin);
    servo1.write(90);
=======
  Serial.begin(9600);
  Serial1.begin(9600);

  Serial.print("Welcome to the Otto Cycle Calculator!");
>>>>>>> 1b0856f688d2e64ad1749f7ca12d5eef312d0dd8
}

void loop() {

  stepper1.move(distance);
  stepper1.run();

  if (Serial1.available()) {
<<<<<<< HEAD
    int num = Serial1.read();
    if (num == 1) {
      Serial.println("On");
      digitalWrite(ledPin, HIGH);
    }
    else if (num == 0) {
      Serial.println("Off");
      digitalWrite(ledPin, LOW);
    }
//    else {
//      servo1.write(Serial1.read());
//    }
  }
  
  if (Serial.available()) {
    Serial1.write(Serial.read());
  }
=======
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
  
>>>>>>> 1b0856f688d2e64ad1749f7ca12d5eef312d0dd8
}
