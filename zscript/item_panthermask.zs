//-------------------------------------------------
// ""
//-------------------------------------------------
class WornPantherMask:HDDamageHandler{
	default{
		+nointeraction;+noblockmap;
		+hdpickup.facecoverage
		inventory.maxamount 1;inventory.amount 1;
		HDDamageHandler.priority 0;
		HDPickup.wornlayer STRIP_HMMASK;
		HDPickup.overlaypriority 150;
		tag "Brandon Mask";
	}
	states{spawn:TNT1 A 0;stop;}
	override inventory createtossable(int amt){
		let rrr=owner.findinventory("PantherMask");
		if(rrr)owner.useinventory(rrr);else destroy();
		return null;
	}
	
	override void attachtoowner(actor owner){
		if(!owner.countinv("PantherMask")){
		    owner.A_GiveInventory("WornPantherMask");
		    owner.A_GiveInventory("PantherSpeed");}
	    A_SetBlend("01 00 00",0.8,16);
		super.attachtoowner(owner);
	}
	override void DetachFromOwner(){
		owner.A_TakeInventory("PantherMask",1);
		owner.A_TakeInventory("PantherSpeed",1);
		owner.A_SetBlend("01 00 00",0.8,16);
		//SetPlayerProperty(0,0,PROP_SPEED);
		super.DetachFromOwner();
	}
	
	//this draws the mask overlay
	override void DisplayOverlay(hdstatusbar sb,hdplayerpawn hpl){
		if(
			sb.blurred
		)return;//if you're invisible, your mask is invisible too, right?
		
		sb.SetSize(0,320,200);
		sb.BeginHUD(forcescaled:true);
		int gogheight=int(screen.getheight()*(1.6*90.)/sb.cplayer.fov);
		int gogwidth=screen.getwidth()*gogheight/screen.getheight();
		int gogoffsx=-((gogwidth-screen.getwidth())>>1);
		int gogoffsy=-((gogheight-screen.getheight())>>1);
		screen.drawtexture(
			texman.checkfortexture("hm_mask",texman.type_any),//overlay texture goes here
			true,
			gogoffsx-(int(hpl.wepbob.x)),
			gogoffsy-(int(hpl.wepbob.y)),
			DTA_DestWidth,gogwidth,DTA_DestHeight,gogheight,
			true
		);
	}
	override void DoEffect(){
		if(!countinv("PantherSpeed")){
		  owner.A_GiveInventory("PantherSpeed");
		}
		super.doeffect(); 
	}
	override void DrawHudStuff(
		hdstatusbar sb,
		hdplayerpawn hpl,
		int hdflags,
		int gzflags
	){
		bool am=hdflags&HDSB_AUTOMAP;
		sb.drawimage(
			"BRNDA0",
			am?(11,157):(-85,-28),
			am?sb.DI_TOPLEFT:
			(sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_ITEM_CENTER_BOTTOM)
		);
	}
}

class PantherSpeed:PowerDamage{
  default{
    inventory.maxamount 1;
    damagefactor "melee", 2;
    powerup.duration -999999;
    inventory.icon "";
  }
}

class PantherMask:HDPickup{
	default{
		//$Category "Gear/Hideous Destructor/Supplies"
		//$Title "Brandon Mask"
		//$Sprite "BRNDA0"

    -hdpickup.droptranslation
    +HDPickup.NoRandomBackpackSpawn
		inventory.pickupmessage "You got a panther mask.";
		inventory.pickupsound "weapons/pocket";
		inventory.icon "BRNDA0";

		hdpickup.bulk 10;
		tag "Brandon Mask";
		hdpickup.refid "brn";
	}
	override void DetachFromOwner(){
		owner.A_TakeInventory("PantherMask");
		owner.A_TakeInventory("WornPantherMask");
		owner.A_TakeInventory("PantherSpeed");
		target=owner;
		super.DetachFromOwner();
	}
	override inventory CreateTossable(int amt){
		if(
			amount<2
			&&owner.findinventory("WornPantherMask")
		){
			owner.UseInventory(self);
			return null;
		}
		return super.CreateTossable(amt);
	}
	override bool BeforePockets(actor other){
		//put on the armour right away
		if(
			other.player
			&&other.player.cmd.buttons&BT_USE
			&&!other.findinventory("WornRoosterMask")
			&&!other.findinventory("WornTigerMask")
			&&!other.findinventory("WornMoleMask")
			&&!other.findinventory("WornPantherMask")
			&&!other.findinventory("WornRabbitMask")
			&&!other.findinventory("WornSuzieMask")
			&&!other.findinventory("WornGrasshopperMask")
			&&!other.findinventory("wornradsuit")
		){
			wornlayer=STRIP_HMMASK;
			bool intervening=!HDPlayerPawn.CheckStrip(other,self,false);
			wornlayer=0;

			if(intervening)return false;

			let onr=HDPlayerPawn(other);
            
			other.A_GiveInventory("PantherMask");
			other.A_GiveInventory("WornPantherMask");
			other.A_GiveInventory("PantherSpeed");
			destroy();
			return true;
		}
		return false;
	}
	override void DoEffect(){
		bfitsinbackpack=(amount!=1||!owner||!owner.findinventory("WornPantherMask"));
		
		super.doeffect();
	}
	
	states{
	spawn:
		BRND A 1;
		BRND A -1{
			if(!target)return;
		}
	use:
		TNT1 A 0{
			let blockinv=HDWoundFixer.CheckCovered(self,CHECKCOV_ONLYFULL);
			if(blockinv){
				//A_TakeOffFirst(blockinv.gettag());
				Console.MidPrint(smallfont,"Something is in the way.");
				A_Jump(256,"nope");
				return;
			}
			let blockface=HDWoundFixer.CheckCovered(self,CHECKCOV_CHECKFACE);
			if(blockface&&!countinv("WornPantherMask")){
				Console.MidPrint(smallfont,"Take your current mask off first!");
				A_Jump(256,"nope");
				return;
			}
			
			let owpm=WornPantherMask(findinventory("WornPantherMask"));
			if(owpm){
				if(!HDPlayerPawn.CheckStrip(self,owpm))return;
			}else{
				invoker.wornlayer=STRIP_HMMASK+1;
				if(!HDPlayerPawn.CheckStrip(self,invoker)){
					invoker.wornlayer=0;
					return;
				}
				invoker.wornlayer=0;
			}

			//let onr=HDPlayerPawn(self);
			if(!countinv("WornPantherMask")){
			  A_SetBlend("01 00 00",0.8,16);//flashes black for a moment
				A_GiveInventory("WornPantherMask");
				A_GiveInventory("PantherSpeed");
			}else{
				actor a;int b;
				inventory wrs=findinventory("WornPantherMask");
				[b,a]=A_SpawnItemEx("PantherMask",0,0,height*0.5,5,0,-8);
				A_TakeInventory("WornPantherMask");
				A_TakeInventory("PantherSpeed");
			}
			/*
			if (player)
			{
				player.crouchfactor=min(player.crouchfactor,0.7);
			}
			*/
		}fail;
	}
}
