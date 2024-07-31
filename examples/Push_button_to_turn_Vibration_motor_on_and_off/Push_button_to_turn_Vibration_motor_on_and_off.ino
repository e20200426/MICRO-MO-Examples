void setup() {
  // put your setup code here, to run once: 
  pinMode(Vibration_motor, OUTPUT); 

  pinMode(Button, INPUT_PULLUP); 
}

void loop() {
  // put your main code here, to run repeatedly:
  int buttonState = digitalRead(Button);

  if (buttonState == LOW) {
    digitalWrite(Vibration_motor, HIGH);   // Turn the Vibration Motor on
  } else {
    digitalWrite(Vibration_motor, LOW);    // Turn the Vibration Motor off
  }
}
