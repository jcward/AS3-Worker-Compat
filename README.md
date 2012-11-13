AS3-Worker-Compat
=================

ActionScript Worker wrapper for compatibility with all versions of the AS3
Flash Player (9 and later)

What does it do?
=================

The WorkerCompat wrapper simply uses dynamic-lookup to determine if the Worker
API is available and supported.  This allows SWFs compiled with this code to be
playable on all version of the Flash Player, not just those with Worker support
(11.4 and later).

This wrapper is an alternative to using static imports, which would cause a
runtime-error of the flavor:

 An ActionScript error has occurred:
  ReferenceError: Error #1065: Variable flash.system::Worker is not defined.

Demo / Usage
=================

See the WorkerCompatTest.as example, and the compiled WorkerCompatTest.swf for
the demo.  The demo shows a red "radar-like" graphic that is generative, while
also running a CPU-burning while loop.  If AS3 Workers are supported, the two
tasks are run on separate threads and the graphic is a smooth fading radar
(subject of course to processor performance and other system processes.)  If
AS3 Workers are not supported, both tasks are run on the same thread (AS3 is
inherently single-threaded) and the radar graphic is choppy.

See demo_output.png
