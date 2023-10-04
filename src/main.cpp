#include <Arduino.h>

enum mode{
  VOLTAGE,
  CURRENT,
  NONE
};

uint16_t data[500];
int16_t index;
mode capMode;

ISR(ADC_vect){
  data[index] = ADC + index*10;
  index++;
  if (index < 500) TIFR1 |= 0x01;
}

void ADC_Init(){

  /*
    ADC to measure Voltage and Current at 6kHz
  */

  // ADMUX – ADC Multiplexer Selection Register
  ADMUX = 0x00; // Clear ADMUX Register
  ADMUX |= (1 << REFS0); // AVCC Capacitor Externo at AREF pin


  // ADCSRA – Enable ADC and Auto Trigger
  ADCSRA = 0x00; // Clear ADCSRA Register
  ADCSRA |= (1 << ADEN); // Enable ADC
  ADCSRA |= (1 << ADATE); // Enable Auto Trigger

  // Division Factor = 128 -> 16MHz/128 = 125kHz
  ADCSRA |=  (1 << ADPS2);
  ADCSRA |=  (1 << ADPS1); 
  ADCSRA |=  (1 << ADPS0); 

  // ADCSRB - Define Auto Trigger Source to Counter 1 Overflow
  ADCSRB = 0x00;
  ADCSRB |= (1 << ADTS1);
  ADCSRB |= (1 << ADTS2); 

  DIDR0 = 0x01; // Disable Digital Input on ADC0

  ADCSRA |= (1 << ADIE); // Enable Interrupt

}

void Timer1_Init(){

  /*
    Timer configuration to trigger ADC
  */

  // TOP = OCR1A; Update of OCR1A at BOTTOM; TOV1 Flag Set on TOP
  TCCR1A = 0x00; // Clear TCCR1A Register
  TCCR1A |= (1 << WGM11); // Fast PWM 10-bit
  TCCR1A |= (1 << WGM10); // Fast PWM 10-bit
  TCCR1B = 0x00; // Clear TCCR1B Register 
  TCCR1B |= (1 << WGM12); // Fast PWM 10-bit
  TCCR1B |= (1 << WGM13); // Fast PWM 10-bit

  // Clock Selection no Scale
  TCCR1B |= (1 << CS10);

  // Timer Cycle for 6kHz
  OCR1A = 2666; // 16MHz/6kHz = 2666.6666666666666666666666666667

  // No interrupted Used
  TIMSK1 = 0x00;

}

void printData(){
  for (int i = 0; i < 500; i++)Serial.println(data[i]);
}

int main(){

  cli(); // disable global interrupts
  // Configuration
  PORTB = 0x00; // Set all ports to input
  DDRB |= (1<< PB5) | (1<<PB0); // Set PB5 and PB0 to output
  memset(data, 10, sizeof(data)); // Clear data array
  index = 0; // Clear index
  ADC_Init(); // Initialize ADC
  Timer1_Init(); // Initialize Timer1
  Serial.begin(9600); // Initialize Serial
  sei(); // enable global interrupts

  uint8_t reading = 0;
  capMode = NONE;
  index = 0;
  uint16_t i;

  while(1){ 
    if (Serial.available()>0 && !reading){
      char receivedByte = Serial.read();
      if (receivedByte == '1'){
          reading = 1;
          capMode = CURRENT;
          index = 0;
          TIFR1 |= 0x01;
          PORTB |= (1<<PB5);
      }
    }
    if (reading){
      if (index == 500){
        for(i = 0; i < 500; i++) Serial.write(data[i]); // Ta errado
        index = 0;
        if (capMode == CURRENT){
          capMode = VOLTAGE;
          TIFR1 |= 0x01;
        }
        else if(capMode == VOLTAGE){
          capMode = NONE;
          reading = 0;
          PORTB &= ~(1<<PB5);
        }
      }
    }
  }
}

