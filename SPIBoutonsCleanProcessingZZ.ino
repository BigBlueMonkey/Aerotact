#include <SPI.h>
#include <ADC.h>

#define MASK   0xFFFF          // Mask AD5452  

ADC *adc = new ADC(); // adc object;

#define OE_PIN  4 //level shifter
#define DIRAB_PIN  5 //level shifter

#define BL_PIN  6
#define POL_PIN  7
#define LE_PIN  8
#define DIR_PIN  9

#define AD5452_PIN_LE  19 //(SYNC = Latch Enable)

#define UP_PIN  2
#define DOWN_PIN  1

#define PIXEL_COUNT         64  //Number of pixels on the display 

float voltage = 1.1 ;
float vref =3.3;
uint16_t code = 0;
uint16_t data = 0;


int up = 0;
int down = 0;

int on = 0;
int off = 110; 
int num= 0;

long startTime;
long stopTime;

int scan =200;

long long val;
long long val0;
//int INDEX = 22;
uint8_t pixel_values[PIXEL_COUNT] = {0}; 

void setup() {
 
SPI.begin ();
Serial.begin(9600);

//adc->setReference(ADC_REFERENCE::REF_3V3, ADC_0);

adc->setAveraging(0); // set number of averages
    adc->setResolution(12); // set bits of resolution

 adc->setConversionSpeed(ADC_CONVERSION_SPEED::HIGH_SPEED);
adc->setSamplingSpeed(ADC_SAMPLING_SPEED::MED_SPEED);
//adc->startContinuous(A10, ADC_0);
pinMode(A10, INPUT); //Diff Channel 0 Positive
  //pinMode(A11, INPUT_PULLUP);  //Diff Channel 0 Negative
    //digitalWrite(A11, HIGH);

pinMode(DIRAB_PIN, OUTPUT);
  digitalWrite(DIRAB_PIN, LOW);
pinMode(POL_PIN, OUTPUT);
  digitalWrite(POL_PIN, LOW);
pinMode(LE_PIN, OUTPUT);
  digitalWrite(LE_PIN, HIGH);
pinMode(BL_PIN, OUTPUT);
  digitalWrite(BL_PIN, HIGH);
pinMode(DIR_PIN, OUTPUT);
  digitalWrite(DIR_PIN, LOW);
    
pinMode(AD5452_PIN_LE , OUTPUT);
    digitalWrite(AD5452_PIN_LE, HIGH);

pinMode(UP_PIN, INPUT);
    digitalWrite(UP_PIN, LOW);
pinMode(DOWN_PIN, INPUT);
     digitalWrite(DOWN_PIN, LOW);

    
  pinMode(OE_PIN, OUTPUT);
    digitalWrite(OE_PIN, LOW);



    /* val0 = 0x00000000LL; //clean the register
   digitalWrite(LE_PIN, LOW);
    SPI.transfer(&val0, 8);
   digitalWrite(LE_PIN, HIGH);
      
SPI.endTransaction(); */

}


void loop() { 

   //startTime = micros(); 
   //Serial.println(voltage); // attention, serial induit interférences
  up = digitalRead(UP_PIN);
    //delayMicroseconds(10);
  down = digitalRead(DOWN_PIN);
    //delayMicroseconds(10);

   if (up == HIGH && down == HIGH){
    voltage = voltage;
  }
   else if (up ==  HIGH && voltage < 3.3 ) {     
          voltage = voltage + 0.0002;
          //Serial.println(voltage);  
  } 
  else if ( down == HIGH && voltage > 0 ){
        voltage = voltage - 0.0002; 
        //Serial.println(voltage);
  }
   
   SPI.beginTransaction(SPISettings(8000000, MSBFIRST, SPI_MODE2)); //Max 50 MHz AD5452
   
    code = (voltage * 4095) / vref;

     data = (code & MASK)<<2;

  digitalWrite(AD5452_PIN_LE , LOW);
  SPI.transfer16(data);
  digitalWrite(AD5452_PIN_LE , HIGH);
SPI.endTransaction(); 

 //Actual display loop: 

 
   if(Serial.available() >= 2){
    uint8_t index = Serial.read();
    uint8_t bright = Serial.read();

    //Serial.print("OK");
    num = index+1;
    on = bright;
    //pixel_values[index] = bright;
   }
  //digitalWrite(BL_PIN, LOW);
  
  SPI.beginTransaction(SPISettings(8000000, LSBFIRST, SPI_MODE0)); //For HV507
for (uint32_t s= 0; s<scan; s++){
  for(uint32_t i = 0; i<num; i++){
    
   //if(pixel_values[i] > 0){ 
    val = 0x00000001LL<<i; //LL does create the value as long long for the bitshift without that it is initalized as int
    
   digitalWrite(LE_PIN, LOW);
    SPI.transfer(&val, 8);
   digitalWrite(LE_PIN, HIGH);
      }
    
   digitalWrite(BL_PIN, HIGH);
   
    delayMicroseconds(on);
     

   digitalWrite(BL_PIN, LOW);

     val0 = 0x00000000LL; //clean the register
   digitalWrite(LE_PIN, LOW);
    SPI.transfer(&val0, 8);
   digitalWrite(LE_PIN, HIGH);
      
              
      SPI.endTransaction();
       //stopTime = micros()- startTime;
      
      delayMicroseconds(off-on);
}
  /*Serial.println ( "---");   
Serial.println ( stopTime);
Serial.println ( num);
   Serial.println ( on);
   Serial.println ( "---");*/
  
   
}
