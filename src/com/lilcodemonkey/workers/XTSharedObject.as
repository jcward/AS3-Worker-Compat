package com.lilcodemonkey.workers {

  import flash.utils.Proxy;
  import flash.utils.flash_proxy;

  /**
   * "Cross-Thread" Shared Object
   *
   * A very simple way to pass data across threads that works in all Flash
   * Player versions.  For Flash Players that support workers, this proxies
   * the primordial worker's get/setSharedProperty functions.  For Flash
   * Players that don't support Workers, this represents a simple static
   * Object.
   *
   * There are 2 requirements to using this class:
   *
   *  - An XTSharedObject must be created from the primordial worker
   *    before the Oobject's properties are accessed.
   *
   *  - To ensure consistent behavior for all Flash Player versions, be
   *    careful to only get/set AMF serializable objects on this object.
   *    If you're unsure what this means, the short answer is: all simple
   *    data types, and Objects and Arrays composed of simple data types
   *    are OK.  References to instances (Sprite, MyClass, etc), are
   *    typically NOT AMF serializable.
   */
  dynamic public class XTSharedObject extends Proxy {

    private static var _primordial:*;
    private static var _cachedWorkersSupported:Boolean;
    private static var _cachedIsPrimordial:Boolean;

    public function XTSharedObject():void
    {
      _cachedWorkersSupported = WorkerCompat.workersSupported;

      if (_cachedWorkersSupported) {
        _cachedIsPrimordial = WorkerCompat.Worker.current.isPrimordial as Boolean;
        if (_cachedIsPrimordial) {
          _primordial = WorkerCompat.Worker.current;
          trace("Setting _primordial with self");
        } else {
          var vectorOfWorkers:* = WorkerCompat.WorkerDomain.current.listWorkers();
          for (var i:int = vectorOfWorkers.length-1; i>=0; i--) {
            trace("Checking worker "+i);
            if (!vectorOfWorkers[i].isPrimordial) {
              trace("Setting _primordial with worker "+i);
              _primordial = vectorOfWorkers[i];
              //break;
            }
          }
          //_primordial = WorkerCompat.Worker.current.getSharedProperty("_XTSOToPrimordial");
        }
        trace("_primordial is: "+_primordial);
      } else {
        if (_primordial==null) {
          _primordial = new Object();
        }
      }

//        if (_cachedWorkersSupported) {
// 
//          if (WorkerCompat.Worker.current.isPrimordial) {
//            _workersvar vectorOfWorkers:* = WorkerCompat.WorkerDomain.current.listWorkers;
//            _primordial = WorkerCompat.Worker.current;
//          }
// 
//          // This doesn't work.  I'm not sure why the primordial worker isn't
//          // returned in the listWorkers vector...
//          var vectorOfWorkers:* = WorkerCompat.WorkerDomain.current.listWorkers;
//          for (var i:int = vectorOfWorkers.length-1; i>=0; i--) {
//            if (!vectorOfWorkers[i].isPrimordial) {
//              _primordial = vectorOfWorkers[i];
//              break;
//            }
//          }
//          //if (_primordial==null) {
//          //  throw new Error("Error: primordial worker not found!");
//          //}
//        } else {
//          _primordial = new Object();
//        }
//      }
    }

    //flash_proxy override function callProperty(name:*, ...args):*

    public function attachWorker(worker:*):void
    {
      if (_cachedWorkersSupported && _cachedIsPrimordial) {
        //var fromPrimordial:* = Worker.current.createMessageChannel(bgWorker);
        //var toPrimordial:* = Worker.current.createMessageChannel(bgWorker);
        worker.setSharedProperty("_XTSOToPrimordial", WorkerCompat.Worker.current);
        // 
        //if (!_sendChannels) { _sendChannels = []; }
        //_sendChannels.push(fromPrimordial);
        // 
        //worker.setSharedProperty("_XTSharedObjectChannel", WorkerCompat.WorkerDomain.current);
      }
    }

    override flash_proxy function getProperty(name:*):*
    {
      if (_cachedWorkersSupported) {
        return _primordial.getSharedProperty(name);
      } else {
        return _primordial[name];
      }
    }

    override flash_proxy function setProperty(name:*, value:*):void
    {
      if (_cachedWorkersSupported) {
        _primordial.setSharedProperty(name, value);
      } else {
        _primordial[name] = value;
      }
    }

  }
}
