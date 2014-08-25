package
{
	public class GameAssets
	{
		[Embed(source="assets/menuMusic.mp3")]
		public static const menuMusic:Class;
		
		[Embed(source="assets/combatMusic.mp3")]
		public static const combatMusic:Class;
		
		[Embed(source="assets/assets.swf", symbol='background')]
		public static const background:Class;
		
		public static const levelInfo:Object = {
				durationProgression: [45.0, 55.0, 65.0, 75.0, 85.0, 95.0, 110.0], 
				baseThreatProgression: [10, 15, 20, 25, 30, 35, 40], //itemized scale for starting threat for each level (could be extrapolated beyond array range for infinite levels)
				standardThreatCreep: 15, //amount that the threat increases over the course of any given level
				minThreatInflectionPoints: 2, maxThreatInflectionPoints: 4, //inflection points cause threat increase over level duration to be less linear
				minThreatInflectionAmp: 4, maxThreatInflectionAmp: 6, //amount of curve mutation that inflection points cause
				successMessages: [
						"Day breaks and the child awakes, unaware that she or her family were ever in any danger. And perhaps they weren\'t in much danger after all. \n\nYet, you can\'t escape the feeling the next night will be worse. Much worse.", //day 1
						"After your second night of battling inside this child\'s imagination, you are beginning to adapt to her thought patterns. \n\nYou are becoming more comfortable with the form her mind has given you, but why does it have to be so pink? and so fluffy?", //day 2
						"You are exhausted. The shadows seem to have found ways of making the night last longer. \n\nBut that's not your primary concern. \n\nYou think they\'re learning.", //day 3
						"There\'s no mistaking it now, the shadows are beginning to coordinate their attacks. \n\nYou will also have to observe and adapt if you are going to make it through the night.", //day 4
						"Another arduous night of struggle against the darkness. You are anxious to return to your normal human form. \n\nAfter spending so long in the form of that little girl\'s stuffed unicorn, you\'re beginnng to feel a bit too comfortable with the rainbow mane.", //day 5
						"It has nearly been a full week since your vigil began. \n\nIf the shadow lord does not succeed tonight, the rift will close and he will have to wait another millennium for his next chance. \nHe does not want to wait.", //day 6
						"With the sun\'s rise this morning, the rift is closed. Thanks to your efforts, the connection between our world and the realm of darkness has been severed. \n\nThat is--until another child delves too deep into the mysteries of one\'s own imagination." //day 7
					]
			};
		
		public static const playerInfo:Object = {
				posX: 512, posY: 487
			};
		
		[Embed(source="assets/assets.swf", symbol='defender')]
		public static const defender:Class;
		public static const defenderInfo:Object = {
				size: 25, //effective radius of hitbox 
				patrolCenterX: 512, patrolCenterY: 512, patrolRadius: 180, patrolMinDeg: -165, patrolMaxDeg: -15, //defines patrol arc along a circle
				minPatrolShift: 15, //limited shift in degrees for patrol move action
				initialMoveDelay: 300, moveDelay: 120, moveDuration: 1.3 //frequency and length of normal move action
			};
		
		[Embed(source="assets/assets.swf", symbol='enemy')]
		public static const enemy:Class;
		public static const enemyInfo:Object = {
				size: 15, //effective radius of hitbox
				initialSpawnDelay: 300, spawnDelay: 120,
				spawnDistance: 750, //distance from player at time of spawn
				standardFlightTime: 5.0
			};
		public static const enemyPatterns:Array = [
				{type: "simple",	threatMin: 0, threatPeak: 10, probabilityPeak: 90, probabilitySteady: 50},
				{type: "stream",	threatMin: 10, threatPeak: 25, probabilityPeak: 90, probabilitySteady: 50},
				{type: "arc",		threatMin: 20, threatPeak: 35, probabilityPeak: 90, probabilitySteady: 50},
				{type: "cluster",	threatMin: 30, threatPeak: 45, probabilityPeak: 90, probabilitySteady: 50}
			];
		
		[Embed(source="assets/assets.swf", symbol='projectile1')]
		public static const projectile1:Class;
		[Embed(source="assets/assets.swf", symbol='projectile2')]
		public static const projectile2:Class;
		[Embed(source="assets/assets.swf", symbol='projectile3')]
		public static const projectile3:Class;
		public static const projectiles:Array = [projectile1, projectile2, projectile3];
		public static const projectilesInfo:Object = {
			size: 10, //effective radius of hitbox 
			velocity: 10, maxConcurrent: 9, launchCooldown: 8, 
			launchOffset: 7, //number of pixels from defender to place new projectiles 
			minBoundsX: -5, maxBoundsX: 1029, minBoundsY: -5, maxBoundsY: 581 //for out of bounds check
		};
		
		[Embed(source="assets/assets.swf", symbol='healthbar')]
		public static const healthIndicator:Class;
		
		[Embed(source="assets/assets.swf", symbol='volumeControl')]
		public static const volumeControl:Class;
		
		[Embed(source="assets/screens.swf", symbol='screens')]
		public static const simpleScreens:Class;
		
		public function GameAssets()
		{
		}
	}
}