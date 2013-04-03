/*
The nPose scripts are licensed under the GPLv2 (http://www.gnu.org/licenses/gpl-2.0.txt), with the following addendum:

The nPose scripts are free to be copied, modified, and redistributed, subject to the following conditions:
    - If you distribute the nPose scripts, you must leave them full perms.
    - If you modify the nPose scripts and distribute the modifications, you must also make your modifications full perms.

"Full perms" means having the modify, copy, and transfer permissions enabled in Second Life and/or other virtual world platforms derived from Second Life (such as OpenSim).  If the platform should allow more fine-grained permissions, then "full perms" will mean the most permissive possible set of permissions allowed by the platform.
*/
key ownerinit;
integer stride = 8;
integer slotMax = 0;
integer slotupdate = 34333;
integer memusage = 34334;
list slots;
integer curPrimCount = 0;
integer lastPrimCount = 0;
integer lastStrideCount = 12;
integer seatupdate = 35353;//we gonna do satmsg and notsatmsg
integer rezadjusters;
integer poseSetHasProps;
//integer newPose = 33333;
integer listener;
integer line;
string defaultprefix = "DEFAULT:";
key dataid;
key clicker;
integer chatchannel;
string cardprefix = "SET:";
key cardid;
string card;
integer btnline;
key btnid;
string btncard;
integer SYNC = 206;

integer x;
integer n;
integer stop;
list adjusters;
integer SWAPTO = 210;
integer STOPADJUST = 205;
//integer SETOFFSET = 209;
integer DUMP = 204;
integer DOPOSE = 200;
integer DOACTIONS = 207;
integer CORERELAY = 300;
//integer BOFflag = 0;
integer ADJUSTOFFSET = 208;
integer ADJUST = 201;

string str_replace(string src, string from, string to){
    integer len = (~-(llStringLength(from)));
    if(~len){
        string  buffer = src;
        integer b_pos = -1;
        integer to_len = (~-(llStringLength(to)));
        @loop;
        integer to_pos = ~llSubStringIndex(buffer, from);
        if(to_pos){
            buffer = llGetSubString(src = llInsertString(llDeleteSubString(src, b_pos -= to_pos, b_pos + len),
                b_pos, to), (-~(b_pos += to_len)), 0x8000);
            jump loop;
        }
    }
    return src;
}

integer FindEmptySlot() {
    for (n=0; n < slotMax; ++n) {
        if (llList2String(slots, n*stride+4) == ""){
            return n;
        }
    }
    return -1;
}

list SeatedAvs(){
    list avs = [];
    integer linkcount = llGetNumberOfPrims();
    for (n = linkcount; n >= 0; n--){
        key id = llGetLinkKey(n);
        if (llGetAgentSize(id) != ZERO_VECTOR){
            avs = [id] + avs;
        }
    }
    return avs;
}

