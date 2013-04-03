/*
The nPose scripts are licensed under the GPLv2 (http://www.gnu.org/licenses/gpl-2.0.txt), with the following addendum:

The nPose scripts are free to be copied, modified, and redistributed, subject to the following conditions:
    - If you distribute the nPose scripts, you must leave them full perms.
    - If you modify the nPose scripts and distribute the modifications, you must also make your modifications full perms.

"Full perms" means having the modify, copy, and transfer permissions enabled in Second Life and/or other virtual world platforms derived from Second Life (such as OpenSim).  If the platform should allow more fine-grained permissions, then "full perms" will mean the most permissive possible set of permissions allowed by the platform.
*/
string currentanim;
list lastanim;
integer facecount;
integer faceindex;
list faceanims;
integer doingFaceAnim = 0;
integer gotFaceAnim = 0;
integer animcount;
integer SYNC = 206;
integer doSync = 0;
integer ADJUSTOFFSET = 208;
integer SETOFFSET = 209;
integer ticker;
float syncsleep = 0.05;
integer primcount;
integer newprimcount;
string lastAnimRunning;
integer seatcount;
integer nextAvatarOffset;
integer avatarOffsetsLength = 20;
list avatarOffsets;
integer stride = 8;

integer seatupdate = 35353;
integer memusage = 34334;
list seatAndAv;
list AVkeys;
integer permissions = 0;
integer layerPose = -218;
list animsList;
list faceTimes = [];
list slots;
key thisAV;
integer stop;


doSeats(integer slotNum, key avKey){
    if (doSync !=1){
        vector vpos = appliedOffsets(slotNum);
        MoveLinkedAv(AvLinkNum(avKey), vpos, llList2Rot(slots, ((slotNum)*8)+2)); 
    }
    if (avKey != ""){
        doingFaceAnim = 0;
        stop = llGetListLength(slots)/8;
        llRequestPermissions(avKey, PERMISSION_TRIGGER_ANIMATION);
    }
}

list SeatedAvs(){
    list avs;
    integer linkcount = llGetNumberOfPrims();
    integer n;
    for (n = linkcount; n >= 0; n--){
        key id = llGetLinkKey(n);
        if (llGetAgentSize(id) != ZERO_VECTOR){
            avs = [id] + avs;
        }else{
                return avs;
        }
    }
    return [];
}

integer AvLinkNum(key av){
    integer linkcount = llGetNumberOfPrims();
    while (av != llGetLinkKey(linkcount)){
        if (llGetAgentSize(llGetLinkKey(linkcount)) == ZERO_VECTOR){
            return -1;
        }
        linkcount--;
    }
    return linkcount;
}

MoveLinkedAv(integer linknum, vector avpos, rotation avrot){
    key user = llGetLinkKey(linknum);
    if(user){  
        vector size = llGetAgentSize(user);
        if(size){  
            
            rotation localrot = ZERO_ROTATION;
            vector localpos = ZERO_VECTOR;
            if(llGetLinkNumber() > 1){  
                localrot = llGetLocalRot();
                localpos = llGetLocalPos();
            }
            avpos.z += 0.4;
            llSetLinkPrimitiveParamsFast(linknum, [PRIM_POSITION, ((avpos - (llRot2Up(avrot) * size.z * 0.02638)) * localrot) + localpos, PRIM_ROTATION, avrot * localrot / llGetRootRotation()]);
        }
    }    
}


vector appliedOffsets(integer n){
    string slot = llList2String(slots, n*stride + 4);
    integer avinoffsets = llListFindList(avatarOffsets, [(key)slot]);
    rotation rot = llList2Rot(slots, n*stride+2); 
    vector pos = (vector)llList2String(slots, n*stride+1); 
    if (avinoffsets != -1){
        vector offset = llList2Vector(avatarOffsets, avinoffsets+1);
        pos += offset * rot; 
    }
    return pos; 
}

SetAvatarOffset(key avatar, vector offset) { 
    integer avatarOffsetsIndex = llListFindList(avatarOffsets, [avatar]); 
    if (offset == ZERO_VECTOR){
        avatarOffsets = llListReplaceList(avatarOffsets, [avatar, offset], avatarOffsetsIndex, avatarOffsetsIndex+1);
    }
    if (avatarOffsetsIndex < 0) { 
        avatarOffsetsIndex = nextAvatarOffset; 
        nextAvatarOffset = (nextAvatarOffset + 2) % avatarOffsetsLength;
    }else{ 
            offset = llList2Vector(avatarOffsets, avatarOffsetsIndex+1) + offset;
    }
    avatarOffsets = llListReplaceList(avatarOffsets, [avatar, offset], avatarOffsetsIndex, avatarOffsetsIndex+1);
}

