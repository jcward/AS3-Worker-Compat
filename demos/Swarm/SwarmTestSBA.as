package
{

  import flash.display.Shape;
  import flash.display.Sprite;
  import flash.text.TextField;
  import flash.events.Event;
  import flash.utils.ByteArray;
  import flash.utils.getTimer;
  import flash.utils.setTimeout;

  import com.jcward.workers.WorkerCompat;
  import com.jcward.workers.XTSharedObject;
  import com.jcward.workers.AsyncScheduler;

  /**
   * This test showcases a real-world use case of Workers: AI.
   */
  public class SwarmTestSBA extends Sprite
  {
    private const NUM:int = 1000;
    private var shape:Shape;

    private var xtSharedObject:Object;
    private var xx:ByteArray;
    private var yy:ByteArray;

    // Constructor
    public function SwarmTestSBA():void
    {
      // Get a reference to the cross-thread shared object
      xtSharedObject = new XTSharedObject();

      if (WorkerCompat.workersSupported) {
        // Setup threading
        if (WorkerCompat.Worker.current.isPrimordial) { // Main thread runs this
          doGuiWork();
          // Creates a duplicate of this worker to run as the background worker
          var bgWorker:* = WorkerCompat.WorkerDomain.current.createWorker(this.loaderInfo.bytes);
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

    private function doGuiWork():void
    {
      stage.align = 'topLeft';
      stage.scaleMode ='noScale';
      stage.frameRate = 60;

      xtSharedObject.num = NUM;
      xtSharedObject.stageWidth = stage.stageWidth;
      xtSharedObject.stageHeight = stage.stageHeight;

      var t:TextField = new TextField();
      t.width = 400;
      t.text = "Workers? "+WorkerCompat.workersSupported;
      addChild(t);

      shape = new Shape();
      addChild(shape);
      this.addEventListener(Event.ENTER_FRAME, onFrame);
    }

    private function doBackgroundWork():void
    {
      xx = new ByteArray();
      WorkerCompat.setShareable(xx);
      yy = new ByteArray();
      WorkerCompat.setShareable(yy);

      xtSharedObject.x = xx;
      xtSharedObject.y = yy;

      var sw:Number = xtSharedObject.stageWidth;
      var sh:Number = xtSharedObject.stageHeight;

      // Setup swarm
      var i:int;
      for (i = xtSharedObject.num-1; i>=0; i--) {
        xx.writeDouble(Math.random()*sw);
        yy.writeDouble(Math.random()*sh);
      }

      // // Assign-back
      // xtSharedObject.x = xx;
      // xtSharedObject.y = yy;

      if (WorkerCompat.workersSupported) {
        // Use the background thread heavily
        AsyncScheduler.setParams(AsyncScheduler.HIGH);
      } else {
        // Stutter UI as little as possible without workers
        AsyncScheduler.setParams(AsyncScheduler.LOW);
      }

      // Asynchronous movement calculation
      i = xtSharedObject.num-1;
      var j:int = xtSharedObject.num-1;
      var forceX:Number;
      var forceY:Number;
      AsyncScheduler.async(this,
        function(timeout:int):Boolean {
          for (; i>=0; i--) { if (getTimer()>timeout) { return false; }
            forceX = forceY = 0;
            xx.position = yy.position = i*8;
            var ix:Number = xx.readDouble();
            var iy:Number = yy.readDouble();
            var jx:Number;
            var jy:Number;
            var dist:Number;
            var angle:Number;

            for (; j>=0; j--) { if (getTimer()>timeout) { return false; }
              if (j==i) continue;

              xx.position = yy.position = j*8;
              jx = xx.readDouble();
              jy = yy.readDouble();

              dist = Math.pow((ix-jx)*(ix-jx)+(iy-jy)*(iy-jy), 0.3);
              angle = Math.atan2(jy-iy, jx-ix);
              if (dist < 20+10*Math.random()) {
                forceX -= 5*Math.cos(angle)/(5+dist);
                forceY -= 5*Math.sin(angle)/(5+dist);
              } else {
                forceX += 5*Math.cos(angle)/(5+dist);
                forceY += 5*Math.sin(angle)/(5+dist);
              }
            }
            j = xtSharedObject.num-1; // reset loop

            // attraction to center
            jx = sw/2;
            jy = sh/2;

            dist = Math.pow((ix-jx)*(ix-jx)+(iy-jy)*(iy-jy), 0.3);
            angle = Math.atan2(jy-iy, jx-ix);
            //if (Math.cos(getTimer()/300)<0.9) {
              forceX += 80*Math.cos(angle)/(10+dist);
              forceY += 80*Math.sin(angle)/(10+dist);
            //} else {
            //  forceX -= 40*Math.cos(angle)/(10+dist);
            //  forceY -= 40*Math.sin(angle)/(10+dist);
            //}

            ix += forceX;
            iy += forceY;
            xx.position = yy.position = i*8;
            xx.writeDouble(forceX);
            yy.writeDouble(forceY);

          }
          i = xtSharedObject.num-1; // reset loop

          // // Assign-back
          // xtSharedObject.x = xx;
          // xtSharedObject.y = yy;

          return false; // this task is indefinite
      });
    }

    private function onFrame(e:Event):void
    {
      var x:ByteArray = xtSharedObject.x;
      var y:ByteArray = xtSharedObject.y;

      if (x && y) {
        shape.graphics.clear();
        shape.graphics.beginFill(0xff0000);
        for (var i:int=xtSharedObject.num-1; i>=0; i--) {
          shape.graphics.drawCircle(x.readDouble(), y.readDouble(), 3);
        }
      }
    }
  }
}
