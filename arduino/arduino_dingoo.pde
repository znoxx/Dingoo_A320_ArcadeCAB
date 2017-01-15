#include <SNESpad.h>

#define DS   11
#define SHCP 12
#define STCP 8

#define RESET_PIN 5
#define POWER_PIN 6
#define HOLD_PIN 7
#define FREE_PIN 9


//"Near" 7hc595 is one connected directly to Arduino. The "Far" one is 
//"cascaded" to it.

//The signals are like this:
// Q7-Q1,Q15 are from high bit to lowest. (128-64-32-16-4-2-1)
// firstly "far" 7hc595 is stuffed, then the near one
// see "send2out"

//state definitions for out1 - "near" 7hc595

#define SELECT 0b01111111
#define START  0b10111111
#define A      0b11011111
#define B      0b11101111
#define X      0b11110111
#define Y      0b11111011
#define LSHIFT 0b11111101
#define RSHIFT 0b11111110

//state definitions for out0 - "far" 7hc595

#define UP     0b01111111
#define DOWN   0b10111111
#define LEFT   0b11011111
#define RIGHT  0b11101111
#define RESET  0b11110111
#define POWER  0b11111011
#define HOLD   0b11111101
#define UNUSED 0b11111110

byte GetAddedState()
{
  byte bRes=0xff;
  if ( digitalRead(RESET_PIN) != HIGH )
    bRes = bRes & RESET;
   
  if ( digitalRead(POWER_PIN) != HIGH )
    bRes = bRes & POWER;
    
  if ( digitalRead(HOLD_PIN) != HIGH )
    bRes = bRes & HOLD;
  
  if ( digitalRead(FREE_PIN) != HIGH )
    bRes = bRes & UNUSED;
    
    return bRes;
  
}

byte decodeNear(int state)
{
  byte res=0b11111111;
  if ( state & SNES_SELECT )
    res = res & SELECT;

  if ( state & SNES_START )
    res = res & START;

  if ( state & SNES_A )
    res = res & A;

  if ( state & SNES_B )
    res = res & B;

  if ( state & SNES_X )
    res = res & X;

  if ( state & SNES_Y )
    res = res & Y;

  if ( state & SNES_L )
    res = res & LSHIFT;

  if ( state & SNES_R )
    res = res & RSHIFT;

  return res;

}

byte decodeFar(int state)
{
  byte res=0xff;
  if ( state & SNES_UP )
    res = res & UP;

  if ( state & SNES_DOWN )
    res = res & DOWN;

  if ( state & SNES_LEFT )
    res = res & LEFT;

  if ( state & SNES_RIGHT )
    res = res & RIGHT;                                       
     
  // the rest shoud be processed in other place - because snes have only 12 buttons  
  return res;
}


void send2out(byte out0, byte out1)
{

  shiftOut(DS,SHCP,MSBFIRST,out0); //far one
  shiftOut(DS,SHCP,MSBFIRST,out1); //near one
  digitalWrite(STCP,HIGH);
  delay(1);
  digitalWrite(STCP,LOW);


}

// setting up arduino pins for connection - as in snespad example
//strobe/clock/data
SNESpad nintendo = SNESpad(2,3,4);

int state = 0x0;
int currentstate = 0x0;
byte nAddedState=0x0;
byte nCurrentAddedState = 0x0; 
byte out0 = 0xff;
byte out1 = 0xff;
void setup() {
  pinMode(13, OUTPUT);

  pinMode(DS,OUTPUT);
  pinMode(SHCP,OUTPUT);
  pinMode(STCP,OUTPUT);
  
  pinMode(RESET_PIN, INPUT);
  pinMode(POWER_PIN, INPUT);
  pinMode(HOLD_PIN, INPUT);
  pinMode(FREE_PIN, INPUT);
  
  digitalWrite(SHCP,LOW);  
  digitalWrite(STCP,LOW);  
  digitalWrite(13,HIGH);

  send2out(0xff,0xff); //pull all high
  state=nintendo.buttons();
  nAddedState = GetAddedState();

}

void loop() {



  currentstate = nintendo.buttons();
  nCurrentAddedState = GetAddedState();

  if((state != currentstate) || (nAddedState != nCurrentAddedState))
  {
   
    out0=decodeFar(currentstate);   
    out1=decodeNear(currentstate);
    //all buttons pressed - means there is no controller
    if (  currentstate == 0xffffffff )
         {
           out0 = 0xFF;
           out1 = 0xFF;
         }
    out0=out0 & nCurrentAddedState;
    send2out(out0,out1);
    
  }
  state = currentstate;
  nAddedState = nCurrentAddedState;
  
 

}


