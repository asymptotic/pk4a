/*

pk4a - pyrokinesis for alex
written by seth hardy, http://asymptotic.ca
various bits "borrowed from" or "inspired by" various arduino tutorials because i'm lazy
todo: clean this code up and write some docs and etc etc etc

*/

#include <Brain.h>
#include <NewSoftSerial.h>

#define ver "0.05"

#define BTPIN 2
#define FIREPIN 9
#define LEDPIN 11
#define LCDPIN 12
#define BUTTONPIN 16

Brain brain(Serial);
NewSoftSerial lcdSerial = NewSoftSerial(255, LCDPIN);
byte attention = 0;
byte meditation = 0;
byte signal = 200;

byte bars = 0;
byte rem = 0;
byte row;

int buttonState;             // the current reading from the input pin
int lastButtonState = HIGH;   // the previous reading from the input pin
int lastDebounceState = HIGH;
long lastDebounceTime = 0;  // the last time the output pin was toggled
long debounceDelay = 50;    // the debounce time; increase if the output flickers
int mode = 0;

void initlcd() {
  // configure LCD serial interface
  pinMode(LCDPIN, OUTPUT);
  lcdSerial.begin(9600);
 
  delay(100); // is this needed?
 
  // set LCD display geometry
  lcdSerial.print("?G420");
 
  // set LCD backlight to maximum
  lcdSerial.print("?Bff");
  delay(100);
 
  // clear the LCD
  lcdSerial.print("?f");
 
  // turn cursor off
  lcdSerial.print("?c0");
 
  lcdSerial.print("?x00?y0");
  lcdSerial.print("initializing...");
 
  // custom chars for vertical bars
  lcdSerial.print("?D0000000000000001F");   // define special characters
  delay(150);
  lcdSerial.print("?D10000000000001F1F");
  delay(150);
  lcdSerial.print("?D200000000001F1F1F");
  delay(150);
  lcdSerial.print("?D3000000001F1F1F1F");
  delay(150);
  lcdSerial.print("?D40000001F1F1F1F1F");
  delay(150);
  lcdSerial.print("?D500001F1F1F1F1F1F");
  delay(150);
  lcdSerial.print("?D6001F1F1F1F1F1F1F");
  delay(150);
  lcdSerial.print("?D71F1F1F1F1F1F1F1F");
  delay(150);

  lcdSerial.print("?f");
  lcdSerial.print("?x00?y0");
  lcdSerial.print("PK4A v");
  lcdSerial.print(ver);
  lcdSerial.print("?x02?y1");
  lcdSerial.print("Link:");
  lcdSerial.print("?x02?y2");
  lcdSerial.print("Mode: Att80");
  lcdSerial.print("?x02?y3");
  lcdSerial.print("Med");
  lcdSerial.print("?x10?y3");
  lcdSerial.print("Att");
  lcdSerial.print("?x18?y0");
  lcdSerial.print("MA"); 
  
}

void setup() {
  delay(3000);
  Serial.begin(57600);
  pinMode(BTPIN,OUTPUT);
  digitalWrite(BTPIN,HIGH);
  pinMode(LEDPIN, OUTPUT);
  pinMode(FIREPIN, OUTPUT);
  pinMode(BUTTONPIN, INPUT);
  digitalWrite(BUTTONPIN, HIGH);
  initlcd();
}

void loop() {
  int reading = digitalRead(BUTTONPIN);
  if (reading != lastButtonState) {
    lastDebounceTime = millis();
  }   
  if ((millis() - lastDebounceTime) > debounceDelay) {
    lastDebounceState = buttonState;
    buttonState = reading;
    if( (buttonState == LOW) && (lastDebounceState == HIGH) ) {
      mode = ++mode % 4;
      lcdSerial.print("?x08?y2");
      if( mode == 0 ) lcdSerial.print("Att80");
      else if( mode == 1 ) lcdSerial.print("Med80");
      else if( mode == 2 ) lcdSerial.print("Att60");
      else if( mode == 3 ) lcdSerial.print("Med60");
      Serial.print("mode = "); Serial.println(mode);
    }
  }
  lastButtonState = reading;
  
  
  if (brain.update()) {
    signal = brain.readSignalQuality();
    if(signal) {
      digitalWrite(LEDPIN, LOW);
      digitalWrite(FIREPIN, LOW);
    }
    else {
      digitalWrite(LEDPIN, HIGH);
    }
    lcdSerial.print("?x08?y1");
    if(signal < 100) {
      lcdSerial.print(" ");
    }
    if(signal < 10) {
      lcdSerial.print(" ");
    }
    lcdSerial.print(signal, DEC);
    attention = brain.readAttention();
    meditation = brain.readMeditation();
    
    if( ((mode == 0) && (attention >= 80))  ||
        ((mode == 1) && (meditation >= 80)) ||
        ((mode == 2) && (attention >= 60))  ||
        ((mode == 3) && (meditation >= 60)) )
      digitalWrite(FIREPIN, HIGH);
    else
      digitalWrite(FIREPIN, LOW);
    
    Serial.println(brain.readCSV());
    threebar100(meditation, 18);
    lcdSerial.print("?x06?y3");
    if(meditation < 100) {
      lcdSerial.print(" ");
    }
    if(meditation < 10) {
      lcdSerial.print(" ");
    }
    lcdSerial.print(meditation, DEC);
    
    threebar100(attention, 19);
    lcdSerial.print("?x14?y3");
    if(attention < 100) {
      lcdSerial.print(" ");
    }
    if(attention < 10) {
      lcdSerial.print(" ");
    }
    lcdSerial.print(attention, DEC);
  }
}

void threebar100(byte val, byte col) {
  byte bars = val / 5; 
  byte row = 3;
  while(bars >= 7) {
    lcdSerial.print("?x");
    lcdSerial.print(col, DEC);
    lcdSerial.print("?y"); 
    lcdSerial.print(row, DEC);
    lcdSerial.print("?7"); 
    //delay(5);
    bars -= 7;
    row -= 1; 
  }
  if(bars != 0) {
    lcdSerial.print("?x");
    lcdSerial.print(col, DEC);
    lcdSerial.print("?y"); 
    lcdSerial.print(row, DEC);
    lcdSerial.print("?");
    lcdSerial.print(bars, DEC);
    //delay(5);
    row -= 1;
  }
  for(;row>0;row--) {
    lcdSerial.print("?x");
    lcdSerial.print(col, DEC);
    lcdSerial.print("?y");
    lcdSerial.print(row, DEC);
    lcdSerial.print(" ");
  }
}
