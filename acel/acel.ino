#include "I2Cdev.h"

#include "MPU6050_6Axis_MotionApps20.h"

#if I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE
    #include "Wire.h"
#endif

MPU6050 mpu;

#define OUTPUT_READABLE_YAWPITCHROLL
#define LED_PIN 13 // (Arduino is 13, Teensy is 11, Teensy++ is 6)

bool blinkState = false;
bool dmpReady = false;  // set true if DMP init was successful
uint8_t mpuIntStatus;   // holds actual interrupt status byte from MPU
uint8_t devStatus;      // return status after each device operation (0 = success, !0 = error)
uint16_t packetSize;    // expected DMP packet size (default is 42 bytes)
uint16_t fifoCount;     // count of all bytes currently in FIFO
uint8_t fifoBuffer[64]; // FIFO storage buffer


// orientation/motion vars
Quaternion q;           // [w, x, y, z]         quaternion container
VectorInt16 aa;         // [x, y, z]            accel sensor measurements
VectorInt16 aaReal;     // [x, y, z]            gravity-free accel sensor measurements
VectorInt16 aaWorld;    // [x, y, z]            world-frame accel sensor measurements
VectorFloat gravity;    // [x, y, z]            gravity vector
float euler[3];         // [psi, theta, phi]    Euler angle container
float ypr[3];           // [yaw, pitch, roll]   yaw/pitch/roll container and gravity vector

uint8_t teapotPacket[14] = { '$', 0x02, 0,0, 0,0, 0,0, 0,0, 0x00, 0x00, '\r', '\n' };

volatile bool mpuInterrupt = false;     // indicates whether MPU interrupt pin has gone high
void dmpDataReady() {
    mpuInterrupt = true;
}

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

  #if I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE
      Wire.begin();
      TWBR = 24; // 400kHz I2C clock (200kHz if CPU is 8MHz)
  #elif I2CDEV_IMPLEMENTATION == I2CDEV_BUILTIN_FASTWIRE
      Fastwire::setup(400, true);
  #endif

  mpu.initialize();
  Serial.println(mpu.testConnection() ? F("MPU6050 connection successful") : F("MPU6050 connection failed"));

  while (Serial1.available() && Serial1.read()); // empty buffer
  while (!Serial1.available());                 // wait for data
  while (Serial1.available() && Serial1.read()); // empty buffer again
  
  devStatus = mpu.dmpInitialize();
  mpu.setXGyroOffset(0);
  mpu.setYGyroOffset(0);
  mpu.setZGyroOffset(0);
  mpu.setZAccelOffset(1788);

  if (devStatus == 0) {
    mpu.setDMPEnabled(true);
    attachInterrupt(0, dmpDataReady, RISING);
    mpuIntStatus = mpu.getIntStatus();
    dmpReady = true;
    packetSize = mpu.dmpGetFIFOPacketSize();
  } else {
    Serial.print(F("DMP Initialization failed (code "));
    Serial.print(devStatus);
    Serial.println(F(")"));
  }

}

void loop() {

  if (!dmpReady) return;

  while (!mpuInterrupt && fifoCount < packetSize) {
      // other program behavior stuff here
      // .
      // .
      // .
      // if you are really paranoid you can frequently test in between other
      // stuff to see if mpuInterrupt is true, and if so, "break;" from the
      // while() loop to immediately process the MPU data
      // .
      // .
      // .
  }

  mpuInterrupt = false;
  mpuIntStatus = mpu.getIntStatus();
  fifoCount = mpu.getFIFOCount();

  // check for overflow (this should never happen unless our code is too inefficient)
  if ((mpuIntStatus & 0x10) || fifoCount == 1024) {
      // reset so we can continue cleanly
      mpu.resetFIFO();
      Serial.println(F("FIFO overflow!"));

  // otherwise, check for DMP data ready interrupt (this should happen frequently)
  }  else if (mpuIntStatus & 0x02) {
        // wait for correct available data length, should be a VERY short wait
        while (fifoCount < packetSize) fifoCount = mpu.getFIFOCount();

        // read a packet from FIFO
        mpu.getFIFOBytes(fifoBuffer, packetSize);
        
        // track FIFO count here in case there is > 1 packet available
        // (this lets us immediately read more without waiting for an interrupt)
        fifoCount -= packetSize;

        // display Euler angles in degrees
        mpu.dmpGetQuaternion(&q, fifoBuffer);
        mpu.dmpGetGravity(&gravity, &q);
        mpu.dmpGetYawPitchRoll(ypr, &q, &gravity);

        bool positivePitch = ypr[1] >= 0;
        bool positiveRoll = ypr[2] >= 0;

        String data = String(positivePitch ? "+" : "") + String(ypr[1] * 180/M_PI) + String(positiveRoll ? "+" : "") + String(ypr[2] * 180/M_PI);
        Serial.println(data);
        Serial1.println(data);
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
