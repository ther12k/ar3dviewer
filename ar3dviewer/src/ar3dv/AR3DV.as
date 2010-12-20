package ar3dv
{
	/* FLARManager Framework [http://words.transmote.com/wp/flarmanager/] */ 
	import ar3dv.AR3DVModelContainer;
	
	import com.transmote.flar.FLARManager;
	import com.transmote.flar.camera.FLARCamera_PV3D;
	import com.transmote.flar.marker.FLARMarker;
	import com.transmote.flar.marker.FLARMarkerEvent;
	import com.transmote.flar.tracker.FLARToolkitManager;
	import com.transmote.flar.utils.geom.PVGeomUtils;
	
	import flash.display.LoaderInfo;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.media.Camera;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.utils.Dictionary;
	
	import org.libspark.flartoolkit.support.pv3d.FLARCamera3D;
	import org.papervision3d.cameras.Camera3D;
	import org.papervision3d.core.math.Matrix3D;
	import org.papervision3d.lights.PointLight3D;
	import org.papervision3d.materials.shadematerials.FlatShadeMaterial;
	import org.papervision3d.materials.utils.MaterialsList;
	import org.papervision3d.objects.DisplayObject3D;
	import org.papervision3d.objects.parsers.DAE;
	import org.papervision3d.objects.primitives.Cube;
	import org.papervision3d.objects.primitives.Sphere;
	import org.papervision3d.render.LazyRenderEngine;
	import org.papervision3d.scenes.Scene3D;
	import org.papervision3d.view.Viewport3D;
	import org.papervision3d.view.stats.StatsView;
	
	/* Setting output */
	[SWF(width="640", height="480", frameRate="60", backgroundColor="#FFFFFF")]
	public class AR3DV extends Sprite {
		/* FLARManager pointer */
		protected var fm:FLARManager;
		/* model config/source */
		protected var ar3dvContainer:AR3DVModelContainer;
		/* Array storing references to all markers on screen, key by pattern id */
		private var _detectedMarkers:Array;
		/* Papervision Scene3D pointer */
		private var _scene3D:Scene3D;
		/* Papervision Viewport3D pointer */
		private var _viewport3D:Viewport3D;
		/* FLARToolkit FLARCamera3D pointer */ 
		private var _camera3D:Camera3D;
		/* Papervision render engine pointer */
		private var _renderEngine:LazyRenderEngine;
		/* Papervision PointLight3D pointer */
		private var _pointLight3D:PointLight3D;
		
		private var _debugText:TextField;
		
		public function AR3DV() {
			this.initDebug();
			this.debug("Starting ...",true);
			this.loaderInfo.addEventListener(Event.COMPLETE, AR3DVComplete);
		}
		
		private function AR3DVComplete(evt:Event):void{
			var queryStrings:Object = this.loaderInfo.parameters;
			var configFile:String = queryStrings.config;
			if(configFile==null){
				configFile = "resources/ar3dv/ar3dv.xml";
			}else{
				configFile = "resources/ar3dv/"+configFile+".xml";
			}
			this.initModels(configFile);
		}
		
		private function initDebug():void{
			var myFormat:TextFormat = new TextFormat();
			myFormat.size = 15;
			
			_debugText = new TextField();
			_debugText.textColor = 0x0000FF;
			_debugText.defaultTextFormat = myFormat;	
			
			// Find the center co-ordinate of Stage
			var stageCenter_x:Number = stage.stageWidth/2;
			var stageCenter_y:Number = stage.stageHeight/2;
			// Find the center co-ordinate of TextField
			var textCenter_x:Number = _debugText.width/2;
			var textCenter_y:Number = _debugText.height/2;
			// Align TextField to Center
			// Note: textField_txt.x and textField_txt.y is the Top Left corner of TextField
			_debugText.x = stageCenter_x - textCenter_x;
			_debugText.y = stageCenter_y - textCenter_y;
			
			addChild(_debugText);
		}
		
		private function debug(info:String,useTextField:Boolean=false):void{
			trace("[AR3DV] "+info);
			if(useTextField){
				_debugText.text = "[AR3DV] "+info;
				_debugText.visible = true;
			}
		}
	
		private function onModelsLoaded(evt:Event):void{
			this.ar3dvContainer.removeEventListener(AR3DVModelContainer.CONFIG_FILE_PARSED,this.onModelsLoaded);
			this.debug("model selesai di-load");
			if (Camera.getCamera() != null){
				this.initAR();	
			}else{
				this.debug("No Camera, plz connect a webcam and refresh this page",true);
			}
		}
		
		private function initModels(configFile:String):void{
			// load model source dan konfigurasinya
			this.ar3dvContainer = new AR3DVModelContainer(configFile);
			this.ar3dvContainer.addEventListener(AR3DVModelContainer.CONFIG_FILE_PARSED,this.onModelsLoaded);
		}
		
		private function onFlarManagerLoad(e:Event):void {
			/* listener dihapus agar fungsi onFlarManagerLoad tidak dijalankan lagi */
			this.fm.removeEventListener(Event.INIT, this.onFlarManagerLoad);
			this.initEngine3D();
		}
		
		/* Inisialisasi AR */
		private function initAR():void {
			/* Inisiliasasi FLARManager */
			this.fm =  new FLARManager("resources/flar/flarConfig.xml", new FLARToolkitManager(), this.stage);
			/* tampilkan webcam */
			this.addChild(Sprite(this.fm.flarSource));
			/* Event listener ketika sebuah marker dikenali */
			this.fm.addEventListener(FLARMarkerEvent.MARKER_ADDED, this.onMarkerAdded);
			/* Event listener ketika sebuah marker tidak terdeteksi lagi*/
			this.fm.addEventListener(FLARMarkerEvent.MARKER_REMOVED, this.onMarkerRemoved);
			/* Event listener jika inisialisasi selesai */
			this.fm.addEventListener(Event.INIT, this.onFlarManagerLoad);
		}
		
		private function initEngine3D():void{
			_scene3D = new Scene3D();
			/* Papervision viewport */
			_viewport3D = new Viewport3D(this.stage.stageWidth, this.stage.stageHeight);
			/* Menambahkan Papervision viewport */
			this.addChild(_viewport3D);
			/* Init FLARCamera3D */
			_camera3D = new FLARCamera_PV3D(this.fm, new Rectangle(0, 0, this.stage.stageWidth, this.stage.stageHeight));
			
			/* Papervision point light */
			_pointLight3D = new PointLight3D(true, false);
			/* light position */
			_pointLight3D.x = 1000;
			_pointLight3D.y = 1000;
			_pointLight3D.z = -1000;
			/* Menambahkan light ke Papervision scene */
			_scene3D.addChild(_pointLight3D);
			
			_detectedMarkers = new Array();
			
			for each(var container:DisplayObject3D in this.ar3dvContainer.containerByPatternId) {
				_scene3D.addChild(container);
			}
			
			/* Papervision render engine Init */
			_renderEngine = new LazyRenderEngine(_scene3D, _camera3D, _viewport3D);
			/* Stats View */
			this.addChild(new StatsView(_renderEngine));
			
			_debugText.visible = false;
			/* event listener untuk setiap frame */
			this.stage.addEventListener(Event.ENTER_FRAME, this.onEnterFrame);
		}
		
		private function onMarkerAdded (evt:FLARMarkerEvent) :void {
			var marker:FLARMarker = evt.marker;
			var patID:int = marker.patternId;
			this.debug("marker denga pola "+patID+" terdeteksi");
			if(this.ar3dvContainer.hasModel(patID)){
				this.debug("model  :  "+patID+" ditemukan");
				_detectedMarkers[patID] = marker;
				this.ar3dvContainer.setVisible(patID,true);
			}else{
				this.debug("model  :  "+patID+" tidak ditemukan");
			}
		}
		
		private function onMarkerRemoved (evt:FLARMarkerEvent) :void {
			var marker:FLARMarker = evt.marker;
			var patID:int = marker.patternId;
			if(this.ar3dvContainer.hasModel(patID) && _detectedMarkers[patID] != null){
				this.debug("marker dengan pola "+patID+" tidak terdeteksi lagi");
				_detectedMarkers[patID] = null;
				this.ar3dvContainer.setVisible(patID,false);
			}
		}
		
		private function onEnterFrame (evt:Event) :void {
			for each(var marker:FLARMarker in _detectedMarkers){
				if(marker!=null){
					//konversi matriks ke matriks yang bersesuaian dengan PV3D
					var transMatrix:Matrix3D = PVGeomUtils.convertMatrixToPVMatrix(marker.transformMatrix);
					this.ar3dvContainer.setTransform(marker.patternId,transMatrix);			
				}
			}
			// render PV3D engine
			_renderEngine.render();
		}
		
	}
}