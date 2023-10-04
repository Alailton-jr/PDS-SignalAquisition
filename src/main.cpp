#include <Arduino.h>

enum mode{
  VOLTAGE,
  CURRENT,
  NONE
};

uint16_t data[500];
volatile uint16_t index;
mode capMode;

ISR(ADC_vect){
  data[index] = ADC + index*10;
  index++;
  if (index < 500) TIFR1 |= 0x01;
}
void ADC_Init();
void Timer1_Init();
void USART_Init(uint64_t baud_rate, uint8_t double_speed);

int main(){

  //Debug
  Serial.begin(9600);

  cli(); // disable global interrupts
  // Configuration
  PORTB = 0x00; // Set all ports to input
  DDRB |= (1<< PB5) | (1<<PB0); // Set PB5 and PB0 to output
  memset(data, 10, sizeof(data)); // Clear data array
  index = 0; // Clear index
  ADC_Init(); // Initialize ADC
  Timer1_Init(); // Initialize Timer1
  USART_Init(9600, 1); // Initialize USART

  sei(); // enable global interrupts

  uint8_t reading = 0;
  capMode = NONE;
  index = 0;
  uint16_t i;
  uint8_t *data2Send;

  

  while(1){ 

    if (!reading){
      while (!(UCSR0A & (1 << RXC0)));
      if (UDR0 == '1'){
        reading = 1;
        capMode = VOLTAGE;
        index = 0;
        ADMUX &= ~(1 << MUX0);
        TIFR1 |= 0x01;
        PORTB |= (1<<PB5);
      }
    }
    
    if (reading){
      if (index == 500){
        // Serial.println("Sending data:");
        for(i = 0; i < 500; i++) {
          while(UCSR0A&0x20 == 0);
          while ( !( UCSR0A & (1<<UDRE0)) )
          UDR0 = (uint8_t)(data[i] >> 8);
          while ( !( UCSR0A & (1<<UDRE0)) )
          UDR0 = (uint8_t)(data[i]);
        }
        index = 0;
        if (capMode == VOLTAGE){
          capMode = CURRENT;
          ADMUX &= ~(0 << MUX0);
          ADMUX &= ~(1 << MUX1);
          TIFR1 |= 0x01;
        }
        else if(capMode == CURRENT){
          capMode = NONE;
          reading = 0;
          PORTB &= ~(1<<PB5);
        }
      }
    }
  }
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

void USART_Init(uint64_t baud_rate, uint8_t double_speed) {

  uint16_t ubrr;
  if (double_speed) {
    ubrr = ((F_CPU + baud_rate * 4UL) / (baud_rate * 8UL) - 1);
    UCSR0A |= (1 << U2X0);
  } else {
    ubrr = ((F_CPU + baud_rate * 8UL) / (baud_rate * 16UL) - 1);
  }

  UBRR0 = ubrr;
  

  UCSR0B = 0;
  UCSR0B |= (1 << RXEN0) | (1 << TXEN0); // Enable receiver and transmitter
  UCSR0B |= (1 << RXCIE0); // Enable receiver interrupt


  UCSR0C = (1 << UCSZ01) | (1 << UCSZ00); // Set frame: 8data, 1 stp

}


ISR(USART_RX_vect)
{
   char head_aux=head;
   head_aux++;
   if(head_aux==16) head_aux=0;
   if(head_aux == tail) //verifica se RAM FIFO está cheia
    {
    head_aux = UDR0; //descarte do byte recebido (RAM FIFO cheia)
    }
   else
    {
    FIFO[head] = UDR0;  // lê byte recebido via serial e carrega na FIFO
    head++;
    if(head==16) head=0; // reset índice de cabeça (buffer circular)
    }
}