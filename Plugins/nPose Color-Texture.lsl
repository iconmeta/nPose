
list savedParms;
integer arbNum = -22452987;
integer DOPOSE = 200;
integer CORERELAY = 300;


manageStrideList(vector col, integer sideNo, string str, key texture){
    integer d = llListFindList(savedParms,[str]);
    if (d != -1)  {
        savedParms = llDeleteSubList(savedParms, d - 2, d + 1);
    }
    savedParms = [col,sideNo,str,texture] + savedParms;
}
integer fncStrideCount(list lstSource, integer intStride){
  return llGetListLength(lstSource) / intStride;
}
list fncGetStride(list lstSource, integer intIndex, integer intStride){
  integer intNumStrides = fncStrideCount(lstSource, intStride);
  if (intNumStrides != 0 && intIndex < intNumStrides)
  {
    integer intOffset = intIndex * intStride;
    return llList2List(lstSource, intOffset, intOffset + (intStride - 1));
  }
  return [];
}


default
{
    link_message(integer sender_num, integer num, string str, key id){
        
         if (num==arbNum){
            list params = llParseString2List(str, ["~"], []);
            integer sides = (integer)llList2String(params, 1);
            string textureWho = llList2String(params, 2);
            vector color = (vector)llList2String(params, 0);
            manageStrideList(color,sides,textureWho,id);
        }
        if (num==arbNum || num == arbNum+1){
            llRegionSay(num, "LINKMSG|"+(string)num+"|"+str+"|"+(string)id);
            if (llGetInventoryNumber(INVENTORY_TEXTURE)>0){
                integer i;
                for(; i<llGetInventoryNumber(INVENTORY_TEXTURE); ++i){
                    if (llGetInventoryName(INVENTORY_TEXTURE, i) == (string)id){
                        id = llGetInventoryKey(llGetInventoryName(INVENTORY_TEXTURE, i));
                    }
                }
            }
            list params = llParseString2List(str, ["~"], []);
            integer sides = (integer)llList2String(params, 1);
            string textureWho = llList2String(params, 2);
            vector color = (vector)llList2String(params, 0);
            integer n;
            integer linkcount = llGetNumberOfPrims();
            for (n = 1; n <= linkcount; n++) {
                if (linkcount > 1) {
                    string desc = (string)llGetObjectDetails(llGetLinkKey(n), [OBJECT_DESC]);
                    list params1 = llParseString2List(desc, ["~"], []);
                    if (llList2String(params1, 0) == textureWho){
                        if(id != ""){
                            llSetLinkTexture(n, id, sides);
                        }
                        llSetLinkColor(n, color, sides);
                    }
                }
                else {
                    string desc = (string)llGetObjectDetails(llGetKey(), [OBJECT_DESC]);
                    list params1 = llParseString2List(desc, ["~"], []);
                    if (llList2String(params1, 0) == textureWho){
                        if(id != ""){
                            llSetTexture(id, sides);
                        }
                        llSetColor(color, sides);
                    }
                }

            }
        }
        if (num == DOPOSE)
        {
            integer stridesNo = llGetListLength(savedParms)/4;
            integer a;
            for (a = 0; a <= stridesNo-1; a++){
                list thisSet = fncGetStride(savedParms, a, 4);
                vector color = (vector)llList2String(thisSet, 0);
                integer sides = (integer)llList2String(thisSet, 1);
                string textureWho = llList2String(thisSet, 2);
                key savedid = (key)llList2String(thisSet,3);
                string myString = (string)color+"~"+(string)sides+"~"+textureWho;
                llSleep(5);
                llMessageLinked(LINK_SET,CORERELAY,llDumpList2String([(arbNum+1), myString,savedid],"|"),NULL_KEY);
            }
        }
    }
 }

