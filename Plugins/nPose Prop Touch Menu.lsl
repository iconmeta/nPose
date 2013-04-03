//start_unprocessed_text
/*integer chatchannel;
string ROOTMENU = "Main";
integer DOMENU_ACCESSCTRL = -801;
default
{
    on_rez(integer param)
    {
        chatchannel = param;
    }
    
    state_entry()
    {
/|/        llSay(0, "Hello, Avatar!");
    }

    touch_start(integer total_number)
    {
        key toucher = llDetectedKey(0);
        /|/ Relay any linkmessages from local prop plugins, back to the base object
        llWhisper(chatchannel,llDumpList2String(["PROPRELAY",DOMENU_ACCESSCTRL,ROOTMENU,toucher], "|"));
    }
}*/
//end_unprocessed_text
//nfo_preprocessor_version 0
//program_version Phoenix Viewer 1.5.2.1185 - Colin Druart
//mono


integer chatchannel;
string ROOTMENU = "Main";
integer DOMENU_ACCESSCTRL = -801;

default
{
    on_rez(integer param)
    {
        chatchannel = param;
    }
    
    state_entry()
    {

    }

    touch_start(integer total_number)
    {
        key toucher = llDetectedKey(0);
        
        llWhisper(chatchannel,llDumpList2String(["PROPRELAY",DOMENU_ACCESSCTRL,ROOTMENU,toucher], "|"));
    }
}
