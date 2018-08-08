package com.jcward.workers {

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
		private function setDirty(name:*):void{
			if(_cachedWorkersSupported){
				_primordial.setSharedProperty(name,this[name]);
			}else{
				_primordial[name] = this[name];
			}
		}
		flash_proxy override function callProperty(name:*,...rest):*{
			switch(String(name)){
				case "setDirty":
					setDirty(rest);
				break;
				default:
			}
		}
		flash_proxy override function callProperty(name:*,...rest):*{
			switch(String(name)){
				case "setDirty":
					setDirty(rest);
				break;
				default:
			}
		}
    flash_proxy override function getProperty(name:*):*
    {
      if (_cachedWorkersSupported) {
        try {
          return _primordial.getSharedProperty(name);
        } catch (e:Error) {
          return null;
        }
      } else {
        return _primordial[name];
      }
    }

    flash_proxy function setProperty(name:*, value:*):void
    {
      if (_cachedWorkersSupported) {
        _primordial.setSharedProperty(name, value);
      } else {
        _primordial[name] = value;
      }
    }

  }
}
