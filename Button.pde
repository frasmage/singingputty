//button type constants, what they will do
final int BUTTON_TYPE_NULL = 0;
final int BUTTON_TYPE_CHALLENGE_1 = 1;
final int BUTTON_TYPE_CHALLENGE_2 = 2;
final int BUTTON_TYPE_GARDEN_1 = 3;
final int BUTTON_TYPE_GARDEN_2 = 4;

class Button {
  //fields
  float x;
  float y;
  float w;
  float h;
  boolean selected = false;
  boolean hovered = false;
  int type = 0;
  PFont font = arista;
  color fontColor = color(#9429C7);
  color selectFontColor = color(255);
  color bgColor = color(255);
  color borderColor = color(#9429C7);
  color selectBgColor = borderColor;
  color selectBorderColor = borderColor;

//constructor
  public Button(float x, float y, float w, float h, int type) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.type = type;
  }
  
  //methods
  public void trigger() {
    //perform action based on type
    switch(type) {
    case BUTTON_TYPE_NULL:
      loadStartMenu();
      break;
    case BUTTON_TYPE_CHALLENGE_1:
      loadChallenge(1);
      break;
    case BUTTON_TYPE_CHALLENGE_2:
      loadChallenge(2);
      break;
    case BUTTON_TYPE_GARDEN_1:
      loadGarden(1);
      break;
    case BUTTON_TYPE_GARDEN_2:
      loadGarden(2);
    }
  }
  public String title(){
    //display title for button
    switch(this.type) {
    case BUTTON_TYPE_NULL:
      return "Main Menu";
    case BUTTON_TYPE_CHALLENGE_1:
      return "1-Player Challenge";
    case BUTTON_TYPE_CHALLENGE_2:
      return "2-Player Challenge";
    case BUTTON_TYPE_GARDEN_1:
      return "Garden Mode";
    case BUTTON_TYPE_GARDEN_2:
      return "Co-op Garden Mode";
    }
    return null;
  }
  
  public String description() {
    //trigger action description
    switch(type) {
    case BUTTON_TYPE_CHALLENGE_1:
      return "Try to get the best score in this one player challenge!";
    case BUTTON_TYPE_CHALLENGE_2:
      return "Compete with a friend for the highest score!\n";
    case BUTTON_TYPE_GARDEN_1:
      return "Relax and conduct your own Singing Putty symphony";
    case BUTTON_TYPE_GARDEN_2:
      return "Conduct a Singing Putty symphony with a friends";
    }
    return null;
  }
  public String details() {
    //trigger action details
    switch(type) {
    case BUTTON_TYPE_CHALLENGE_1:
      return "- Use your Singing Putty on your game board to copy the on-screen connnections. \n"
        +"- Careful! you're racing against the Timer in the middle! \n"
        +"- The longer you play, the harder it gets but the more point you could win!";
    case BUTTON_TYPE_CHALLENGE_2:
      return "- Be the first player to use their Singing Putty to copy the on-screen connections. \n"
        +"- Careful! You're racing against the Timer in the middle! \n"
        +"- The longer you play, the harder it gets but the more point you could win!";
    case BUTTON_TYPE_GARDEN_1:
      return "- Make different connections on your gameboard for the flowers to sing!\n "
        +"- Stretch the Putty to get different sounds!\n"
        +"- Remember that connection needs to be passing through the source in the center!\n"
        +"- Why not sculpt your Singing Putty into Monsters to live in the garden?";
    case BUTTON_TYPE_GARDEN_2:
      return "- Make different connections on your gameboard for the flowers to sing!\n "
        +"- Stretch the Putty to get different sounds!\n"
        +"- Remember that connection needs to be passing through the source in the center!\n"
        +"- Why not sculpt your Singing Putty into Monsters to live in the garden?\n"
        +"- You can also play this mode alone with two boards for more sounds.";
    }
    return null;
  }
  public void draw() {
    //draw box
    textFont(font, h/2);
    textAlign(CENTER);
    if (hovered) {
      fill(selectBgColor);
      stroke(selectBorderColor);
    }
    else {
      fill(bgColor);
      stroke(borderColor);
    }
    strokeWeight(h/5);
    
    rect(x, y, w, h);
    
    //draw text
    if (hovered)fill(selectFontColor);
    else fill(fontColor);
    text(title(), x+w/2, y+h/2+h/5);
  }

  public boolean hitTest(float x, float y) {
    return (x > this.x && y>this.y && x < this.x+this.w && y < this.y+this.h);
  }
}

