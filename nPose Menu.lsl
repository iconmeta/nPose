/*
The nPose scripts are licensed under the GPLv2 (http://www.gnu.org/licenses/gpl-2.0.txt), with the following addendum:

The nPose scripts are free to be copied, modified, and redistributed, subject to the following conditions:
    - If you distribute the nPose scripts, you must leave them full perms.
    - If you modify the nPose scripts and distribute the modifications, you must also make your modifications full perms.

"Full perms" means having the modify, copy, and transfer permissions enabled in Second Life and/or other virtual world platforms derived from Second Life (such as OpenSim).  If the platform should allow more fine-grained permissions, then "full perms" will mean the most permissive possible set of permissions allowed by the platform.
*/

//default options settings.  Change these to suit personal preferences
list Permissions = ["Public"]; //default permit option [Pubic, Locked, Group]
string curmenuonsit = "off"; //default menuonsit option
string cur2default = "off";  //default action to revert back to default pose when last sitter has stood
string RLVenabled = "off";   //default RLV enabled state


integer optionsNum = -240;
integer curseatednumber = 0; //number of currently seated AVs.  used in change function to help sort options
list menus; //strided list in form [colon-delimited menupath,pipe-delimited items in that menu]
list menuPerm = [];
string setprefix = "SET";
string btnprefix = "BTN";
string defaultprefix = "DEFAULT";
list cardprefixes = [setprefix, defaultprefix, btnprefix];

list dialogids;     //3-strided list of dialog ids, the avs they belong to, and the menu path.
integer stride = 3; //id, toucher, path for the dialogids

integer DIALOG = -900;
integer DIALOG_RESPONSE = -901;
integer DIALOG_TIMEOUT = -902;
integer DOPOSE = 200;
integer ADJUST = 201;
integer SWAP = 202;
//integer KEYBOARD_CONTROL = 203;
integer DUMP = 204;
integer STOPADJUST = 205;
integer SYNC = 206;
integer DOBUTTON = 207;
integer ADJUSTOFFSET = 208;
integer SETOFFSET = 209;
integer SWAPTO = 210;
//integer DUMPALL = 212;
integer DOMENU = -800; 
integer DOMENU_ACCESSCTRL = -801;
integer memusage = 34334;
integer sensorStart = -233;
integer sensorEnd = -234;
integer attemptCapture = -235;
integer sendVicList = -236;


string SYNCBTN = "sync";
string OFFSETBTN = "offset";
string BACKBTN = "^";
//dialog button responses
string ROOTMENU = "Main";
string ADMINBTN = "admin";
string ManageRLV = "ManageRLV";
string ADJUSTBTN = "Adjust";
string STOPADJUSTBTN = "StopAdjust";
string POSDUMPBTN = "PosDump";
string UNSITBTN = "Unsit";
string OPTIONS = "Options";
string MENUONSIT = "Menuonsit";
string TODEFUALT = "ToDefault";
string PERMITBTN = "Permit";
string PUBLIC = "Public";
string LOCKED = "Locked";
string GROUP = "Group";
string CAPTURE = "Capture";
string VICTIMLIST = "VictimList";
string RlV = "RLV Enable";

list options = [PERMITBTN, MENUONSIT, TODEFUALT];//remove the options from this list you don't want to show

//RLV stuff here
integer relaychannel = -1812221819;
string RLVpath;
string cmdname;
key victim = "00000000-0000-0000-0000-000000000000"; //var to hold current active victim to impose/remove restrictions
key toucherid;
list victims;//2 strided list in form of name,key used to create menu of people to grab, and process responses.
list tempvictims; //also 2 stride list that holds potential victims info found by the sensor
//menu button lists.  not all inclusive of all buttons
list adminbuttons = [ADJUSTBTN, STOPADJUSTBTN, POSDUMPBTN, UNSITBTN, OPTIONS];
list permitbuttons = [PUBLIC, LOCKED, GROUP];
list managebuttons = [CAPTURE, VICTIMLIST];

