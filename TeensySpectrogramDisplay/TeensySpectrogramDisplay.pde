/**
 * LiveSpectrogram
 * Takes successive FFTs from Serial port and renders them onto the screen as grayscale, scrolling left.
 *
 * Dan Ellis dpwe@ee.columbia.edu 2010-01-15
 * Clemens Wegener clemens.wegener@uni-weimar.de 2021-03-15
 */
 
import processing.serial.*;
import java.util.ArrayDeque;
import java.util.Iterator;
import java.util.Arrays;

ArrayDeque<Frame> spectrogram = new ArrayDeque<Frame>();

Serial myPort;    // The serial port
int baudrate = 115200;
String operatingSystem = "Linux"; // set Linux or Windows here
int lf = 10;      // ASCII linefeed
int fftSize = 128;
float max_freq = 10000; // max frequency on y-axis in Hz
float sample_rate = 44100;
int win_width = 800;
int stroke_w = 1;
int stroke_h = 6;
int colmax = win_width / stroke_w;
int rowmax = (int) (max_freq/sample_rate*2*fftSize);
int win_height = rowmax * stroke_h;
boolean newFFTData = false;
int env_min = -60;
int env_max = -11;
boolean serialInited = false;
int loopcount = 0;

public void settings() {
  size(win_width, win_height, P2D);
}

void setup()
{
  initializeSpectrogram(colmax, fftSize);
  initSerial();
  colorMode(HSB, 255);
  
}

void draw()
{
  background(0);
  /*
  if (serialInited) {
        // serial is up and running
        try {
            getData();
        } catch (RuntimeException e) {
            // serial port closed :(
            serialInited = false;
            println("Runtime Exception happend!");
        }
    } else {
        // serial port is not available. bang on it until it is.
        //myPort.stop();
        initSerial();
    }
  */
  
  getData();
  if(newFFTData)
  { //<>//
    newFFTData = false;
    Iterator<Frame> it = spectrogram.iterator();
    int i = 0;
    float prev_env = 0;
    while (it.hasNext())
    {
      Frame f = it.next();
      f.drawFFTColAtPos(i, stroke_w, stroke_h);
      f.drawEnvelopeAtPosFromPrev(i, prev_env);
      f.drawThresholdCrossedAtPos(i, env_min, env_max);
      f.drawSoundIDLocAtPos(i);
      f.drawSoundLabelAtPos(i);
      prev_env = f.getEnvelope();
      i=i+1;
    }
    
    drawFreqScale();
    drawEnvScale();
  }else loopcount++;
  if (loopcount>100){
    myPort.stop();
    serialInited = false;
    println("resetting serial conncection");
    initSerial();
    loopcount = 0;
  }
  //println(frameRate);
}

