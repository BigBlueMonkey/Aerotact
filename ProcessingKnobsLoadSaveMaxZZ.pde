import controlP5.*;
import processing.serial.*;
import java.io.FileOutputStream;
import java.io.FileInputStream;
import java.io.IOException;


//CLASSES
class Frame{
  public byte[] pixelValues;
  
  public Frame(){
    pixelValues = new byte[matrix_width * matrix_height];
    for(int i = 0; i < matrix_width * matrix_height; i++)
      pixelValues[i] = 0;
  }
}

//CONSTANTS

final int maxKnobValue = 100;    //Maximum value knobs can reach

final int matrix_width = 8;
final int matrix_height = 8;

final int knob_spacing = 64;
final int knob_x_offset = 196;
final int knob_y_offset = 64;

final int serial_ports_x = 16;
final int serial_ports_y = 64;

final int current_frame_x = 196;
final int current_frame_y = 600;

final int fpsNumberbox_x = 400;
final int fpsNumberbox_y = 600;

final int saveButton_x = 16;
final int saveButton_y = 256;

final int openButton_x = 16;
final int openButton_y = 272;

final int maxFrames = 255;

//GLOBAL VARIABLES

ControlP5 cp5;  //The UI controller
Serial serialPort = null;  //Serial interface
ArrayList<Frame> frames;  //The list of current frames
Knob[] knobs;  //The knobs
DropdownList serialPortsList; //List of available Serial interfaces
Numberbox fpsBox; //To set FPS
Button playButton; //The Play/Pause button
Button removeFrameButton; //button to remove a frame
Button addFrameButton;  //to add a frame
int currentFrame = 1;  //The current frame shown on screen
Button nextFrameButton;
Button prevFrameButton;
Button saveButton;
Button openButton;
Numberbox framesCount;  //Label of the total number of frames
Numberbox fpsNumberbox; //Sets the FPS
int playingFrame = 1;
boolean knobEventsEnabled = true;  //Setting this to false disables the knob events (Used to load values from memory)
int lastFrameTime = 0;

void saveToFile(File file){
  try{
    OutputStream stream = new FileOutputStream(file);
    
    //Saves the number of frames first
    stream.write((byte)frames.size());
    
    //Saves all the frames
    for(Frame f : frames){
      for(byte b : f.pixelValues){
        stream.write(b);
      }
    }
    
    stream.close();
  }catch(IOException e){
    println("Error saving file");
  }
}

void loadFromFile(File file){
  try{
    InputStream stream = new FileInputStream(file);
    
    //Clears the frame array
    frames.clear();
    
    //The first byte of the file is the number of frames to load
    byte framesNumber = (byte)stream.read();
    
    for(int i = 0; i < framesNumber; i++){
      Frame f = new Frame();
      for(int j = 0; j < matrix_width * matrix_height; j++){
        f.pixelValues[j] = (byte)stream.read();
      }
      addFrame(f);
    }
    
    stream.close();
  }catch(IOException e){
    println("Error opening file");
  }
}

void addFrame(){
    Frame f = new Frame();
    addFrame(f);
}

void addFrame(Frame f){
  if(frames.size() < 255){
    frames.add(f);
    framesCount.setMax(frames.size());
    
    //Jumps to the last frame added
    currentFrame = frames.size();
    onFrameSelect();
  }
}

void removeFrame(int index){
  if(frames.size() > 1){
    frames.remove(index);
    
    //Moves the currentFrame counter back if its frame is removed
    if(currentFrame > frames.size()){
      currentFrame--;
    }
    
    framesCount.setMax(frames.size());
    
    //Updates the scene
    onFrameSelect();
    
    //Resets the animation
    playingFrame = 1;
  }
}

void onFrameSelect(){
  knobEventsEnabled = false;
  
  byte[] fr = frames.get(currentFrame - 1).pixelValues;
  for(int i = 0; i < (matrix_width * matrix_height); i++){
    knobs[i].setValue((float)(fr[i]));
  }
  
  framesCount.setValue((float)currentFrame);
    
  knobEventsEnabled = true;
}

void drawKnobs(int x, int y, int width, int height, int spacing){
  knobs = new Knob[matrix_width * matrix_height];
  
  for(int i = 0; i < height; i++)
    for(int j = 0; j < width; j++){
      knobs[i * matrix_width + j] = cp5.addKnob("knob" + (i * matrix_width + j))
      .setPosition(x + j * spacing, y + i * spacing)
      .setMax(maxKnobValue)
      .setResolution(maxKnobValue)
      .setLabel("" + ((i * matrix_width + j) + 1));
    }
}

