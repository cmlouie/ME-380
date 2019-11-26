#include <Wire.h>
#include <Adafruit_PWMServoDriver.h>

Adafruit_PWMServoDriver pwm = Adafruit_PWMServoDriver();

int motorAngles[6] = {0, 0 , 0 , 0 , 0, 0};

const float SERVOMIN = 300; // 'minimum' pulse length count (out of 4096)
const float SERVOMAX = 500; // 'maximum' pulse length count (out of 4096)
const float SERVOMIDVAL = 400;
const float SERVOMID[6] = {SERVOMIN, 355, 355, 425, 350, 300}; // 'mid' pulse length count (out of 4096)

const int degreeTolerance = 1;
uint8_t servonum = 0;

void setup() {
  Serial1.begin(9600);
  Serial.begin(9600);
  pwm.begin();
  pwm.setPWMFreq(60);
  
  delay(50);

  for (int i = 0; i <6; i++) {
    if (i == 0 || i == 2 || i == 4) {
      pwm.setPWM(i, 0, SERVOMID[i] - 50);
    }else {
      pwm.setPWM(i, 0, SERVOMID[i] + 50);
    }
  }

  delay(500);

  for (int i=0; i<6; i++) {
    Serial.println(i);
    pwm.setPWM(i, 0, SERVOMID[i]);
  }
}

void loop() {
  readAngles();
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
      while (Serial1.available() > 0 && shouldRead && retry < 10000) {
        retry++;
        rc = Serial1.read();
        if (rc == startMarker) {
          shouldRead = false;
          processed = true;
        }
      }

      if (retry >= 10000 || !processed) {
        Serial.println("Exiting after retry");
        return;
      }
      
      Serial.println("[");
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
      Serial.println("]");
    }
}

void moveMotors() {
  for (int i = 0; i < 6; i++) {
    
  }
}
