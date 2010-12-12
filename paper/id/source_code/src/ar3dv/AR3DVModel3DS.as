package ar3dv
{
	/* Flash event package*/
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	
	import org.papervision3d.events.FileLoadEvent;
	import org.papervision3d.objects.DisplayObject3D;
	import org.papervision3d.objects.parsers.Max3DS;
	
	public class AR3DVModel3DS extends EventDispatcher
	{
		private var _loaded:Boolean;
		private var _source:String;
		private var _dir:String;
		private var _model:Max3DS;
		
		protected var _id:int;
		public function AR3DVModel3DS(name:String,dir:String,source:String,id:int) 
		{
			_model = new Max3DS(name);
			_dir = dir;
			_source = source;
			_id = id;
			_loaded = false;
		}
		
		private function debug(info:String):void{
			trace("[AR3DVModel] "+info);
		}
		
		private function addListener():void{
			this.model.addEventListener(FileLoadEvent.LOAD_COMPLETE, this.onLoaded);
		}
		
		private function removeListener():void{
			this.model.removeEventListener(FileLoadEvent.LOAD_COMPLETE, this.onLoaded);
		}
		
		private function loadSource():void{
			this.model.load(_dir+_source,null,_dir);
		}
		
		public function get loaded():Boolean{ 
			return _loaded;
		}
		
		public function get model():Max3DS{ 
			return _model;
		}
		
		public function load():void{
			if(_loaded) {
				this.debug(_id+" loaded");
				_loaded = true;
				dispatchEvent(new AR3DVModelEvent(AR3DVModelEvent.LOADED,_id));
				return;
			}
			this.addListener();
			this.loadSource();
		}
		
		public function setRotationXYZ(x:int,y:int,z:int):void{
			this.model.rotationX = x;
			this.model.rotationY = y;
			this.model.rotationZ = z;
		}
		
		public function set scale(scale:int):void{
			this.model.scale = scale;
		}
		
		private function onLoaded (evt:Event) :void {
			this.debug(_id+" loaded");
			_loaded = true;
			this.model.x = 0;
			this.model.y = 0;
			this.model.z = 0;
			
			this.removeListener();
			this.dispatchEvent(new AR3DVModelEvent(AR3DVModelEvent.LOADED,_id));
		}
	}
}