int getData() 
{
  int linecount = 0;
  Frame[] bufferFrames = new Frame[128];
  for(int i=0; i<128; i++) 
  {
    bufferFrames[i]=new Frame(fftSize);
  }
  int start_frame = 0;
  int frame_num = 0;
  boolean start_set = false;
  while (myPort.available() > 0)
  {
    linecount++;
    byte[] inBuffer = new byte[fftSize+3];
    int cnt = myPort.readBytesUntil(lf,inBuffer);
    // if the first byte is '0', then it's sound id data
    if (inBuffer[0]==0 && cnt >= 5)
    {
      frame_num = inBuffer[1]+128;
      if(!start_set) 
      {
        start_frame = frame_num;
        start_set = true;
      }
      bufferFrames[frame_num].setSoundID(inBuffer[2]);
      
      String soundLabel = new String(inBuffer);
      // Show it text area
      soundLabel = soundLabel.substring(2);
      bufferFrames[frame_num].setSoundLabel(soundLabel);
    }
    // if the first byte is '1', then it's FFT data
    else if (inBuffer[0]==1 && cnt == fftSize+3)
    {
      frame_num = inBuffer[1]+128;
      if(!start_set) 
      {
        start_frame = frame_num;
        start_set = true;
      }
      bufferFrames[frame_num].setFFTfromByteArray(inBuffer, 2, 0, fftSize);
    }
    // if the first byte is '2', then it's envelope data
    else if (inBuffer[0]==2 && cnt == 4)
    {
      frame_num = inBuffer[1]+128;
      if(!start_set) 
      {
        start_frame = frame_num;
        start_set = true;
      } 
      bufferFrames[frame_num].setEnvelope((float) -inBuffer[2]);
    }
    // if the first byte is '3', then it's event detector data
    else if (inBuffer[0]==3 && cnt == 4)
    {
      frame_num = inBuffer[1]+128;
      if(!start_set) 
      {
        start_frame = frame_num;
        start_set = true;
      }
      float thres_val = -inBuffer[2];
      bufferFrames[frame_num].setThresholdCrossedAt(thres_val);
    }
    else if (inBuffer[0]==4 && cnt >= 3)
    {
      frame_num = inBuffer[1]+128;
      if(!start_set) 
      {
        start_frame = frame_num;
        start_set = true;
      }
      String greeting = new String(inBuffer);
      // Show it text area
      greeting = greeting.substring(2);
      println(greeting);
    }
    else 
    {
      //printArray(inBuffer);
      println("message unknown: failed to read from serial");
    }
  }
  if (linecount>0)
  {
    if(frame_num-start_frame>0)
    {
      for(int i=start_frame; i<frame_num; i++){  
        spectrogram.remove();
        spectrogram.add(bufferFrames[i]);
      }
    }
    else
    {
      for(int i=start_frame; i<128; i++){  
        spectrogram.remove();
        spectrogram.add(bufferFrames[i]);
      }
      for(int i=0; i<frame_num; i++){  
        spectrogram.remove();
        spectrogram.add(bufferFrames[i]);
      }
    }
  }
  
  if(linecount>0) newFFTData = true;

  return linecount;
}

void drawFreqScale()
{
  int pl = 10;
  int w = width;
  int cnt = 10;
  float vd = height/cnt;
  float freq_inc =  max_freq / (float)(1000 * cnt);
  textSize(10);
  stroke(60);
  for( int i=0; i<cnt; i++){
    float freq = i*freq_inc;
    line(0, height-i*vd, w, height-i*vd);
    text(freq + " kHz", pl, height-i*vd-5);
  }
}

void drawEnvScale()
{
  int w = width;
  int cnt = 10;
  float vd = height/cnt;
  float env_inc =  (env_max-env_min) / (float)cnt;
  int indent = 50;
  textSize(10);
  stroke(255,255,100);
  for( int i=0; i<cnt; i++){
    float env_db = env_min+i*env_inc;
    String text = nf(env_db, 0, 1);
    line(0, height-i*vd, w, height-i*vd);
    text(text + " dB", width-indent, height-i*vd-5);
  }
}

void initializeSpectrogram(int size, int fftSize)
{
  float[] emptyFFT = new float[fftSize];
  Arrays.fill(emptyFFT, 120);
  for( int i=0; i<size; i++)
  {
    Frame f = new Frame(emptyFFT);
    spectrogram.add(f);
  }
}

void stop()
{
  myPort.stop();
  super.stop();
}

void initSerial()
{
  String portName = "";  // defined depending on operatingSystem

  if (operatingSystem.equals("Linux") == true) { 
    portName = "/dev/ttyACM1";
  }
  if (operatingSystem.equals("Windows") == true) { 
    portName = "COM10";
  }
  if (operatingSystem.equals("Mac") == true) { 
    portName = "/dev/tty.usbmodem14201";
  }

  println("Assuming "+operatingSystem+" OS");
  println("Serial port is set to "+portName);
    
  try {
          myPort = new Serial(this, portName, baudrate);
          myPort.clear();
          serialInited = true;
  } catch (RuntimeException e) {
    //if (e.getMessage().contains("<init>")) {
          System.out.println("port in use, trying again later...");
          printArray(Serial.list());
          serialInited = false;
          //myPort.stop();
     // }
  }
  

}
