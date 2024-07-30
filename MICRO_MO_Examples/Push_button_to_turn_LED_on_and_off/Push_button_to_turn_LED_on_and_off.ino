void setup() {
  // put your setup code here, to run once:
  pinMode(LED, OUTPUT);      
  digitalWrite(LED, HIGH);   

  pinMode(Button, INPUT_PULLUP); 
}

void loop() {
  // put your main code here, to run repeatedly:
    int buttonState = digitalRead(Button);

    if (buttonState == LOW) {
      digitalWrite(LED, LOW);   // Turn the LED on
    } else {
      digitalWrite(LED, HIGH);    // Turn the LED off
    }
}