assignSlots(){
    list avqueue = SeatedAvs();
    stop = llGetListLength(avqueue);
//    slotMax = llGetListLength(slots)/stride;
    if (slotMax < lastStrideCount){
        //AV's that were in a 'real' seat are already assigned so leave them be
        for (x=slotMax; x<=lastStrideCount; ++x){//only need to worry about the 'extra' slots so limit the count
            if (llList2Key(slots, x*stride+4) != ""){//check this slot for a seated AV
                integer emptySlot = FindEmptySlot();//user functions are memory expensive and only used once. suggest put that code here
                if ((emptySlot >=0) && (emptySlot < slotMax)){
                    //if AV in a 'now' extra seat and if a real seat available, seat them
                    slots = llListReplaceList(slots, [llList2Key(slots, x*stride+4)], emptySlot*stride+4, emptySlot*stride+4);
                }
            }
        }
        //remove the 'now' extra seats from slots list
        slots = llDeleteSubList(slots, (slotMax)*stride, -1);
        //unsit extra seated AV's
        for (n=0; n<stop; ++n){
            if (llListFindList(slots, [llList2Key(avqueue, n)]) < 0){
                llUnSit(llList2Key(avqueue, n));
            }
        }
    }else if (slotMax > lastStrideCount){
        //nothing to do as it is already done by processLine routine
    }else if (slotMax == lastStrideCount){
        //nothing to do as it is already done by processLine routine
    }
    
    if (curPrimCount > lastPrimCount){
        //we have a new AV, if a seat is available then seat them
        //if not, unseat them
        //numbered seats take priority so check if new AV is on a numbered prim
        //find the new seated AV, will be the first one in the avqueue list
        key thisKey=llList2Key(avqueue,stop-1);
        //step through the prims to see if our new AV has a numbered seat
        integer primcount = llGetObjectPrimCount(llGetKey());
        integer slotNum=-1;
        for (n= 1; n <= primcount; ++n){//find out which prim this new AV is seated on and grab the slot number if it's a numbered prim.
            integer x = (integer)llGetSubString(llGetLinkName(n), 4, -1);
            if ((x>0) && (x<=slotMax)){
                if (llAvatarOnLinkSitTarget(n) == thisKey){
                    if (llList2String(slots, (x-1)*stride+4) == ""){
                        slotNum = (integer)llGetLinkName(n);
                    }
                }
            }
        }
        integer nn;
        for (nn= 1; nn <= primcount; ++nn){
            if (slotNum != -1  && llListFindList(slots, [thisKey]) == -1){
                //AV is seated on a numbered prim so give them the correct seat
                if (slotNum <= slotMax){
                    slots = llListReplaceList(slots, [thisKey], (slotNum-1)*stride+4, (slotNum-1)*stride+4);
                }else{
                    //sitter is on a numbered prim not incluced in this pose set so find first open slot for them.
                    integer y = FindEmptySlot();
                    if (y != -1){
                        //we have a spot.. seat them
                        slots = llListReplaceList(slots, [thisKey], (y)*stride+4, (y)*stride+4);
                    }else if (llListFindList(SeatedAvs(), [thisKey]) != -1){
                        //no open slots, so unseat them
                        llUnSit(thisKey);
                    }
                }
            }
            if (llListFindList(slots, [thisKey]) == -1){//AV not on a numbered prim or seat is taken.
                integer y = FindEmptySlot();
                if (y != -1){
                    //we have a spot.. seat them
                    slots = llListReplaceList(slots, [thisKey], (y)*stride+4, (y)*stride+4);
                }else if (llListFindList(SeatedAvs(), [thisKey]) != -1){
                    //no open slots, so unseat them
                    llUnSit(thisKey);
                }
            }
        }
    }else if (curPrimCount < lastPrimCount){//we lost a seated AV
        //remove this AV key from the slots list
        for (x=0; x < slotMax; ++x) {
            //look in the avqueue for the key in the slots list
            if (llListFindList(avqueue, [llList2Key(slots, x*stride+4)]) < 0) {
                //if the key is not in the avqueue, remove it from the slots list
                slots = llListReplaceList(slots, [""], x*stride+4, x*stride+4);
            }
        }
    }
    //update lastStrideCount
    //chat out seat update
    lastPrimCount = curPrimCount;
    lastStrideCount = slotMax;
    llMessageLinked(LINK_SET, seatupdate, llDumpList2String(slots, "^"), NULL_KEY);
}

