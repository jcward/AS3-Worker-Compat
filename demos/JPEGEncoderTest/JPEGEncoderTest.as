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

  import com.lilcodemonkey.workers.WorkerCompat;
  import com.lilcodemonkey.workers.XTSharedObject;

  /**
   * This test showcases the backward-compatible use of AS3 Workers.  It runs
   * in all versions of the Flash Player, and takes advantage of AS3 workers
   * whenever possible (Flash Player >= 11.4 && Worker.isSupported)
   *
   * A notable exception is Google Chrome under Windows (PPAPI)... for some
   * reason Google has disabled workers in their bundled version of Flash 11.4
   *
   * Very simple cross-thread data sharing (again, in any Flash Player) is
   * achieved via getting/setting values on xtSharedObject.
   */
  public class JPEGEncoderTest extends Sprite
  {
    private var shape:Shape;
    private var bitmap:Bitmap;
    private var text:TextField;
    private var log:Array;

    private var imageData:ByteArray;
    //private var lastJPEG:DisplayObject;

    private var xtSharedObject:Object;

    // Constructor
    public function JPEGEncoderTest():void
    {
      // Get a reference to the cross-thread shared object
      xtSharedObject = new XTSharedObject();
      
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

      trace("Entered JPEGEncoderTest...");

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
        doBackgroundWork();
      }
    }

    private function showInfo():void
    {
      text = new TextField();
      text.width = text.height = 500;
      text.x = 105;
      var s:String = 
        "JPEGEncoderTest, AS3-Worker-Compat v0.2.1\n"+
        "Flash Player version: " + Capabilities.version+
        ", workersSupported: "+WorkerCompat.workersSupported+
        ", shareableByteArray support: "+(WorkerCompat.Mutex!=null)+"\n"+
        "-------------------------------------------------------------------------------------\n";
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
      var s:Shape = new Shape();
      for (var i:int=0; i<1000; i++) {
        s.graphics.lineStyle(Math.random()*5, Math.random()*0xffffff);
        s.graphics.moveTo(Math.random()*512, Math.random()*512);
        s.graphics.curveTo(Math.random()*512, Math.random()*512,
                           Math.random()*512, Math.random()*512);
      }
      var canvas:BitmapData = new BitmapData(512, 512, false, 0x0);
      canvas.draw(s);

      // Encode as JPEG
      var t0:uint = getTimer();
      var j:JPEGEncoder = new JPEGEncoder();
      j.encode_async(canvas, function(ba:ByteArray):void {
        xtSharedObject.msg = "JPEG Generated: 512x512, "+ba.length+" bytes in "+(getTimer()-t0)+" ms";
        doBackgroundWork(); // more JPEGs!
      });
      // Pass to Main thread for display
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
  }
}
