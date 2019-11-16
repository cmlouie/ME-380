//#include "I2Cdev.h"
//
//#include "MPU6050_6Axis_MotionApps20.h"
//
//#if I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE
//    #include "Wire.h"
//#endif
//
//MPU6050 mpu;
//
//#define OUTPUT_READABLE_YAWPITCHROLL
//#define LED_PIN 13 // (Arduino is 13, Teensy is 11, Teensy++ is 6)
//
//bool blinkState = false;
//bool dmpReady = false;  // set true if DMP init was successful
//uint8_t mpuIntStatus;   // holds actual interrupt status byte from MPU
//uint8_t devStatus;      // return status after each device operation (0 = success, !0 = error)
//uint16_t packetSize;    // expected DMP packet size (default is 42 bytes)
//uint16_t fifoCount;     // count of all bytes currently in FIFO
//uint8_t fifoBuffer[64]; // FIFO storage buffer
//
//
//// orientation/motion vars
//Quaternion q;           // [w, x, y, z]         quaternion container
//VectorInt16 aa;         // [x, y, z]            accel sensor measurements
//VectorInt16 aaReal;     // [x, y, z]            gravity-free accel sensor measurements
//VectorInt16 aaWorld;    // [x, y, z]            world-frame accel sensor measurements
//VectorFloat gravity;    // [x, y, z]            gravity vector
//float euler[3];         // [psi, theta, phi]    Euler angle container
//float ypr[3];           // [yaw, pitch, roll]   yaw/pitch/roll container and gravity vector
//
//uint8_t teapotPacket[14] = { '$', 0x02, 0,0, 0,0, 0,0, 0,0, 0x00, 0x00, '\r', '\n' };
//
//volatile bool mpuInterrupt = false;     // indicates whether MPU interrupt pin has gone high
//void dmpDataReady() {
//    mpuInterrupt = true;
//}

int pins[4] = {22, 23, 24, 25};
int previousDirection = 0;

void setup() {

  // Serial1 is pins 19 RX and 18 TX
  // RX from bluetooth goes to 19
  // TX from bluetooth goes to 18
  Serial1.begin(9600);
  Serial.begin(9600);

  for (int i = 0; i < 6; i ++) {
    pinMode(pins[0] + 4 * i, OUTPUT);
    pinMode(pins[1] + 4 * i, OUTPUT);
    pinMode(pins[2] + 4 * i, OUTPUT);
    pinMode(pins[3] + 4 * i, OUTPUT);
  }

}

void loop() {
  if (Serial1.available()) {
    int newDirection = Serial1.read() - 48;

    if (previousDirection == newDirection || (newDirection != 0 && previousDirection != 0) ) {
      return;
    }

    if (previousDirection == 0 && newDirection == 1) {
      int directions[6] = {-1, 2, -2, 2, 0, 0};
      move(directions);

    } else if (previousDirection == 0 && newDirection == 2) {
      int directions[6] = { -2, 1, 0, 0, -2, 2};
      move(directions);

    } else if (previousDirection == 0 && newDirection == 3) {
      int directions[6] = { -2, 2, 0, 0, 0, 0};
      move(directions);

    } else if (previousDirection == 0 && newDirection == 4) {
      int directions[6] = {0, 0, -2, 2, -2, 2};
      move(directions);

    } else if (previousDirection == 4) {
      int directions[6] = {0, 0, 2, -2, 2, -2};
      move(directions);

    } else if (previousDirection == 3) {
      int directions[6] = { 2, -2, 0, 0, 0, 0};
      move(directions);

    } else if (previousDirection == 2) {
      int directions[6] = { 2, -1, 0, 0, 2, -2};
      move(directions);

    } else if (previousDirection == 1) {
      int directions[6] = {1, -2, 2, -2, 0, 0};
      move(directions);
    }
    previousDirection = newDirection;
  }
}

void move(int directions[]) {

  for (int k = 0; k < 128; k ++ ) {

    for (int i = 0; i < 6; i ++) {
      if (directions[i] > 0 && (k < 32 || directions[i] == 2) ) {
        digitalWrite(pins[0] + 4 * i, HIGH);
        digitalWrite(pins[1] + 4 * i, LOW);
        digitalWrite(pins[2] + 4 * i, LOW);
        digitalWrite(pins[3] + 4 * i, LOW);
      } else if (directions[i] < 0  && (k < 32 || directions[i] == -2)) {
        digitalWrite(pins[0] + 4 * i, LOW);
        digitalWrite(pins[1] + 4 * i, LOW);
        digitalWrite(pins[2] + 4 * i, LOW);
        digitalWrite(pins[3] + 4 * i, HIGH);
      }
    }
    delay(2);

    for (int i = 0; i < 6; i ++) {
      if (directions[i] > 0 && (k < 32 || directions[i] == 2)) {
        digitalWrite(pins[0] + 4 * i, LOW);
        digitalWrite(pins[1] + 4 * i, HIGH);
        digitalWrite(pins[2] + 4 * i, LOW);
        digitalWrite(pins[3] + 4 * i, LOW);
      } else if (directions[i] < 0  && (k < 32 || directions[i] == -2)) {
        digitalWrite(pins[0] + 4 * i, LOW);
        digitalWrite(pins[1] + 4 * i, LOW);
        digitalWrite(pins[2] + 4 * i, HIGH);
        digitalWrite(pins[3] + 4 * i, LOW);
      }
    }
    delay(2);

    for (int i = 0; i < 6; i ++) {
      if (directions[i] > 0 && (k < 32 || directions[i] == 2)) {
        digitalWrite(pins[0] + 4 * i, LOW);
        digitalWrite(pins[1] + 4 * i, LOW);
        digitalWrite(pins[2] + 4 * i, HIGH);
        digitalWrite(pins[3] + 4 * i, LOW);
      } else if (directions[i] < 0  && (k < 32 || directions[i] == -2)) {
        digitalWrite(pins[0] + 4 * i, LOW);
        digitalWrite(pins[1] + 4 * i, HIGH);
        digitalWrite(pins[2] + 4 * i, LOW);
        digitalWrite(pins[3] + 4 * i, LOW);
      }
    }
    delay(2);

    for (int i = 0; i < 6; i ++) {
      if (directions[i] > 0 && (k < 32 || directions[i] == 2)) {
        digitalWrite(pins[0] + 4 * i, LOW);
        digitalWrite(pins[1] + 4 * i, LOW);
        digitalWrite(pins[2] + 4 * i, LOW);
        digitalWrite(pins[3] + 4 * i, HIGH);
      } else if (directions[i] < 0  && (k < 32 || directions[i] == -2)) {
        digitalWrite(pins[0] + 4 * i, HIGH);
        digitalWrite(pins[1] + 4 * i, LOW);
        digitalWrite(pins[2] + 4 * i, LOW);
        digitalWrite(pins[3] + 4 * i, LOW);
      }
    }
    delay(2);
  }
}
