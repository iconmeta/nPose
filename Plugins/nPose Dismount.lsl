

integer seatupdate = 35353;
list seatAndAv;
integer dismount = -221;

list SeatedAvs(){ //returns the list of uuid's of seated AVs
    list avs=[];
    integer counter = llGetNumberOfPrims();
    while (llGetAgentSize(llGetLinkKey(counter)) != ZERO_VECTOR){
        avs += [llGetLinkKey(counter)];
        counter--;
    }    
    return avs;
}

default
{
    state_entry()
    {
    }

    link_message(integer sender_num, integer num, string str, key id){
        if (num == dismount){
            list tempList = llParseStringKeepNulls(str, ["~"], []);
            integer sitters = llGetListLength(tempList);
            integer n;
            llSleep(1.5);
            for (n=0; n<sitters; ++n){
                if (llListFindList(SeatedAvs(), [(key)llList2String(seatAndAv, (n * 2) + 1)]) != -1){
                    llUnSit((key)llList2String(seatAndAv, (n * 2) + 1));
                }
            }
        }else if (num == seatupdate){
            integer seatcount;
            list seatsavailable = llParseStringKeepNulls(str, ["^"], []);
            integer stop = llGetListLength(seatsavailable)/8;
            seatAndAv = [];
           for (seatcount = 1; seatcount <= stop; ++seatcount){
               integer seatNum = (integer)llGetSubString(llList2String(seatsavailable, (seatcount-1)*8), 4,-1);
                seatAndAv += [seatNum, llList2String(seatsavailable, (seatcount-1)*8+4)];
            }
        }
    }
}