//vector X_AXIS = <1.0, 0.0, 0.0>;
//vector Y_AXIS = <0.0, 1.0, 0.0>;
//vector Z_AXIS = <0.0, 0.0, 1.0>;
string FWDBTN = "forward";
string BKWDBTN = "backward";
string LEFTBTN = "left";
string RIGHTBTN = "right";
string UPBTN = "up";
string DOWNBTN = "down";
string ZEROBTN = "reset";
float currentOffsetDelta = 0.2;
list offsetbuttons = [FWDBTN, LEFTBTN, UPBTN, BKWDBTN, RIGHTBTN, DOWNBTN, "0.2", "0.1", "0.05", "0.01", ZEROBTN];
//integer seatupdate = 35353;//the core sends out the slots list when anything in it changes.
string defaultPose;//holds the name of the default notecard.
integer n = 0;
integer stop = 0;
integer index = 0;
string SLOTBTN = "ChangeSeat";
list slotbuttons = [];//list of seat# or seated AV name for change seats menu.
list avs = [];//list of seated AV keys.

key Dialog(key rcpt, string prompt, list choices, list utilitybuttons, integer page){
    if (toucherid != llGetOwner()){
        integer stopc = llGetListLength(choices);
        integer nc;
        for (nc = 0; nc < stopc; ++nc){
            integer indexc = llListFindList(menuPerm, [llList2String(choices, nc)]);
            if (indexc != -1){
                if (llList2String(menuPerm, indexc+1) == "owner"){
                    choices = llDeleteSubList(choices, nc, nc);
                    nc--;
                    stopc--;
                }else if (llList2String(menuPerm, indexc+1) != "public"){
                    if (llList2String(menuPerm, indexc+1) == "group"){
                        if (llSameGroup(toucherid)!=1){
                            choices = llDeleteSubList(choices, nc, nc);
                            nc--;
                            stopc--;
                        }
                    }
                }
            }
        }
    }
    key id = llHTTPRequest("http://google.com", [HTTP_METHOD, "GET"], "");
    llMessageLinked(LINK_SET, DIALOG, (string)rcpt + "|" + prompt + "|" + (string)page + "|" + llDumpList2String(choices, "`") + 
        "|" + llDumpList2String(utilitybuttons, "`"), id);
    return id;
}

list SeatedAvs(){ //returns the list of uuid's of seated AVs
    avs=[];
    integer counter = llGetNumberOfPrims();
    while (llGetAgentSize(llGetLinkKey(counter)) != ZERO_VECTOR){
        avs += [llGetLinkKey(counter)];
        counter--;
    }    
    return avs;
}

AdjustOffsetDirection(key id, vector direction) {
    vector delta = direction * currentOffsetDelta;
    llMessageLinked(LINK_SET, ADJUSTOFFSET, (string)delta, id);
}    

UnseatByName(string avname){
    stop = llGetListLength(avs);
    for (n = 0; n < stop; n++){
        key av = llList2Key(avs, n);
        if (llGetSubString(llKey2Name(av), 0, 20) == avname){ //rlv uses the unsit routine too.. manage the victims list when used by rlv
            if ((llKey2Name(av) == llKey2Name(victim)) && (RLVenabled == "on") && (llListFindList(SeatedAvs(), [av]) != -1)){
                llMessageLinked(LINK_SET, relaychannel, "release,"+(string)victim, toucherid);
//                index = llListFindList(victims, [av]);
//                victims = llDeleteSubList((victims = []) + victims, index-1, index);
//                victim = NULL_KEY;
                llUnSit(av);
                return;
            }else if (llListFindList(SeatedAvs(), [av]) != -1){
                llUnSit(av);
                return;
            }
        }
    }    
}

integer AvCount(){ //same as SeatedAvs except doesn't return the list of keys, just the count
    stop = llGetNumberOfPrims();
    n = stop;
    while (llGetAgentSize(llGetLinkKey(n)) != ZERO_VECTOR){
        n--;
    }
    return stop - n;
}