//UpdateSlots has been deminished to simply handling SATMSG and NOTSAGMSG data.
UpdateSlots(){
    list avqueue = SeatedAvs();
    for (n = 0; n < slotMax; ++n){
        string slot = llList2String(slots, n*stride + 4);
        if (llList2String(slots, n*stride + 4) != ""){
            string sm = llList2String(slots, n*stride + 5);
            if (sm != ""){
                integer ndx;
                string line = str_replace(sm, "%AVKEY%", (key)slot);
                list smsgs=llParseString2List(line, ["§"], []);
                integer msgcnt = llGetListLength(smsgs);
                for (ndx = 0; ndx < msgcnt; ndx++){
                    list parts = llParseString2List(llList2String(smsgs,ndx), ["|"], []);
                    llMessageLinked(LINK_SET, (integer)llList2String(parts, 0), llList2String(parts, 1),
                        (key)llList2String(slots, n*stride + 4));
                    if(poseSetHasProps){
                        llWhisper(chatchannel,llDumpList2String(["LINKMSG",(string)llList2String(parts, 0),
                            llList2String(parts, 1), (string)llList2String(slots, n*stride + 4)], "|"));
                    }
                }
            }
        }else{
                string nsm = llList2String(slots, n*stride + 6);
            if (nsm != "") {
                integer ndx;
                string line = str_replace(nsm, "%AVKEY%", (key)slot);
                list nsmsgs=llParseString2List(line, ["§"], []);
                integer msgcnt = llGetListLength(nsmsgs);
                for (ndx = 0; ndx < msgcnt; ndx++){
                    list parts = llParseString2List(llList2String(nsmsgs,ndx), ["|"], []);
                    llMessageLinked(LINK_SET, (integer)llList2String(parts, 0), llList2String(parts, 1), (key)slot);
                    if(poseSetHasProps){
                        llWhisper(chatchannel,llDumpList2String(["LINKMSG",(string)llList2String(parts, 0),
                            llList2String(parts, 1),slot], "|"));
                    }
                }
            }
        }
    }
}


SwapTwoSlots(integer currentseatnum, integer newseatnum) {
//    key avKey = llList2Key(slots, llListFindList(slots, ["seat"+(string)currentseatnum])-4);
    if (newseatnum <= slotMax){
        integer OldSlot=llListFindList(slots, ["seat"+(string)currentseatnum])/stride;
        integer NewSlot=llListFindList(slots, ["seat"+(string)newseatnum])/stride;

        list curslot = llList2List(slots, NewSlot*stride, NewSlot*stride+3)
                + [llList2Key(slots, OldSlot*stride+4)]
                + llList2List(slots, NewSlot*stride+5, NewSlot*stride+7);
        slots = llListReplaceList(slots, llList2List(slots, OldSlot*stride, OldSlot*stride+3)
                + [llList2Key(slots, NewSlot*stride+4)]
                + llList2List(slots, OldSlot*stride+5, OldSlot*stride+7), OldSlot*stride, (OldSlot+1)*stride-1);

        slots = llListReplaceList(slots, curslot, NewSlot*stride, (NewSlot+1)*stride-1);
    }else{
        llRegionSayTo(llList2Key(slots, llListFindList(slots, ["seat"+(string)currentseatnum])-4),
             0, "Seat "+(string)newseatnum+" is not available for this pose set");
    }
    if (rezadjusters){
        integer seatNum;
        for (seatNum = 0; seatNum<slotMax; ++seatNum){
            ChatAdjusterPos(seatNum);
        }
    }
    llMessageLinked(LINK_SET, seatupdate, llDumpList2String(slots, "^"), NULL_KEY);
}



SwapAvatarInto(key avatar, string newseat) { 
    
//    string Avseat = llList2String(slots, llListFindList(slots, [avatar])+3); 
    integer oldseat = (integer)llGetSubString(llList2String(slots, llListFindList(slots, [avatar])+3), 4,-1); 
    if (oldseat <= 0) {
        llWhisper(0, "avatar is not assigned a slot: " + (string)avatar);
    }else{ 
            SwapTwoSlots(oldseat, (integer)newseat); 
    }
}

RezNextAdjuster(){
    llRezObject("Adjuster", llGetPos() + <0,0,1>, ZERO_VECTOR, llGetRot(), chatchannel);
}

ReadCard(){
    lastStrideCount = slotMax;
//    slots = [];
    slotMax = 0;
    llSay(chatchannel, "die");
    poseSetHasProps = FALSE;
    llSay(chatchannel, "adjuster_die");
    adjusters = [];
    line = 0;
    cardid = llGetInventoryKey(card);
    dataid = llGetNotecardLine(card, line);
}


