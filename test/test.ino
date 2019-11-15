int pins[4] = {22, 23, 24, 25};
int previousDirection = 0;

void setup() {

  Serial1.begin(9600);

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