void updateSerialPortsList(){
  String[] serialPorts = Serial.list();
  serialPortsList = cp5.addDropdownList("serialPorts").setPosition(serial_ports_x, serial_ports_y);
  
  for(int i = 0; i < serialPorts.length; i++){
    serialPortsList.addItem(serialPorts[i], i);
  }
}

void controlEvent(ControlEvent event){
  if(event.getController() == nextFrameButton){
    if(currentFrame < frames.size())
      currentFrame++;
    
    onFrameSelect();
    
  }
  else if(event.getController() == prevFrameButton){
    if(currentFrame > 1)
      currentFrame--;
    
    onFrameSelect();
  }
  //If the event is fired by a knob
  else if(event.getName().indexOf("knob") == 0 && knobEventsEnabled){
    //Save all the values of the knobs into the current
    //Frame's matrix
    
    for(int i = 0; i < (matrix_width * matrix_height); i++){
      frames.get(currentFrame - 1).pixelValues[i] = (byte)knobs[i].getValue();
    }
  }
  else if(event.getController() == addFrameButton){
    addFrame();
  }
  else if(event.getController() == removeFrameButton){
    removeFrame(currentFrame - 1);
  }
  else if(event.getController() == serialPortsList){
    try{
      Serial temp = new Serial(this, Serial.list()[(int)serialPortsList.getValue()], 115200);
      serialPort = temp;
      
    }catch(ArrayIndexOutOfBoundsException e){
    
    }
    catch(RuntimeException e){
      println("Port busy");
    }
  }
  else if(event.getController() == saveButton){
    selectOutput("Select where to save:", "saveToFile");
  }
  else if(event.getController() == openButton){
    selectInput("Select where to open from:", "loadFromFile");
  }
}

void sendFrame(int frame){
  if(serialPort != null){
    for(byte i = 0; i < matrix_width * matrix_height; i++){
      try{
        serialPort.write(i);
        serialPort.write(frames.get(frame - 1).pixelValues[i]);
      }catch(ArrayIndexOutOfBoundsException e){
        println("Out of bounds");
      }
    }
  }
}

void setup(){ 
  size(960, 720);
  background(32);
  
  //Sets up the ControlP5
  cp5 = new ControlP5(this);
  
  //Creates the frames list
  frames = new ArrayList<Frame>();
  
  //Draw the knobs
  drawKnobs(knob_x_offset, knob_y_offset, matrix_width, matrix_height, knob_spacing);
  
  //Initializes the Serial ports list
  updateSerialPortsList();
  
  //Creates the frame navigation buttons
  nextFrameButton = cp5.addButton("nextFrameButton").
              setPosition(current_frame_x + 64, current_frame_y + 64).
              setLabel(">");
              
  prevFrameButton = cp5.addButton("prevFrameButton").
              setPosition(current_frame_x, current_frame_y + 64).
              setLabel("<");
              
  addFrameButton = cp5.addButton("addFrameButton").
              setPosition(current_frame_x + 136, current_frame_y).
              setSize(24, 24).
              setLabel("+");      
              
  removeFrameButton = cp5.addButton("removeFrameButton").
              setPosition(current_frame_x + 164, current_frame_y).
              setSize(24, 24).
              setLabel("-"); 
              
              
  framesCount = cp5.addNumberbox("framesCount")
                .setPosition(current_frame_x, current_frame_y)
                .setSize(128, 24)
                .setValue(currentFrame)
                .setLabel("Current Frame")
                .setMin(1)
                .lock();
        
  fpsNumberbox = cp5.addNumberbox("fpsNumberbox")
                .setPosition(fpsNumberbox_x, fpsNumberbox_y)
                .setMin(1)
                .setMax(60)
                .setValue(30)
                .setLabel("FPS");
                
  saveButton = cp5.addButton("saveButton")
                .setPosition(saveButton_x, saveButton_y);
    
  openButton = cp5.addButton("openButton")
                .setPosition(openButton_x, openButton_y);
                
              
  //Adds a frame
  addFrame();
}

void draw(){
  //If the frame interval has expired
  if(millis() > lastFrameTime + (1000/fpsNumberbox.getValue())){
    sendFrame(playingFrame);
    playingFrame = ((playingFrame + 1) % frames.size()) + 1;
    lastFrameTime = millis();
  }
}
