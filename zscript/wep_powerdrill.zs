// ------------------------------------------------------------
// Power Drill
// ------------------------------------------------------------
const POWERDRILLDRAIN=1023;
class PowerDrill:HDCellWeapon{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "PowerDrill"
		//$Sprite "DRILLA0"
		+hdweapon.fitsinbackpack
		+hdweapon.reverseguninertia

		weapon.selectionorder 90;
		weapon.slotnumber 1;
		weapon.slotpriority 0.9;
		weapon.bobstyle "Alpha";
		weapon.bobrangex 0.3;
		weapon.bobrangey 1.4;
		weapon.bobspeed 2.1;
		weapon.kickback 2;
		scale 0.4;
		hdweapon.barrelsize 16,1,2;//shorter than the chainsaw
		hdweapon.refid "drl";
		tag "Power Drill";
		obituary "%o gave %k a surprise trepanning.";
		inventory.pickupmessage "You got the power drill!";
	}
	override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){return GetSpareWeaponRegular(newowner,reverse,doselect);}
	override string,double getpickupsprite(){return "DRLPA0",0.7;}
	int walldamagemeter;
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		if(sb.hudlevel==1){
			sb.drawbattery(-54,-4,sb.DI_SCREEN_CENTER_BOTTOM,reloadorder:true);
			sb.drawnum(hpl.countinv("HDBattery"),-46,-8,sb.DI_SCREEN_CENTER_BOTTOM);
		}
		if(!hdw.weaponstatus[1])sb.drawstring(
			sb.mamountfont,"00000",(-16,-9),sb.DI_TEXT_ALIGN_RIGHT|
			sb.DI_TRANSLATABLE|sb.DI_SCREEN_CENTER_BOTTOM,
			Font.CR_DARKGRAY
		);else if(hdw.weaponstatus[1]>0)sb.drawwepnum(hdw.weaponstatus[1],20);
		if(walldamagemeter>0)sb.drawwepnum(walldamagemeter,100,posy:-9);
	}
	override string gethelptext(){
		LocalizeHelp();
		return
		LWPHELP_FIRE.."  Drill\n"
		..LWPHELP_RELOADRELOAD
		..LWPHELP_UNLOADUNLOAD
		;
	}
	override double gunmass(){
		return 5+(weaponstatus[DRILLS_BATTERY]<0?0:1);
	}
	override double weaponbulk(){
		return 50+(weaponstatus[DRILLS_BATTERY]>=0?ENC_BATTERY_LOADED:0);
	}//half the bulk of a chainsaw
	override void consolidate(){
		CheckBFGCharge(DRILLS_BATTERY);
	}
	action void A_HDDrill(){
		A_WeaponReady(WRF_NOFIRE);
		int battery=invoker.weaponstatus[DRILLS_BATTERY];
		int inertia=invoker.weaponstatus[DRILLS_INERTIA];
		if(inertia<8)invoker.weaponstatus[DRILLS_INERTIA]++;

		int drainprob=POWERDRILLDRAIN;
		int dmg=0;
		name sawpuff="HDSawPuff";//damage reduced by about 1/3
		if((inertia>6)&&(battery>random(5,8))){
			dmg=random(3,10);
			A_MuzzleClimb(
				randompick(-1,1)*frandom(0.2,0.3),
				randompick(-1,1)*frandom(0.2,0.4)
			);
		}else if((inertia>4)&&(battery>random(2,4))){
			dmg=random(2,8);
			A_SetTics(2);
			A_MuzzleClimb(
				randompick(-1,1)*frandom(0.1,0.3),
				randompick(-1,1)*frandom(0.1,0.4)
			);
		}else if((inertia>1)&&(battery>random(1,4))){
			drainprob*=3/2;
			dmg=random(1,5);
			A_SetTics(random(2,4));
			A_MuzzleClimb(
				randompick(-1,1)*frandom(0.05,0.6),
				randompick(-1,1)*frandom(0.05,0.2)
			);
		}else{
			drainprob*=4;
			A_StartSound("weapons/drillidle",CHAN_WEAPON);
			sawpuff="HDSawPufShitty";
			A_SetTics(random(3,6));
			A_MuzzleClimb(
				frandom(-0.2,0.2),
				frandom(-0.2,0.2)
			);
		}
		if(battery>0&&!random(0,drainprob))invoker.weaponstatus[DRILLS_BATTERY]--;

		actor victim=null;
		int finaldmg=0;
		vector3 puffpos=pos+gunpos();
		flinetracedata flt;
		if(dmg>0){
			A_AlertMonsters();

			//determine angle
			double shootangle=angle;
			double shootpitch=pitch;
			vector3 shootpos=(0,0,height*0.8);
			let hdp=hdplayerpawn(self);
			if(hdp){
				shootangle=hdp.gunangle;
				shootpitch=hdp.gunpitch;
				shootpos=gunpos((0,0,-4));
			}

			//create the line
			linetrace(
				shootangle,
				invoker.barrellength+4,
				shootpitch,
				flags:TRF_NOSKY|TRF_ABSOFFSET,
				offsetz:shootpos.z,
				offsetforward:shootpos.x,
				offsetside:shootpos.y,
				data:flt
			);

			if(flt.hittype!=Trace_HitNone){
				A_SprayDecal("BulletChip",invoker.barrellength+4,gunpos(),flt.hitdir);
				A_StartSound("weapons/drillfull",9);//sound of drill hitting wall
			}
			A_StartSound("weapons/drillfull",CHAN_WEAPON);

			if(flt.hitactor){
				victim=flt.hitactor;
				puffpos=flt.hitlocation+flt.hitdir*min(victim.radius,frandom(2,5));
				invoker.setxyz(flt.hitlocation);
				if(countinv("WornGrasshopperMask")){
				finaldmg=victim.damagemobj(invoker,self,dmg*2,"cutting");//double damage if wearing Carl's mask
				}else finaldmg=victim.damagemobj(invoker,self,dmg,"cutting");
			}else if(flt.hittype!=Trace_HitNone){
				puffpos=flt.hitlocation-flt.hitdir*4;
				if(dmg>6){
					bool didit;double didwhat;
					[didit,didwhat]=doordestroyer.destroydoor(
						self,dmg*10,dmg*0.01,48,height-10,//can still damage doors, just takes 3 times as long
						angle,pitch
					);
					if(didit||!didwhat)invoker.walldamagemeter=0;else
					invoker.walldamagemeter=int(clamp(1-didwhat,0,1)*100);
				}
			}
		}

		if(
			!!victim
			&&(
				finaldmg>0
				||HDMath.IsDead(victim)
			)
		){
			invoker.weaponstatus[0]|=DRILLF_CHOPPINGFLESH;
			if(victim.bnoblood)spawn("BulletPuffMedium",puffpos,ALLOW_REPLACE);
			else{
				int pdmg=7;
				array<HDDamageHandler> handlers;
				HDDamageHandler.GetHandlers(victim,handlers);
				for(int i=0;i<handlers.Size();i++){
					let hhh=handlers[i];
					if(hhh&&hhh.owner==victim)pdmg=hhh.HandleDamage(
						pdmg,
						"cutting",
						0,
						invoker,
						self
					);
				}

				if(pdmg<1){
					spawn("BulletPuffMedium",puffpos,ALLOW_REPLACE);
					return;
				}else{
					actor vb=spawn(victim.bloodtype,puffpos,ALLOW_REPLACE);
					vb.vel=victim.vel-flt.hitdir;
					vb.translation=victim.bloodtranslation;
				}

				double ddd=frandom(1,pdmg);
				double www=frandom(4,2.*pdmg);
				double maxdepth=max(20.,victim.radius*2.);//wounds aren't as deep nor wide
				let hdblw=hdbleedingwound.inflict(
					victim,ddd,www,source:target,damagetype:"cutting",hitlocation:flt.hitlocation
				);
				if(
					!!hdblw
					&&hdblw.depth>maxdepth
				){
					let extrawidth=hdblw.depth-maxdepth;
					hdblw.depth=maxdepth;
					hdblw.width+=extrawidth*frandom(0.6,1);
				}


				if(hdmobbase(victim)){
					hdmobbase(victim).bodydamage+=int(max(ddd,www));
					hdmobbase(victim).stunned+=(pdmg<<2);
				}
			}
		}else if(
			dmg>0
			&&flt.hittype!=Trace_HitNone
		){
			spawn("FragPuff",puffpos,ALLOW_REPLACE);
			if(
				invoker.weaponstatus[DRILLS_BATTERY]>0
				&&!random(0,POWERDRILLDRAIN*3)
			)invoker.weaponstatus[DRILLS_BATTERY]--;
			if(invoker.weaponstatus[0]&DRILLF_CHOPPINGFLESH){
				invoker.weaponstatus[0]&=~DRILLF_CHOPPINGFLESH;
				let tgt=HDPlayerPawn(self);
				if(tgt){
					tgt.muzzleclimb1.x+=random(-30,10);
					tgt.muzzleclimb1.y+=random(-10,6);
				}
				A_Recoil(random(-1,2));
				damagemobj(invoker,self,1,"cutting");
			}
		}
	}
	states{
	ready:
		DRIL A 1{
			invoker.weaponstatus[0]&=~DRILLF_CHOPPINGFLESH;
			invoker.walldamagemeter=0;
			if(invoker.weaponstatus[DRILLS_INERTIA]>0)setweaponstate("ready2");
			else A_WeaponReady(WRF_ALLOWRELOAD|WRF_ALLOWUSER3|WRF_ALLOWUSER4);
		}goto readyend;
	ready2:
		DRIL AB 3{
			if(invoker.weaponstatus[DRILLS_INERTIA]>0)invoker.weaponstatus[CSAWS_INERTIA]--;
			if((invoker.weaponstatus[DRILLS_INERTIA]>4)&&(invoker.weaponstatus[CSAWS_BATTERY]>4)){
				A_SetTics(2);
				A_StartSound("weapons/drillfull",CHAN_WEAPON);
			}else if((invoker.weaponstatus[DRILLS_INERTIA]>1)&&(invoker.weaponstatus[CSAWS_BATTERY]>2)){
				A_StartSound("weapons/drillidle",CHAN_WEAPON);
			}else{
				A_SetTics(random(2,4));
				A_StartSound("weapons/drillidle",CHAN_WEAPON);
			}
			A_WeaponReady(WRF_NOSECONDARY);
		}goto readyend;
	select0:
		DRIL A 0{invoker.weaponstatus[DRILLS_INERTIA]=0;}
		goto select0small;
	deselect0:
		DRIL A 0;
		goto deselect0small;
	hold:
		DRIL A 0 A_JumpIf(invoker.weaponstatus[DRILLS_BATTERY]>0,"drill");
		goto nope;
	fire:
		DRIL A 2 A_StartSound("weapons/drillstart",CHAN_WEAPON);
		DRIL A 4 A_JumpIf(invoker.weaponstatus[DRILLS_BATTERY]>0,"drill");
		goto nope;
	drill:
		DRIL AB 1 { A_HDDrill();//the drill attack
		            //using A_CustomPunch for the pull-in effect
		            A_CustomPunch(0, 
		                          norandom:true,
		                          CPF_PULLIN,
		                          range: invoker.barrellength+8, 
		                          meleesound: "");
		          }
		DRIL B 0 A_Refire();
		goto readyend;

	reload:
		DRIL A 0{
			if(
				invoker.weaponstatus[DRILLS_BATTERY]>=20
				||!countinv("HDBattery")
			){return resolvestate("nope");}
			invoker.weaponstatus[0]&=~DRILLF_JUSTUNLOAD;
			return resolvestate("unmag");
		}

	user4:
	unload:
		DRIL A 0{
			if(invoker.weaponstatus[DRILLS_BATTERY]<0){
				return resolvestate("nope");
			}invoker.weaponstatus[0]|=DRILLF_JUSTUNLOAD;return resolvestate(null);
		}
	unmag:
		DRIL A 1 offset(0,33);
		DRIL A 1 offset(0,35);
		DRIL A 1 offset(0,37);
		DRIL A 1 offset(0,39);
		DRIL A 2 offset(0,44);
		DRIL A 2 offset(0,52);
		DRIL A 3 offset(2,62);
		DRIL A 4 offset(4,74);
		DRIL A 7 offset(6,78)A_StartSound("weapons/csawopen",8);
		DRIL A 0{
			A_StartSound("weapons/csawload",8,CHANF_OVERLAP);
			if(
				!PressingUnload()&&!PressingReload()
			){
				setweaponstate("dropmag");
			}else setweaponstate("pocketmag");
		}
	dropmag:
		DRIL A 0{
			if(invoker.weaponstatus[DRILLS_BATTERY]>=0){
				HDMagAmmo.SpawnMag(self,"HDBattery",invoker.weaponstatus[DRILLS_BATTERY]);
			}
			invoker.weaponstatus[DRILLS_BATTERY]=-1;
		}goto magout;
	pocketmag:
		DRIL A 6 offset(7,80){
			if(invoker.weaponstatus[DRILLS_BATTERY]>=0){
				HDMagAmmo.GiveMag(self,"HDBattery",invoker.weaponstatus[DRILLS_BATTERY]);
				A_StartSound("weapons/pocket",9);
				A_MuzzleClimb(
					randompick(-1,1)*frandom(-0.3,-1.2),
					randompick(-1,1)*frandom(0.3,1.8)
				);
			}
			invoker.weaponstatus[DRILLS_BATTERY]=-1;
		}
		DRIL A 7 offset(6,81) A_StartSound("weapons/pocket",9);
		goto magout;

	magout:
		DRIL A 0 A_JumpIf(invoker.weaponstatus[0]&DRILLF_JUSTUNLOAD,"reloadend");
	loadmag:
		DRIL A 4 offset(7,79) A_MuzzleClimb(
			randompick(-1,1)*frandom(-0.3,-1.2),
			randompick(-1,1)*frandom(0.3,0.8)
		);
		DRIL A 2 offset(6,78) A_StartSound("weapons/pocket",9);
		DRIL AA 5 offset(5,76) A_MuzzleClimb(
			randompick(-1,1)*frandom(-0.3,-1.2),
			randompick(-1,1)*frandom(0.3,0.8)
		);
		DRIL A 0{
			let mmm=HDMagAmmo(findinventory("HDBattery"));
			if(mmm)invoker.weaponstatus[DRILLS_BATTERY]=mmm.TakeMag(true);
		}
	reloadend:
		DRIL A 6 offset(5,72);
		DRIL A 5 offset(4,74)A_StartSound("weapons/csawclose",8);
		DRIL A 4 offset(2,62);
		DRIL A 3 offset(0,52);
		DRIL A 4 offset(0,44);
		DRIL A 1 offset(0,37);
		DRIL A 1 offset(0,35);
		DRIL C 1 offset(0,33);
		goto ready;

	user3:
		DRIL A 0 A_MagManager("HDBattery");
		goto ready;

	spawn:
		DRLP A -1;
	}
	override void initializewepstats(bool idfa){
		weaponstatus[DRILLS_BATTERY]=20;
	}
}
enum lumberstatus{
	DRILLF_JUSTUNLOAD=1,
	DRILLF_CHOPPINGFLESH=2,

	DRILLS_FLAGS=0,
	DRILLS_BATTERY=1,
	DRILLS_INERTIA=2,
};