backbuttonremenu(key toucher, string path){ //manage menu when back button is clicked
    list pathparts = llParseString2List(path, [":"], []);
    pathparts = llDeleteSubList(pathparts, -1, -1);
    if (llList2String(pathparts, -1) == ADMINBTN){
        AdminMenu(toucher, llDumpList2String(pathparts, ":"), "Pick an option.", adminbuttons);
    }else if (llList2String(pathparts, -1) == OPTIONS){
        AdminMenu(toucher, llDumpList2String(pathparts, ":"), "Pick an option.", options);
    }else if (llList2String(pathparts, -1) == ManageRLV){
        AdminMenu(toucher, llDumpList2String(pathparts, ":"), "Pick an option.", managebuttons);
    }else if (llGetListLength(pathparts)){
       DoMenu(toucher, llDumpList2String(pathparts, ":"), 0);
    } else {
        DoMenu(toucher, ROOTMENU, 0);
    }
}

AdminMenu(key toucher, string path, string prompt, list buttons){
    key id = Dialog(toucher, prompt, buttons, [BACKBTN], 0);
    index = llListFindList(dialogids, [toucher]);
    list addme = [id, toucher, path];
    if (index == -1){
        dialogids += addme;
    } else{
        dialogids = llListReplaceList((dialogids = []) + dialogids, addme, index - 1, index + 1);        
    }
}

DoMenu(key toucher, string path, integer page){//builds the final menu for authorized and/or owner, and/or RLV button
    index = llListFindList(menus, [path]);
    if (index != -1){
        list buttons = llListSort(llParseStringKeepNulls(llList2String(menus, index + 1), ["|"], []), 1, 1);
        list utility = [SYNCBTN, SLOTBTN, OFFSETBTN];
        if (toucher == llGetOwner()){ //owner only gets admin button
            utility += [ADMINBTN];
        }    
        if (path != ROOTMENU){
            utility += [BACKBTN];
        }
        if ((path == ROOTMENU) && (RLVenabled == "on")){
            utility = ManageRLV + utility; //add the managerlv button if enabled on rootmenu only
        }
        key id = Dialog(toucher, "Pick your pose.\n"+llList2String(dialogids, llListFindList(dialogids, [toucher])+1)+"\n", buttons, utility, page);    
        list addme = [id, toucher, path];
        index = llListFindList(dialogids, [toucher]);
        if (index == -1){
            dialogids += addme;
        }else{
            dialogids = llListReplaceList((dialogids = []) + dialogids, addme, index - 1, index + 1);        
        }        
    }else{
//        debug("error: path '" + path + "' not present in list");
    }
}

UnsitMenu(key av, string path){//unseat an AV by name.  this builds the button names for the menu.
    avs = SeatedAvs();
    list buttons;
    stop = llGetListLength(avs);
    for (n = 0; n < stop; n++){
        buttons += [llGetSubString(llKey2Name((key)llList2String(avs, n)), 0, 20)];
    }    
    key dialogid = Dialog(av, "Pick an avatar to unsit.", buttons, [BACKBTN], 0);
    list addme = [dialogid, av, path];
    index = llListFindList(dialogids, [av]);
    if (index == -1){
        dialogids += addme;
    }else{
        dialogids = llListReplaceList((dialogids = []) + dialogids, addme, index - 1, index + 1); 
    }    
}

DoMenu_AccessCtrl(key toucher, string path, integer page){//checks and enforces who has access to the menu.
    integer authorized = FALSE;
    if (toucher == llGetOwner()){//owner always gets authorized, even if they are a victim
        authorized = TRUE;
    }else if (((llList2String(Permissions, 0) == GROUP) && (llSameGroup(toucher))) || (llList2String(Permissions, 0) == PUBLIC)){
        if (llListFindList(victims, [toucher]) == -1){ //victims do not get authorization
            authorized = TRUE;
        }
    }
    if (authorized){
        DoMenu(toucher,path,page);
    }
}