ProcessLine(string line, key av){
    line = llStringTrim(line, STRING_TRIM);
    list params = llParseString2List(line, ["|"], []);
    string action = llList2String(params, 0);
    if (action == "ANIM"){
        if (slotMax<lastStrideCount){
            slots = llListReplaceList(slots, [llList2String(params, 1), (vector)llList2String(params, 2),
                llEuler2Rot((vector)llList2String(params, 3) * DEG_TO_RAD), llList2String(params, 4), llList2Key(slots, (slotMax)*stride+4),
                 "", "","seat"+(string)(slotMax+1)], (slotMax)*stride, (slotMax)*stride+7);
        }else{
            slots += [llList2String(params, 1), (vector)llList2String(params, 2),
                llEuler2Rot((vector)llList2String(params, 3) * DEG_TO_RAD), llList2String(params, 4), "", "", "","seat"+(string)(slotMax+1)]; 
        }
        slotMax++;
    }else if (action == "SINGLE"){
        //this pose is for a single sitter within the slots list
        //got to find out which slot and then replace the entire slot
        integer posIndex = llListFindList(slots, [(vector)llList2String(params, 2)]);
        if ((posIndex == -1) || ((posIndex != -1) && llList2String(slots, posIndex-1) != llList2String(params, 1))){
//        if ((llListFindList(slots, [llList2String(params, 1)])==-1) && (llListFindList(slots, [(vector)llList2String(params, 2)])==-1)){
            integer slotindex = llListFindList(slots, [clicker])-4;
            slots = llListReplaceList(slots, [llList2String(params, 1), (vector)llList2String(params, 2),
                llEuler2Rot((vector)llList2String(params, 3) * DEG_TO_RAD), llList2String(params, 4), llList2Key(slots,
                     slotindex+4), "", "",llList2String(slots, slotindex+7)], slotindex, slotindex + 7);
        }
        slotMax = llGetListLength(slots)/stride;
        lastStrideCount = slotMax;
    }else if (action == "PROP"){
        string obj = llList2String(params, 1);
        if (llGetInventoryType(obj) == INVENTORY_OBJECT){
            list strParm2 = llParseString2List(llList2String(params, 2), ["="], []);
            if (llList2String(strParm2, 1) == "die"){
                llSay(chatchannel,llList2String(strParm2,0)+"=die");
            }else{
                vector pos = llGetPos() + ((vector)llList2String(params, 2) * llGetRot());
                rotation rot = llEuler2Rot((vector)llList2String(params, 3) * DEG_TO_RAD) * llGetRot();
                llRezAtRoot(obj, pos, ZERO_VECTOR, rot, chatchannel);
            }
        }
    }else if (action == "LINKMSG"){
        integer num = (integer)llList2String(params, 1);
        string line1 = str_replace(line, "%AVKEY%", av);
        list params1 = llParseString2List(line1, ["|"], []);
        key lmid;
        if ((key)llList2String(params1, 3) != ""){
            lmid = (key)llList2String(params1, 3);
        }else{
            lmid = (key)llList2String(slots, (slotMax-1)*stride+4);
        }
        string str = llList2String(params1, 2);
        llMessageLinked(LINK_SET, num, str, lmid);
        if(poseSetHasProps){
            llWhisper(chatchannel,llDumpList2String(["LINKMSG",num,str,lmid], "|"));
        }
    }else if (action == "SATMSG"){
        integer index = (slotMax-1) * stride + 5;
        slots = llListReplaceList(slots, [llDumpList2String([llList2String(slots,index),
            llDumpList2String(llDeleteSubList(params, 0, 0), "|")], "§")], index, index);
    }else if (action == "NOTSATMSG"){
        integer index = (slotMax-1) * stride + 6;
        slots = llListReplaceList(slots, [llDumpList2String([llList2String(slots,index),
            llDumpList2String(llDeleteSubList(params, 0, 0), "|")], "§")], index, index);
    }
}

