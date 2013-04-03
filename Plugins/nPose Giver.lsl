//
// on receipt of a message formatted like an nPose LINKMSG, it gives an object to somebody
// the value of LnkMsgNo is completely arbitrary and is not part of the nPose system
// (just make sure you use the same value in the (probably BTN) menu cards
//
// Script by Logan Taov 2012-04-10, use it as you please.
// the format of the notecard LINKMSG line MUST be as follows:
//
//  LINKMSG|1234|Object-to-give|%AVKEY%
//
//  and if you need to give more than one object, just use multiple LINKMSG lines
//
// note that Object-to-give MUST be in the inventory of the nPose object prim containing the script!
//Modified by Howard Baxton.  This script will now accept a list of items via link message and give a list of items in a folder.
//The folder name is also proviced by link message.


integer LnkMsgNo = 1334;         // Link Object Giver Messages have this number
integer gListener;     // Identity of the listener associated with the dialog, so we can clean up when not needed
list avKeyAndName = []; //a list to hold seated AV name part and their key.  stride 2 list
list giveItems;    //will be set to the item name which will be given.  set when link message is received.
string giveFolderName;
key cardid;
key dataid;
key receiverKey;
key menuToucher;
integer line;


//this function will return a list of keys for all seated AVs
list SeatedAvs(){
    list avs = [];
    integer linkcount = llGetNumberOfPrims();
    integer n;
    for (n = linkcount; n >= 0; n--){
        key thisID = llGetLinkKey(n);
        if (llGetAgentSize(thisID) != ZERO_VECTOR){
            avs = [thisID] + avs;
        }
    }
    return avs;
}

ReadCard(string card){
    //kick off the dataserver with line 0 of the notecard
    line = 0;
    cardid = llGetInventoryKey(card);
    dataid = llGetNotecardLine(card, line);
}


ProcessLine(string line){
    //trim leading and trailing spaces from the line
    line = llStringTrim(line, STRING_TRIM);
    //add the line to the giveItems list
    giveItems += [line];
}

giveSetup(){
    //clear this list and rebuild it from current seated AVs
    avKeyAndName = [];
    list avNames = [];
    list avs = SeatedAvs();
    integer n;
    integer stop = llGetListLength(avs);
    //if there are no seated AV's we want to give to the menu toucher instead
    if (stop > 0){
        for (n=0; n<stop; ++n){
            //we limit the length of the Av names to 12 characters for dialog buttons
            string thisAVname = llGetSubString(llKey2Name(llList2Key(avs, n)), 0, 11);
            //add name and key to master list
            avKeyAndName += avKeyAndName + [thisAVname, llList2Key(avs, n)];
            //add name to button list
            avNames += [thisAVname];
        }
        //start the timer which will turn off the listener if menu is not clicked
        llSetTimerEvent(60.0);
        //start the listen
        gListener = llListen(-999999, "", menuToucher, "");
        //this thing sometimes menus up faster than the nPose menu putting names menu behind the nPos menu.
        //sleep for a second to give nPose time to menu up and then do this one.
        llSleep(1.0);
        //give the nPose menu clicker a menu with names of seated AVs
        llDialog(menuToucher, "\nWho would you like to send this "+giveFolderName+" to?", avNames , -999999);
    }else{
        //give to the menu toucher since there are no seated AV's
        giveStuff(menuToucher);
    }
}

giveStuff(key giveTo){
    llGiveInventoryList(giveTo, giveFolderName, giveItems);
    llRegionSayTo(giveTo, 0, llKey2Name(menuToucher)+" gave you a folder named '"+giveFolderName+"'.");
}

default
{
    state_entry()
    {
        
    }

   link_message(integer sender_num, integer num, string msg, key id){
        if (num == LnkMsgNo){
            menuToucher = id;     //(key)llList2String(params, 1);
            receiverKey = id;
            list params = llParseStringKeepNulls(msg, [","], []);
            //get the name of the folder to be given
            giveFolderName = llList2String(params, 0);
            //get the list of items to give
            giveItems = [];
            integer n;
            integer stop = llGetInventoryNumber(INVENTORY_NOTECARD);
            //look to see if we have a notecard with contents and read it if we do
            for (n = 0; n < stop; n++){
                string name = llGetInventoryName(INVENTORY_NOTECARD, n);
                if (name == giveFolderName){
                    ReadCard(name); 
                    return;
                } 
            }
            //check if we have read a notecard and if not assign the items in BTN notecard to giveItems list
            if (llGetListLength(giveItems) == 0){
                giveItems = llParseString2List(llList2String(params, 1),["~"], []);
            }
            giveSetup();
        }
    }
    
    listen(integer chan, string name, key ID, string msg){
        //check that is is most likely the dialog response this script is listening for.
        if (chan == -999999){
            //find the index for the name returned when the name of receiver AV is clicked in dialog
            integer index = llListFindList(avKeyAndName, [msg]);
            //get the key of receiver Av from the list
            receiverKey = llList2Key(avKeyAndName, index+1);
            //give the item to the AV who's name was clicked in menu
            giveStuff(receiverKey);
            //stop the timer as it is no longer needed
            llSetTimerEvent(0.0);
        }
    }

    dataserver(key id, string data){
        if (id == dataid){
            if (data == EOF){
                //we have read all the lines in the notecard so give the stuff to the intended receiver
                giveSetup();
//                giveStuff(receiverKey);
            }else{
                //we not at the end of file so process this line and kick off the next line to be read
                ProcessLine(data);
                line++;
                dataid = llGetNotecardLine(giveFolderName, line);
            }
        }
    }

    timer()
    {
        // Stop listening. It's wise to do this to reduce lag
        llListenRemove(gListener);
        // Stop the timer now that its job is done
        llSetTimerEvent(0.0);
    }
}