BuildMenus(){//builds the user defined menu buttons
    menus = [];
    menuPerm = [];
    stop = llGetInventoryNumber(INVENTORY_NOTECARD);
    integer defaultSet = FALSE;
    for (n = 0; n<stop; ++n){//step through the notecards backwards so that default notecard is first in the contents
        string name = llGetInventoryName(INVENTORY_NOTECARD, n);
        integer permsIndex1 = llSubStringIndex(name,"{");
        integer permsIndex2 = llSubStringIndex(name,"}");
        string menuPerms = "";
        if (permsIndex1 != -1){
            menuPerms = llToLower(llGetSubString(name, permsIndex1+1, permsIndex2-1));
            name = llDeleteSubString(name, permsIndex1, permsIndex2);
        }else{
            menuPerms = "public";
        }
        list path = llParseStringKeepNulls(name, [":"], []);
        menuPerm += [llList2String(path, -1), menuPerms];
        string prefix = llList2String(path, 0);
        if (!defaultSet && ((prefix == setprefix) || (prefix == defaultprefix))){
            defaultPose = llGetInventoryName(INVENTORY_NOTECARD,n);
            defaultSet = TRUE;
        }
        if (llListFindList(cardprefixes, [prefix]) != -1){
            list path = llDeleteSubList(path, 0, 0);            
            while(llGetListLength(path)){
                string last = llList2String(path, -1);
                string parentpath = llDumpList2String([ROOTMENU] + llDeleteSubList(path, -1, -1), ":");
                index = llListFindList(menus, [parentpath]);
                if (index != -1 && !(index % 2)){
                    list children = llParseStringKeepNulls(llList2String(menus, index + 1), ["|"], []);
                    if (llListFindList(children, [last]) == -1){
                        children += [last];
                        menus = llListReplaceList((menus = []) + menus, [llDumpList2String(children, "|")], index + 1, index + 1);
                    }
                }else{
                    menus += [parentpath, last];
                }
                path = llDeleteSubList(path, -1, -1);
            }
        }
    }
}

