package com.jcward.workers {

  import flash.utils.getTimer;
  import flash.utils.setTimeout;

  /**
   * AsyncScheduler is a static class that provides scheduling of asynchronous
   * (pseudo-threaded) tasks.  Splitting a synchronous loop-based algorithm
   * into pseudo-threads is easy (see JPEGEncoder.encodeAsync compared to
   * .encodeNonNative()).
   *
   * This class also has tunable parameters, either via simple profiles or
   * fine-grained control of computation time.  This allows you to decide
   * how choppy the UI becomes while processing background jobs.  Naturally
   * this also affects its efficiency of computation compared to synchronous
   * computation.  Also, on a background Worker it's recommended to set the
   * profile to high as it won't block the UI anyway.
   *
   * Note that pseudo-threading algorithms isn't a bad idea even for background
   * threads.  By pseudo-threading on a background thread and using
   * AsyncScheduler to manager those tasks, one background Worker can service
   * many tasks simultaneously.
   *
   * Also note that while the AsyncScheduler class is static, it is not shared
   * among Workers.  But there does exist a separate instance of it in each
   * Worker thread.
   */
  public class AsyncScheduler {

    // Scheduler aggression (batch priority) usage profiles
    public static var LOW:String = "low";
    public static var MEDIUM:String = "medium";
    public static var HIGH:String = "high";

    private static var initialized:Boolean = false;
    private static var pending_jobs:Vector.<AsyncJob>;
    private static var jobs:Vector.<AsyncJob>;
    private static var prioritySum:Number = 0;

    private static var msToGrind:uint = 150;
    private static var msToRest:uint = 4;
    private static var forceWorkerRest:Boolean = false;
    private static var isBackgroundWorker:Boolean;

    public static function async(context:Object,
                                 asyncFunc:Function,
                                 priority:Number=1):void
    {
      if (!initialized) { init(); }

      if (priority<1) { priority = 1; }
      pending_jobs.push(new AsyncJob(priority, asyncFunc, context));

      if (pending_jobs.length==1 && jobs.length==0) {
        runScheduler();
      }
    }

    private static function init():void
    {
      initialized = true;
      jobs = new Vector.<AsyncJob>();
      pending_jobs = new Vector.<AsyncJob>();
      isBackgroundWorker = WorkerCompat.workersSupported &&
        !WorkerCompat.Worker.current.isPrimordial;
    }

    public static function setParams(timeToGrindInMs:*,
                                     timeToRestInMs:uint=0,
                                     forceWorkerRest:Boolean=false):void
    {
      if (!initialized) { init(); }

      if (timeToGrindInMs is String) {
        if (timeToGrindInMs==LOW) {
          timeToGrindInMs = 32;
          timeToRestInMs = 16;
        }
        if (timeToGrindInMs==MEDIUM) {
          timeToGrindInMs = 100;
          timeToRestInMs = 10;
        }
        if (timeToGrindInMs==HIGH) {
          timeToGrindInMs = 200;
          timeToRestInMs = 2;
        }
      }

      msToGrind = timeToGrindInMs;
      msToRest = timeToRestInMs
      forceWorkerRest = forceWorkerRest;
    }

    private static function runScheduler():void
    {
      checkPendingJobs();
      for (var i:int=jobs.length-1; i>=0; --i) {
        var j:AsyncJob = jobs[i];
        var t0:uint = getTimer();

        // Duration is a percentage of time to grind
        var duration:uint = (j.priority*msToGrind)/prioritySum;

        var complete:Boolean = j.asyncFunc.call(j.context, t0+duration);
        if (complete) {
          jobs.splice(i, 1);
          prioritySum -= j.priority
        }
      }
      if (jobs.length>0 || pending_jobs.length>0) {
        setTimeout(runScheduler, (!isBackgroundWorker || forceWorkerRest) ? msToRest : 1);
      }
    }

    private static function checkPendingJobs():void
    {
      while (pending_jobs.length>0) {
        var j:AsyncJob = pending_jobs.pop();
        prioritySum += j.priority;

        // Insert in reverse-priority order
        var i:int = jobs.length;
        for (; i>0; i--) {
          if (j.priority > jobs[i-1].priority) break;
        }
        jobs.splice(i, 0, j);
      }
    }

  }
}

class AsyncJob {
  public var priority:Number;
  public var asyncFunc:Function;
  public var context:Object;

  public function AsyncJob(p:Number, f:Function, c:Object):void
  {
    priority = p;
    asyncFunc = f;
    context = c;
  }
}
