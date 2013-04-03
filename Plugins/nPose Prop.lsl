/*
The nPose scripts are licensed under the GPLv2 (http://www.gnu.org/licenses/gpl-2.0.txt), with the following addendum:

The nPose scripts are free to be copied, modified, and redistributed, subject to the following conditions:
    - If you distribute the nPose scripts, you must leave them full perms.
    - If you modify the nPose scripts and distribute the modifications, you must also make your modifications full perms.

"Full perms" means having the modify, copy, and transfer permissions enabled in Second Life and/or other virtual world platforms derived from Second Life (such as OpenSim).  If the platform should allow more fine-grained permissions, then "full perms" will mean the most permissive possible set of permissions allowed by the platform.
*/
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
        
        if (llGetOwnerKey(id) == llGetOwner())
        {
            list msg = llParseString2List(message, ["|"], []);
            string cmd = llList2String(msg,0);
            if (cmd == "die")
            {
                llDie();
            }          
            else if (cmd == "posdump")
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

