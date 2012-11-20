package
{

  import flash.display.Bitmap;
  import flash.display.BitmapData;
  import flash.display.DisplayObject;
  import flash.display.Loader;
  import flash.display.Shape;
  import flash.display.Sprite;
  import flash.events.Event;
  import flash.system.Capabilities;
  import flash.text.TextField;
  import flash.utils.getTimer;
  import flash.utils.setTimeout;
  import flash.utils.ByteArray;
  import flash.utils.Dictionary;
  import flash.utils.getDefinitionByName;

  import com.jcward.workers.WorkerCompat;
  import com.jcward.workers.XTSharedObject;
  import com.jcward.workers.AsyncScheduler;
  import com.jcward.workers.JPEGEncoder;

  /**
   * This test uses the AS3-Worker-Compat library to encode JPEGs in an
   * asynchronous manner, compare performance with synchronous methods, and
   * highlight smooth UI while using background Workers (though via the use of
   * the pseudo-threaded algorithm, retains a functional if choppy UI in
   * Flash Players without Worker support.)
   *
   * The JPEGEncoder.as class is the standard Adobe library but with
   * modifications:
   *  - added encodeAsync() method which uses AsyncScheduler.async pseudo-
   *    threading (compare it to the standard, synchronous encode method.)
   *  - changed encode() method to use Flash native JPEg encoding by default
   *    with fallbacks to the software encoder for older Flash Players
   *
   * Note that pseudo-threading algorithms isn't a bad idea even for background
   * threads.  By pseudo-threading on a background thread and using
   * AsyncScheduler to manager those tasks, one background Worker can service
   * many tasks simultaneously.
   *
   * See AsyncScheduler and JPEGEncoder for more details.
   */
  public class JPEGEncoderTest extends Sprite
  {
    private static const JPEG_QUALITY:int = 50;

    private var shape:Shape;
    private var bitmap:Bitmap;
    private var text:TextField;
    private var log:Array;
    private var header:String;
    private var tLast:Number;

    private var container:Sprite;
    private var tweenData:Dictionary;

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
        "JPEGEncoderTest, AS3-Worker-Compat v0.2.1\n"+
        "Flash Player version: " + Capabilities.version+
        ", workersSupported: "+WorkerCompat.workersSupported+
        ", shareableByteArray support: "+(WorkerCompat.Mutex!=null)+"\n"+
        "------------------------------------------------------------"+
        "------------------------------------------------------------";
      log = ["Testing encoding on a 512x512 bitmap..."];
      text.text = header+"\n"+log.join("\n");
      addChild(text);
    }

    private function appendLog(msg:Object):void
    {
      if (msg is String) { log.push(msg); }
      if (msg is Array) { while (msg.length>0) { log.push(msg.shift()); } }

      //while (log.length>4) log.shift();

      text.text = header+"\n"+log.join("\n");
    }

    private function doGuiWork():void
    {
      // Setup stage
      stage.align = 'topLeft';
      stage.scaleMode ='noScale';
      stage.frameRate = 60;

      xtSharedObject.frameCount = 0;

      container = new Sprite();
      addChild(container);

      showInfo();

      tweenData = new Dictionary();

      // Setup shareable bytearray fpr image data
      var imageData:ByteArray = new ByteArray();
      //WorkerCompat.setShareable(imageData);
      xtSharedObject.imageData = imageData;

      // Setup spinner shape graphics
      shape = new Shape();
      bitmap = new Bitmap(new BitmapData(100, 100, false, 0x0));
      addChild(bitmap);

      this.addEventListener(Event.ENTER_FRAME, onFrame);
    }

    private function doBackgroundWork():void
    {
      compareEncoders();
    }

    /**
     * Measure the performance of JPEG encoding using:
     *  - Flash Player native encoding (11.3+)
     *  - Software encoding
     *  - Pseudo-threaded software encoding using AsyncScheduler LOW,
     *    MEDIUM, and HIGH profiles
     */
    private function compareEncoders():void
    {
      var canvas:BitmapData = getRandomBitmapData();

      var msgs:Array = [];

      // Test synchronous encoding with native JPEG encoding BitmapData.encode
      var t0:uint = getTimer();
      var encoderSync:JPEGEncoder = new JPEGEncoder(JPEG_QUALITY);
      var bytes:ByteArray;
      if (JPEGEncoder.supportsNativeEncode) {
        bytes = encoderSync.encode(canvas);
        msgs.push("BKG: JPEG sync, native encoder: "+bytes.length+" bytes in "+(getTimer()-t0)+" ms");
      } else {
        msgs.push("BKG: native JPEG encoder not supported (FP < 11.3)");
      }

      // Test synchronous, non-native encoding
      t0 = getTimer();
      bytes = encoderSync.encodeNonNative(canvas);
      msgs.push("BKG: JPEG sync JPEGEncoder: "+bytes.length+" bytes in "+(getTimer()-t0)+" ms");
      xtSharedObject.msg = msgs;

      asyncTestProfiles(canvas, [AsyncScheduler.LOW, AsyncScheduler.MEDIUM, AsyncScheduler.HIGH]);
    }

    /**
     * Test the various profiles of AsyncScheduler so-as to compare
     * asynchronous performance of JPEG encoding against synchronous
     * encoding above
     */
    private function asyncTestProfiles(canvas:BitmapData, profiles:Array):void
    {
      var profile:String = profiles.shift();
      AsyncScheduler.setParams(profile);
      var t0:uint = getTimer();
      var encoderAsync:JPEGEncoder = new JPEGEncoder(JPEG_QUALITY);

      // Reset frame counter
      xtSharedObject.frameCount = 0;
      encoderAsync.encodeAsync(canvas, function(bytes:ByteArray):void {
        var ms:uint = getTimer()-t0;
        var msg:String = "BKG: JPEG async, AsyncScheduler."+profile+": "+
            bytes.length+" bytes in "+ms+" ms"+
            ", average FPS="+(Math.floor(xtSharedObject.frameCount*10000/ms)/10);

        if (profiles.length==0) {
          xtSharedObject.msg = [msg, "Now running JPEG spawn test..."];
          setTimeout(asyncSpawnJPEGs, 200);
        } else {
          xtSharedObject.msg = msg;
          asyncTestProfiles(canvas, profiles);
        }
      });
    }

    /**
     * Encode JPEGs on the background worker and pass them to the
     * main worker for display/animation.
     */
    private function asyncSpawnJPEGs():void
    {
      var canvas:BitmapData = getRandomBitmapData(512, 512);

      if (WorkerCompat.workersSupported) {
        // Use the background thread heavily
        AsyncScheduler.setParams(AsyncScheduler.HIGH);
      } else {
        // Stutter UI as little as possible without workers
        AsyncScheduler.setParams(AsyncScheduler.LOW);
      }

      var t0:uint = getTimer();
      var encoderAsync:JPEGEncoder = new JPEGEncoder(JPEG_QUALITY);

      encoderAsync.encodeAsync(canvas, function(bytes:ByteArray):void {
        xtSharedObject.imageData = bytes;
        xtSharedObject.imageDataValid = true;

        setTimeout(asyncSpawnJPEGs, 20);
      }, xtSharedObject.imageData);
    }

    private function getRandomBitmapData(width:int=512,
                                         height:int=512):BitmapData
    {
      // Generate BMP
      var s:Shape = new Shape();
      for (var i:int=0; i<1000; i++) {
        s.graphics.lineStyle(Math.random()*5, Math.random()*0xffffff);
        s.graphics.moveTo(Math.random()*width, Math.random()*height);
        s.graphics.curveTo(Math.random()*width, Math.random()*height,
                           Math.random()*width, Math.random()*height);
      }
      var canvas:BitmapData = new BitmapData(width, height, false, Math.random()*0xffffff);
      canvas.draw(s);

      return canvas;
    }

    private function onFrame(e:Event):void
    {
      var t:Number = getTimer();
      var dt:Number = t - tLast;
      tLast = getTimer();
      xtSharedObject.frameCount++;

      // Receieve new messages
      var m:Object = xtSharedObject.msg;
      if (m) {
        xtSharedObject.msg = null;
        appendLog(m);
      }

      // Receieve new JPEG
      var imageData:ByteArray = xtSharedObject.imageData;
      if (xtSharedObject.imageDataValid) {
        // If we don't clone, the image can change as it's overwritten
        spawnJPEGChild(cloneByteArray(imageData));
        xtSharedObject.imageDataValid = false;
      }

      // Animate JPEGs
      for (var i:int=container.numChildren-1; i>=0; i--) {
        var loader:Loader = container.getChildAt(i) as Loader;
        var tgt:Object = tweenData[loader];
        loader.x += dt*tgt.dx;
        loader.y += dt*tgt.dy;
        loader.rotation += dt*tgt.drotation;
        loader.scaleY += tgt.dscale;
        loader.scaleX += tgt.dscale;
     }

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

    private function spawnJPEGChild(bytes:ByteArray):void
    {
      var loader:Loader = new Loader();
      loader.loadBytes(bytes);
      tweenData[loader] = { dx:Math.random()*.2-.1, dy:Math.random()*.2, drotation:Math.random()*.04-0.02, dscale:Math.random()*0.004-0.003 };
      loader.x = 300;
      loader.y = 300;
      loader.rotation = Math.random()*20-10;
      container.addChild(loader);

      setTimeout(function():void {
        delete tweenData[loader];
        container.removeChild(loader);
      }, 3000);
    }

    private static function cloneByteArray(input:ByteArray):ByteArray
    {
      var bytes:ByteArray = new ByteArray();
      input.position = 0;
      bytes.writeBytes(input, 0, input.length);
      return bytes;
    }

  }
}
