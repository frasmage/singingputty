/** Singing Putty
 * All code (c) Sean Fraser
 *
 */
//Libraries
import pitaru.sonia_v2_9.*;
import processing.serial.*;
import java.awt.Color;

Serial port; //serial connection
//Minim minim; //audio player

//number of readings to expect
//should not exceed the number of pins being read by Arduino
final int maxPlayers = 2;
final int pinsPerPlayer = 5;
int counter = 0; //sorting received data
int[][] values = new int[maxPlayers][pinsPerPlayer]; //array of values received from arduino
boolean verboseMode = false; //output serial readings
boolean debugMode = false; //allow number keys to control players

//Game Variables
int numberOfPlayers = 2;
Button[] buttons;
//constants for displayMode states
final int DISPLAY_STARTUP = 0;
final int DISPLAY_CHALLENGE = 1;
final int DISPLAY_GARDEN = 2;
int displayMode = DISPLAY_STARTUP;

//challenge mode variables
//timer variables
int timer = 0; //time limit for current round
final int timerMax = 180; //max time limit in frames
int currentTimerMax = timerMax; //accelerating time limit
final float timerDecrement = .02; //amount by which timer accelerates
int rounds = 0; //how many rounds have been played
int countDownTimer=0; //delay between rounds
//round key variables
int expectedCount = 0; //how many pins need to be active to win
int maxExpected = 1; //limit to number of expected pins
final int roundsForHigherExpectations = 4; //number of rounds needed for difficulty to increase, will increase exponentially
boolean[] expectedSet = new boolean[pinsPerPlayer]; //current win key
boolean[] previousExpectedSet = new boolean[pinsPerPlayer]; //last win key, to make sure we don't ask for the same things twice
//scoring variables
int[] scores = new int[maxPlayers];
int lastWinner = -1;


//garden mode variables
SPFlower[][] flowers = new SPFlower[maxPlayers][pinsPerPlayer];

//General Animation vars
color[] playerColors = {
  #FF0066, #469F38, color(255, 255, 0), color(255, 0, 255)
};
PFont defaultFont;
PFont arista;
String[] imagePaths = {
  "pink.svg", "green.svg", "blue.svg", "orange.svg", "purple.svg"
};
PShape[] icons = new PShape[imagePaths.length]; //the five vector images
Point[] drifters = new Point[6]; //origin of shapes that float in space
int[] driftersImg = new int [drifters.length]; //index of images of shapes
//audio vars
String[] audioPaths = {
  //"aaa_low.wav", "eee_low.wav", "eee_med.wav", "oin_med.wav", "ooo_high.wav"
  "mid_high_2.wav", "mid_low_2.wav", "mid_low.wav", "mid_sound_3.wav", "purring.wav", 
  "low_sound_2.wav", "mid_high_3.wav", "mid_low_3.wav", "mid_low_4.wav", "mumbling.wav"
};
Sample[][] voices = new Sample[maxPlayers][pinsPerPlayer]; //all player audio samples
Sample winChime;
Sample loseChime;


///\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\\\
void setup() {
  ///\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\\\
  size(displayWidth, displayHeight-30);
  //size(1280,600);
  frame.setBackground(new Color(255,255,255));
  frame.setTitle("Singing Putty!");
  frameRate(15);
  smooth();

  //set up Serial
  port = new Serial(this, Serial.list()[4%Serial.list().length], 9600);
  //expect to receive n bytes per player plus separators
  port.buffer(pinsPerPlayer *(maxPlayers+1));

  //load external resources
  defaultFont = createFont("futura", height/20); //in case external font files fail to load
  try {
    if (height>700)arista = loadFont("zAristaLight-96.vlw");
    else arista = loadFont("zAristaLight-48.vlw");
  }
  catch(Exception e) {
    arista =defaultFont;
  }
  for (int i =0;i<imagePaths.length;i++) {
    imagePaths[i] = "data/"+imagePaths[i];
    icons[i] = loadShape(imagePaths[i%imagePaths.length]);
  }
  //set up audio
  Sonia.start(this);

  for (int i=0;i<maxPlayers;i++) {
    for (int j=0;j<pinsPerPlayer;j++) {      

      voices[i][j] = new Sample(audioPaths[(j+i*pinsPerPlayer)%audioPaths.length]);
      voices[i][j].setVolume(1.5);
    }
  }
  winChime = new Sample("winner.wav");
  loseChime = new Sample("buzzer.wav");

  strokeJoin(ROUND);
  strokeCap(ROUND);
  
  for(int i = 0; i<drifters.length;i++){
    drifters[i] = new Point(random(width),random(height));
    driftersImg[i] = floor(random(icons.length));
  }
  
  //begin the game
  loadStartMenu();
}