ChatAdjusterPos(integer slotnum){
    integer index = slotnum * stride;
    vector pos = llGetPos() + llList2Vector(slots, index + 1) * llGetRot();
    rotation rot = llList2Rot(slots, index + 2) * llGetRot();
    string out = llList2String(adjusters, slotnum) + "|posrot|" + (string)pos + "|" + (string)rot;
    llSay(chatchannel, out);


}

default{
    state_entry(){
        curPrimCount = llGetNumberOfPrims();
        for (n=0; n<=curPrimCount; ++n){
           llLinkSitTarget(n,<0.0,0.0,0.5>,ZERO_ROTATION);
        }
        chatchannel = (integer)("0x" + llGetSubString((string)llGetKey(), 0, 7));
        ownerinit = llGetOwner();
        lastPrimCount = curPrimCount;
        listener = llListen(chatchannel, "", "", "");
        stop = llGetInventoryNumber(INVENTORY_NOTECARD);
        for (n = 0; n < stop; n++){
            string name = llGetInventoryName(INVENTORY_NOTECARD, n);
            if ((llSubStringIndex(name, defaultprefix) == 0) || (llSubStringIndex(name, cardprefix) == 0)){
                card = name;
                ReadCard(); 
                return;
            } 
        }
    }
    link_message(integer sender, integer num, string str, key id){
        if (num == DOPOSE){
            card = str;
            clicker = id;
            if (llGetInventoryType(str) == INVENTORY_NOTECARD){
                ReadCard();
            }
        }else if (num == DOACTIONS){
            btncard = str;
            clicker = id;
            btnline = 0;
            btnid = llGetNotecardLine(btncard, btnline);
        }else if (num == ADJUST){ 
            llSay(chatchannel, "adjuster_die");
            adjusters = [];
            if (llGetInventoryType("Adjuster") & INVENTORY_OBJECT) {
                rezadjusters = TRUE;
                RezNextAdjuster();
            } else {
                llRegionSayTo(ownerinit, 0, "Seat Adjustment disabled.  No Adjuster object found.");
            }
        }else if (num == STOPADJUST){ 
            llSay(chatchannel, "adjuster_die"); 
            adjusters = [];
            rezadjusters = FALSE;
        }else if (num == DUMP){
            for (n = 0; n < slotMax; ++n){
                list slice = llList2List(slots, n*stride, n*stride + 3);
                slice = llListReplaceList(slice, [RAD_TO_DEG * llRot2Euler(llList2Rot(slice, 2))], 2, 2);
                string sendSTR = "ANIM|" + llDumpList2String(slice, "|");
                llRegionSayTo(ownerinit, 0, "\n"+sendSTR);
                llMessageLinked(LINK_SET, slotupdate, sendSTR, NULL_KEY); 
            }
            llSay(chatchannel, "posdump");
        }else if((num == CORERELAY) && poseSetHasProps){
            list msg = llParseString2List(str, ["|"], []);
            if(id != NULL_KEY) msg = llListReplaceList((msg = []) + msg, [id], 2, 2);
            llWhisper(chatchannel,llDumpList2String(["LINKMSG",(string)llList2String(msg, 0),
                llList2String(msg, 1), (string)llList2String(msg,2)], "|"));
        }else if (num == SWAPTO) {
            SwapAvatarInto(id, str);
//        }else if (num == SYNC) {
//            assignSlots();
        }else if (num == seatupdate){
            UpdateSlots();
        }else if (num == memusage){
            llSay(0,"Memory Used by " + llGetScriptName() + ": " + (string)llGetUsedMemory() + " of " + (string)llGetMemoryLimit() + ", Leaving " + (string)llGetFreeMemory() + " memory free.");
        }
    }

    object_rez(key id){
        if (llKey2Name(id) == "Adjuster"){
            adjusters += [id];
            integer adjLen = llGetListLength(adjusters);
            ChatAdjusterPos(adjLen - 1); 
            
            if (adjLen < slotMax){ 
                RezNextAdjuster();
            }
        }else{
            poseSetHasProps = TRUE;
        }
    }

    listen(integer channel, string name, key id, string message){
        
        if (name == "Adjuster"){
            integer index = llListFindList(adjusters, [id]);
            if (index != -1){
                list params = llParseString2List(message, ["|"], []);
                vector newpos = (vector)llList2String(params, 0) - llGetPos();
                newpos = newpos / llGetRot();
                integer slotsindex = index * stride;
                rotation newrot = (rotation)llList2String(params, 1) / llGetRot();
                slots = llListReplaceList(slots, [newpos, newrot], slotsindex + 1, slotsindex + 2);
                llRegionSayTo(ownerinit, 0, "\nANIM|" + llList2String(slots, slotsindex) + "|" + (string)newpos + "|" +
                    (string)(llRot2Euler(newrot) * RAD_TO_DEG) + "|" + llList2String(slots, slotsindex + 3));
                llMessageLinked(LINK_SET, seatupdate, llDumpList2String(slots, "^"), NULL_KEY);
            }
        }else{
            if (llGetOwnerKey(id) == ownerinit){
                if (message == "ping"){
                    llSay(chatchannel, "pong");
                }else if (llGetSubString(message,0,8) == "PROPRELAY"){
                        list msg = llParseString2List(message, ["|"], []);
                    llMessageLinked(LINK_SET,llList2Integer(msg,1),llList2String(msg,2),llList2Key(msg,3));
                }else{
                    list params = llParseString2List(message, ["|"], []);
                    vector newpos = (vector)llList2String(params, 0) - llGetPos();
                    newpos = newpos / llGetRot();
                    rotation newrot = (rotation)llList2String(params, 1) / llGetRot();
                    llRegionSayTo(ownerinit, 0, "\nPROP|" + name + "|" + (string)newpos + "|" + (string)(llRot2Euler(newrot) * RAD_TO_DEG));
                    llMessageLinked(LINK_SET, slotupdate, "PROP|" + name + "|" + (string)newpos + "|" +
                        (string)(llRot2Euler(newrot) * RAD_TO_DEG), NULL_KEY); 

                }
            }
        }
    }

    dataserver(key id, string data){
        if (id == dataid){
            if (data == EOF){
                assignSlots();
                if (rezadjusters){
                    adjusters = [];
                    RezNextAdjuster();
                }
            }else{
                ProcessLine(data, clicker);
                line++;
                dataid = llGetNotecardLine(card, line);
            }
        }else if (id == btnid){
            if (data != EOF){
                ProcessLine(data, clicker);
                btnline++;
                btnid = llGetNotecardLine(btncard, btnline);
            }
        }
    }

    changed(integer change){
        if (change & CHANGED_LINK){
            lastPrimCount = curPrimCount;
            curPrimCount = llGetNumberOfPrims();
            assignSlots();
        }
        if (change & CHANGED_INVENTORY){
            if (card != ""){
                if (llGetInventoryType(card) == INVENTORY_NOTECARD){
                    if (cardid != llGetInventoryKey(card)){
                        ReadCard();
                    }
                }else{
                        llResetScript();
                }
            }else{
                llResetScript();
            }
        }
        if (change & CHANGED_REGION){
            llMessageLinked(LINK_SET, seatupdate, llDumpList2String(slots, "^"), NULL_KEY);
        }
        if (change & CHANGED_OWNER ){
            ownerinit = llGetOwner();
        }
    }

    on_rez(integer param){
        ownerinit = llGetOwner();
        curPrimCount = llGetNumberOfPrims();
        for (n=0; n<=curPrimCount; ++n){
           llLinkSitTarget(n,<0.0,0.0,0.5>,ZERO_ROTATION);
        }
        llResetScript();
    }
}
