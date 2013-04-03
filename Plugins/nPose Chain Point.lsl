/*
The nPose scripts are licensed under the GPLv2 (http://www.gnu.org/licenses/gpl-2.0.txt), with the following addendum:

The nPose scripts are free to be copied, modified, and redistributed, subject to the following conditions:
    - If you distribute the nPose scripts, you must leave them full perms.
    - If you modify the nPose scripts and distribute the modifications, you must also make your modifications full perms.

"Full perms" means having the modify, copy, and transfer permissions enabled in Second Life and/or other virtual world platforms derived from Second Life (such as OpenSim).  If the platform should allow more fine-grained permissions, then "full perms" will mean the most permissive possible set of permissions allowed by the platform.
*/

string sourcename;
vector scale = <0.07,0.07,0>;
vector gravity = <0,0,-0.5>;
string destname;
key av;
float age = 2.0;
integer STOPCHAIN = 7201;
integer STARTCHAIN = 7200;
integer DOPOSE = 200;


DoParticles(key dest)
{
    llParticleSystem( [
        PSYS_SRC_TARGET_KEY, dest,    
        PSYS_PART_START_SCALE, scale,
        PSYS_PART_MAX_AGE, age,
        PSYS_SRC_ACCEL, gravity,        

        PSYS_SRC_TEXTURE,"40809979-b6be-2b42-e915-254ccd8d9a08", 
        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_DROP,        
        PSYS_SRC_BURST_PART_COUNT,1,
        PSYS_SRC_BURST_RATE,0.0,
        PSYS_PART_FLAGS,
            PSYS_PART_FOLLOW_VELOCITY_MASK |
            PSYS_PART_FOLLOW_SRC_MASK |
            PSYS_PART_TARGET_POS_MASK
    ] );    
}


default
{
    state_entry()
    {
        sourcename = llGetObjectDesc();
    }

    on_rez(integer param)
    {
        llResetScript();
    }
    
    link_message(integer sender, integer num, string str, key id)
    {
        if (num == STARTCHAIN)
        {
            list chains = llParseString2List(str, ["~"], []);
            integer index = llListFindList(chains, [sourcename]);
            if (index != -1)
            {           
                av = id;
                destname = llList2String(chains, index + 1);
                
                llListen(-8888, "", NULL_KEY, "");
                llWhisper(-8888, (string)av + destname);                
            }
        }
        else if (num == STOPCHAIN)
        {
            list chains = llParseString2List(str, ["~"], []);
            integer index = llListFindList(chains, [sourcename]);
            if (index != -1)
            {
                llParticleSystem([]);
                llResetScript();
            }            
        }
        else if (num == DOPOSE)
        {
            llParticleSystem([]);
            llResetScript();            
        }
    }
    
    listen(integer channel, string name, key id, string message)
    {
        if (channel == -8888)
        {
            if (message == (string)av + destname + " ok")
            {
                
                DoParticles(id);
            }
        }
    }
}