default{
    state_entry(){
        llMessageLinked(LINK_SET, -390390, "RUThere", "");//check if RLV plugin is in contents
        cmdname = (string)llGetKey();//don't really know why the relay uses this name param, but at least this ensures uniqueness for rlv
        BuildMenus();        
        llMessageLinked(LINK_SET, DOPOSE, defaultPose, NULL_KEY);
    }

    touch_start(integer total_number){
            toucherid = llDetectedKey(0);
            DoMenu_AccessCtrl(toucherid,ROOTMENU,0);
    }
    
    link_message(integer sender, integer num, string str, key id){
        if ((num == -390391) && (str == "IAmHere")){
            options = [PERMITBTN, MENUONSIT, TODEFUALT, RlV];//add RLV button to options if RLV plugin answers
        }
        if (num == DIALOG_RESPONSE){ //response from menu
//            debug("dialog response: " + str);
            index = llListFindList(dialogids, [id]); //find the id in dialogids  
            //to get an id in response, user dialog had to origniate from this build.
            //(no cross talk between nPose items) 
            if (index != -1){ //we found the toucher in dialogids
                list params = llParseString2List(str, ["|"], []);  //parse the message
                integer page = (integer)llList2String(params, 0);  //get the page number
                string selection = llList2String(params, 1);  //get the button that was pressed from str
//                key toucher = llList2Key(dialogids, index + 1); //get the toucher from dialogids             
                string path = llList2String(dialogids, index + 2); //get the path from dialogids
                toucherid = llList2Key(dialogids, index + 1);
//                debug("dialog path: " + path);
                dialogids = llDeleteSubList((dialogids = []) + dialogids, index, index + 2);
                //go find out which button was pressed
                //was it main menu options?
                if (selection == ADMINBTN){ 
                    dialogids += [id, toucherid, path + ":" + ADMINBTN];
                    AdminMenu(toucherid, path + ":" + ADMINBTN, "Pick an option.", adminbuttons);
                }else if (selection == BACKBTN){
                    backbuttonremenu(toucherid, path);
                }else if (selection == OFFSETBTN){
                    //give offset menu
                    path = path + ":" + selection;
                    dialogids += [id, toucherid, path];
                    AdminMenu(toucherid, path,   "Adjust by " + (string)currentOffsetDelta + "m,
or choose another distance.", offsetbuttons);
                }else if (selection == SLOTBTN){
                    //someone wants to change sit positionss.  would be nice to know who is seated where and
                    //the number of places available with this pose set and make the buttons accordingly
                    //taking a place where someone already has that slot should do the swap regardless of how many 
                    //places are open
                    path = path + ":" + selection;
                    dialogids += [id, toucherid, path];
                    AdminMenu(toucherid, path,  "Where will you sit?", slotbuttons);
                }else if (selection == SYNCBTN){
                    llMessageLinked(LINK_SET, SYNC, "", "");
                    dialogids += [id, toucherid, path];
                    DoMenu(toucherid, path, page);                    
                }else if (selection == ManageRLV){
                    path = path + ":" + selection;
                    dialogids += [id, toucherid, path];
                    RLVpath = path;
                    AdminMenu(toucherid, path, "Pick an option.", managebuttons);                    
                }else if (~llListFindList(menus, [path + ":" + selection])){
                    path = path + ":" + selection;
                    dialogids += [id, toucherid, path];
                    DoMenu(toucherid, path, 0);
                }else if (llList2String(llParseString2List(path, [":"], []), -1) == OFFSETBTN){
                         if (selection ==   FWDBTN) AdjustOffsetDirection(toucherid,  (vector)<1.0, 0.0, 0.0>);
                    else if (selection ==  BKWDBTN) AdjustOffsetDirection(toucherid,  (vector)(-<1.0, 0.0, 0.0>));
                    else if (selection ==  LEFTBTN) AdjustOffsetDirection(toucherid,  (vector)<0.0, 1.0, 0.0>);
                    else if (selection == RIGHTBTN) AdjustOffsetDirection(toucherid,  (vector)(-<0.0, 1.0, 0.0>));
                    else if (selection ==    UPBTN) AdjustOffsetDirection(toucherid,  (vector)<0.0, 0.0, 1.0>);
                    else if (selection ==  DOWNBTN) AdjustOffsetDirection(toucherid,  (vector)(-<0.0, 0.0, 1.0>));
                    else if (selection ==  ZEROBTN) llMessageLinked(LINK_SET, SETOFFSET, (string)ZERO_VECTOR, toucherid);
                    else currentOffsetDelta = (float)selection;
                    dialogids += [id, toucherid, path];
                    AdminMenu(toucherid, path,  "Adjust by " + (string)currentOffsetDelta + "m,
or choose another distance.", offsetbuttons);
                }else if (llList2String(llParseString2List(path, [":"], []), -1) == SLOTBTN){//change seats
                    if (llGetSubString(selection, 0,3)=="seat"){ //clicker selected an open seat where menu is 'seat'+#
                        integer slot = (integer)llGetSubString(selection, 4,-1);
                         if (slot >= 0) {
                            llMessageLinked(LINK_SET, SWAPTO, (string)(slot), toucherid);
                        }
                    }else{ //clicker selected a name so get seat# from list
                        integer slot = llListFindList(slotbuttons, [selection])+1;
                        if (slot >= 0) {
                            llMessageLinked(LINK_SET, SWAPTO, (string)(slot), toucherid);
                        }
                    }
                    dialogids += [id, toucherid, ROOTMENU];
                    DoMenu_AccessCtrl(toucherid,ROOTMENU,0);
                    //was it ManageRLV sub menu choices?
                }else if (llList2String(llParseString2List(path, [":"], []), -1) == ManageRLV){//capture or select victim
                    if (selection == CAPTURE){
                        path = path + ":" + selection;
                        dialogids += [id, toucherid, path];
                        RLVpath = path;
                        //request the list of potential victims from RLV plugin
                        llMessageLinked(LINK_SET, sensorStart, "", toucherid);
//                        DoMenu(toucherid, ROOTMENU, 0);
                    }else if (selection == VICTIMLIST){
                        list buttonslist = [];
                        integer stop = llGetListLength(victims);
                        for (n=0; n< stop -1; n++){
                                buttonslist = buttonslist + llList2String(victims,n);
                                n = n + 1;
                            }
                        path = path + ":" + selection;
                        dialogids += [id, toucherid, path];
                        AdminMenu(toucherid, path, "Current Victim is " + llKey2Name(victim) + "
Pick a name to change victims.", buttonslist);
                    }
                }else if (llList2String(llParseString2List(path, [":"], []), -1) == VICTIMLIST){//pick the victim
                    index = llListFindList(victims, [selection]);
                    victim = llList2String(victims, index + 1); //select the active victim to act upon by notecard
//                    string message = cmdname + "," + (string)victim + ",newvictim";
                    llMessageLinked(LINK_SET, sendVicList-3, selection, toucherid);
                    DoMenu(toucherid, ROOTMENU, 0);
                    //admin sub menu choices
                }else if (llList2String(llParseString2List(path, [":"], []), -1) == ADMINBTN){
                    if (selection == ADJUSTBTN){
                        llMessageLinked(LINK_SET, ADJUST, "", "");
                        dialogids += [id, toucherid, path];
                        AdminMenu(toucherid, path, "Pick an option.", adminbuttons);
                    }else if (selection == STOPADJUSTBTN){
                        llMessageLinked(LINK_SET, STOPADJUST, "", "");                        
                        dialogids += [id, toucherid, path];
                        AdminMenu(toucherid, path, "Pick an option.", adminbuttons);
                    }else if (selection == POSDUMPBTN){
                        llMessageLinked(LINK_SET, DUMP, "", "");
                        dialogids += [id, toucherid, path];
                        AdminMenu(toucherid, path, "Pick an option.", adminbuttons);
                    }else if (selection == UNSITBTN){
                        UnsitMenu(toucherid, path + ":" + selection);
                    }else if (selection == OPTIONS){
                    dialogids += [id, toucherid, path+":"+selection];
                        AdminMenu(toucherid, path + ":" + selection,  "Pick an option.", options);
                    }
                    //was it admin options sub menu?
                }else if (llList2String(llParseString2List(path, [":"], []), -1) == OPTIONS){//do admin/options stuff
                    if (selection == PERMITBTN){ //note: the admin menu is really just a routine 
                    //for remenu other than notecard path
                        dialogids += [id, toucherid, path + ":" + selection];
                        AdminMenu(toucherid, path + ":" + selection, "\nCurrently set to "+ 
                        llList2String(Permissions,0)+"\nPick an option.", permitbuttons);
                    }else if (selection == MENUONSIT){ //note continued: we'll use it for options menu as well
                        dialogids += [id, toucherid, path + ":" + selection];
                        AdminMenu(toucherid, path + ":" + selection, "\nCurrently set to "+ curmenuonsit+"
Pick an option.", ["on", "off"]);
                    }else if (selection == TODEFUALT){
                        dialogids += [id, toucherid, path + ":" + selection];
                        AdminMenu(toucherid, path + ":" + selection, "\nCurrently set to "+ cur2default+"
Pick an option.", ["on", "off"]);
                    }else if (selection == RlV){
                        dialogids += [id, toucherid, path + ":" + selection];
                        AdminMenu(toucherid, path + ":" + selection, "\nCurrently set to "+ RLVenabled+"
Pick an option.", ["on", "off"]);
                    }
                    //was it one step beyond these option buttons?
                }else if (llList2String(llParseString2List(path, [":"], []), -1) == UNSITBTN){
                    UnseatByName(selection);
                    UnsitMenu(toucherid, path);
                }else if (llList2String(llParseString2List(path, [":"], []), -1) == PERMITBTN){
                    Permissions = [selection];
                    AdminMenu(toucherid, path, "\nCurrently set to "+ llList2String(Permissions,0)+"\n
                    Pick an option.", permitbuttons);
                }else if (llList2String(llParseString2List(path, [":"], []), -1) == MENUONSIT){
                    curmenuonsit = selection;
                    dialogids += [id, toucherid, path];
                    AdminMenu(toucherid, path, "\nCurrently set to "+ curmenuonsit+"\nPick an option.", ["on", "off"]);
                }else if (llList2String(llParseString2List(path, [":"], []), -1) == TODEFUALT){
                    if ((cur2default == "off") && (selection == "on") && (AvCount()<=0)){
                        cur2default = selection;
                        llMessageLinked(LINK_SET, DOPOSE, defaultPose, NULL_KEY);
                        dialogids += [id, toucherid, path];
                        AdminMenu(toucherid, path, "\nCurrently set to "+ cur2default+"\nPick an option.", ["on", "off"]);
                    }else{
                        cur2default = selection;
                        dialogids += [id, toucherid, path];
                        AdminMenu(toucherid, path, "\nCurrently set to "+ cur2default+"\nPick an option.", ["on", "off"]);
                    }
                }else if (llList2String(llParseString2List(path, [":"], []), -1) == RlV){
                    RLVenabled = selection; //used to turn 'on/off' the rlv option in menu
                    llSay(relaychannel, "" + "," + "" + "," + RLVenabled);
                    dialogids += [id, toucherid, path];
                    AdminMenu(toucherid, path, "\nCurrently set to "+ RLVenabled + "\nPick an option.", ["on", "off"]);
                }else{
                    dialogids += [id, toucherid, path];
                    DoMenu(toucherid, path, page);
                }//normal housekeeping stuff
                list pathlist = llDeleteSubList(llParseStringKeepNulls(path, [":"], []), 0, 0);
                string defaultname = llDumpList2String([defaultprefix] + pathlist + [selection], ":");                
                string setname = llDumpList2String([setprefix] + pathlist + [selection], ":");
                if (llGetInventoryType(defaultname) == INVENTORY_NOTECARD){
                    llMessageLinked(LINK_SET, DOPOSE, defaultname, toucherid);                    
                }else if (llGetInventoryType(setname) == INVENTORY_NOTECARD){
                    llMessageLinked(LINK_SET, DOPOSE, setname, toucherid);
                }                             
                string btnname = llDumpList2String([btnprefix] + pathlist + [selection], ":");
                if (llGetInventoryType(btnname) == INVENTORY_NOTECARD){
                    llMessageLinked(LINK_SET, DOBUTTON, btnname, toucherid);
                }
            }            
        }else if (num == DIALOG_TIMEOUT){//menu not clicked and dialog timed out
            index = llListFindList(dialogids, [id]);
            if (index != -1){
                dialogids = llDeleteSubList((dialogids = []) + dialogids, index, index + stride - 1);
                tempvictims = [];
            }                
        }else if (num == DOMENU){//external call to do menu
            if (str){
                DoMenu(id, str, 0);
            }else{
                DoMenu(id, ROOTMENU, 0);                
            }
        }else if (num == DOMENU_ACCESSCTRL){//external call to check permissions
            if (str){
                DoMenu_AccessCtrl(id,str,0);
            }else{
                DoMenu_AccessCtrl(id,ROOTMENU,0);
            }
            //rlv sensor stuff
        }else if (num == sensorEnd){//list of potential victims' names for buttons
            AdminMenu(toucherid, RLVpath, "Pick a victim to attempt capturing.", llCSV2List(str));
        }else if (num == attemptCapture){//we trying to capture a victim
            if (llListFindList(victims,[str]) >= 0){
                index = llListFindList(victims, [str]);
                victims = llDeleteSubList((victims = []) + victims, index, index + 1);
            } //this victim will be added to victims list and also become the current 
            //active victim when they sit in changed event
            index = llListFindList(tempvictims, [str]);
            llInstantMessage(toucherid, "Attempting to grab " + str);
            string message = cmdname + "," + (string)llList2Key(tempvictims, index +1) + "," + "grab";
            llMessageLinked(LINK_SET, relaychannel, message, toucherid);
            dialogids += [id, toucherid, ROOTMENU];
            DoMenu(toucherid, ROOTMENU, 0);
        }else if (num == sendVicList){//received the list of potential victims, awaiting confirmation as to which one will be the victim
            tempvictims = llCSV2List(str);
        }else if(num == sendVicList-1){
            victim = str;
        }else if(num == sendVicList-2){
            victims = llCSV2List(str);
        }else if (num==optionsNum){
            list optionsToSet = llParseStringKeepNulls(str, ["~"], []);
            stop = llGetListLength(optionsToSet);
            for (n=0; n<stop; ++n){
                list optionsItems = llParseString2List(llList2String(optionsToSet, n), ["="], []);
                string optionItem = llList2String(optionsItems, 0);
                string optionSetting = llList2String(optionsItems, 1);
                if (optionItem == "menuonsit") {curmenuonsit = optionSetting;}
                else if (optionItem == "2default") {cur2default = optionSetting;}
            }
        }else if (num==35354){
            slotbuttons = llParseString2List(str, [","], []);
        }else if (num == memusage){//dump memory stats to local
            llSay(0,"Memory Used by " + llGetScriptName() + ": " + (string)llGetUsedMemory() + " of " + (string)llGetMemoryLimit()
                 + ",Leaving " + (string)llGetFreeMemory() + " memory free.");
        }
    }

    changed(integer change){
        if (change & CHANGED_INVENTORY){
            BuildMenus();           
            //Ping for RLV plugin
            options = [PERMITBTN, MENUONSIT, TODEFUALT];
            llMessageLinked(LINK_SET, -390390, "RUThere", "");
        }
        if (change & CHANGED_OWNER){
            llResetScript();
        }
        // check on the options and act accordingly on av count change
        avs = SeatedAvs();
        if ((change & CHANGED_LINK) && (AvCount()>0)){ //we have a sitter
            if (RLVenabled == "on"){
/*                stop = llGetListLength(victims);
                for (n = 0; n < stop; ++n){ //check and release any victims not seated. sitter may not be a victim
                    if (llListFindList(avs, [llList2Key(victims, n+1)])==-1){ //no one seated so clean up
                        llMessageLinked(LINK_SET, relaychannel, "release,"+(string)llList2Key(victims, n+1), toucherid);
                        victims = llDeleteSubList((victims = []) + victims, n, n+1);
                        victim = "";
                    }
                    n = n+1;
                } //check and add any new seated victim
                key id = llList2Key(avs, 0);  //the first key in the avs list will be our new sitter
                index = llListFindList(tempvictims, [id]); //should they be in the victim list?
                if (index > 0){//test to see if this is our victim and add to victims list and current victim variable
                    victims = victims + [llList2String(tempvictims, index-1), llList2Key(tempvictims, index)];
                    victim = llList2Key(tempvictims, index);
                    string message = cmdname + "," + (string)victim + ",newvictim";
                    llMessageLinked(LINK_SET, relaychannel, message, "");
                    tempvictims = [];
                }*/
                if (curmenuonsit == "on"){
                    integer lastSeatedAV = llGetListLength(avs);  //get current number of AVs seated
                    if (lastSeatedAV > curseatednumber){  //we are in changed event so find out if 
                    //it is a new sitter that brought us here
                        key id = llList2Key(avs,lastSeatedAV-curseatednumber-1);  //if so, get key of last sitter 
                        curseatednumber = lastSeatedAV;  //update our number of sitters
                        if (llListFindList(victims, [id])==-1){ //check if new sitter is a victim
                            DoMenu_AccessCtrl(id, ROOTMENU, 0);  //not a victim, give menu
                        }
                    }
                }
            }else{
                if (curmenuonsit == "on"){
                    integer lastSeatedAV = llGetListLength(avs);  //get current number of AVs seated
                    if (lastSeatedAV > curseatednumber){  //we are in changed event so find out if 
                    //it is a new sitter that brought us here
                        key id = llList2Key(avs,lastSeatedAV-curseatednumber-1);  //if so, get key of last sitter 
                        curseatednumber = lastSeatedAV;  //update our number of sitters
                        if (llListFindList(victims, [id])==-1){ //check if new sitter is a victim
                            DoMenu_AccessCtrl(id, ROOTMENU, 0);  //if not a victim, give menu
                        }
                    }
                }
            }
            curseatednumber=llGetListLength(avs);
        }else if ((change & CHANGED_LINK) && (cur2default == "on")){ //av count is 0 (we lost all sitters)
            llMessageLinked(LINK_SET, DOPOSE, defaultPose, NULL_KEY);
            curseatednumber=0;
        }else{
            stop = llGetListLength(victims);
            for (n = 0; n < stop; n++){
                if (llListFindList(avs, [llList2Key(victims, n+1)])==-1){ //this victim not seated so clean up
                    llMessageLinked(LINK_SET, relaychannel, "release,"+(string)llList2Key(victims, n+1), toucherid);
                    victims = llDeleteSubList((victims = []) + victims, n, n+1);
                    victim = "";
                }
                n = n+1;
            }
            curseatednumber=0;
        }
    }
    on_rez(integer params){
        llResetScript();
    }
}
