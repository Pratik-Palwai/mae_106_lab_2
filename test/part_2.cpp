    #include <Arduino.h>

    #include <Arduino.h>

    float potentiometer_val = 0.0;
    const int POTENTIOMETER_PIN = D2;
    const int OUTPUT_PIN = D3;

    float filtered_signal_previous = 0.0;
    float filtered_signal = 0.0;

    int square_wave_state = 1;

    // simple low pass filter with adjustable smoothing (filter strength)
    float averagingFilter(float measured_signal, float filter_strength) {
        float filter_output = (1 - filter_strength) * measured_signal + filter_strength * filtered_signal_previous;
        filtered_signal_previous = filter_output;
        return filter_output;
    }

    void sendSquareWave(void *param) {
        while (true) {
            square_wave_state = 1 - square_wave_state;
            digitalWrite(OUTPUT_PIN, square_wave_state);
            vTaskDelay(pdMS_TO_TICKS(100)); // the square wave will spend 100 ms HIGH, then 100 ms LOW, and so on
        }
    }

    void filterData(void *param) {
        while(true) {
            potentiometer_val = analogRead(POTENTIOMETER_PIN) / 4095.0;
            filtered_signal = averagingFilter(square_wave_state, potentiometer_val);

            vTaskDelay(pdMS_TO_TICKS(10));
        }
    }

    void serialPrint(void *param) {
        while (true) {
            Serial.println(">" + String(square_wave_state) + "," + String(potentiometer_val) + "," + String(filtered_signal));
            vTaskDelay(pdMS_TO_TICKS(10));
        }
    }

    void setup() {
        pinMode(POTENTIOMETER_PIN, INPUT_PULLDOWN);
        pinMode(OUTPUT_PIN, OUTPUT);

        Serial.begin(115200);

        xTaskCreate(sendSquareWave, "MAIN", 4096, NULL, 3, NULL);
        xTaskCreate(filterData, "FILTER", 4096, NULL, 2, NULL);
        xTaskCreate(serialPrint, "USB", 4096, NULL, 1, NULL);
    }

    void loop() {
    }