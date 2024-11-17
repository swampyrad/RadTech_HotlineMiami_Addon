//-------------------------------------------------
// "I can't see shit in this thing."
//-------------------------------------------------

class WornMoleMask:HDDamageHandler{
	default{
		+nointeraction;+noblockmap;
		+hdpickup.facecoverage
		inventory.maxamount 1;inventory.amount 1;
		HDDamageHandler.priority 0;
		HDPickup.wornlayer STRIP_HMMASK;
		HDPickup.overlaypriority 150;
		tag "Oscar Mask";
	}
	states{spawn:TNT1 A 0;stop;}
	override inventory createtossable(int amt){
		let rrr=owner.findinventory("MoleMask");
		if(rrr)owner.useinventory(rrr);else destroy();
		return null;
	}
	override void attachtoowner(actor owner){
		if(!owner.countinv("MoleMask")){
		    owner.A_GiveInventory("WornMoleMask");
		    owner.A_GiveInventory("MoleDarkness");
		}
		A_SetBlend("01 00 00",0.8,16);
		super.attachtoowner(owner);
	}
	override void DetachFromOwner(){
		owner.A_TakeInventory("MoleMask",1);
		owner.A_TakeInventory("MoleDarkness",1);
		owner.A_SetBlend("01 00 00",0.8,16);
		super.DetachFromOwner();
	}
	
	override void DoEffect(){
    if(!countinv("MoleDarkness"))
      owner.A_GiveInventory("MoleDarkness");
		super.doeffect();
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
	
	override void DrawHudStuff(
		hdstatusbar sb,
		hdplayerpawn hpl,
		int hdflags,
		int gzflags
	){
		bool am=hdflags&HDSB_AUTOMAP;
		sb.drawimage(
			"OSCRA0",
			am?(11,157):(-85,-28),
			am?sb.DI_TOPLEFT:
			(sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_ITEM_CENTER_BOTTOM)
		);
	}
    
}

//applies red-tinted grayscale filter
class MoleDarkness:Powerup{
  default{
    inventory.maxamount 1;

    powerup.colormap 1.0, 0.0, 0.0;
    powerup.duration -999999;
  }
}

class MoleMask:HDPickup{
	default{
		//$Category "Gear/Hideous Destructor/Supplies"
		//$Title "Oscar Mask"
		//$Sprite "OSCRA0"
        
        -hdpickup.droptranslation
        +HDPickup.NoRandomBackpackSpawn
		inventory.pickupmessage "You got a mole mask.";
		inventory.pickupsound "weapons/pocket";
		inventory.icon "OSCRA0";

		hdpickup.bulk 10;
		tag "Oscar Mask";
		hdpickup.refid "osc";
	}
	override void DetachFromOwner(){
		owner.A_TakeInventory("MoleMask");
		owner.A_TakeInventory("WornMoleMask");
		target=owner;
		super.DetachFromOwner();
	}
	override inventory CreateTossable(int amt){
		if(
			amount<2
			&&owner.findinventory("WornMoleMask")
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
			&&!other.findinventory("WornMoleMask")
			&&!other.findinventory("WornTigerMask")
			&&!other.findinventory("WornPantherMask")
			&&!other.findinventory("WornGrasshopperMask")
			&&!other.findinventory("WornRabbitMask")
			&&!other.findinventory("wornradsuit")
		){
			wornlayer=STRIP_HMMASK;
			bool intervening=!HDPlayerPawn.CheckStrip(other,self,false);
			wornlayer=0;

			if(intervening)return false;

			let onr=HDPlayerPawn(other);
			
			other.A_GiveInventory("MoleMask");
			other.A_GiveInventory("WornMoleMask");
			other.A_GiveInventory("MoleDarkness");
			
			destroy();
			return true;
		}
		return false;
	}
	override void DoEffect(){
		bfitsinbackpack=(amount!=1||!owner||!owner.findinventory("WornMoleMask"));
		super.doeffect();
	}
	states{
	spawn:
		OSCR A 1;
		OSCR A -1{
			if(!target)return;
		}
	use:
		TNT1 A 0{
		    let blockinv=HDWoundFixer.CheckCovered(self,CHECKCOV_ONLYFULL);
			if(blockinv){
				Console.MidPrint(smallfont,"Something is in the way.");
				A_Jump(256,"nope");
				return;
			}
			let blockface=HDWoundFixer.CheckCovered(self,CHECKCOV_CHECKFACE);
			if(blockface&&!countinv("WornMoleMask")){
				Console.MidPrint(smallfont,"Take your current mask off first!");
				A_Jump(256,"nope");
				return;
			}
			
			let owmm=WornMoleMask(findinventory("WornRoosterMask"));
			if(owmm){
				if(!HDPlayerPawn.CheckStrip(self,owmm))return;
			}else{
				invoker.wornlayer=STRIP_HMMASK+1;
				if(!HDPlayerPawn.CheckStrip(self,invoker)){
					invoker.wornlayer=0;
					return;
				}
				invoker.wornlayer=0;
			}
			
			//let onr=HDPlayerPawn(self);
			if(!countinv("WornMoleMask")){
				A_SetBlend("01 00 00",0.8,16);//flashes black for a moment
				A_GiveInventory("WornMoleMask");
				A_GiveInventory("MoleDarkness");
			}else{
				actor a;int b;
				inventory wrs=findinventory("WornMoleMask");
				[b,a]=A_SpawnItemEx("MoleMask",0,0,height*0.5,5,0,-8);
				A_TakeInventory("WornMoleMask");
				A_TakeInventory("MoleDarkness");
			}
		}fail;
	}
}
