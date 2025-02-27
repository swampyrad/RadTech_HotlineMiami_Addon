//-------------------------------------------------
// "This is my rifle..."
//-------------------------------------------------
class WornGrasshopperMask:HDDamageHandler{
	default{
		+nointeraction;+noblockmap;
		+hdpickup.facecoverage
		
		inventory.maxamount 1;inventory.amount 1;
		HDDamageHandler.priority 0;
		HDPickup.wornlayer STRIP_HMMASK;
		HDPickup.overlaypriority 150;
		tag "Carl Mask";
	}
	states{spawn:TNT1 A 0;stop;}
	override inventory createtossable(int amt){
		let rrr=owner.findinventory("GrasshopperMask");
		if(rrr)owner.useinventory(rrr);else destroy();
		return null;
	}
	override void attachtoowner(actor owner){
	  //null check, avoids crashes 
	  //if owner not initialized
	  if(!owner)return; 
	  
		if(!owner.countinv("GrasshopperMask")){
		    owner.A_GiveInventory("WornGrasshopperMask");}
		A_SetBlend("01 00 00",0.8,16);
		super.attachtoowner(owner);
	}
	override void DetachFromOwner(){
		owner.A_TakeInventory("GrasshopperMask",1);
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
		let hdp=hdplayerpawn(owner);
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
			"CARLA0",
			am?(11,157):(-85,-28),
			am?sb.DI_TOPLEFT:
			(sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_ITEM_CENTER_BOTTOM)
		);
	}
    
}

class GrasshopperMask:HDPickup{
	default{
		//$Category "Gear/Hideous Destructor/Supplies"
		//$Title "Carl Mask"
		//$Sprite "CARLA0"
        
        -hdpickup.droptranslation
        +HDPickup.NoRandomBackpackSpawn
		inventory.pickupmessage "You got a grasshopper mask. (drill sold seperately)";
		inventory.pickupsound "weapons/pocket";
		inventory.icon "CARLA0";

		hdpickup.bulk 10;
		tag "Carl Mask";
		hdpickup.refid "crl";
	}
	override void DetachFromOwner(){
		owner.A_TakeInventory("GrasshopperMask");
		owner.A_TakeInventory("WornGrasshopperMask");
		target=owner;
		super.DetachFromOwner();
	}
	override inventory CreateTossable(int amt){
		if(
			amount<2
			&&owner.findinventory("WornGrasshopperMask")
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
            
			other.A_GiveInventory("GrasshopperMask");
			other.A_GiveInventory("WornGrasshopperMask");
			destroy();
			return true;
		}
		return false;
	}
	override void DoEffect(){
		bfitsinbackpack=(amount!=1||!owner||!owner.findinventory("WornGrasshopperMask"));
		super.doeffect();
	}
	
	states{
	spawn:
		CARL A 1;
		CARL A -1{
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
			if(blockface&&!countinv("WornGrasshopperMask")){
				Console.MidPrint(smallfont,"Take your current mask off first!");
				A_Jump(256,"nope");
				return;
			}
			
			let owcm=WornGrasshopperMask(findinventory("WornGrasshopperMask"));
			if(owcm){
				if(!HDPlayerPawn.CheckStrip(self,owcm))return;
			}else{
				invoker.wornlayer=STRIP_HMMASK+1;
				if(!HDPlayerPawn.CheckStrip(self,invoker)){
					invoker.wornlayer=0;
					return;
				}
				invoker.wornlayer=0;
			}

			//let onr=HDPlayerPawn(self);
			if(!countinv("WornGrasshopperMask")){
			    A_SetBlend("01 00 00",0.8,16);//flashes black for a moment
				A_GiveInventory("WornGrasshopperMask");
			}else{
				actor a;int b;
				inventory wrs=findinventory("WornGrasshopperMask");
				[b,a]=A_SpawnItemEx("GrasshopperMask",0,0,height*0.5,5,0,-8);
				A_TakeInventory("WornGrasshopperMask");
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
