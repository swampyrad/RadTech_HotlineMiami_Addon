//-------------------------------------------------
// "Nyyyyeeeeeeeeehhhhhh, what's up, doc?"
//-------------------------------------------------
class WornRabbitMask:HDDamageHandler{
	default{
		+nointeraction;+noblockmap;
		+hdpickup.facecoverage
		inventory.maxamount 1;inventory.amount 1;
		HDDamageHandler.priority 0;
		HDPickup.wornlayer STRIP_HMMASK;
		HDPickup.overlaypriority 150;
		tag "Graham Mask";
	}
	states{spawn:TNT1 A 0;stop;}
	override inventory createtossable(int amt){
		let rrr=owner.findinventory("RabbitMask");
		if(rrr)owner.useinventory(rrr);else destroy();
		return null;
	}
	
	override void attachtoowner(actor owner){
	  //null check, avoids crashes 
	  //if owner not initialized
	  if(!owner)return; 
	  
		if(!owner.countinv("RabbitMask")){
		    owner.A_GiveInventory("WornRabbitMask");
		    owner.A_GiveInventory("RabbitSpeed");}
	    A_SetBlend("01 00 00",0.8,16);
		super.attachtoowner(owner);
	}
	override void DetachFromOwner(){
		owner.A_TakeInventory("RabbitMask",1);
		owner.A_TakeInventory("RabbitSpeed",1);
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
		if(!countinv("RabbitSpeed")){
		  owner.A_GiveInventory("RabbitSpeed");
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
			"GRHMA0",
			am?(11,157):(-85,-28),
			am?sb.DI_TOPLEFT:
			(sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_ITEM_CENTER_BOTTOM)
		);
	}
}

class RabbitSpeed:PowerSpeed{
  default{
    +powerspeed.notrail
    -inventory.noteleportfreeze
    
    inventory.maxamount 1;
    speed 1.25;
    powerup.duration -999999;
    inventory.icon "";
  }
}

class RabbitMask:HDPickup{
	default{
		//$Category "Gear/Hideous Destructor/Supplies"
		//$Title "Graham Mask"
		//$Sprite "GRHMA0"

    -hdpickup.droptranslation
    +HDPickup.NoRandomBackpackSpawn
		inventory.pickupmessage "You got a rabbit mask. ";
		inventory.pickupsound "weapons/pocket";
		inventory.icon "GRHMA0";

		hdpickup.bulk 10;
		tag "Graham Mask";
		hdpickup.refid "grm";
	}
	override void DetachFromOwner(){
		owner.A_TakeInventory("RabbitMask");
		owner.A_TakeInventory("WornRabbitMask");
		owner.A_TakeInventory("RabbitSpeed");
		target=owner;
		super.DetachFromOwner();
	}
	override inventory CreateTossable(int amt){
		if(
			amount<2
			&&owner.findinventory("WornRabbitMask")
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
			&&!other.findinventory("WornPantherMask")
			&&!other.findinventory("WornGrasshopperMask")
			&&!other.findinventory("wornradsuit")
		){
			wornlayer=STRIP_HMMASK;
			bool intervening=!HDPlayerPawn.CheckStrip(other,self,false);
			wornlayer=0;

			if(intervening)return false;

			let onr=HDPlayerPawn(other);
            
			other.A_GiveInventory("RabbitMask");
			other.A_GiveInventory("WornRabbitMask");
			other.A_GiveInventory("RabbitSpeed");
			destroy();
			return true;
		}
		return false;
	}
	override void DoEffect(){
		bfitsinbackpack=(amount!=1||!owner||!owner.findinventory("WornRabbitMask"));
		
		super.doeffect();
	}
	
	states{
	spawn:
		GRHM A 1;
		GRHM A -1{
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
			if(blockface&&!countinv("WornRabbitMask")){
				Console.MidPrint(smallfont,"Take your current mask off first!");
				A_Jump(256,"nope");
				return;
			}
			
			let owgm=WornRabbitMask(findinventory("WornRabbitMask"));
			if(owgm){
				if(!HDPlayerPawn.CheckStrip(self,owgm))return;
			}else{
				invoker.wornlayer=STRIP_HMMASK+1;
				if(!HDPlayerPawn.CheckStrip(self,invoker)){
					invoker.wornlayer=0;
					return;
				}
				invoker.wornlayer=0;
			}

			//let onr=HDPlayerPawn(self);
			if(!countinv("WornRabbitMask")){
			    A_SetBlend("01 00 00",0.8,16);//flashes black for a moment
				A_GiveInventory("WornRabbitMask");
				A_GiveInventory("RabbitSpeed");
			}else{
				actor a;int b;
				inventory wrs=findinventory("WornRabbitMask");
				[b,a]=A_SpawnItemEx("RabbitMask",0,0,height*0.5,5,0,-8);
				A_TakeInventory("WornRabbitMask");
				A_TakeInventory("RabbitSpeed");
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
