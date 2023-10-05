#include <Arduino.h>

enum mode{
  NONE = 0x00,
  VOLTAGE = 0x01,
  CURRENT = 0x02,
};

volatile uint16_t data[500];
volatile uint16_t index = 0;
volatile char lastChar = 0;

void ADC_Init();
void Timer1_Init();
void USART_Init(uint64_t baud_rate, uint8_t double_speed);

int main(){

  // Initialize

  cli(); // disable global interrupts
  PORTB = 0x00; // Set all ports to input
  DDRB = (1<< PB5); // Set PB5 and PB0 to output
  ADC_Init(); // Initialize ADC
  Timer1_Init(); // Initialize Timer1
  USART_Init(115200, 1); // Initialize USART
  
  // Local variables
  uint8_t reading = 0;
  mode capMode = NONE;
  uint16_t i;

  // enable global interrupts
  sei(); 
  
  // Main loop
  while(1){
    if (!(reading) && (lastChar == '1')){
      reading = 1;
      capMode = VOLTAGE;
      index = 0;
      lastChar = 0;
      ADMUX |= (1 << MUX0); // Set ADC to measure voltage
      ADMUX &= ~(1 << MUX1); // Set ADC to measure voltage
      TIFR1 |= 0x01; // Clear Timer1 Overflow Flag
      PORTB |= (1<<PB5); // Set PB5 to HIGH
    }
    if (reading){
      // Send data to serial
      if (index == 500){

        for(i = 0; i < 500; i++) {
          // break data into 8-bit chunks and send it to the serial port
          while (!(UCSR0A & (1 << UDRE0)));
          UDR0 =  (data[i]);
          while (!(UCSR0A & (1 << UDRE0)));
          UDR0 =  (data[i] >> 8); 
        }
        
        index = 0;
        // Change mode to current
        if (capMode == VOLTAGE){
          capMode = CURRENT;
          ADMUX &= ~(1 << MUX0); // Set ADC to measure current
          ADMUX |= (1 << MUX1); // Set ADC to measure current
          TIFR1 |= 0x01;
        }
        // Stop reading
        else if(capMode == CURRENT){
          capMode = NONE;
          reading = 0;
          PORTB &= ~(1<<PB5); // Set PB5 to LOW
        }
      }
    }
  }
}

/*
  @brief Initialize ADC to measure Voltage and Current at 6kHz
*/
void ADC_Init(){

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

/*
  @brief Initialize Timer1 and configure it to trigger ADC at overflow (6kHz)
*/
void Timer1_Init(){

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

/*
  @brief Initialize USART
  @param baud_rate Baud rate for USART
  @param double_speed Double speed for USART
*/
void USART_Init(uint64_t baud_rate, uint8_t double_speed) {

  // Find ubrr value for boud_rate and double_speed
  uint16_t ubrr;
  if (double_speed) {
    ubrr = ((F_CPU + baud_rate * 4UL) / (baud_rate * 8UL) - 1);
    UCSR0A |= (1 << U2X0);
  } else {
    ubrr = ((F_CPU + baud_rate * 8UL) / (baud_rate * 16UL) - 1);
  }


  UBRR0 = ubrr; // Set baud rate

  UCSR0B = 0;
  UCSR0B |= (1 << RXEN0) | (1 << TXEN0); // Enable receiver and transmitter
  UCSR0B |= (1 << RXCIE0); // Enable receiver interrupt
  UCSR0C = (1 << UCSZ01) | (1 << UCSZ00); // Set frame: 8data, 1 stp

}

// Interrupt for ADC
ISR(ADC_vect){
  data[index] = ADC;
  index++;
  if (index < 500) TIFR1 |= 0x01; // Clear Timer1 Overflow Flag
}

// Interrupt for USART
ISR(USART_RX_vect){
  lastChar = UDR0;
}