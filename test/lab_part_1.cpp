#include <Arduino.h>

float potentiometer_val = 0.0;
const int POTENTIOMETER_PIN = D2;
const int PWM_PIN = D3;

// this is how to create a FreeRTOS task, which allows for multiple tasks to run simultaneously
// you can set the loop rates, task priorities, and behaviors for each task independently
// for example, this would be useful for reading an analog pin
// you want the pin to be read very quickly so that the filters are getting good data, but serial output doesn't need to happen that fast
// you can set the analog pin to be read every 2 ms, for example, and have data sent through USB every 50 ms
void sendPWM(void *param) {
    while (true) {
    // analogRead returns a value between 0 and 4096. analogWrite sends a PWM value with a duty cycle between 0 (0%) and 255 (100%)
        potentiometer_val = analogRead(POTENTIOMETER_PIN);
        analogWrite(PWM_PIN, potentiometer_val * 255.0 / 4095.0);

        // this sets the loop rate to 4 ms or 250 Hz
        // vTaskDelay is non-blocking, meaning while the sendPWM task is paused it will allow other tasks, if they exist, to be executed
        vTaskDelay(pdMS_TO_TICKS(4));
    }
}

void serialPrint(void *param) {
    while (true) {
        Serial.println(potentiometer_val);
        vTaskDelay(pdMS_TO_TICKS(10)); // serial printing runs every 10 ms or 100 Hz. you can change this if you want more or less data
    }
}

// with FreeRTOS, you just need to create the task and the controller will take care of the rest
// there is no need to put anything in loop() to execute
void setup() {
    pinMode(POTENTIOMETER_PIN, INPUT_PULLDOWN);
    pinMode(PWM_PIN, OUTPUT);

    Serial.begin(115200);

    // the relevant parameters are the task itself (sendPWM), the task name ("MAIN"), and allocated memory (4096 bytes is usually enough)
    // if two tasks try to execute at the same time the controller pick will the most important one
    xTaskCreate(sendPWM, "MAIN", 4096, NULL, 2, NULL); // priority 2 -> higher importance
    xTaskCreate(serialPrint, "USB", 4096, NULL, 1, NULL); // priority 1 -> lower importance
}

void loop() {
}