//scene initializers
void loadStartMenu() {
  displayMode = DISPLAY_STARTUP;

  //create menu buttons
  buttons = new Button[4];
  for (int i = 0;i<buttons.length;i++) {
    buttons[i] = new Button(width/8, height/3.75+i*height/8, width/4.4, height/12, i+1);
  }
  
  //stop any running audio
  for (int i=0;i<maxPlayers;i++) {
    for (int j=0;j<pinsPerPlayer;j++) {
      voices[i][j].stop();
    }
  }
}

void loadChallenge(int players) {
  displayMode = DISPLAY_CHALLENGE;

 //create return button
  buttons = new Button[1];
  buttons[0] = new Button(0, 0, 0, 0, 0);

//reset challenge vars
  numberOfPlayers = (players < maxPlayers)?players:maxPlayers;
  rounds = -1;
  maxExpected = 1;
  for (int i = 0; i<scores.length;i++) {
    scores[i] = 0;
  }
  challengeNewRound();
}

void loadGarden(int players) {
  displayMode = DISPLAY_GARDEN;
  numberOfPlayers = (players < maxPlayers)?players:maxPlayers;
  buttons = new Button[1];
  buttons[0] = new Button(width/24, height/18, width/5, height/16, 0);

//reset garden vars
  for (int i = 0; i<numberOfPlayers;i++) {
    for (int j =0;j<pinsPerPlayer;j++) {
      float x = random(width/10, width-width/10);
      flowers[i][j] = new SPFlower(new Point(x, height/2+i*height/8), 
      new Point(x, height), icons[j%icons.length]);
    }
  }
}

