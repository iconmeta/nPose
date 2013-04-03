//to have prop explicitly die, send propname=die in notecard parm spot #2
// PROP|propname|propname=die

float timeout = 10.0;
rotation rot;
vector pos;
key parent = NULL_KEY;
integer chatchannel;
integer dietimeout;
integer timeoutticker =0;
string lifetime;
//string timeToLive;



string timeToLive()
{
    string desc = (string)llGetObjectDetails(llGetKey(), [OBJECT_DESC]);
    //prim desc will be elementtype~notexture(maybe)
    list params = llParseString2List(desc, ["~"], []);
    integer n;
    integer stop = llGetListLength(params);
    for (n=0; n<stop; n++)
    {
        list param = llParseString2List(llList2String(params,n), ["="], []);
        if (llList2String(param,0) == "lifetime")
        {
            lifetime = llList2String(param, 1);
        }
    }
    if (lifetime =="" || lifetime == "0")
    {
        return "0";
    }
    else
    {
        return lifetime;
    }
}

default
{
    on_rez(integer param)
    {
        parent = NULL_KEY;
        if (param)
        {
            pos = llGetPos();
            rot = llGetRot();
            chatchannel = param;
            dietimeout = (integer)timeToLive();
            llListen(chatchannel, "", "", "");
            llSetTimerEvent(timeout);
            llSay(chatchannel, "ping");
        }
        else
        {
            llSetTimerEvent(0.0);
        }
    }

    listen(integer channel, string name, key id, string message)
    {
        
        list msg = llParseString2List(message, ["|"], []);
        string cmd = llList2String(msg,0);
        list params1 = llParseString2List(cmd, ["="],[]);
        if ((llList2String(params1,0) == llGetObjectName()) && (llList2String(params1,1) == "die"))
        {
            llDie();
        }          
        if (llGetOwnerKey(id) == llGetOwner())
        {
            if (cmd == "posdump")
            {
                string out = (string)pos + "|" + (string)rot;
                llSay(chatchannel, out);                
            }
            else if (cmd == "pong")
            {
                if (parent == NULL_KEY)
                {
                    parent = id;
                }
            }
            else if (cmd == "LINKMSG")
            {
                llMessageLinked(LINK_SET,(integer)llList2String(msg,1),llList2String(msg,2),(key)llList2String(msg,3));
            }
        }
    }

    timer()
    {
        timeoutticker = timeoutticker+10;
        if (parent != NULL_KEY)
        {
            if (dietimeout !=0)
            {
                if (llKey2Name(parent) == "" || timeoutticker >= dietimeout)
                {
                    
                    llDie();
                }
            }
            else if (llKey2Name(parent) == "")
            {
                
                llDie();
            }
        }
        
        integer chat_out = FALSE;
        if (llGetPos() != pos)
        {
            pos = llGetPos();
            chat_out = TRUE;
        }
        
        if (llGetRot() != rot)
        {
            rot = llGetRot();
            chat_out = TRUE;
        }
        
        if (chat_out)
        {
            string out = (string)pos + "|" + (string)rot;
            llSay(chatchannel, out);
        }
    }
}
