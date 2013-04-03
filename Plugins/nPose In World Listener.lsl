integer listenChannel = -22452987;

default
{
    state_entry()
    {
        llListen(listenChannel, "", NULL_KEY, "");
    }

    listen(integer channel, string name, key id, string message)
    {
        if (llGetOwnerKey(id) == llGetOwner())
        {
            if (channel == listenChannel){
                list msg = llParseString2List(message, ["|"], []);
                string cmd = llList2String(msg,0);
                string strOut = llList2String(msg, 2);
                key idOut = (key)llList2String(msg,3);
                if (cmd == "LINKMSG")
                {
                    llMessageLinked(LINK_SET, channel, strOut, idOut);
                }
            }
        }
    }
}