///\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\\\
void draw() {
  ///\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\\\

  background(255);
  
  //animate drifting shapes
  for(int i = 0; i<drifters.length;i++){
    drifters[i].x+= width/60;
    if(drifters[i].x > width+height/16){
      drifters[i].x = -height/16;
      drifters[i].y = random(height);
      driftersImg[i] = floor(random(icons.length));
    }
    icons[driftersImg[i]].enableStyle();
    shape(icons[driftersImg[i]],drifters[i].x,drifters[i].y,height/8,height/8);
  }
  
  //--------------------------------------------------------//
  if (displayMode == DISPLAY_STARTUP) {
    //big box
    fill(#469F38);
    noStroke();
    rect(width/10, height/10, width/10*8, height/10*8);

    //details box
    fill(255);
    stroke(#9429C7);
    Rect detailsBox = new Rect(width/5.25*2, buttons[0].y, width/2.1, (buttons[buttons.length-1].y+buttons[buttons.length-1].h -buttons[0].y));
    detailsBox.draw();

    //main title
    fill(255);
    textFont(arista);
    textAlign(CENTER);
    text("Singing Putty!", width/2, height/5);
    
    //buttons
    for (int i = 0;i<buttons.length;i++) {
      buttons[i].draw();
      
      //if a button is hovered, fill the details box with detail information
      if (buttons[i].hovered) {
        fill(#9429C7);
        rect(buttons[i].x+buttons[i].w, buttons[i].y+buttons[i].h/3, width/40, buttons[i].h/3);
        
        textFont(arista,height/35);
        textAlign(LEFT);
        fill(#ED8A09);
        text(buttons[i].description(), detailsBox.x+width/20,detailsBox.y+height/30,detailsBox.w-width/10, height/15);
        fill(0);
        textFont(arista,height/35);
        text(buttons[i].details(), detailsBox.x+width/20,detailsBox.y+height/30+height/15,detailsBox.w-width/10, detailsBox.h-height/15-height/30);
      }
    }
  }




  //--------------------------------------------------------//
  //audio
  else { //if not start menu, play audio for powered pins, stop inactive ones
    for (int i = 0; i < numberOfPlayers;i++) {
      for (int j = 0; j <pinsPerPlayer;j++) {
        float newLevel = (values[i][j] > 100) ? constrain( map( values[i][j], 200, 250, .3, 1), .3, 1) : 0;
        if (newLevel>0) {
          if (!voices[i][j].isPlaying())voices[i][j].repeat();
          voices[i][j].setSpeed(newLevel*2.5);
          //filters[i][j].setMultiplier(newLevel);
        }
        else voices[i][j].stop();
      }
    }
  }




  //--------------------------------------------------------//
  if (displayMode == DISPLAY_CHALLENGE) {

    //board display vars
    float radius = height/2 - height/8;
    float originX = width*3/5;
    float originY = height/2;
    float angleOffset = -PI/3.5;

    //background
    fill(255);
    stroke(0);
    strokeWeight(height/20);
    ellipseMode(CENTER);
    ellipse(originX, originY, radius*2, radius*2);

    //shapes
    for (int j = 0; j<pinsPerPlayer;j++) {

      //draw shapes
      float x = originX + radius * cos(TWO_PI/icons.length * j+angleOffset);
      float y = originY + radius * sin(TWO_PI/icons.length * j+angleOffset);
      shapeMode(CENTER);


      if (expectedSet[j] && countDownTimer <=0) {
        icons[j].enableStyle();
        
        //draw power line from expected pins to center
        stroke(255, max(255-rounds*3, 0), 0);
        strokeWeight(height/60);
        noFill();
        bezier(originX, originY, originX+random(-height/10, height/10), originY+random(-height/10, height/10), 
        x+random(-height/10, height/10), y+random(-height/10, height/10), x, y);
        
        //circle under shapes
        fill(0);
        noStroke();
        ellipse(x, y, height/5, height/5);
      }
      else {
        //circle under shapes
        fill(0);
        noStroke();
        ellipse(x, y, height/5, height/5);
        
        //if pin not expected make white
        icons[j].disableStyle();
        fill(255);
        noStroke();
      }
      
      //draw the shape
      shape(icons[j], x, y, height/5, height/5);
      
      //draw concentric ellipses around player selections
      ellipseMode(CENTER);
      for (int i = 0; i< numberOfPlayers; i++) {

        float level = (values[i][j] > 100) ? constrain( map( values[i][j], 200, 250, 0, 1), 0, 1) : 0;
        if (level > 0) {
          noFill();
          stroke(playerColors[i]);
          strokeWeight(level*height/40);
          ellipse(x, y, height/5.7+i*height/25, height/5.7+i*height/25);
        }
      }
    }

    //set up box area for display scores
    Rect scoreBox = new Rect(width/20, height/5, width/5, height*3/5);
    float scoreInset = height/40;
    float scoreSectionHeight = (scoreBox.h - scoreInset-height/7.5)/(numberOfPlayers);
    Rect sectionBox = new Rect(scoreBox.x+scoreInset, 0, scoreBox.w - scoreInset*2, scoreSectionHeight);

    if (buttons[0].x ==0) { //reposition the menu button into the menu
      buttons[0].x = scoreBox.x+scoreInset;
      buttons[0].y = scoreBox.y+scoreBox.h-scoreInset-height/15;
      buttons[0].w = scoreBox.w - scoreInset*2;
      buttons[0].h = height/15;
    }
    
    //title above box
    fill(0);
    textAlign(CENTER);
    textFont(arista,height/20);
    text("Singing Putty!",scoreBox.center().x, scoreBox.y-height/30);

    //draw box frame
    fill(255);
    stroke(0);
    strokeWeight(height/60);
    scoreBox.draw();
    
    //draw the players' scores
    int scoreOffset = height/2;
    textAlign(CENTER);
    for (int i = 0; i<numberOfPlayers;i++) {
      sectionBox.y = scoreBox.y+i*(scoreSectionHeight+scoreInset)+scoreInset;
      fill(playerColors[i]);
      stroke(playerColors[i]);
      sectionBox.draw();

      textFont(arista, height/20);
      fill(255);
      text("Player "+(i+1), sectionBox.x+sectionBox.w/2, sectionBox.y+sectionBox.h/3);
      text(scores[i], sectionBox.x+sectionBox.w/2, sectionBox.y+sectionBox.h/3*2);
    }
    //draw the menu button
    for (int i = 0;i<buttons.length;i++) {
      buttons[i].draw();
    }

    //draw the timer
    if (countDownTimer > 0) {
      countDownTimer--;
      noStroke();
      ellipseMode(CENTER);
      fill(0);
      ellipse(originX, originY, height/5, height/5);
      textFont(defaultFont, 30);
      textAlign(CENTER);
      fill(255, max(255-rounds*3, 0), 0);
      text(ceil(countDownTimer/30.0), originX, originY+height/60);
    }
    else {
      lastWinner = -1;
      //display timer
      noStroke();
      ellipseMode(CENTER);
      fill(0);
      ellipse(originX, originY, height/5, height/5);
      fill(255, max(255-rounds*3, 0), 0);
      arc(originX, originY, height/6, height/6, TWO_PI-TWO_PI*timer/currentTimerMax+PI*3/2, TWO_PI+PI*3/2);



      //check for winner
      for (int i= 0; i<numberOfPlayers;i++) {
        if (challengeCheckForScoring(i)) {
          winChime.play();
          lastWinner = i;
          challengeNewRound();
        }
      }
      //check for timer end
      timer--;
      if (timer < 0) {
        loseChime.play();
        challengeNewRound();
      }
    }
  }
  
  
  
  //--------------------------------------------------------//
  else if (displayMode == DISPLAY_GARDEN) {
    //draw the title
    fill(0);
    textMode(CENTER);
    textFont(arista, height/8);
    text("Singing Putty!",width/2,height/8);

    //draw and animate the flowers
    for (int i = 0;i<numberOfPlayers;i++) {
      for (int j = 0;j<pinsPerPlayer;j++) {
        float newLevel=0;
        if (values[i][j] > 100) {
          newLevel = constrain(map(values[i][j], 200, 250, 0, 1), 0, 1);
          flowers[i][j].enabled = true;
        }
        else flowers[i][j].enabled = false;
        float newHeight = map(newLevel, 0, 1, height*3/4, height/4)-i*height/8;

        flowers[i][j].targetCenter.y = newHeight;
        flowers[i][j].update();
        flowers[i][j].draw();
      }
    }

    for (int i = 0;i<buttons.length;i++) {
      buttons[i].draw();
    }
  }
}

boolean challengeCheckForScoring(int player) {
  //check if player has all the right pins and none of the wrong ones
  for (int j= 0; j < pinsPerPlayer;j++) {

    if (expectedSet[j] != (values[player][j] > 100)) {
      return false;
    }
  }
  //otherwise increment score and return true
  scores[player] += max((ceil(float(rounds)/float(roundsForHigherExpectations)))*expectedCount, 1);
  return true;
}


void challengeNewRound() {
  //add cooldown period, reduces in length as the challenge increases
  println(currentTimerMax/timerMax);
  countDownTimer = int(3* ceil(frameRate)* (float(currentTimerMax)/float(timerMax)));
  //start new round
  rounds++;
  
  //check if difficulty should increase
  if (rounds % roundsForHigherExpectations*maxExpected == 0 && maxExpected < pinsPerPlayer+1)maxExpected++;
  //reset timer
  timer =currentTimerMax = constrain(int(timerMax - timerMax * timerDecrement * rounds), 30, timerMax);

  //populate new set
  expectedCount = floor(random(1, maxExpected-.1)); //determine how many pins for next key
  while (arraysAreEqual (expectedSet, previousExpectedSet)) { //make sure the new set is different than the old one
    int activeCount = expectedCount;
    //clear set
    for (int i = 0; i<expectedSet.length;i++) {
      expectedSet[i] = false;
    }
    //populate set
    while (activeCount > 0) {
      int index = floor(random(pinsPerPlayer));
      if (!expectedSet[index]) {
        expectedSet[index] = true;
        activeCount--;
      }
    }
  }
  arrayCopy(expectedSet, previousExpectedSet);
}



///\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\\\
// Interaction functions
///\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\\\
//all of these are purely for button interaction
void mousePressed() {
  for (int i = 0; i<buttons.length;i++) {
    if (buttons[i].hitTest(mouseX, mouseY)) {
      buttons[i].selected = true;
      buttons[i].draw();
    }
  }
}
void mouseDragged() {
  for (int i = 0; i<buttons.length;i++) {
    if (buttons[i].selected) {
      if (!buttons[i].hitTest(mouseX, mouseY)) {
        buttons[i].selected = false;
        buttons[i].hovered = false;
      }
    }
  }
}

void mouseMoved() {
  for (int i = 0; i<buttons.length;i++) {
    if (buttons[i].hitTest(mouseX, mouseY)) {
      buttons[i].hovered = true;
    }
    else {
      buttons[i].hovered = false;
    }
  }
}

void mouseReleased() {
  for (int i = 0; i<buttons.length;i++) {
    if (buttons[i].selected && buttons[i].hitTest(mouseX, mouseY)) {
      buttons[i].trigger();
      return;
    }
    buttons[i].selected = false;
  }
}

//for debug mode
void keyPressed() {
  if (key == 'd' || key == 'D')debugMode = !debugMode;
  else if(key == 'v' || key == 'V')verboseMode = !verboseMode;
  if (debugMode) {
    if (key >48 && key <54) {
      values[0][key-49] = 255;
    }
    if (key >53 && key <58) {
      values[1][key-54] = 255;
    }
    if (key == 48) {
      values[1][4] = 255;
    }
  }
}

void keyReleased() {
  if (debugMode) {
    if (key >48 && key <54) {
      values[0][key-49] = 0;
    }
    if (key >53 && key <58) {
      values[1][key-54] = 0;
    }
    if (key == 48) {
      values[1][4] = 0;
    }
  }
}

///\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\\\
// Background functions
///\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\\\
boolean arraysAreEqual(boolean[] a, boolean[] b) {
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (int i = 0; i<a.length;i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}


//called whenever inputCount+1 bytes are available
void serialEvent(Serial port) {

  //as long as we have bytes
  while (port.available () > 0) {
    //read oldest value
    int val = port.read();
    //if its a starter
    if (val == '$') {
      //grab the next n values
      counter = 0;
      if (verboseMode) print("player "+(counter+1)+": ");
      for (int i =0;i<pinsPerPlayer;i++) {
        values[counter][i] = port.read();
        if (verboseMode) print(values[counter][i] + ", ");
      }
    }
    if (val == '-' && counter >-1 && counter <maxPlayers-1) {
      counter++;
      if (verboseMode)print(" player "+(counter+1)+": ");
      for (int i =0;i<pinsPerPlayer;i++) {
        values[counter][i] = port.read();
        if (verboseMode)print(values[counter][i] + ", ");
      }
    }
    if (val == '\n') {
      counter = -1;
      if (verboseMode)println(' ');
      return;
    }
    //otherwise, wait until buffer refills again
    else return;
  }
}

void stop()
{
  //dispose of resources
  Sonia.stop();
  super.stop();
}

