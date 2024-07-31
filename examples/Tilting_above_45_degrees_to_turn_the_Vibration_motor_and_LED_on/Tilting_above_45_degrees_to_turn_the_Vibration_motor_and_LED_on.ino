#include <Wire.h>
#include "I2Cdev.h"

void setup() {
  pinMode(Vibration_motor, OUTPUT);
  pinMode(LED, OUTPUT);      
  digitalWrite(LED, HIGH); 

  Wire.begin(); 
  Serial.begin(115200);
}

void loop() {
  unsigned long currentMillis = millis();
  unsigned long previousMillis = 0;
  
  if (currentMillis - previousMillis >= 100) {
    previousMillis = currentMillis;

    // Read accelerometer data
    Wire.beginTransmission(0x68);
    Wire.write(0x3B);  // Starting register for accelerometer data
    Wire.endTransmission(false);
    Wire.requestFrom(0x68, 6, true);

    int16_t accX = Wire.read() << 8 | Wire.read();
    int16_t accY = Wire.read() << 8 | Wire.read();
    int16_t accZ = Wire.read() << 8 | Wire.read();

    // Calculate tilt
    double x_g = accX / 16384.0;
    double y_g = accY / 16384.0;
    double z_g = accZ / 16384.0;
    double tilt = acos(z_g / sqrt(x_g*x_g + y_g*y_g + z_g*z_g)) * 180.0 / PI;
    
    // Debug output
    Serial.print("Tilt: ");
    Serial.println(tilt);

    // Check if tilt condition is met
    if (tilt > 45) {
      digitalWrite(Vibration_motor, HIGH);  // Activate vibration motor
      digitalWrite(LED, LOW);
      
    } else {
      digitalWrite(Vibration_motor, LOW);  // Deactivate vibration motor
      digitalWrite(LED, HIGH);          // Turn off LED
    }
  } 
}
