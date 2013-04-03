list dialogids;
integer DIALOG_TIMEOUT = -902;
integer DIALOG_RESPONSE = -901;
integer DIALOG = -900;
integer stride = 3;
integer RLVchannel=-1812221819;
integer sensorStart = -233;
integer sensorEnd = -234;
integer attemptCapture = -235;
integer sendVicList = -236;
integer listener;
string cmd;
string path;
string ping;
key victim;
integer victimLink;
key toucherid;
string restraints = "";
integer memusage = 34334;
list tempvictims = [];
list victims;//2 strided list in form of name,key used to create menu of people to grab, and process responses.
list avs = [];
integer range = 8; //sensor range to find potential capture victims
integer seatedCount = 0;
key tempvic;

string str_replace(string src, string from, string to){
    integer len = (~-(llStringLength(from)));
    if(~len){
        string  buffer = src;
        integer b_pos = -1;
        integer to_len = (~-(llStringLength(to)));
        @loop;
        integer to_pos = ~llSubStringIndex(buffer, from);
        if(to_pos){
            buffer = llGetSubString(src = llInsertString(llDeleteSubString(src, b_pos -= to_pos, b_pos + len), b_pos, to), (-~(b_pos += to_len)), 0x8000);
            jump loop;
        }
    }
    return src;
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

integer AvCount(){ //same as SeatedAvs except doesn't return the list of keys, just the count
    integer stop = llGetNumberOfPrims();
    integer n = stop;
    while (llGetAgentSize(llGetLinkKey(n)) != ZERO_VECTOR){
        n--;
    }
    return stop - n;
}

default
{
    state_entry()
    {
        cmd = (string)llGetKey();
        ping = "ping," + cmd + ",ping,ping";
        listener = llListen(RLVchannel, "", NULL_KEY, ping);//listen for pings
    }

    link_message(integer sender, integer num, string str, key id){
        toucherid = id;
        list params = llParseString2List(str, [","], []);
        string commandlist = llList2String(params,1);
        if (num == RLVchannel){
            if (llList2String(params,0) == "release"){
                victim = (key)llList2String(params,1);
                llSay(RLVchannel, cmd+","+(string)victim + ",@clear");
                victim = NULL_KEY;
//                llInstantMessage(victim, "Your restraints have been removed!");
//                llUnSit(victim);
            }else if (llList2String(params,0) == "RlVcommand"){
                restraints = str_replace(commandlist,"/","|");
//                llSay(0, (string)restraints);
                llSay(RLVchannel, cmd+","+(string)victim + "," + restraints);
            }else if (llList2String(params,2) == "grab"){
                victim = (key)llList2String(params,1);
                if (llListFindList(SeatedAvs(), [victim])!=-1){
                    victims += [llKey2Name(victim), victim];//add them to victims list
                    tempvictims = [];//clear the tempvictim list.. we done
                    llMessageLinked(LINK_SET, sendVicList-1, victim, "");
                    llMessageLinked(LINK_SET, sendVicList-2, llList2CSV(victims), "");
                }else{
                    llSay(RLVchannel, cmd + "," + (string)victim + "," + "@sit:" + cmd + "=force");
                }
            }
//            llSay(0, "current victim at relay="+llKey2Name(victim));
        }else if (num == sensorStart){//menu asking for a list of potential victims
            llSensor("", NULL_KEY, AGENT, range, PI);
        }else if (num == DIALOG_RESPONSE){
            list params = llParseString2List(str, ["|"], []);  //parse the message
            string selection = llList2String(params, 1);  //get the button that was pressed from str
            integer index = llListFindList(tempvictims, [selection]);
            if (index != -1){
                llMessageLinked(LINK_SET, RLVchannel, cmd+","+llList2String(tempvictims, index+1)+",grab", "");
                llSetTimerEvent(30.0);
            }
        }else if (num == sendVicList-3){
            integer index = llListFindList(victims, [str]);
            victim = llList2Key(victims, index+1);
        }else if (num == memusage){
            llSay(0,"Memory Used by " + llGetScriptName() + ": " + (string)llGetUsedMemory() + " of " + (string)llGetMemoryLimit()
                 + ", Leaving " + (string)llGetFreeMemory() + " memory free.");
        }
        if ((num==-390390) && (str=="RUThere")){
            llMessageLinked(LINK_SET, -390391, "IAmHere", "");
        }
    }
    listen(integer channel, string name, key id, string message)
    {
        llListenRemove(listener);
        if (channel == RLVchannel){
            if (message == ping){
                //pong if no one sat
                string pong = "ping," + (string)llGetOwnerKey(id) + ",!pong";
                llSay(RLVchannel, pong);
            }
        }else if (channel == sendVicList-4){
            if (llAvatarOnSitTarget()==tempvic){
                llMessageLinked(LINK_SET, RLVchannel, cmd+","+(string)tempvic+",grab", "");
                tempvic = NULL_KEY;
                tempvictims = [];
            }
        }
    }

    sensor(integer num){
        //give menu the list of potential victims
        list victimsbuttons = [];
        tempvictims = [];
        integer n;
        for(n=0;n<num;n++){
            victimsbuttons = victimsbuttons + [llGetSubString(llDetectedName(n), 0, 20)]; 
            tempvictims = tempvictims + [llGetSubString(llDetectedName(n), 0, 20), llDetectedKey(n)];
        }
        llMessageLinked(LINK_SET, sensorEnd, llList2CSV(victimsbuttons), "");
        llMessageLinked(LINK_SET, sendVicList, llList2CSV(tempvictims), "");
    }
    
    no_sensor(){
        list victimsbuttons = [];
        tempvictims = [];
        llMessageLinked(LINK_SET, sensorEnd, llList2CSV(victimsbuttons), "");
    }
    
    timer(){
        //wait 30 seconds and then clear out the tempvictims list. this will effectively disable grabbing someone else if intended victim didn't sit
        //possible reason: no RLV relay so they don't get grabbed,
        tempvictims = [];
        if (llListFindList(SeatedAvs(), [victim])==-1){
            victim=NULL_KEY;
        }
        llSetTimerEvent(0.0);
    }

    changed(integer change){
        if (change & CHANGED_OWNER){
            llResetScript();
        }
        avs = SeatedAvs();
        if (change & CHANGED_LINK && (AvCount()>0)){
            //need to determine if we have a new sitter and if new sitter is our intended victim.
            //if so, add them to victims list.  linkmessage receiver already set intended victim to active victim.
            //send update to menu of victims list and active victim name for menu usage only
            integer n = llListFindList(avs, [victim]);
            if ((llList2Key(avs, n) == victim) && (llListFindList(victims, [victim]) == -1)){
                llSay(RLVchannel, cmd + "," + (string)victim + "," + restraints);//do restraints
                llInstantMessage(victim, "You have been captured!");//let them know they have been captured
                victims += [llKey2Name(victim), victim];//add them to victims list
                tempvictims = [];//clear the tempvictim list.. we done
//                llMessageLinked(LINK_SET, sendVicList-1, victim, "");
//                llMessageLinked(LINK_SET, sendVicList-2, llList2CSV(victims), "");
            }
        }
        //then: if someone stands and they are in victims list, release them and remove them from victims list and active victim if they are.
        integer stop = llGetListLength(victims)/2;
        integer n;
        for (n = 0; n < stop; ++n){
            key thisSeatedAV = llList2Key(victims, (n*2)+1);
            integer index = llListFindList(avs, [thisSeatedAV]);
            if (index == -1){
                llMessageLinked(LINK_SET, RLVchannel, "release,"+(string)thisSeatedAV, "");
                victims = llDeleteSubList(victims, n*2, (n*2)+1);
                if (llListFindList(victims, [victim]) == -1){
                    victim = "";
                }
            }
        }
        llMessageLinked(LINK_SET, sendVicList-1, victim, "");
        llMessageLinked(LINK_SET, sendVicList-2, llList2CSV(victims), "");
        seatedCount = AvCount();
    }
    on_rez(integer param){
        cmd = (string)llGetKey();
        llMessageLinked(LINK_SET, -390390, "RUThere", "");
    }
}
