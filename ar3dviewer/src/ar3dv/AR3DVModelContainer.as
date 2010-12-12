package ar3dv
{
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	
	import org.papervision3d.core.math.Matrix3D;
	import org.papervision3d.objects.DisplayObject3D;
	import org.papervision3d.objects.parsers.DAE;
	import org.papervision3d.objects.parsers.Max3DS;
	
	public class AR3DVModelContainer extends EventDispatcher
	{
		public static const CONFIG_FILE_LOADED:String = "configFileLoaded";
		public static const CONFIG_FILE_PARSED:String = "configFileParsed";

		private var _configFileLoader:URLLoader;
		private var _containerByPatternId:Array;
		private var _modelAR3DVContainer:Array;
		private var _modelAR3DV:AR3DVModel;
		
		public function AR3DVModelContainer(url:String) 
		{
			_configFileLoader = new URLLoader();
			_configFileLoader.addEventListener(IOErrorEvent.IO_ERROR, this.onConfigLoaded);
			_configFileLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, this.onConfigLoaded);
			_configFileLoader.addEventListener(Event.COMPLETE, this.onConfigLoaded);
			_configFileLoader.load(new URLRequest(url));
		}
		
		public function get containerByPatternId():Array{
			return _containerByPatternId;
		}
		
		public function getModelContainer(id:int):DisplayObject3D{	
			if(this.hasModel(id)){
				return _containerByPatternId[id];	
			}else{
				return null;
			}
		}
		
		public function setVisible(id:int,visibility:Boolean):void{
			this.getModelContainer(id).visible = visibility;
		}
		
		public function setTransform(id:int,matrix:Matrix3D):void{
			var container:DisplayObject3D = this.getModelContainer(id);
			container.transform = matrix;
		}
		
		public function hasModel(id:int):Boolean{
			return _containerByPatternId[id]!=null;
		}
		
		private function onConfigLoaded (evt:Event) :void {
			_configFileLoader.removeEventListener(IOErrorEvent.IO_ERROR, this.onConfigLoaded);
			_configFileLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, this.onConfigLoaded);
			_configFileLoader.removeEventListener(Event.COMPLETE, this.onConfigLoaded);
			
			if (evt is ErrorEvent) {
				this.debug("file konfigurasi gagal di-load");
				return;
			}
			
			this.debug("proses file konfigurasi...");
			this.parseConfigFile(new XML(_configFileLoader.data as String));
			_configFileLoader.close();
			_configFileLoader = null;
		}
		
		private function parseConfigFile(data:XML):void{
			var modelList:XMLList = data.models;
			_containerByPatternId = new Array();
			_modelAR3DVContainer = new Array();
			for each (var elem:XML in modelList.model) {
				if (elem.@enable=="true"){
					var modelAR3DV:AR3DVModel = new AR3DVModel(elem.@name,elem.@source_dir,elem.@source,elem.@pattern,elem.@type);
					modelAR3DV.addEventListener(AR3DVModelEvent.LOADED,this.onModelLoaded);
					modelAR3DV.addEventListener(AR3DVModelEvent.FAILED,this.onModelFailedLoaded);
					
					if(elem.rotation!=undefined){
						modelAR3DV.setRotationXYZ(elem.rotation.@x,elem.rotation.@y,elem.rotation.@z);
					}
					if(elem.position!=undefined){
						modelAR3DV.setPositionXYZ(elem.position.@x,elem.position.@y,elem.position.@z);
					}
					modelAR3DV.scale = Number(elem.@scale);	
					
					this.debug("load model : "+elem.@name);
					modelAR3DV.load();
					_modelAR3DVContainer[elem.@pattern] = modelAR3DV;
				}
			}
		}
		
		private function onModelLoaded(evt:AR3DVModelEvent):void{
			var modelAR3DV:AR3DVModel = _modelAR3DVContainer[evt.patternId];
			modelAR3DV.removeEventListener(AR3DVModelEvent.LOADED,this.onModelLoaded);
			var container:DisplayObject3D = new DisplayObject3D();			
			container.addChild(modelAR3DV.model);
			container.visible = false;
			_containerByPatternId[evt.patternId] = container;
			var parsed:Boolean = true;
			//cek apakah sudah semua model ter-load
			for each(modelAR3DV in _modelAR3DVContainer){
				if(modelAR3DV.model!=null){
					parsed = parsed && modelAR3DV.loaded;
				}
			}
			//jika semua objek ter-load
			if (parsed) {
				this.dispatchEvent(new Event(CONFIG_FILE_PARSED));
			}
		}
		
		private function debug(info:String):void{
			trace("[AR3DVModelContainer] "+info);
		}
		
		private function onModelFailedLoaded(evt:AR3DVModelEvent):void{
			var modelAR3DV:AR3DVModel = _modelAR3DVContainer[evt.patternId];
			modelAR3DV.removeEventListener(AR3DVModelEvent.LOADED,this.onModelFailedLoaded);
			this.debug("model "+evt.patternId+" gagal di-load");
		}
	}
}