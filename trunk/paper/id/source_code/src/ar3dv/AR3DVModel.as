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
	import org.papervision3d.objects.parsers.DAE;
	import org.papervision3d.objects.parsers.Max3DS;

	public class AR3DVModel extends EventDispatcher
	{
		private var _loaded:Boolean;
		private var _source:String;
		private var _dir:String;
		private var _type:String;
		private var _model:DisplayObject3D;
		
		protected var _id:int;
		public function AR3DVModel(name:String,dir:String,source:String,id:int,type:String="") 
		{
			switch(type){
				case "3DS":
					_model = new Max3DS(name);
					break;
				case "DAE":
					_model = new DAE(true,name,true);
					break;	
			}
			_type = type;
			_dir = dir;
			_source = source;
			_id = id;
			_loaded = false;
		}
		
		private function debug(info:String):void{
			trace("[AR3DVModel] "+info);
		}
		
		private function addListener():void{
			_model.addEventListener(FileLoadEvent.LOAD_COMPLETE, this.onLoaded);
		}
		
		private function removeListener():void{
			_model.removeEventListener(FileLoadEvent.LOAD_COMPLETE, this.onLoaded);
		}
		
		private function loadSource():void{
			switch(type){
				case "3DS":
					Max3DS(this.model).load(_dir+_source,null,_dir);
					break;
				case "DAE":
					DAE(this.model).load(_dir+_source);
			}
		}
		
		public function get type():String{ 
			return _type;
		}
		
		public function get loaded():Boolean{ 
			return _loaded;
		}
		
		public function get model():DisplayObject3D{ 
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
			_model.rotationX = x;
			_model.rotationY = y;
			_model.rotationZ = z;
		}
		
		public function set scale(scale:int):void{
			_model.scale = scale;
		}
		
		private function onLoaded (evt:Event) :void {
			this.debug(_id+" loaded");
			_loaded = true;
			
			this.removeListener();
			this.dispatchEvent(new AR3DVModelEvent(AR3DVModelEvent.LOADED,_id));
		}
	}
}