package
{
	import com.demonsters.debugger.MonsterDebugger;
	import com.greensock.TweenMax;
	import com.greensock.easing.Expo;
	import com.greensock.easing.Linear;
	import com.greensock.easing.Sine;
	import com.greensock.plugins.TintPlugin;
	import com.greensock.plugins.TweenPlugin;
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	
	public class DefenseGameView extends Sprite
	{
		//VARIABLES
		private var _objectPool:ObjectPoolManager;
		
		//display elements
		private var _bg:MovieClip;
		private var _defenderMC:MovieClip;
		
		//game objects
		private var _defenderPosition:Number; //in degrees, along his patrol arc
		private var _defenderMoveDelay:uint;
		private var _spawnerCountdown:uint;
		private var _enemies:Array; //each: {asset:MovieClip, tween:TweenMax}
		private var _projectiles:Array; //each: {asset:MovieClip, direction:Number(Radians)}
		private var _projectileCooldown:uint;
		private var _healthIndicator:MovieClip;
		
		//state
		public var isReady:Boolean = false;
		private var _currentLevel:uint; //starts at 1 (subtract 1 to use as idx)
		private var _levelBaseThreat:Number;
		public var currentThreat:Number;
		private var _threatTween:TweenMax;
		private var _mouseButtonDown:Boolean;
		private var _currentHealth:Number;
		private var _healthRegenCooldown:uint;
		private var _wavesComplete:Boolean;
		private var _gameEnding:Boolean;
		
		//animation
		private var _tweenList:Array;
		
		//FUNCTIONS
		public function DefenseGameView()
		{
			super();
			init();
		}
		
		private function init():void {
			MonsterDebugger.trace(this, "Initial game setup");
			var tween:TweenMax;
			
			TweenPlugin.activate([TintPlugin]);
			_objectPool = ObjectPoolManager.getInstance();
			
			_currentLevel = 0;
			_threatTween = null;
			
			_tweenList = new Array();
			
			//background
			_bg = new GameAssets.background();
			this.addChild(_bg);
			tween = TweenMax.fromTo(Object(_bg).protectionAura, 2, {scaleX:0.95, scaleY:0.95}, {scaleX:1.10, scaleY:1.10, ease:Sine.easeInOut, paused: true, repeat: -1, yoyo: true});
			_tweenList.push(tween);
			
			//defender
			_defenderMC = new GameAssets.defender();
			_defenderMC.filters = [new DropShadowFilter(2, 90, 0x333333, 1.0, 8.0, 8.0, 1.0, 2)];
			this.addChild(_defenderMC);
			
			//enemies
			_enemies = new Array();
			
			//projectiles
			_projectiles = new Array();
			
			//health
			_healthIndicator = new GameAssets.healthIndicator();
			this.addChild(_healthIndicator);
			_healthIndicator.x = 512;
			_healthIndicator.y = 544;
			
			//done with first time setup; reset game state
			reset();
		}
		
		public function reset(levelNum:int = -1):void {
			MonsterDebugger.trace(this, "Reset game");
			
			this.alpha = 0.0;
			
			//level threat
			if (levelNum != -1) {
				_currentLevel = levelNum;
			} else {
				_currentLevel += 1;
			}
			_levelBaseThreat = getBaseThreatFromLevelNumber(_currentLevel);
			
			if (_threatTween != null) {
				_threatTween.pause();
				_threatTween = null;
			}
			
			//defender
			_defenderMoveDelay = GameAssets.defenderInfo.initialMoveDelay;
			_defenderMC.x = GameAssets.defenderInfo.patrolCenterX;
			_defenderMC.y = GameAssets.defenderInfo.patrolCenterY;
			_defenderPosition = 90;
			
			//enemies
			while (_enemies.length > 0) {
				var enemyObj:Object = _enemies.pop();
				this.removeChild(enemyObj.asset);
			}
			_spawnerCountdown = GameAssets.enemyInfo.initialSpawnDelay;
			
			//projectiles
			while (_projectiles.length > 0) {
				var projectileObj:Object = _projectiles.pop();
				this.removeChild(projectileObj.asset);
			}
			_projectileCooldown = 0;
			
			//health
			_currentHealth = 100.0;
			_healthIndicator.fill.scaleX = 1.0;
			_healthRegenCooldown = 0;
			
			//ready!
			isReady = true;
			this.dispatchEvent(new Event("READY"));
		}
		
		public function play(levelNum:int = -1):void {
			MonsterDebugger.trace(this, "Play game");
			var i:uint;
			
			isReady = false;
			
			if (levelNum != -1) {
				_currentLevel = levelNum
				_levelBaseThreat = getBaseThreatFromLevelNumber(_currentLevel);
			}
			MonsterDebugger.trace(this, "Game level: " + _currentLevel);
			//create threat curve
			currentThreat = _levelBaseThreat;
			var min:Number = _levelBaseThreat;
			var max:Number = _levelBaseThreat + GameAssets.levelInfo.standardThreatCreep;
			var numPoints:uint = Math.floor(Math.random() * (GameAssets.levelInfo.maxThreatInflectionPoints - GameAssets.levelInfo.minThreatInflectionPoints) + GameAssets.levelInfo.minThreatInflectionPoints);
			var variance:Number;
			var adjustNegative:Boolean;
			
			var arrPoints:Array = new Array();
			adjustNegative = (Math.random() >= 0.5) ? true : false;
			for (i = 1; i <= numPoints; i++) {
				variance = Math.random() * (GameAssets.levelInfo.maxThreatInflectionAmp - GameAssets.levelInfo.minThreatInflectionAmp) + GameAssets.levelInfo.minThreatInflectionAmp;
				if (adjustNegative) {
					variance = variance * -1;
				}
				adjustNegative = !adjustNegative;
				arrPoints.push({currentThreat: ((max - min) * (i / (numPoints + 1)) + min) + variance});
			}
			arrPoints.push({currentThreat: max});
			arrPoints.unshift({currentThreat: min});
			
			_wavesComplete = false;
			_gameEnding = false;
			var levelDuration:Number;
			if (levelNum <= GameAssets.levelInfo.durationProgression.length) {
				levelDuration = GameAssets.levelInfo.durationProgression[_currentLevel-1];
			} else {
				levelDuration = GameAssets.levelInfo.durationProgression[GameAssets.levelInfo.durationProgression.length-1];
			}
			_threatTween = TweenMax.to(this, levelDuration, {bezierThrough:arrPoints, ease: Linear.easeNone, onComplete: handleWavesComplete});
			
			//mouse
			_mouseButtonDown = false;
			
			//begin animations
			for (i = 0; i < _tweenList.length; i++) {
				_tweenList[i].restart();
			}
			
			TweenMax.fromTo(_defenderMC, 1.5, {scaleX: 0.2, scaleY: 0.2, x: 540, y: 500, alpha: 0.0}, {scaleX: 1.0, scaleY: 1.0, x: 545, y: 470, alpha: 1.0, ease: Sine.easeOut, delay: 2.0});
			TweenMax.fromTo(this, 2.0, {alpha: 0.0, tint: 0x000000}, {alpha: 1.0, tint: null, ease: Sine.easeInOut});
			
			//add listeners
			this.addEventListener(Event.ENTER_FRAME, mainLoop);
			this.addEventListener(MouseEvent.CLICK, fireProjectile, false, 0, true);
			this.addEventListener(MouseEvent.MOUSE_DOWN, updateMouseDownStatus, false, 0, true);
			this.addEventListener(MouseEvent.MOUSE_UP, updateMouseDownStatus, false, 0, true);
		}
		
		public function stop():void {
			MonsterDebugger.trace(this, "Stop game");
			var i:uint;
			
			//halt animations
			for (i = 0; i < _tweenList.length; i++) {
				_tweenList[i].pause();
			}
			for (i = 0; i < _enemies.length; i++) {
				_enemies[i].tween.pause();
			}
			
			//remove listeners
			this.removeEventListener(Event.ENTER_FRAME, mainLoop);
			this.removeEventListener(MouseEvent.CLICK, fireProjectile);
			this.removeEventListener(MouseEvent.MOUSE_DOWN, updateMouseDownStatus);
			this.removeEventListener(MouseEvent.MOUSE_UP, updateMouseDownStatus);
		}
		
		private function mainLoop(evt:Event = null):void {
			tickDefender();
			tickEnemies();
			tickProjectiles();
			tickHealth();
		}
		
		//tick functions
		private function tickDefender():void {
			_defenderMoveDelay -= 1;
			if (_defenderMoveDelay <= 0) {
				//adjust regular defender patrol
				_defenderMoveDelay = GameAssets.defenderInfo.moveDelay;
				var rDeg:Number;
				/*if (_defenderPosition == 90) {
					//initial roll
					rDeg = (Math.random() * (GameAssets.defenderInfo.patrolMaxDeg - GameAssets.defenderInfo.patrolMinDeg)) + GameAssets.defenderInfo.patrolMinDeg;
					_defenderPosition = rDeg;
				} else {
					//normal roll
					rDeg = Math.random() * (GameAssets.defenderInfo.maxPatrolShift - GameAssets.defenderInfo.minPatrolShift) + GameAssets.defenderInfo.minPatrolShift;
					rDeg *= (Math.random() < 0.5) ? -1 : 1;
					if (_defenderPosition + rDeg < GameAssets.defenderInfo.patrolMinDeg || _defenderPosition + rDeg > GameAssets.defenderInfo.patrolMinDeg) {
						_defenderPosition -= rDeg;
					} else {
						_defenderPosition += rDeg;
					}
				}*/
				do {
					rDeg = (Math.random() * (GameAssets.defenderInfo.patrolMaxDeg - GameAssets.defenderInfo.patrolMinDeg)) + GameAssets.defenderInfo.patrolMinDeg;
				} while(Math.abs(_defenderPosition - rDeg) < GameAssets.defenderInfo.minPatrolShift);
				_defenderPosition = rDeg;
				var posX:Number = GameAssets.defenderInfo.patrolCenterX + (GameAssets.defenderInfo.patrolRadius * Math.cos(Util.degToRad(rDeg)));
				var posY:Number = GameAssets.defenderInfo.patrolCenterY + (GameAssets.defenderInfo.patrolRadius * Math.sin(Util.degToRad(rDeg)));
				if (posX < _defenderMC.x) {
					_defenderMC.scaleX = -1;
				} else {
					_defenderMC.scaleX = 1;
				}
				TweenMax.to(_defenderMC, GameAssets.defenderInfo.moveDuration, {x:posX, y:posY, ease:Sine.easeOut});
			}
		}
		private function tickEnemies():void {
			//each enemy is updated with its tween and either removed on collision or upon reaching the player (at the end of the tween)
			//tick spawn countdown
			if (!_wavesComplete) {
				_spawnerCountdown -= 1;
				if (_spawnerCountdown <= 0) {
					spawnEnemies();
				}
			}
			//check collision (simplified based on known constants; point-linesegment, kinda)
			var px:Number, py:Number, vx:Number, vy:Number, wx:Number, wy:Number, t:Number, distSqr:Number;
			var lineLenSqr:Number = Math.pow(GameAssets.projectilesInfo.velocity, 2);
			var collisionDistSqr:Number = Math.pow(GameAssets.enemyInfo.size + GameAssets.projectilesInfo.size, 2);
			for (var i:int = 0; i < _projectiles.length; i++) {
				//v = current point; w = new point
				vx = _projectiles[i].asset.x;
				vy = _projectiles[i].asset.y;
				wx = vx + (Math.cos(_projectiles[i].direction) * GameAssets.projectilesInfo.velocity);
				wy = vy + (Math.sin(_projectiles[i].direction) * GameAssets.projectilesInfo.velocity);
				for (var j:int = 0; j < _enemies.length; j++) {
					if (_enemies[j].targetable) {
						px = _enemies[j].asset.x;
						py = _enemies[j].asset.y;
						//get shortest distance between enemy point and projectile line segment
						t = ((px - vx) * (wx - vx) + (py - vy) * (wy - vy)) / lineLenSqr;
						if (t > 1) { //closer to new pt
							distSqr = Util.distSquared(px, py, wx, wy);
						} else if (t < 0) { //closer to current pt
							distSqr = Util.distSquared(px, py, vx, vy);
						} else { //closer to some point on spanned segment
							distSqr = Util.distSquared(px, py, (vx + t * (wx - vx)), (vy + t * (wy - vy)));
						}
						
						if (distSqr < collisionDistSqr) {
							MonsterDebugger.trace(this, "Enemy-Projectile collision");
							//remove enemy
							_enemies[j].targetable = false;
							_enemies[j].tween.pause();
							_enemies[j].tween = TweenMax.to(_enemies[j].asset, 0.5, {x: "+="+(35 * Math.cos(_projectiles[i].direction)), y: "+="+(35 * Math.sin(_projectiles[i].direction)), scaleX: 2.0, scaleY: 2.0, tint: 0xFFFFFF, alpha: 0.0, 
																					ease: Sine.easeOut, onComplete: cleanupEnemy, onCompleteParams: [_enemies[j].asset]});
							//remove projectile
							this.removeChild(_projectiles[i].asset);
							_objectPool.returnProjectile(_projectiles[i].asset);
							_projectiles.splice(i, 1);
							i -= 1;
							
							break; //since projectile is now gone
						}
					}
				}
			}
		}
		private function tickProjectiles():void {
			//cooldown
			if (_projectileCooldown > 0) {
				_projectileCooldown -= 1;
			}
			//autofire if mouse held down
			if (_mouseButtonDown && _projectileCooldown <= 0) {
				fireProjectile();
			}
			//each projectile
			var projectileObj:Object
			for (var i:uint = 0; i < _projectiles.length; i++) {
				projectileObj = _projectiles[i];
				//update position
				projectileObj.asset.x += Math.cos(projectileObj.direction) * GameAssets.projectilesInfo.velocity;
				projectileObj.asset.y += Math.sin(projectileObj.direction) * GameAssets.projectilesInfo.velocity;
				//out of bounds check
				if (projectileObj.asset.x < GameAssets.projectilesInfo.minBoundsX || 
					projectileObj.asset.x > GameAssets.projectilesInfo.maxBoundsX || 
					projectileObj.asset.y < GameAssets.projectilesInfo.minBoundsY || 
					projectileObj.asset.y > GameAssets.projectilesInfo.maxBoundsY) 
				{
					MonsterDebugger.trace(this, "Removing projectile");
					
					this.removeChild(projectileObj.asset);
					_objectPool.returnProjectile(projectileObj.asset);
					_projectiles.splice(i, 1);
					i -= 1;
				}
			}
		}
		private function tickHealth():void {
			if (!_wavesComplete) {
				if (_healthRegenCooldown > 0) {
					_healthRegenCooldown -= 1;
				} else if (_currentHealth < 100.0) {
					_healthRegenCooldown = 70;
					
					_currentHealth += 1;
					TweenMax.to(_healthIndicator.fill, 1.5, {scaleX: Math.max(_currentHealth / 100, 0.0), ease: Sine.easeOut});
				}
			}
		}
		
		//event functions
		private function spawnEnemies():void {
			MonsterDebugger.trace(this, "Enemy spawn (threat = " + (int(currentThreat*100)/100) + ")");
			var i:uint;
			
			//determine spawn type
			//construct possible types
			var arrProbabilities:Array = new Array();
			for (i = 0; i < GameAssets.enemyPatterns.length; i++) {
				var pattern:Object = GameAssets.enemyPatterns[i];
				if (currentThreat > pattern.threatMin) {
					var weight:Number;
					var mid:Number = (pattern.threatPeak - pattern.threatMin) / 2;
					if (currentThreat > pattern.threatPeak + mid) {
						//sustaining
						weight = pattern.probabilitySteady;
					} else if (currentThreat > pattern.threatMin + mid) {
						//peaking
						weight = pattern.probabilityPeak - ((pattern.probabilityPeak - pattern.probabilitySteady) * Math.pow((currentThreat - pattern.threatPeak) / mid, 2));
					} else {
						//introducing
						weight = pattern.probabilitySteady * (currentThreat - pattern.threatMin) / mid;
					}
					arrProbabilities.push({type: pattern.type, weight: weight});
				}
			}
			//total probability weights
			var totalWeight:Number = 0;
			for (i = 0; i < arrProbabilities.length; i++) {
				totalWeight += arrProbabilities[i].weight;
			}
			//pick random type based on probability weights
			var randWeight:Number = Math.random() * totalWeight;
			var spawnType:String;
			for (i = 0; i < arrProbabilities.length; i++) {
				if (randWeight < arrProbabilities[i].weight) {
					spawnType = arrProbabilities[i].type;
					break;
				} else {
					randWeight -= arrProbabilities[i].weight;
				}
			}
			
			//default counter reset
			_spawnerCountdown = GameAssets.enemyInfo.spawnDelay;
			_spawnerCountdown *= 8.3 - 8.0 * (-1 / (currentThreat+1) + 1); //gradual speed increase from about 102% at level 1 start - 43% at the end of level 7
			
			//calculate "extra" factor
			var extraFactor:Number = Math.max(0, (currentThreat / 15) - 1);
			
			//generate the spawn
			var numSpawns:int;
			var randAngle:Number, posX:Number, posY:Number, spawnDistance:Number, flightTime:Number;
			var spread:Number, thisAngle:Number, passthroughOffset:Number, px:Number, py:Number;
			var enemyMC:MovieClip;
			var tween:TweenMax;
			var dest:Object;
			MonsterDebugger.trace(this, "Spawn type: "+spawnType);
			switch (spawnType) {
				case "cluster":
					numSpawns = 3 + Math.floor(extraFactor / 1.3);
					spread = Math.random() * (13 - 6) + 6; //each between 5 and 14 degrees apart
					if (_currentLevel == 7) {
						spread += 2;
					}
					spread = Util.degToRad(spread);
					
					randAngle = ((-1 * Math.PI) + (spread * numSpawns)) * Math.random();
										
					thisAngle = randAngle;
					for (i = 0; i < numSpawns; i++) {
						posX = GameAssets.playerInfo.posX + (GameAssets.enemyInfo.spawnDistance * Math.cos(thisAngle));
						posY = GameAssets.playerInfo.posY + (GameAssets.enemyInfo.spawnDistance * Math.sin(thisAngle));
						dest = getRandomizedEnemyDestianation(thisAngle);
						
						enemyMC = _objectPool.getEnemy();
						enemyMC.x = posX;
						enemyMC.y = posY;
						enemyMC.rotation = Util.radToDeg(thisAngle) + 180;
						this.addChild(enemyMC);
						
						tween = TweenMax.to(enemyMC, GameAssets.enemyInfo.standardFlightTime, {x: dest.x, y: dest.y, ease: Linear.easeNone, onComplete: enemyCollideWithPlayer, onCompleteParams: [enemyMC]});
						
						_enemies.push({asset: enemyMC, tween: tween, targetable: true});
						
						thisAngle -= spread;
					}
					break;
				case "arc":
					randAngle = -1 * Math.PI * Math.random();
					numSpawns = 3 + Math.floor(extraFactor / 2);
					
					passthroughOffset = (Math.random() * (30 - 10)) + 10; //must be between 30 and 60 degrees "off-course"
					passthroughOffset *= (Math.random() < 0.5) ? -1 : 1;
					passthroughOffset = Util.degToRad(passthroughOffset);
					if (randAngle + passthroughOffset > 0 || randAngle + passthroughOffset < -1 * Math.PI) {
						passthroughOffset *= -1; //passthrough cannot put enemies outside normal bounds
					}
					
					for (i = 0; i < numSpawns; i++) {
						spawnDistance = GameAssets.enemyInfo.spawnDistance + ((GameAssets.enemyInfo.size + 15) * i);
						posX = GameAssets.playerInfo.posX + (spawnDistance * Math.cos(randAngle));
						posY = GameAssets.playerInfo.posY + (spawnDistance * Math.sin(randAngle));
						dest = getRandomizedEnemyDestianation(randAngle + passthroughOffset);
						px = GameAssets.playerInfo.posX + (spawnDistance / 2) * Math.cos(randAngle + passthroughOffset);
						py = GameAssets.playerInfo.posY + (spawnDistance / 2) * Math.sin(randAngle + passthroughOffset);
						
						enemyMC = _objectPool.getEnemy();
						enemyMC.x = posX;
						enemyMC.y = posY;
						enemyMC.rotation = Util.radToDeg(randAngle) + 180;
						this.addChild(enemyMC);
						
						flightTime = GameAssets.enemyInfo.standardFlightTime * (spawnDistance / GameAssets.enemyInfo.spawnDistance) * ((_currentLevel == 7) ? 1.15 : 1.25);
						tween = TweenMax.to(enemyMC, flightTime, {bezierThrough:{values:[{x: posX, y: posY}, {x: px, y: py}, {x: dest.x, y: dest.y}], autoRotate: true}, ease: Linear.easeNone, onComplete: enemyCollideWithPlayer, onCompleteParams: [enemyMC]});
						
						_enemies.push({asset: enemyMC, tween: tween, targetable: true});
					}
					break;
				case "stream":
					randAngle = -1 * Math.PI * Math.random();
					numSpawns = 4 + Math.floor(extraFactor);
					
					for (i = 0; i < numSpawns; i++) {
						spawnDistance = GameAssets.enemyInfo.spawnDistance + ((GameAssets.enemyInfo.size + 15) * i);
						posX = GameAssets.playerInfo.posX + (spawnDistance * Math.cos(randAngle));
						posY = GameAssets.playerInfo.posY + (spawnDistance * Math.sin(randAngle));
						dest = getRandomizedEnemyDestianation(randAngle);
						
						enemyMC = _objectPool.getEnemy();
						enemyMC.x = posX;
						enemyMC.y = posY;
						enemyMC.rotation = Util.radToDeg(randAngle) + 180;
						this.addChild(enemyMC);
						
						flightTime = GameAssets.enemyInfo.standardFlightTime * spawnDistance / GameAssets.enemyInfo.spawnDistance;
						tween = TweenMax.to(enemyMC, flightTime, {x: dest.x, y: dest.y, ease: Linear.easeNone, onComplete: enemyCollideWithPlayer, onCompleteParams: [enemyMC]});
						
						_enemies.push({asset: enemyMC, tween: tween, targetable: true});
					}
					break;
				case "simple":
				default:
					randAngle = -1 * Math.PI * Math.random();
					posX = GameAssets.playerInfo.posX + (GameAssets.enemyInfo.spawnDistance * Math.cos(randAngle));
					posY = GameAssets.playerInfo.posY + (GameAssets.enemyInfo.spawnDistance * Math.sin(randAngle));
					dest = getRandomizedEnemyDestianation(randAngle);
					
					enemyMC = _objectPool.getEnemy();
					enemyMC.x = posX;
					enemyMC.y = posY;
					enemyMC.rotation = Util.radToDeg(randAngle) + 180;
					this.addChild(enemyMC);
					
					tween = TweenMax.to(enemyMC, GameAssets.enemyInfo.standardFlightTime, {x: dest.x, y: dest.y, ease: Linear.easeNone, onComplete: enemyCollideWithPlayer, onCompleteParams: [enemyMC]});
					
					_enemies.push({asset: enemyMC, tween: tween, targetable: true});
					
					_spawnerCountdown *= 1.8 - 1.2 * (-1 / (currentThreat+1) + 1); //spawn time reduction: about 71% at level 1 start - 62% at the end of level 7
					if (_currentLevel == 7) {
						_spawnerCountdown *= 0.9;
					}
					break;
			}
		}
		private function enemyCollideWithPlayer(enemy:MovieClip):void {
			MonsterDebugger.trace(this, "Enemy collision with player");
			var i:uint, idx:int;
			//get enemy index
			idx = -1;
			for (i = 0; i < _enemies.length; i++) {
				if (_enemies[i].asset == enemy) {
					idx = i;
				}
			}
			
			if (idx != -1) {
				//take damage
				_currentHealth -= 12;
				TweenMax.to(_healthIndicator.fill, 1.5, {scaleX: Math.max(_currentHealth / 100, 0.0), ease: Sine.easeOut});
				TweenMax.to(_bg.child, 0.1,{x: GameAssets.playerInfo.posX + (1 + Math.random() * 3), repeat: 12 - 1, delay: 0.1, ease:Expo.easeInOut});
				TweenMax.to(_bg.child, 0.1,{x: GameAssets.playerInfo.posX, delay:(12 + 1) * .1, ease: Expo.easeInOut});
				
				if (_currentHealth <= 0.0) {
					_currentHealth = 0.0;
					if (!_gameEnding) {
						handleGameOver();
					}
				}
				
				//tween out
				_enemies[idx].targetable = false;
				_enemies[idx].tween = TweenMax.to(_enemies[idx].asset, 1.8, {x: GameAssets.playerInfo.posX, y: GameAssets.playerInfo.posY, alpha: 0.0, ease: Sine.easeOut, onComplete: cleanupEnemy, onCompleteParams: [_enemies[idx].asset]});
			}
		}
		
		private function cleanupEnemy(enemy:MovieClip):void {
			var i:uint, idx:int;
			//get enemy index
			idx = -1;
			for (i = 0; i < _enemies.length; i++) {
				if (_enemies[i].asset == enemy) {
					idx = i;
				}
			}
			
			if (idx != -1) {
				//cleanup and remove enemy 
				if (idx >= 0) {
					this.removeChild(_enemies[idx].asset);
					_objectPool.returnEnemy(_enemies[idx].asset);
					_enemies.splice(idx, 1);
				}
			}
			
			//if no more enemies are coming and this is the last one, level complete
			if (_wavesComplete) {
				handleWavesComplete();
			}
		}
		
		private function fireProjectile(evt:MouseEvent = null):void {
			if (_projectileCooldown == 0) {
				if (_projectiles.length < GameAssets.projectilesInfo.maxConcurrent) {
					var asset:MovieClip = _objectPool.getProjectile();
					if (asset != null) {
						MonsterDebugger.trace(this, "Firing projectile");
						
						var direction:Number = Math.atan2(this.mouseY - _defenderMC.y, this.mouseX - _defenderMC.x);
						var posX:Number = _defenderMC.x + ((GameAssets.defenderInfo.size + GameAssets.projectilesInfo.launchOffset) * Math.cos(direction));
						var posY:Number = _defenderMC.y + ((GameAssets.defenderInfo.size + GameAssets.projectilesInfo.launchOffset) * Math.sin(direction));
						this.addChild(asset);
						asset.x = posX;
						asset.y = posY;
						_projectiles.push({asset: asset, direction: direction});
						_projectileCooldown = GameAssets.projectilesInfo.launchCooldown;
					}
				} 
			}
		}
		
		private function updateMouseDownStatus(evt:MouseEvent):void {
			_mouseButtonDown = evt.buttonDown;
		}
		
		private function handleGameOver():void {
			//trigger end fade
			_gameEnding = true;
			TweenMax.to(this, 5.0, {tint: 0x9900CC, alpha: 0.0, ease: Sine.easeInOut, onComplete: finalizeGameOver});
		}
		
		private function handleWavesComplete():void {
			MonsterDebugger.trace(this, "Waves complete. When last enemy dies, level should complete.");
			_wavesComplete = true;
			
			//check if we can end it now
			if (_enemies.length < 1 && _currentHealth > 0) {
				//trigger end fade
				_gameEnding = true;
				TweenMax.to(this, 5.0, {alpha: 0.0, tint: 0xFFF9AF, ease: Sine.easeInOut, onComplete: finalizeLevelComplete});
			}
		}
		
		private function finalizeGameOver():void {
			MonsterDebugger.trace(this, "Game over");
			this.stop();
			this.dispatchEvent(new Event("GAMEOVER"));
		}
		
		private function finalizeLevelComplete():void {
			MonsterDebugger.trace(this, "Level complete");
			this.stop();
			this.dispatchEvent(new Event("LEVELCOMPLETE"));
		}
		
		//misc utility functions
		private function getRandomizedEnemyDestianation(incomingAngle:Number):Object {
			var randAngle:Number = Math.random() * Math.PI * 2;
			var randDisplacement:Number = Math.random() * 20;
			return {
				x: GameAssets.playerInfo.posX + (80 * Math.cos(incomingAngle)) + (randDisplacement * Math.cos(randAngle)),
				y: GameAssets.playerInfo.posY + (80 * Math.sin(incomingAngle)) + (randDisplacement * Math.sin(randAngle))
			};
		}
		
		private function getBaseThreatFromLevelNumber(levelNum:uint):Number {
			if (levelNum <= GameAssets.levelInfo.baseThreatProgression.length) {
				return GameAssets.levelInfo.baseThreatProgression[_currentLevel-1];
			} else {
				//extrapolate from last two items of progression
				var len:uint = GameAssets.levelInfo.baseThreatProgression.length;
				var diff:Number = GameAssets.levelInfo.baseThreatProgression[len-1] - GameAssets.levelInfo.baseThreatProgression[len-2];
				return GameAssets.levelInfo.baseThreatProgression[len-1] + (diff * (levelNum - len));
			}
		}
	}
}