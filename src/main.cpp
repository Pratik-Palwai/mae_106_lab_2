#include <Arduino.h>

// copy and paste code from the test/ folder to run here

void setup() {
    Serial.begin(115200);
}

void loop() {
    Serial.println("Hello world");
    delay(500);
}