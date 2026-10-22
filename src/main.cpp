#include <Arduino.h>

const int LAB_SECTION = 1;

float potentiometer_val = 0.0;
const int POTENTIOMETER_PIN = 2;
const int PWM_PIN = 3;

const int OUTPUT_PIN = 3;
float filtered_signal_previous = 0.0;
float filtered_signal = 0.0;

// set this to 1 to run the code for lab 3 part 1. set this to 2 to run the code for part 2
int square_wave_state = 1;

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

// RTOS task for printing data to serial. this occurs at 250 Hz to still be smooth but not take up too much compute
void serialPrintPart1(void *param) {
    while (true) {
        Serial.println(potentiometer_val);
        vTaskDelay(pdMS_TO_TICKS(4)); // serial printing runs every 10 ms or 100 Hz. you can change this if you want more or less data
    }
}

// simple low pass filter with adjustable smoothing (filter strength)
float averagingFilter(float measured_signal, float filter_strength) {
    float filter_output = (1 - filter_strength) * measured_signal + filter_strength * filtered_signal_previous;
    filtered_signal_previous = filter_output;
    return filter_output;
}

// RTOS task to send a square wave on the output pin. by changing the value in pdMS_TO_TICKS you can change how fast the signal toggles
void sendSquareWave(void *param) {
    while (true) {
        square_wave_state = 1 - square_wave_state;
        digitalWrite(OUTPUT_PIN, square_wave_state);
        vTaskDelay(pdMS_TO_TICKS(100)); // the square wave will spend 100 ms HIGH, then 100 ms LOW, and so on
    }
}

// RTOS task to filter the signal. this occurs at 0.5 kHz to provide smooth data
void filterData(void *param) {
    while(true) {
        potentiometer_val = analogRead(POTENTIOMETER_PIN) / 4095.0;
        filtered_signal = averagingFilter(square_wave_state, potentiometer_val);

        vTaskDelay(pdMS_TO_TICKS(2));
    }
}

void serialPrintPart2(void *param) {
    while (true) {
        Serial.println(">" + String(square_wave_state) + "," + String(potentiometer_val) + "," + String(filtered_signal));
        vTaskDelay(pdMS_TO_TICKS(4));
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

    if (LAB_SECTION == 1) {
        xTaskCreate(sendPWM, "MAIN", 4096, NULL, 2, NULL); // priority 2 -> higher importance
        xTaskCreate(serialPrintPart1, "USB", 4096, NULL, 1, NULL); // priority 1 -> lower importance   
    }

    else if (LAB_SECTION == 2) {
        xTaskCreate(sendSquareWave, "MAIN", 4096, NULL, 3, NULL);
        xTaskCreate(filterData, "FILTER", 4096, NULL, 2, NULL);
        xTaskCreate(serialPrintPart2, "USB", 4096, NULL, 1, NULL);
    }
}

void loop() { }