default
{
    state_entry()
    {
        primcount = llGetNumberOfPrims();
        newprimcount = primcount;
    }
 
    link_message(integer sender, integer num, string str, key id)
    {
        if (num == layerPose)
        {
            key av;
            list tempList = llParseString2List(str, ["/"], []);
            if (llListFindList(SeatedAvs(), [(key)llList2String(tempList, 0)]) != -1){
                av = (key)llList2String(tempList, 0);
            }else{
                integer seatNum = (integer)llList2String(tempList, 0);
                integer index = llListFindList(seatAndAv, [seatNum]);
                av = (key)llList2String(seatAndAv, index+1);
            }
            if (av)
            {
                llRequestPermissions(av, PERMISSION_TRIGGER_ANIMATION);
                list tempList1 = llParseString2List(llList2String(tempList, 1), ["~"], []);
                integer instruction;
                integer stop = llGetListLength(tempList1);
                for (instruction = 0; instruction < stop; ++instruction){
                    tempList = llParseString2List(llList2String(tempList1, instruction), [","],[]);
                    if (llList2String(tempList,0)=="stopAll"){
                        
                        integer x;
                        integer animsStop = llGetListLength(animsList)/2;
                        for (x = 0; x<animsStop; ++x){
                            llStopAnimation(llList2String(animsList, x*2+1));
                        }
                        animsList = [];
                    }else{
                        
                        integer index = llListFindList(animsList, [llList2String(tempList, 1)]);
                        if (index>=1){
                            animsList = llDeleteSubList(animsList, index-1, index);
                        }
                        animsList += llList2List(tempList, index-1, index);
                    }
                }
                integer n;
                stop = llGetListLength(animsList)/2;
                for (n=0; n<stop; ++n){
                   if (llList2String(animsList, n*2) == "start"){
                        if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION){
                            llStartAnimation(llList2String(animsList, n*2+1));
                        }
                    }else if (llList2String(animsList, n*2) == "stop"){
                        if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION){
                            llStopAnimation(llList2String(animsList, n*2+1));
                            animsList = llDeleteSubList(animsList, n*2, n*2+2);
                            
                            n-=1;
                            stop-=1;
                        }
                    }
                }
            }
        }else if (num == ADJUSTOFFSET) {
            SetAvatarOffset(id, (vector)str);
            llMessageLinked(LINK_SET, seatupdate, llDumpList2String(slots, "^"), NULL_KEY);
        }else if (num == SETOFFSET) {
            SetAvatarOffset(id, (vector)str);
            llMessageLinked(LINK_SET, seatupdate, llDumpList2String(slots, "^"), NULL_KEY);
        }else if (num == seatupdate){
            list seatsavailable = llParseStringKeepNulls(str, ["^"], []);
            integer stop = llGetListLength(seatsavailable)/8;
            seatAndAv = [];
            slots = [];
            faceTimes = [];
            gotFaceAnim = 0;
            string buttonStr = "";
            string faces = "";
            for (seatcount = 1; seatcount <= stop; ++seatcount){
                integer seatNum = (integer)llGetSubString(llList2String(seatsavailable, (seatcount-1)*8+7), 4,-1);
                seatAndAv += [seatNum, llList2String(seatsavailable, (seatcount-1)*8+4),llList2String(seatsavailable, (seatcount-1)*8)];
                slots = slots + [llList2String(seatsavailable, (seatcount-1)*8), (vector)llList2String(seatsavailable, (seatcount-1)*8+1), 
                        (rotation)llList2String(seatsavailable, (seatcount-1)*8+2), llList2String(seatsavailable, (seatcount-1)*8+3), 
                        (key)llList2String(seatsavailable, (seatcount-1)*8+4), llList2String(seatsavailable, (seatcount-1)*8+5),
                        llList2String(seatsavailable, (seatcount-1)*8+6), llList2String(seatsavailable, (seatcount-1)*8+7)];
                //menu needs the list of buttons for 'ChangeSeats'
                if (llList2String(slots, (seatcount-1)*8+4)!=""){
                    buttonStr += llGetSubString(llKey2Name((key)llList2String(seatsavailable, (seatcount-1)*8+4)), 0, 20)+",";
                }else{
                    buttonStr += llList2String(seatsavailable, (seatcount-1)*8+7)+",";
                }
                if (llList2String(seatsavailable, (seatcount-1)*8+3) != ""){
                    //we need a list consisting of sitter key followed by each face anim and the associated time of each
                    //put face anims for this slot in a list
                    list faceanimsTemp = llParseString2List(llList2String(seatsavailable, (seatcount-1)*8+3), ["~"], []); 
                    facecount = llGetListLength(faceanimsTemp);   
                    list faces = []; 
                    integer nFace;
                    integer hasNewFaceTime = 0;
                    for (nFace=0; nFace<facecount; ++nFace){
                        //parse this face anim for anim name and time
                        list temp = llParseString2List(llList2String(faceanimsTemp, nFace), ["="], []);
                        //time must be optional so we will make default a zero
                        //queue on zero to revert to older stuff
                        if (llList2String(temp, 1)){
                            //collect the name of the anim and the time
                            faces += [llList2String(temp, 0), (integer)llList2String(temp, 1)];
                            hasNewFaceTime = 1;
                        }else{
                            faces += [llList2String(temp, 0), -1];
                        }
                    }
                    gotFaceAnim=1;
                    //add sitter key and flag if timer defined followed by a stride 2 list containing face anim name and associated time
                    faceTimes += [(key)llList2String(seatsavailable, (seatcount-1)*8+4), hasNewFaceTime, facecount] + faces;
                }
            }
//            llOwnerSay(llList2CSV(faceTimes));
            llMessageLinked(LINK_SET, seatupdate+1, buttonStr, NULL_KEY);//send list of buttons to the menu
            buttonStr = "";
            //we have our new list of AV's and positions so put them where they belong.  fire off the first seated AV and run time will do the rest.
            for (seatcount = 0; seatcount < stop; ++seatcount){
                if (llList2Key(slots, seatcount*8+4) != ""){
                    doSync = 0;
                    doSeats(seatcount, llList2String(slots, (seatcount)*8+4));
                    return;
                }
            }
        }else if (num == SYNC){
            doSync = 1;
            integer stop = llGetListLength(slots)/8;
            for (seatcount = 0; seatcount < stop; ++seatcount){
                if (llList2Key(slots, seatcount*8+4) != ""){
                    doSeats(seatcount, llList2String(slots, (seatcount)*8+4));
                    return;
                }
            }
        }else if (num == memusage){
            llSay(0,"Memory Used by " + llGetScriptName() + ": " + (string)llGetUsedMemory() + " of " + (string)llGetMemoryLimit()
                 + ",Leaving " + (string)llGetFreeMemory() + " memory free.");
        }
    }
 
    run_time_permissions(integer perm){
        thisAV = llGetPermissionsKey();
//        integer stop = llGetListLength(slots)/8;
        if (doingFaceAnim != 1){
            //get the current requested animation from list seatAndAv.
            integer avIndex = llListFindList(seatAndAv, [(string)thisAV]);
            currentanim = llList2String(seatAndAv, (avIndex+1));
            //look for the default LL 'Sit' animation.  We must stop this animation if it is running. New Sitter!
            list animsRunning = llGetAnimationList(thisAV);
            integer indexx = llListFindList(animsRunning, [(key)"1a5fe8ac-a804-8a5d-7cbd-56bd83184568"]);
            //we also need to know the last animation running.  Not New Sitter!
            //lastanim is a 2 stride list [thisAV, last active animation name]
            //index thisAV as a string in the list and then we can find the last animation.
            integer thisAvIndex = llListFindList(lastanim, [(string)thisAV]);
            if (doSync !=1){
                if (indexx != -1){
                    lastAnimRunning = "Sit";
                    lastanim += [(string)thisAV, "Sit"];
                }
                if (thisAvIndex != -1){
                    lastAnimRunning = llList2String(lastanim, thisAvIndex+1);
                }
                //now we know which animation to stop so go ahead and stop it.
                if (lastAnimRunning != ""){
                    llStopAnimation(lastAnimRunning);
                }
                thisAvIndex = llListFindList(lastanim, [(string)thisAV]);
                //now that we have the name of the last animation running, we can update the list with current animation.
                lastanim = llListReplaceList(lastanim, [(string)thisAV, currentanim], thisAvIndex, thisAvIndex+1);
        //            debug("starting " + currentanim);
                if (avIndex != -1){
                    llStartAnimation(currentanim);
                }
            }else{
                llStopAnimation(currentanim);
                llStartAnimation("sit");
                llSleep(syncsleep);
                llStopAnimation("sit");
                llStartAnimation(currentanim);
            }
        }
        //start timer if we have face anims for any slot
        if (gotFaceAnim==1){
            llSetTimerEvent(1.0);
            doingFaceAnim=1;
        }else{
            llSetTimerEvent(0.0);
            doingFaceAnim=0;
        }
        //check all the slots for next seated AV, call for next seated AV to move and animate.
        for (; seatcount < stop-1; ){
            seatcount += 1;
            if (llList2Key(slots, seatcount*8+4) != ""){
                doSeats(seatcount, llList2String(slots, (seatcount)*8+4));
                return;
            }
//            return;
        }
    }

    timer(){        
        integer n;
        integer stop = llGetListLength(slots)/8;
        key av;
        for (n=0; n<stop; ++n){
            //doing each seat
            av = (key)llList2String(slots, n*8+4);
            faceindex = 0;
            //locate our stride in faceTimes list
            integer keyHasFacial = llListFindList(faceTimes, [av]);
            //get number of face anims for this seat
            integer newFaceTimeFlag = llList2Integer(faceTimes, keyHasFacial+1);
            
            if (newFaceTimeFlag == 0){
            //need to know if someone seated in this seat, if not we won't do any facials
                if (av != ""){
                    faceanims = llParseString2List(llList2String(slots, n*8+3), ["~"], []);     
                    facecount = llGetListLength(faceanims);                
                    if (facecount > 0){
                        doingFaceAnim=1;
                        thisAV = llGetPermissionsKey();
                        llRequestPermissions(av, PERMISSION_TRIGGER_ANIMATION);
                    }
                }
                integer x;
                for (x=0; x<facecount; ++x){
                    if (facecount>0){
                        if (faceindex < facecount){
                            if (AvLinkNum(av) != -1){
                                llStartAnimation(llList2String(faceanims, faceindex));
                            }
                        }            
                        faceindex++;
                    }
                }
            }else if (av != ""){
            //need to know if someone seated in this seat, if not we won't do any facials
            //do our stuff with defined facial times
                facecount = llList2Integer(faceTimes, keyHasFacial+2);                
                //if we have facial anims make sure we have permissions for this av
                if (facecount > 0){
                    doingFaceAnim=1;
                    thisAV = llGetPermissionsKey();
                    llRequestPermissions(av, PERMISSION_TRIGGER_ANIMATION);
                }
                    integer x;
                for (x=1; x<=facecount; ++x){
                    //non looping we check if anim has run long enough
                    if (faceindex < facecount){
                        integer faceStride = keyHasFacial+1+(x*2);
                        string animName = llList2String(faceTimes, faceStride);
                        if (llList2Integer(faceTimes, faceStride+1) > 0){
                            faceTimes = llListReplaceList(faceTimes, [llList2Integer(faceTimes, faceStride+1)-1],
                             faceStride+1, faceStride+1);
                        }
                        if (facecount>0){
                            if (AvLinkNum(av) != -1 && llList2Integer(faceTimes, faceStride+1) > 0){
                                llStartAnimation(animName);
                            }else if (AvLinkNum(av) != -1 && llList2Integer(faceTimes, faceStride+1) == -1){
                                llStartAnimation(animName);
                            }
                            faceindex++;
                        }
                    }
                }
            
            }
        }
        if (llGetListLength(SeatedAvs())<1){
            llSetTimerEvent(0.0);
            doingFaceAnim=0;
        }
    }

    changed(integer change){
        if (change & CHANGED_LINK){
            animsList=[]; 
            integer newPrimCount1 = llGetNumberOfPrims();
            if (newprimcount>newPrimCount1){
                //we have lost a sitter so find out who and remove them from the list.
                integer n;
                integer stop = llGetListLength(lastanim)/2;
                for (n=0; n<stop; ++n){
                    if (AvLinkNum((key)llList2String(lastanim, n*2)) == -1){
                        lastanim = llDeleteSubList(lastanim, n*2, n*2+1);
                    }
                }
            }
            newprimcount = newPrimCount1;
            if (newprimcount == primcount){
                //no AV's seated so clear the lastanim list.  done so we can detect LL's default Sit when reseating.
                lastanim = [];
                currentanim = "";
                lastAnimRunning = "";
//                llResetScript();
//                llReleaseControls();  
            }
        }else if (change & CHANGED_OWNER){
            llResetScript();
        }
    }
}
