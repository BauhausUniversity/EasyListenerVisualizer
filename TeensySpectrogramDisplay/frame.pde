class Frame {
  
  Frame(float[] fft, float envelope){
    _fft = new float[fft.length];
    System.arraycopy(fft, 0, _fft, 0, fft.length);
    _e = envelope;
    _fftSize = fft.length;
    _thres_crossed = -120;
    _soundID = -1;
  }
  
  Frame(float[] fft){
    _fft = new float[fft.length];
    System.arraycopy(fft, 0, _fft, 0, fft.length);
    _e = -1;
    _fftSize = fft.length;
    _thres_crossed = -120;
    _soundID = -1;
  }
  
  
  Frame(int fftSize){
    _fft = new float[fftSize];
    _e = -1;
    _fftSize = fftSize;
    _thres_crossed = -120;
    _soundID = -1;
  }
  
  private float _e;
  private float[] _fft;
  private int _fftSize;
  private float _thres_crossed;
  private float _soundID;
  private String _soundLabel;
  
  public void setSoundID(float soundID) {
    _soundID = soundID;
  }
  
  public float getSoundID() {
    return _soundID;
  }
  
  public void setSoundLabel(String soundLabel) {
    _soundLabel = soundLabel;
  }
  
  public String getSoundLabel() {
    return _soundLabel;
  }
  
  public float getEnvelope() {
    return _e;
  }
  
  
  public void setEnvelope(float env) {
    _e = env;
  }
  
  public void setThresholdCrossedAt(float thres_val) {
    _thres_crossed = thres_val;
  }
  
  public float getThresholdCrossedAt() {
    return _thres_crossed;
  }
  
  public void setFFT(float[] fft, int src_offset, int dst_offset) {
    _fft = new float[fft.length];
    _fftSize =fft.length;
    System.arraycopy(fft, src_offset, _fft, dst_offset, fft.length);
  }
  
  public float getFFTBin(int idx) {
    return _fft[idx];
  }
  
  public void setFFTBin(int idx, float val) {
    _fft[idx] = val;
  }
  
  public void setFFTfromByteArray(byte[] fft, int src_offset, int dst_offset, int len) {
    _fft = new float[len];
    _fftSize = len;
    for(int i=0; i<len; i++) {
      _fft[i+dst_offset] = fft[i+src_offset];
    }
  }
  
  public void drawEnvelopeAtPos(int i) 
  {
    stroke(255,255,255);
    float env_value = this.getEnvelope();
    env_value = constrain(env_value, -60, 0);
    env_value = map(env_value, -60, 0, 0, height);
    line(i,height-env_value,i+1,height-env_value);
  }
  
  public void drawThresholdCrossedAtPos(int i, float env_min, float env_max) 
  {
    stroke(96,255,255);
    float thres_value = this.getThresholdCrossedAt();
    thres_value = (float)(thres_value-env_min)/(float)(env_max-env_min)*height;
    line(i,height-thres_value,i+1,height-thres_value);
  }
  
  public void drawSoundIDLocAtPos(int i) 
  {
    if(_soundID!=-1)
    {
      stroke(32*_soundID,255,255);
      line(i,0,i,height/6);
    }
  }
  
  public void drawSoundLabelAtPos(int i)
  {
    if(_soundID!=-1)
    {
      textSize(20);
      stroke(32*_soundID,255,255);
      text(_soundLabel, i-150, height/6);
    }
  }
  
  public void drawEnvelopeAtPosFromPrev(int i, float old_env) 
  {
    stroke(255,255,255);
    float env = this.getEnvelope();
    env = constrain(env, -60, 0);
    env = map(env, -60, 0, 0, height);
    old_env = constrain(old_env, -60, 0);
    old_env = map(old_env, -60, 0, 0, height);
    line(i-1, height-old_env,i, height-env);
  }
  
  public void drawFFTColAtPos(int i, int stroke_w, int stroke_h) 
  {
    for (int j=0; j<_fftSize; j++) {
      float fft_value = -this.getFFTBin(j);
      fft_value = constrain(fft_value, -120, -11); //<>//
      fft_value = map(fft_value, -120, -30, 0, 255);
      stroke(fft_value, 255, fft_value);
      strokeWeight(1);
      line(i*stroke_w,height-j*stroke_h, (i+1)*stroke_w, height-(j+1)*stroke_h);
    }
  }
  
} 
