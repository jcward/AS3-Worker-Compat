package com.lilcodemonkey.workers {

  import flash.utils.getTimer;
  import flash.utils.setTimeout;

  public class AsyncScheduler {

    private static var initialized:Boolean = false;
    private static var pending_jobs:Vector.<AsyncJob>;
    private static var jobs:Vector.<AsyncJob>;
    private static var prioritySum:Number = 0;

    private static var msToGrind:uint = 150;
    private static var msToRest:uint = 4;
    private static var forceWorkerRest:Boolean = false;
    private static var isBackgroundWorker:Boolean;

    public static function loop(context:Object,
                                loopFunc:Function,
                                priority:Number=1):void
    {
      if (!initialized) { init(); }

      if (priority<1) { priority = 1; }
      pending_jobs.push(new AsyncJob(priority, loopFunc, context));

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

    public static function setParams(timeToGrindInMs:uint,
                                     timeToRestInMs:uint=0,
                                     forceWorkerRest:Boolean=false):void
    {
      if (!initialized) { init(); }

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

        var complete:Boolean = j.loopFunc.call(j.context, t0+duration);
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
  public var loopFunc:Function;
  public var context:Object;

  public function AsyncJob(p:Number, l:Function, c:Object):void
  {
    priority = p;
    loopFunc = l;
    context = c;
  }
}
