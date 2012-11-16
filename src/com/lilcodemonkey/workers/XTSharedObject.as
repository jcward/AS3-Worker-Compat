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
   * There are a few things to keep in mind when using this class:
   *
   *  - A background worker could potentially saturate this shared object
   *    by writing too often (i.e. in a loop) and it can crash Flash.  Plan
   *    your write/update frequency accordingly.
   *
   *  - To ensure consistent behavior for all Flash Player versions, be
   *    careful to only get/set AMF serializable objects on this object.
   *    If you're unsure what this means, the short answer is: all simple
   *    data types, and Objects and Arrays composed of simple data types
   *    are OK.  References to instances (Sprite, MyClass, etc), are
   *    typically NOT AMF serializable.
   *
   *  - Typically you should not use Objects and Arrays as properties,
   *    because setting a property within those Objects does not trigger
   *    the setter that writes the value to the other workers.  In other
   *    words, a setter should only use one level of accessor:
   *
   *     xtso.value = 1;
   *
   *    And never sub-properties:
   *
   *     xtso.obj.value = 1; // This set won't get sent to other workers!
   *
   *    TODO: make this XTSO-class recursive?
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
        } else {
          var vectorOfWorkers:* = WorkerCompat.WorkerDomain.current.listWorkers();
          for (var i:int = vectorOfWorkers.length-1; i>=0; i--) {
            if (vectorOfWorkers[i].isPrimordial) {
              _primordial = vectorOfWorkers[i];
              break;
            }
          }
        }
      } else {
        if (_primordial==null) {
          _primordial = new Object();
        }
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
