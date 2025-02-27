//-------------------------------------------------------
// "Man, this party stinks, I fucking hate these people."
//-------------------------------------------------------
class WornTigerMask:HDDamageHandler{
	default{
		+nointeraction;+noblockmap;
		+hdpickup.facecoverage
		inventory.maxamount 1;inventory.amount 1;
		HDDamageHandler.priority 0;
		HDPickup.wornlayer STRIP_HMMASK;
		HDPickup.overlaypriority 150;
		tag "Tony Mask";
	}
	states{spawn:TNT1 A 0;stop;}
	override inventory createtossable(int amt){
		let rrr=owner.findinventory("TigerMask");
		if(rrr)owner.useinventory(rrr);else destroy();
		return null;
	}
	
	string currweap;
	override void attachtoowner(actor owner){
	  //null check, avoids crashes 
	  //if owner not initialized
	  if(!owner)return; 
	  
	  if(owner)currweap = owner.Player.ReadyWeapon.GetClassName();
		if(!owner.countinv("TigerMask")){
		    owner.A_GiveInventory("WornTigerMask");
    }
    if(currweap=="HDFist")owner.A_GiveInventory("TonyFists");
		A_SetBlend("01 00 00",0.8,16);
		super.attachtoowner(owner);
	}
	override void DetachFromOwner(){
		owner.A_TakeInventory("TigerMask",1);
		owner.A_TakeInventory("TonyFists",1);
		owner.A_SetBlend("01 00 00",0.8,16);
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
		super.doeffect();
		
		let hdp=hdplayerpawn(owner);
    
    if (Owner.Player.ReadyWeapon 
        && Owner.Player.ReadyWeapon.GetClassName() != currweap)
		{
			currweap = Owner.Player.ReadyWeapon.GetClassName();
    }
    
		if(!countinv("TonyFists")
	     &&currweap=="HDFist"
	    ){owner.A_GiveInventory("TonyFists");
		}else if(currweap!="HDFist"
		  ){owner.A_TakeInventory("TonyFists",1);
		}
	}
	
	override void DrawHudStuff(
		hdstatusbar sb,
		hdplayerpawn hpl,
		int hdflags,
		int gzflags
	){
		bool am=hdflags&HDSB_AUTOMAP;
		sb.drawimage(
			"TONYA0",
			am?(11,157):(-85,-28),
			am?sb.DI_TOPLEFT:
			(sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_ITEM_CENTER_BOTTOM)
		);
	}
    
}

class TonyFists:PowerDamage{
  default{
    inventory.maxamount 1;
    damagefactor "melee", 5;
    damagefactor "bashing", 10;
    powerup.duration -999999;
    inventory.icon "";
  }
}

class TigerMask:HDPickup{
	default{
		//$Category "Gear/Hideous Destructor/Supplies"
		//$Title "Tony Mask"
		//$Sprite "TONYA0"

        -hdpickup.droptranslation
        +HDPickup.NoRandomBackpackSpawn
		inventory.pickupmessage "You got a tiger mask...great. ";
		inventory.pickupsound "weapons/pocket";
		inventory.icon "TONYA0";

		hdpickup.bulk 10;
		tag "Tony Mask";
		hdpickup.refid "tgr";
	}
	override void DetachFromOwner(){
		owner.A_TakeInventory("TigerMask");
		owner.A_TakeInventory("WornTigerMask");
		target=owner;
		super.DetachFromOwner();
	}
	override inventory CreateTossable(int amt){
		if(
			amount<2
			&&owner.findinventory("WornTigerMask")
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
			&&!other.findinventory("WornGrasshopperMask")
			&&!other.findinventory("WornRabbitMask")
			&&!other.findinventory("WornSuzieMask")
			&&!other.findinventory("wornradsuit")
		){
			wornlayer=STRIP_HMMASK;
			bool intervening=!HDPlayerPawn.CheckStrip(other,self,false);
			wornlayer=0;

			if(intervening)return false;

			let onr=HDPlayerPawn(other);
			
			other.A_GiveInventory("TigerMask");
			other.A_GiveInventory("WornTigerMask");
			destroy();
			return true;
		}
		return false;
	}
	override void DoEffect(){
		bfitsinbackpack=(amount!=1||!owner||!owner.findinventory("WornTigerMask"));
		super.doeffect();
	}
	
	states{
	spawn:
		TONY A 1;
		TONY A -1{
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
			if(blockface&&!countinv("WornTigerMask")){
				Console.MidPrint(smallfont,"Take your current mask off first!");
				A_Jump(256,"nope");
				return;
			}
			
			let owtm=WornTigerMask(findinventory("WornTigerMask"));
			if(owtm){
				if(!HDPlayerPawn.CheckStrip(self,owtm))return;
			}else{
				invoker.wornlayer=STRIP_HMMASK+1;
				if(!HDPlayerPawn.CheckStrip(self,invoker)){
					invoker.wornlayer=0;
					return;
				}
				invoker.wornlayer=0;
			}

			//let onr=HDPlayerPawn(self);
			if(!countinv("WornTigerMask")){
			    A_SetBlend("01 00 00",0.8,16);//flashes black for a moment
				A_GiveInventory("WornTigerMask");
				A_GiveInventory("TonyFists");
			}else{
				actor a;int b;
				inventory wrs=findinventory("WornTigerMask");
				[b,a]=A_SpawnItemEx("TigerMask",0,0,height*0.5,5,0,-8);
				A_TakeInventory("WornTigerMask");
				A_TakeInventory("TonyFists");
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
