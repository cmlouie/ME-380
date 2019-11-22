#include "I2Cdev.h"
#include "MPU6050_6Axis_MotionApps20.h"
#if I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE
    #include "Wire.h"
#endif

float ypr[3];
float euler[3];

uint8_t devStatus;
uint8_t mpuIntStatus;
uint16_t fifoCount;
uint16_t packetSize;
uint8_t fifoBuffer[1024];

bool dmpReady = false;
bool blinkState = false;

const int pins[4] = {22, 23, 24, 25};
int motorAngles[6] = {0, 0 , 0 , 0 , 0, 0};
int motorPosition[6] = {0, 180, 0, 180, 0 , 180};
uint8_t teapotPacket[14] = { '$', 0x02, 0,0, 0,0, 0,0, 0,0, 0x00, 0x00, '\r', '\n' };

volatile bool mpuInterrupt = false;

int increment = 0;
const int degreeTolerance = 7;
const float stepsPerDegree = 4096 / 360;
const int delaySpeed = 1;

MPU6050 mpu;
Quaternion q;
VectorInt16 aa;
VectorInt16 aaReal;
VectorInt16 aaWorld;
VectorFloat gravity;

void setup() {
  setupGyro();
}

void loop() {
  increment++;
  readAngles();
  if (!dmpReady) return;
  moveMotors();
  sendAngles();
}

void moveMotors() {
    // 2 4 6 clockwise is positive
    // 1 3 5 counter clockwise is positive

    // 1 3 5 -> positive angle is reverse
    // 1 3 5 -> negative angle is regular
    // 2 4 6 -> positive is regular
    // 2 4 6 -> negative is reverse
    for (int i = 0; i < 6; i ++) {
      if (abs(motorAngles[i]) <= degreeTolerance) continue;
      if ((motorAngles[i] > 0 && i % 2 == 1) || (motorAngles[i] < 0 && i % 2 == 0)) {
        digitalWrite(pins[0] + 4 * i, HIGH);
        digitalWrite(pins[1] + 4 * i, LOW);
        digitalWrite(pins[2] + 4 * i, LOW);
        digitalWrite(pins[3] + 4 * i, LOW);
      } else {
        digitalWrite(pins[0] + 4 * i, LOW);
        digitalWrite(pins[1] + 4 * i, LOW);
        digitalWrite(pins[2] + 4 * i, LOW);
        digitalWrite(pins[3] + 4 * i, HIGH);
      }
      delay(delaySpeed);
    }
    for (int i = 0; i < 6; i ++) {
      if (abs(motorAngles[i]) <= degreeTolerance) continue;
      if ((motorAngles[i] > 0 && i % 2 == 1) || (motorAngles[i] < 0 && i % 2 == 0)) {
        digitalWrite(pins[0] + 4 * i, LOW);
        digitalWrite(pins[1] + 4 * i, HIGH);
        digitalWrite(pins[2] + 4 * i, LOW);
        digitalWrite(pins[3] + 4 * i, LOW);
      } else {
        digitalWrite(pins[0] + 4 * i, LOW);
        digitalWrite(pins[1] + 4 * i, LOW);
        digitalWrite(pins[2] + 4 * i, HIGH);
        digitalWrite(pins[3] + 4 * i, LOW);
      }
      delay(delaySpeed);
    }
    for (int i = 0; i < 6; i ++) {
      if (abs(motorAngles[i]) <= degreeTolerance) continue;
      if ((motorAngles[i] > 0 && i % 2 == 1) || (motorAngles[i] < 0 && i % 2 == 0)) {
        digitalWrite(pins[0] + 4 * i, LOW);
        digitalWrite(pins[1] + 4 * i, LOW);
        digitalWrite(pins[2] + 4 * i, HIGH);
        digitalWrite(pins[3] + 4 * i, LOW);
      } else {
        digitalWrite(pins[0] + 4 * i, LOW);
        digitalWrite(pins[1] + 4 * i, HIGH);
        digitalWrite(pins[2] + 4 * i, LOW);
        digitalWrite(pins[3] + 4 * i, LOW);
      }
      delay(delaySpeed);
    }
    for (int i = 0; i < 6; i ++) {
      if (abs(motorAngles[i]) <= degreeTolerance) continue;
      if ((motorAngles[i] > 0 && i % 2 == 1) || (motorAngles[i] < 0 && i % 2 == 0)) {
        digitalWrite(pins[0] + 4 * i, LOW);
        digitalWrite(pins[1] + 4 * i, LOW);
        digitalWrite(pins[2] + 4 * i, LOW);
        digitalWrite(pins[3] + 4 * i, HIGH);
      } else {
        digitalWrite(pins[0] + 4 * i, HIGH);
        digitalWrite(pins[1] + 4 * i, LOW);
        digitalWrite(pins[2] + 4 * i, LOW);
        digitalWrite(pins[3] + 4 * i, LOW);
      }
      delay(delaySpeed);
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

void setupGyro() {
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

void sendAngles() {
  while (!mpuInterrupt && fifoCount < packetSize) {}

  mpuInterrupt = false;
  mpuIntStatus = mpu.getIntStatus();
  fifoCount = mpu.getFIFOCount();

  if ((mpuIntStatus & 0x10) || fifoCount == 16384) {
      mpu.resetFIFO();
      Serial.println(F("FIFO overflow!"));

  }  else if (mpuIntStatus & 0x02) {
        while (fifoCount < packetSize) fifoCount = mpu.getFIFOCount();
        mpu.getFIFOBytes(fifoBuffer, packetSize);
        fifoCount -= packetSize;

        mpu.dmpGetQuaternion(&q, fifoBuffer);
        mpu.dmpGetGravity(&gravity, &q);
        mpu.dmpGetYawPitchRoll(ypr, &q, &gravity);

        float ypr1 = ypr[1] - 5 * M_PI / 180;
        float ypr2 = ypr[2] - 1 * M_PI / 180;

        bool positivePitch = ypr1 >= 0;
        bool positiveRoll = ypr2 >= 0;
        String data = String(positivePitch ? "+" : "") + String(ypr1 * 180/M_PI) + "," + String(positiveRoll ? "+" : "") + String(ypr2 * 180/M_PI);
        if (increment >= 8) {
          Serial1.write(data.c_str());
          increment = 0;
        }
    } else {
      Serial.println("Completely Broken");
    }
}

void dmpDataReady() {
    mpuInterrupt = true;
}
