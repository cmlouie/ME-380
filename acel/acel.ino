#include <Adafruit_PWMServoDriver.h>
Adafruit_PWMServoDriver pwm = Adafruit_PWMServoDriver();

int actualPulse[6] = {290, 365, 365, 405, 350, 300 };
int motorAngles[6] = {0, 0, 0, 0, 0, 0};
int increment = 0;
int incrementMove = 0;

const int SERVOMID[6] = {290, 365, 355, 410, 350, 300 };
const int SERVOMIN[6] = {170, 245, 205, 255, 230, 170 };
const int SERVOMAX[6] = {450, 505, 505, 605, 490, 440 };

const int PULSE_PER_DEGREE = 2;
const int pulseTolerance = 7;
uint8_t servonum = 0;
int val[6] = {0, 0 ,0 ,0 ,0 ,0};

void setup() {
  Serial1.begin(9600);
  Serial.begin(9600);
  pwm.begin();
  pwm.setPWMFreq(60);
  
  delay(50);
  for (int i = 0; i <6; i++) {
    pwm.setPWM(i, 0, 0);
  }
  delay(250);

  for (int i=0; i<6; i++) {
    pwm.setPWM(i, 0, SERVOMID[i]);
  }
  
  delay(500);
}

void loop() {
  incrementMove++;
  readAngles();

  if (incrementMove == 5) {
      moveMotors();
      incrementMove = 0;
  }
}

void readAngles() {
    static boolean recvInProgress = false;
    static byte ndx = 0;
    char startMarker = '<';
    char endMarker = '>';
    char rc;
    bool shouldRead = true;
    bool processed = false;

    if (Serial1.available()) {
      int retry = 0;
      while (Serial1.available() > 0 && shouldRead) {
        retry++;
        rc = Serial1.read();
        if (rc == startMarker) {
          shouldRead = false;
          processed = true;
        }
      }

      if (retry >= 10000 || !processed) {
        return;
      }
      
      //Serial.println("[");
      for (int i = 0; i < 6; i ++) {
        motorAngles[i] = 0;
        for (int j = 0; j < 3; j++) {
          int retry = 0;
          while(Serial1.available() <= 0 && retry < 10000) {
            retry++;
          }

          if (retry >= 10000) {
            Serial.println("Exiting after retry");
            return;
          }
          char rc = Serial1.read() - 48;
          motorAngles[i] += (rc * pow(10, 2-j));
        }
        if (motorAngles[i] > 180) {
          motorAngles[i] = motorAngles[i] - 360;
        }
        Serial.println(motorAngles[i], DEC);
      }
      Serial1.read(); // Read one more to remove the endMarker
      //Serial.println("]");
    } else {
      //Serial.println("No data");
    }
}

void moveMotors() {
  for (int i = 0; i < 6; i++) {
    val[i] = SERVOMID[i];
    // 0 2 4
    if (i % 2 == 0) {
      if (motorAngles[i] >= 0) {
        val[i] = SERVOMID[i] - motorAngles[i]*PULSE_PER_DEGREE;
      } else {
        val[i] = SERVOMID[i] - motorAngles[i]*PULSE_PER_DEGREE;
      }
    // 1 3 5
    } else {
      if (motorAngles[i] >= 0) {
        val[i] = SERVOMID[i] + motorAngles[i]*PULSE_PER_DEGREE;
      } else {
        val[i] = SERVOMID[i] + motorAngles[i]*PULSE_PER_DEGREE;
      }
    }
    pwm.setPWM(i, 0, max(min(val[i],SERVOMAX[i]),SERVOMIN[i]));
  }
}
