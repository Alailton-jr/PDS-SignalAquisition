#include <Arduino.h>


volatile int16_t data[500];
volatile int16_t index;

ISR(ADC_vect){
  if (index <500) TIFR1 |= 0x01;

  data[index] = ADC;
  index++; 
}

void ADC_Init(){

  // ADMUX – ADC Multiplexer Selection Register
  // Bit       7     6     5     4     3     2     1     0
  // (0x7C) REFS1 REFS0 ADLAR  –  MUX3  MUX2  MUX1  MUX0
  // Init. Val. 0      0   0    0     0     0     0      0
  // This code  0      1   0    0     0     0     0      0   -> AVCC with external capacitor at AREF pin

  ADMUX = 0x00; // Clear ADMUX Register
  ADMUX |= (1 << REFS0); // AVCC Capacitor Externo at AREF pin


  // ADCSRA – ADC Control and Status Register A
  // Bit       7     6     5     4     3     2     1     0
  // (0x81) ADEN ADSC ADATE ADIF ADIE ADPS2 ADPS1 ADPS0
  // Init. Val. 0      0   0    0     0     0     0      0
  // This code  1      0   1    0     1     1     1      1   -> Enable ADC; Start Conversion; Enable Auto Trigger; Enable Interrupt; Division Factor = 128

  ADCSRA = 0x00; // Clear ADCSRA Register
  ADCSRA |= (1 << ADEN); // Enable ADC
  ADCSRA |= (1 << ADATE); // Enable Auto Trigger

  // Division Factor = 128 -> 16MHz/128 = 125kHz
  ADCSRA |=  (1 << ADPS2);
  ADCSRA |=  (1 << ADPS1); 
  ADCSRA |=  (1 << ADPS0); 

  DIDR0 = 0x01; // Disable Digital Input on ADC0
}

void Timer1_Init(){

  TCCR1A = 0x00;
  TCCR1A |= WGM10;
  TCCR1A=0x03;

  //---------------------------------------------------------------           
  //TCCR1B – Timer/Counter1 Control Register B
  //Bit       7     6     5     4     3     2     1     0
  //(0x81) ICNC1 ICES1    –  WGM13 WGM12  CS12  CS11  CS10 
  //Init. Val. 0      0   0    0     0     0     0      0
  //This code  0      0   0    1     1     0     0      1   -> Waveform generation Mode=15 WGM=15 ->  WGM13:WGM12=11; clk_timer=clk_cpu/1=16MHz 
  //---------------------------------------------------------------  
  TCCR1B=0x19;

}

int main(){
    DDRB = 0x00;  // PORTB -> Todos para entrada

    cli();

    ADCSRA |= (1 << ADSC);

    sei();

    float** current;
    float** voltage;


    while(1){ 
      PORTB ^= 0x20;  //inverte PB5 (PORTB XOR PORTB)
      _delay_ms(5000);//espera 1s (1000ms)



    } 
}








// // put function declarations here:
// int myFunction(int, int);

// void setup() {
//   // put your setup code here, to run once:
//   // int result = myFunction(2, 3);
//   pinMode(LED_BUILTIN, OUTPUT);
// }

// void loop() {
//   digitalWrite(LED_BUILTIN, HIGH);
//   delay(1000);
//   digitalWrite(LED_BUILTIN, LOW);
//   delay(1000);
// }

// // put function definitions here:
// int myFunction(int x, int y) {
//   return x + y;
// }