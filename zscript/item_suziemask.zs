//-------------------------------------------------
// "Do you feel lucky? Well, do ya, punk?"
//-------------------------------------------------
class WornSuzieMask:HDDamageHandler{
	default{
		+nointeraction;+noblockmap;
		+hdpickup.facecoverage  //can't drink potions when worn
		inventory.maxamount 1;inventory.amount 1;
		HDDamageHandler.priority 0;
		HDPickup.wornlayer STRIP_HMMASK;
		HDPickup.overlaypriority 150;
		tag "Suzie Mask";
	}
	
	states{spawn:TNT1 A 0;stop;}
	
	override inventory createtossable(int amt){
		let rrr=owner.findinventory("SuzieMask");
		if(rrr)owner.useinventory(rrr);
		else destroy();
		return null;
	}
	
	//tracks player's currently held weapon
	class<object> currweap;
	
	//do this when putting on mask
	override void attachtoowner(actor owner){
	  //null check, avoids crashes 
	  //if owner not initialized
	  if(!owner)return; 
    
    //set currweap to owner's held weapon
	  if(owner)
	    currweap = owner.Player.ReadyWeapon.GetParentClass();
	  
	  //remove if mask not found in inventory
		if(!owner.countinv("SuzieMask")){
		    owner.A_GiveInventory("WornSuzieMask");
    }
    
    //activate damage buff if holding a
    //weapon that inherits from "HDHandgun"
    //when mask is equipped
    if(currweap is "HDHandgun")
      owner.A_GiveInventory("SuzieDamage");
    
    //apply screen fade effect
		A_SetBlend("01 00 00",0.8,16);
		
		super.attachtoowner(owner);
	}
	
	//do this when taking mask off
	override void DetachFromOwner(){
	  //remove mask from inventory
		owner.A_TakeInventory("SuzieMask",1);
	  //remove damage buff powerup
		owner.A_TakeInventory("SuzieDamage",1);
	  //apply screen fade effect
		owner.A_SetBlend("01 00 00",0.8,16);
		super.DetachFromOwner();
	}
	
	//this draws the mask overlay
	override void DisplayOverlay(hdstatusbar sb,hdplayerpawn hpl){
		if(
			sb.blurred
		)return;//if you're invisible, your mask 
		        //is invisible too, right?
		
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
    
    //check if "currweap" matches held weapon
    //if not, set "currweap" to held weapon's class
    if (Owner.Player.ReadyWeapon 
        && Owner.Player.ReadyWeapon.GetParentClass() != currweap)
		{
			currweap = Owner.Player.ReadyWeapon.GetParentClass();
    }
    
    //if held weapon's class inherits from "HDHandgun"
    //give damage buff powerup
    //else remove powerup
		if(!countinv("SuzieDamage")
	     &&(currweap is "HDHandgun")
	    ){owner.A_GiveInventory("SuzieDamage");
		}else if (!(currweap is "HDHandgun")
		  ){owner.A_TakeInventory("SuzieDamage",1);
		}
	}
	
	//draws mask sprite above HUD
	//armor durability indicator
	override void DrawHudStuff(
		hdstatusbar sb,
		hdplayerpawn hpl,
		int hdflags,
		int gzflags
	){
		bool am=hdflags&HDSB_AUTOMAP;
		
		//draws mask above worn armor HUD indicator
		sb.drawimage(
			"SUZIA0",
			am?(11,157):(-85,-28),
			am?sb.DI_TOPLEFT:
			(sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_ITEM_CENTER_BOTTOM)
		);
	}
}

//ability powerup given when mask is worn,
//wearer does extra damage with handguns
class SuzieDamage:PowerDamage{
  default{
    inventory.maxamount 1;
    damagefactor "piercing", 3;
    powerup.duration -999999;
    inventory.icon "";
  }
}

//the actual mask item
class SuzieMask:HDPickup{
	default{
		//$Category "Gear/Hideous Destructor/Supplies"
		//$Title "Graham Mask"
		//$Sprite "SUZIA0"

    -hdpickup.droptranslation
    +HDPickup.NoRandomBackpackSpawn
		inventory.pickupmessage "You got a rabbit mask. This one looks different...";
		inventory.pickupsound "weapons/pocket";
		inventory.icon "SUZIA0";

		hdpickup.bulk 10;
		tag "Suzie Mask";
		hdpickup.refid "suz";
	}
	
	override void DetachFromOwner(){
		owner.A_TakeInventory("SuzieMask");
		owner.A_TakeInventory("WornSuzieMask");
		owner.A_TakeInventory("SuzieDamage");
		target=owner;
		super.DetachFromOwner();
	}
	
	override inventory CreateTossable(int amt){
		if(
			amount<2
			&&owner.findinventory("WornSuzieMask")
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
			&&!other.findinventory("WornRabbitMask")
			&&!other.findinventory("WornSuzieMask")
			&&!other.findinventory("WornPantherMask")
			&&!other.findinventory("WornGrasshopperMask")
			&&!other.findinventory("wornradsuit")
		){
			wornlayer=STRIP_HMMASK;
			bool intervening=!HDPlayerPawn.CheckStrip(other,self,false);
			wornlayer=0;

			if(intervening)return false;

			let onr=HDPlayerPawn(other);
            
			other.A_GiveInventory("SuzieMask");
			other.A_GiveInventory("WornSuzieMask");
			other.A_GiveInventory("SuzieDamage");
			destroy();
			return true;
		}
		return false;
	}
	
	override void DoEffect(){
		bfitsinbackpack=(amount!=1||!owner||!owner.findinventory("WornSuzieMask"));
		
		super.doeffect();
	}
	
	states{
	spawn:
		SUZI A 1;
		SUZI A -1{
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
			if(blockface&&!countinv("WornSuzieMask")){
				Console.MidPrint(smallfont,"Take your current mask off first!");
				A_Jump(256,"nope");
				return;
			}
			
			let owsm=WornSuzieMask(findinventory("WornSuzieMask"));
			if(owsm){
				if(!HDPlayerPawn.CheckStrip(self,owsm))return;
			}else{
				invoker.wornlayer=STRIP_HMMASK+1;
				if(!HDPlayerPawn.CheckStrip(self,invoker)){
					invoker.wornlayer=0;
					return;
				}
				invoker.wornlayer=0;
			}

			if(!countinv("WornSuzieMask")){
			    A_SetBlend("01 00 00",0.8,16);//flashes black for a moment
				A_GiveInventory("WornSuzieMask");
				A_GiveInventory("SuzieDamage");
			}else{
				actor a;int b;
				inventory wrs=findinventory("WornSuzieMask");
				[b,a]=A_SpawnItemEx("SuzieMask",0,0,height*0.5,5,0,-8);
				A_TakeInventory("WornSuzieMask");
				A_TakeInventory("SuzieDamage");
			}
		}fail;
	}
}
