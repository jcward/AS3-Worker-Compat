package
{

  import flash.display.Bitmap;
  import flash.display.BitmapData;
  import flash.display.Shape;
  import flash.display.Sprite;
  import flash.events.Event;
  import flash.system.Capabilities;
  import flash.text.TextField;
  import flash.utils.getTimer;
  import flash.utils.setTimeout;
  import flash.utils.ByteArray;
  import flash.utils.getDefinitionByName;

  import com.lilcodemonkey.workers.WorkerCompat;
  import com.lilcodemonkey.workers.XTSharedObject;

  /**
   * This test uses the AS3-Worker-Compat library to encode JPEGs in an
   * asynchronous manner.  The JPEGEncoder.as class is the standard Adobe
   * library but an added encode_async() method (compare it to the standard
   * encode method.)  It uses AsyncScheduler to break the algorithm into
   * a pseudo-threaded one, which is necessary for single-threaded scenarios,
   * but helpful in multi-threaded players also (synchronous encoding would
   * block the background thread, possibly delaying other jobs that thread
   * is responsible for.)  While asynchronous/scheduled computation is
   * slightly less efficient than synchronous, uninterrupted operation, it
   * allows a thread/Worker to be shared between tasks.
   *
   * Note that the AsyncScheduler is tunable - you can direct how much time
   * it computes each pass, and how much time between passes - and jobs can
   * be submitted with varying priorities (since jobs will compete for CPU
   * time).  Naturally this affects its efficiency of computation compared
   * to synchronous computation, and on a background thread there's no need
   * for time between passes since it doesn't have to render the UI.
   *
   * Also note that while the AsyncScheduler class is static, it is not
   * shared among threads.  There exists a separate instance of it in each
   * Worker thread.
   */
  public class JPEGEncoderTest extends Sprite
  {
    private var shape:Shape;
    private var bitmap:Bitmap;
    private var text:TextField;
    private var log:Array;

    //private var imageData:ByteArray;
    //private var xtSharedObject:Object;

    // Constructor
    public function JPEGEncoderTest():void
    {
      // Get a reference to the cross-thread shared object
      //xtSharedObject = new XTSharedObject();
      
      // WorkerCompat.setShareable(imageData);
      //  
      // if (!WorkerCompat.workersSupported ||
      //     WorkerCompat.Worker.current.isPrimordial) {
      //   imageData = new ByteArray();
      //   xtSharedObject.imageData = imageData;
      // } else {
      //   // Background worker, get ByteArray reference
      //   imageData = xtSharedObject.imageData;
      // }

      if (WorkerCompat.workersSupported) {
        // Setup threading
        if (WorkerCompat.Worker.current.isPrimordial) { // Main thread runs this
          doGuiWork();
          // Creates a duplicate of this worker to run as the background worker
          var bgWorker:* = WorkerCompat.WorkerDomain.current.createWorker(this.loaderInfo.bytes);
          XTSharedObject.attachWorker(bgWorker);
          bgWorker.start();
        } else { // Background thread runs this
          doBackgroundWork();
        }
      } else {
        // Fallback: Do all the work in this thread
        doGuiWork();
        setTimeout(doBackgroundWork, 20);
      }
    }

    private function showInfo():void
    {
      text = new TextField();
      text.width = text.height = 800;
      text.x = 105;
      var s:String = 
        "JPEGEncoderTest, AS3-Worker-Compat v0.2.1\n"+
        "Flash Player version: " + Capabilities.version+
        ", workersSupported: "+WorkerCompat.workersSupported+
        ", shareableByteArray support: "+(WorkerCompat.Mutex!=null)+"\n"+
        "------------------------------------------------------------"+
        "------------------------------------------------------------";
      log = s.split("\n");
      text.text = s
      addChild(text);
    }

    private function appendLog(msg:String):void
    {
      log.push(msg);
      if (log.length>10) log.splice(3, 1);
      text.text = log.join("\n");
    }

    private function doGuiWork():void
    {
      stage.align = 'topLeft';
      stage.scaleMode ='noScale';
      stage.frameRate = 60;
      showInfo();

      shape = new Shape();
      bitmap = new Bitmap(new BitmapData(100, 100, false, 0x0));
      addChild(bitmap);
      this.addEventListener(Event.ENTER_FRAME, onFrame);
    }

    private function doBackgroundWork():void
    {
      // Generate BMP
      var imageSize:Number = 1024;
      var s:Shape = new Shape();
      for (var i:int=0; i<1000; i++) {
        s.graphics.lineStyle(Math.random()*5, Math.random()*0xffffff);
        s.graphics.moveTo(Math.random()*imageSize, Math.random()*imageSize);
        s.graphics.curveTo(Math.random()*imageSize, Math.random()*imageSize,
                           Math.random()*imageSize, Math.random()*imageSize);
      }
      var canvas:BitmapData = new BitmapData(imageSize, imageSize, false, 0x0);
      canvas.draw(s);

      var ba:ByteArray;

      // Test synchronous encoding with native JPEG encoding BitmapData.encode
      // (will block the UI if Workers are not supported)
      var t0:uint = getTimer();
      ba = tryNativeEncode(canvas);
      if (ba) {
        xtSharedObject.msg = "BKG: JPEG Generated snychronously using native encoder: "+ba.length+" bytes in "+(getTimer()-t0)+" ms";
      } else {
        xtSharedObject.msg = "BKG: can't test synchronous native JPEG encoder (FP < 11.3)";
      }

      // Test synchronous encoding (will block the UI if Workers are not supported)
      t0 = getTimer();
      var j_sync:JPEGEncoder = new JPEGEncoder();
      ba = j_sync.encode(canvas);
      xtSharedObject.msg = "BKG: JPEG Generated snychronously using JPEGEncoder: "+ba.length+" bytes in "+(getTimer()-t0)+" ms";

      // Test asynchronous encoding (will stutter the UI if Workers are not supported)
      t0 = getTimer();
      var j:JPEGEncoder = new JPEGEncoder();
      j.encode_async(canvas, function(ba:ByteArray):void {
        xtSharedObject.msg = "BKG: JPEG Generated asynchronously using JPEGEncoder: "+ba.length+" bytes in "+(getTimer()-t0)+" ms";
        setTimeout(doBackgroundWork, 20); // more JPEGs!
      });
    }

    private function onFrame(e:Event):void
    {
      var t:Number = getTimer();

      if (xtSharedObject.msg) {
        appendLog(xtSharedObject.msg);
        xtSharedObject.msg = null;
      }

      // Fade to black
      shape.graphics.clear();
      shape.graphics.beginFill(0x0, 0.05);
      shape.graphics.drawRect(0,0,100,100);
      bitmap.bitmapData.draw(shape);

      // Draw red circle/line
      shape.graphics.clear();
      shape.graphics.lineStyle(3, 0xff0000, 1, true);
      shape.graphics.drawCircle(50, 50, 46);
      shape.graphics.moveTo(50, 50);
      shape.graphics.lineTo(50+45*Math.cos(t/300), 50+45*Math.sin(t/300));
      bitmap.bitmapData.draw(shape);
    }

    private function tryNativeEncode(canvas:BitmapData):ByteArray
    {
      try {
        var ba:ByteArray = new ByteArray();
        var JPEGEncoderOptionsClass:* = getDefinitionByName("flash.display.JPEGEncoderOptions");
        Object(canvas).encode(canvas.rect, new JPEGEncoderOptionsClass(), ba);
        return ba;
      } catch (e:Error) { }
      return null;
    }

  }
}
