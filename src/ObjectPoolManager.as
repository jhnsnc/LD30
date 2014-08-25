package
{
	import com.demonsters.debugger.MonsterDebugger;
	import com.greensock.TweenMax;
	
	import flash.display.MovieClip;
	import flash.filters.GlowFilter;
	
	import flashx.textLayout.operations.MoveChildrenOperation;
	
	public class ObjectPoolManager
	{
		private static var _instance:ObjectPoolManager;
		
		//VARIABLES
		private const INITIAL_ENEMY_POOL_SIZE:uint = 20;
		
		private var _enemyGlowFilter:GlowFilter;
		
		private var _enemies:Array;
		private var _projectiles:Array;
		
		//FUNCTIONS
		public function ObjectPoolManager(singleton:SingletonEnforcer)
		{
			if(!singleton) throw new Error("You cannot instantiate the ObjectPoolManager class using the constructor. Please use ObjectPoolManager.getInstance() instead.");
			initialize();
		}
		
		static public function getInstance():ObjectPoolManager
		{
			if(!_instance)
			{
				_instance = new ObjectPoolManager(new SingletonEnforcer());
			}
			return _instance;
		}
		
		public function initialize():void
		{
			var i:uint;
			var mc:MovieClip;
			
			_enemyGlowFilter = new GlowFilter(0x9900CC, 1.0, 9.0, 9.0, 2.5);
			
			//create enemies
			_enemies = new Array();
			for (i = 0; i < INITIAL_ENEMY_POOL_SIZE; i++) {
				mc = new GameAssets.enemy();
				mc.filters = [_enemyGlowFilter];
				mc.stop();
				_enemies.push({inUse: false, asset: mc});
			}
			
			//create projectiles
			_projectiles = new Array();
			for (i = 0; i < GameAssets.projectilesInfo.maxConcurrent; i++) {
				mc = new GameAssets.projectiles[i%GameAssets.projectiles.length]();
				mc.stop();
				_projectiles.push({inUse: false, asset: mc});
			}
		}
		
		//actual functions start here
		public function getEnemy():MovieClip
		{
			var result:MovieClip;
			for (var i:uint = 0; i < _enemies.length; i++) {
				if (!_enemies[i].inUse) {
					_enemies[i].inUse = true;
					result = _enemies[i].asset;
					_enemies.push(_enemies.splice(i, 1)[0]); //move to end of array
					
					//reset values before sending
					TweenMax.set(result, {scaleX: 1.0, scaleY: 1.0, alpha: 1.0, tint: null});
					result.gotoAndPlay(Math.floor(Math.random() * result.totalFrames) + 1);
					return result;
				}
			}
			//none found -- generate a new one and add it to the pool
			result = new GameAssets.enemy();
			result.filters = [_enemyGlowFilter];
			result.gotoAndPlay(1);
			_enemies.push({inUse: true, asset: result});
			return result;
		}
		
		public function returnEnemy(asset:MovieClip):void
		{
			for (var i:uint = 0; i < _enemies.length; i++) {
				if (_enemies[i].asset == asset) {
					asset.stop();
					_enemies[i].inUse = false;
					break;
				}
			}
		}
		
		public function getProjectile():MovieClip
		{
			for (var i:uint = 0; i < _projectiles.length; i++) {
				if (!_projectiles[i].inUse) {
					_projectiles[i].inUse = true;
					var result:MovieClip = _projectiles[i].asset;
					_projectiles.push(_projectiles.splice(i, 1)[0]); //move to end of array
					result.gotoAndPlay(1);
					return result;
				}
			}
			//none found
			return null;
		}
		
		public function returnProjectile(asset:MovieClip):void
		{
			for (var i:uint = 0; i < _projectiles.length; i++) {
				if (_projectiles[i].asset == asset) {
					asset.stop();
					_projectiles[i].inUse = false;
					break;
				}
			}
		}
	}
}

class SingletonEnforcer
{
	public function SingletonEnforcer(){};
}