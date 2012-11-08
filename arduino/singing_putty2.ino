/** Singing Putty
* Attribution: multiplexer code appropriated from Elio Bidinost and the Concordia Sensor Lab
*/

const int pinsPerPlayer = 5;
const int numberOfPlayers = 2; //currently limited to 2
int readings[numberOfPlayers][pinsPerPlayer];


// Constants
#define MULTIPLEXER_S0 5
#define MULTIPLEXER_S1 4
#define MULTIPLEXER_S2 3
#define MULTIPLEXER_S3 2

const byte readpin = A0;

// Declare Multiplexer Access Variabless
int pinA, pinB, pinC, pinD;

void setup()
{
  Serial.begin(9600);

  // Set MULTIPLEXER_S0/1/2 Mode
  pinMode(MULTIPLEXER_S0, OUTPUT);
  pinMode(MULTIPLEXER_S1, OUTPUT);
  pinMode(MULTIPLEXER_S2, OUTPUT);
  pinMode(MULTIPLEXER_S3, OUTPUT);
  pinMode(readpin, INPUT);

  // Initialise Multiplexer Access Variabless
  pinA = pinB = pinC = pinD = 0;
}


int readMultiplexer(int pin)
{
  //determine which multiplexer pin to read from
  pinA = pin & 0x01;
  pinB = (pin >> 1) & 0x01;
  pinC = (pin >> 2) & 0x01;
  pinD = (pin >> 3) & 0x01;

  // set multiplexer reading
  digitalWrite(MULTIPLEXER_S0, pinA);
  digitalWrite(MULTIPLEXER_S1, pinB);
  digitalWrite(MULTIPLEXER_S2, pinC);
  digitalWrite(MULTIPLEXER_S3, pinD);

  return analogRead(readpin); //10-bit
} 




void loop ()
{

  for(int i = 0; i < pinsPerPlayer; i++)
  {
    readings[0][i] = readMultiplexer(i)/4; //player 1
    readings[1][i] = readMultiplexer(15-i)/4; //player2
  }
  echoOut();
  delay(5);
}

void echoOut(){
  Serial.write('$'); //start characters
  //iterate over readings, write them to serial
  for(int p = 0; p<numberOfPlayers;p++){
    for(int i = 0; i< pinsPerPlayer;i++){
      if(readings[p][i] == '$' || readings[p][i] == '-')readings[p][i]++;
      Serial.write(readings[p][i]); //readings for player
    }
    if(p!= numberOfPlayers-1)Serial.write('-'); //betwen players
  }
  Serial.write('\n'); //end of set
}


