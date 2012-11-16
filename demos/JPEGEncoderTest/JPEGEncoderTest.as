package
{

  import flash.display.Bitmap;
  import flash.display.BitmapData;
  import flash.display.Loader;
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
  import com.lilcodemonkey.workers.AsyncScheduler;

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
    private static const JPEG_QUALITY:int = 50;

    private var shape:Shape;
    private var bitmap:Bitmap;
    private var text:TextField;
    private var log:Array;
    private var header:String;

    private var lastJPEG1:Loader;
    private var lastJPEG2:Loader;
    private var tgt1:Object;
    private var tgt2:Object;

    private var xtSharedObject:Object;

    // Constructor
    public function JPEGEncoderTest():void
    {
      // Get a reference to the cross-thread shared object
      xtSharedObject = new XTSharedObject();

      if (WorkerCompat.workersSupported) {
        // Setup threading
        if (WorkerCompat.Worker.current.isPrimordial) {
          // -- Main thread runs this ----
          doGuiWork();

          var bgWorker:* = WorkerCompat.WorkerDomain.current.createWorker(this.loaderInfo.bytes);
          bgWorker.start();
        } else {
          // -- Background thread runs this ----
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
      header =
        "asdf JPEGEncoderTest, AS3-Worker-Compat v0.2.1\n"+
        "Flash Player version: " + Capabilities.version+
        ", workersSupported: "+WorkerCompat.workersSupported+
        ", shareableByteArray support: "+(WorkerCompat.Mutex!=null)+"\n"+
        "------------------------------------------------------------"+
        "------------------------------------------------------------";
      log = [];
      text.text = header + "\nTesting synchronous encoding...";
      addChild(text);
    }

    private function appendLog(msg:String):void
    {
      log.push(msg);
      if (log.length>4) log.shift();

      text.text = header+"\n"+
        (xtSharedObject.msg1 || "--")+"\n"+
        (xtSharedObject.msg2 || "--")+"\n"+
        "------------------------------------------------------------"+
        "------------------------------------------------------------\n"+
        log.join("\n");
    }

    private function doGuiWork():void
    {
      // Setup stage
      stage.align = 'topLeft';
      stage.scaleMode ='noScale';
      stage.frameRate = 60;
      showInfo();

      // Setup shareable bytearray fpr image data
      var imageData:ByteArray = new ByteArray();
      //WorkerCompat.setShareable(imageData);
      xtSharedObject.imageData1 = imageData;

      imageData = new ByteArray();
      //WorkerCompat.setShareable(imageData);
      xtSharedObject.imageData2 = imageData;

      // Setup spinner shape graphics
      shape = new Shape();
      bitmap = new Bitmap(new BitmapData(100, 100, false, 0x0));
      addChild(bitmap);

      // Setup JPEG loaders
      lastJPEG1 = new Loader();
      lastJPEG1.y = 200;
      addChild(lastJPEG1);
      lastJPEG2 = new Loader();
      lastJPEG2.y = 200;
      lastJPEG2.x = 515;
      addChild(lastJPEG2);

      tgt1 = { dx:0, dy:0, drotation:0, dscale:1 };
      tgt2 = { dx:0, dy:0, drotation:0, dscale:1 };

      this.addEventListener(Event.ENTER_FRAME, onFrame);
    }

    private function doBackgroundWork():void
    {
      synchronousEncodingTest();
      xtSharedObject.msg = "BKG: Synchronous tests complete, starting asynchronous encoding";
      asynchronousEncodingTest();
    }

    private function synchronousEncodingTest():void
    {
      var canvas:BitmapData = getRandomBitmapData();
      var ba:ByteArray;

      // Test synchronous encoding with native JPEG encoding BitmapData.encode
      var t0:uint = getTimer();
      ba = tryNativeEncode(canvas);
      if (ba) {
        xtSharedObject.msg1 = "BKG: JPEG generated snychronously using native encoder: "+ba.length+" bytes in "+(getTimer()-t0)+" ms";
      } else {
        xtSharedObject.msg1 = "BKG: can't test synchronous native JPEG encoder (FP < 11.3)";
      }

      // Test synchronous encoding
      t0 = getTimer();
      var j_sync:JPEGEncoder = new JPEGEncoder();
      ba = j_sync.encode(canvas);
      xtSharedObject.msg2 = "BKG: JPEG generated snychronously using JPEGEncoder: "+ba.length+" bytes in "+(getTimer()-t0)+" ms";
    }

    private function asynchronousEncodingTest():void
    {
      var canvas:BitmapData = getRandomBitmapData();

      // Test asynchronous encoding with an intensive AsyncScheduler profile
      //  - will stutter the UI lots if Workers are not supported, but is
      //    closest to synchronous performance
      //  - if workers are supported, this shouldn't affect performance much
      AsyncScheduler.setParams(250, 4);
      var t0:uint = getTimer();
      var j:JPEGEncoder = new JPEGEncoder(JPEG_QUALITY);

      j.encode_async(canvas, function(ba:ByteArray):void {
        xtSharedObject.msg = "BKG: JPEG generated asynchronously using JPEGEncoder, intensive: "+ba.length+" bytes in "+(getTimer()-t0)+" ms";
        xtSharedObject.imageData1 = ba;
        xtSharedObject.imageData1Valid = true;

        // Test asynchronous encoding with more lax AsyncScheduler profile
        //  - will stutter the UI less if Workers are not supported, but
        //    is least performant
        //  - if workers are supported, this shouldn't affect performance much
        AsyncScheduler.setParams(80, 20);
        canvas = getRandomBitmapData();
        var t1:uint = getTimer();
        j = new JPEGEncoder(JPEG_QUALITY);
        j.encode_async(canvas, function(ba:ByteArray):void {
          xtSharedObject.msg = "BKG: JPEG generated asynchronously using JPEGEncoder, relaxed: "+ba.length+" bytes in "+(getTimer()-t1)+" ms";
          xtSharedObject.imageData2 = ba;
          xtSharedObject.imageData2Valid = true;

          // Run again in a second
          setTimeout(asynchronousEncodingTest, 1000);
        }, xtSharedObject.imageData2);
      }, xtSharedObject.imageData1);
    }

    private function getRandomBitmapData(size:int=512):BitmapData
    {
      // Generate BMP
      var s:Shape = new Shape();
      for (var i:int=0; i<1000; i++) {
        s.graphics.lineStyle(Math.random()*5, Math.random()*0xffffff);
        s.graphics.moveTo(Math.random()*size, Math.random()*size);
        s.graphics.curveTo(Math.random()*size, Math.random()*size,
                           Math.random()*size, Math.random()*size);
      }
      var canvas:BitmapData = new BitmapData(size, size, false, Math.random()*0xffffff);
      canvas.draw(s);

      return canvas;
    }

    private function onFrame(e:Event):void
    {
      var t:Number = getTimer();

      // Receieve new messages
      var m:String = xtSharedObject.msg;
      if (m) {
        appendLog(m);
        xtSharedObject.msg = null;
      }

      // Apply smoothing
      if (xtSharedObject.smooth1 && lastJPEG1.content) {
        Bitmap(lastJPEG1.content).smoothing = true;
        xtSharedObject.smooth1 = false;
      }
      if (xtSharedObject.smooth2 && lastJPEG2.content) {
        Bitmap(lastJPEG2.content).smoothing = true;
        xtSharedObject.smooth2 = false;
      }

      // Receieve new JPEGs
      var imageData:ByteArray;
      var ba:ByteArray;

      imageData = xtSharedObject.imageData1;
      if (xtSharedObject.imageData1Valid) {
        // If we don't clone, the image can change as it's overwritten
        lastJPEG1.loadBytes(cloneByteArray(imageData));
        xtSharedObject.imageData1Valid = false;
        xtSharedObject.smooth1 = true;
        tgt1 = { dx:Math.random()*2-1, dy:Math.random()*2-1, drotation:Math.random()*1-0.5, dscale:1+Math.random()*0.004-0.003 };
        lastJPEG1.x = 0;
        lastJPEG1.y = 200;
        lastJPEG1.rotation = 0;
        lastJPEG1.scaleX = lastJPEG1.scaleY = 1;
      }

      imageData = xtSharedObject.imageData2;
      if (xtSharedObject.imageData2Valid) {
        // If we don't clone, the image can change as it's overwritten
        lastJPEG2.loadBytes(cloneByteArray(imageData));
        xtSharedObject.imageData2Valid = false;
        xtSharedObject.smooth2 = true;
        tgt2 = { dx:Math.random()*2-1, dy:Math.random()*2-1, drotation:Math.random()*1-0.5, dscale:1+Math.random()*0.004-0.003 };
        lastJPEG2.x = 515;
        lastJPEG2.y = 200;
        lastJPEG2.rotation = 0;
        lastJPEG2.scaleX = lastJPEG2.scaleY = 1;
      }

      // Animate JPEGs
      lastJPEG1.x += tgt1.dx;
      lastJPEG1.y += tgt1.dy;
      lastJPEG1.rotation += tgt1.drotation;
      lastJPEG1.scaleY = lastJPEG1.scaleX *= tgt1.dscale;
      lastJPEG2.x += tgt2.dx;
      lastJPEG2.y += tgt2.dy;
      lastJPEG2.rotation += tgt2.drotation;
      lastJPEG2.scaleY = lastJPEG2.scaleX *= tgt2.dscale;

      // Animate spinner
      shape.graphics.clear();
      shape.graphics.beginFill(0x0, 0.05);
      shape.graphics.drawRect(0,0,100,100);
      bitmap.bitmapData.draw(shape);
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
        var ba:ByteArray = xtSharedObject.imageData1;
        var JPEGEncoderOptionsClass:* = getDefinitionByName("flash.display.JPEGEncoderOptions");
        Object(canvas).encode(canvas.rect, new JPEGEncoderOptionsClass(JPEG_QUALITY), ba);
        return ba;
      } catch (e:Error) { }
      return null;
    }

    private static function cloneByteArray(input:ByteArray):ByteArray
    {
      var ba:ByteArray = new ByteArray();
      input.position = 0;
      ba.writeBytes(input, 0, input.length);
      return ba;
    }

  }
}
