#include "I2Cdev.h"
#include "MPU6050_6Axis_MotionApps20.h"
#if I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE
    #include "Wire.h"
#endif

MPU6050 mpu;

bool dmpReady = false;
bool blinkState = false;

uint8_t devStatus;
uint8_t mpuIntStatus;
uint16_t fifoCount;
uint16_t packetSize;
uint8_t fifoBuffer[64];

int increment = 0;

Quaternion q;
VectorInt16 aa;
VectorInt16 aaReal;
VectorInt16 aaWorld;
VectorFloat gravity;
float euler[3];
float ypr[3];

uint8_t teapotPacket[14] = { '$', 0x02, 0,0, 0,0, 0,0, 0,0, 0x00, 0x00, '\r', '\n' };

volatile bool mpuInterrupt = false;
void dmpDataReady() {
    mpuInterrupt = true;
}

const int pins[4] = {22, 23, 24, 25};
int motorAngles[6] = {0, 0 , 0 , 0 , 0 , 0};
const int degreeTolerance = 3;
const byte numChars = 20;

bool newData = false;
int previousDirection = 0;
char receivedChars[numChars];

void setup() {
  setupGyro();
}

void loop() {

  increment++;
  readAngles();
  if (!dmpReady) return;
  sendAngles();
  
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
      while (Serial1.available() > 0 && shouldRead) {
        processed = true;
        rc = Serial1.read();
        if (rc == startMarker) {
          shouldRead = false;
        }
      }

      Serial.println(processed);
      if (!processed) {
        return;
      }
      
      Serial.println("[");
      for (int i = 0; i < 6; i ++) {
        for (int j = 0; j < 3; j++) {
          Serial.println(Serial1.read());
          //motorAngles[i] += (rc * (100/pow(10, j) ));
        }
        //Serial.println(motorAngles[i]);
      }
      //Serial1.read();
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

  if ((mpuIntStatus & 0x10) || fifoCount == 1024) {
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
      Serial.println("Completely Busted");
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
