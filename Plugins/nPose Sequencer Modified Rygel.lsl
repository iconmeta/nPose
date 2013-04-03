//start_unprocessed_text
/*/|/ nPose Simple Sequencer - by Rygel Ryba
/|/ --------------------------------------


list whosOn = [NULL_KEY,NULL_KEY,NULL_KEY,NULL_KEY]; /|/IMPORTANT: Add list entries here for EACH possible sitter on your object for example - if you have 4-Some animations, you need to make it [NULL_KEY,NULL_KEY,NULL_KEY,NULL_KEY]


/|/ Nothing really fancy here - just drop this in a seperate prim from the main nPose scripts (normal Link Messages from nPose remenu now, so it can't work in the same prim.) Make sure your main nPOse scripts are NOT in the root prim of your bed/object or you might get menu confusion as well. 



integer touchable = FALSE; /|/Change to "FALSE" if nPose updates with a way to block re-menu in link messages.

integer MENU_LINK = -123; /|/If nPose allows a link with no re-menu some day, you can change this to whatever number you want to use and it will trigger a menu from that command (and you can turn off the "touchable" above. nPose will also need to be able to pass the toucher ID rather than a predefined key for this to work - so this might not ever be functional - but I wanted to add it just so it's here.)

string cardPrefix = "SEQ"; /|/ Cards should be "SEQ:ButtonText"

integer debug = FALSE; /|/If True - it'll spit out some info when it reads notecard lines.

integer isPaused = FALSE;
integer isRunning = FALSE;

key kQuery;
integer iLine = 0;

float posePause = 0.0;
string poseSet;
string loadedCard;
integer loopTo = 0;

string msg = "Please make a choice.";

list DIALOG_CHOICES = [];
 
integer channel_dialog;
integer listen_id;
key ToucherID;
 
/|/if not offering a back button, there are 3 things to change:
/|/MAX_DIALOG_CHOICES_PER_PG, and 2 code lines in the giveDialog function.
/|/It is noted in the function exactly where and how to change these.
 
 
integer N_DIALOG_CHOICES;
integer MAX_DIALOG_CHOICES_PER_PG = 8; /|/ if not offering back button, increase this to 9
string PREV_PG_DIALOG_PREFIX = "< Page ";
string NEXT_PG_DIALOG_PREFIX = "> Page ";
string DIALOG_DONE_BTN = "Done";
string DIALOG_STOP_BTN = "Stop";
string DIALOG_RESUME_BTN = " ";
string SlideShowCurrent;
integer pageNum;




loadCards(){
    
    /|/Note: This will not account for submenus or anything like that. All sequences are in the same menu. 
    DIALOG_CHOICES = [];
    integer a = 0;
    integer b = llGetInventoryNumber(INVENTORY_NOTECARD);
    for(; a < b; ++a){
        string cardName = llGetInventoryName(INVENTORY_NOTECARD,a);
        list cardParts = llParseString2List(cardName,[":"],[]);
        if (llList2String(cardParts,0) == cardPrefix){
            DIALOG_CHOICES = DIALOG_CHOICES + [llList2String(cardParts,1)];
        }  
    }
}
 
giveDialog(key ID, integer pageNum) {
    list buttons;
    integer firstChoice;
    integer lastChoice;
    integer prevPage;
    integer nextPage;
    string OnePage;
    N_DIALOG_CHOICES = llGetListLength(DIALOG_CHOICES);
    if (N_DIALOG_CHOICES <= 10) {
        buttons = DIALOG_CHOICES;
        OnePage = "Yes";
    }else {
        integer nPages = (N_DIALOG_CHOICES+MAX_DIALOG_CHOICES_PER_PG-1)/MAX_DIALOG_CHOICES_PER_PG;
        if (pageNum < 1 || pageNum > nPages) {
            pageNum = 1;
        }
        integer firstChoice = (pageNum-1)*MAX_DIALOG_CHOICES_PER_PG;
        integer lastChoice = firstChoice+MAX_DIALOG_CHOICES_PER_PG-1;
        if (lastChoice >= N_DIALOG_CHOICES) {
            lastChoice = N_DIALOG_CHOICES;
        }
        if (pageNum <= 1) {
            prevPage = nPages;
            nextPage = 2;
        }else if (pageNum >= nPages) {
            prevPage = nPages-1;
            nextPage = 1;
        }else {
            prevPage = pageNum-1;
            nextPage = pageNum+1;
        }
        buttons = llList2List(DIALOG_CHOICES, firstChoice, lastChoice);
    }
    /|/ FYI, this puts the navigation button row first, so it is always at the bottom of the dialog
        list buttons01 = llList2List(buttons, 0, 2);
        list buttons02 = llList2List(buttons, 3, 5);
        list buttons03 = llList2List(buttons, 6, 8);
        list buttons04;
        if (OnePage == "Yes") {
            buttons04 = llList2List(buttons, 9, 11);
        }
        buttons = buttons04 + buttons03 + buttons02 + buttons01;
        if (OnePage == "Yes") {
             buttons = [ DIALOG_DONE_BTN, DIALOG_STOP_BTN, DIALOG_RESUME_BTN ]+ buttons;
            /|/omit DIALOG_STOP_BTN in line above  if not offering
        }else {
            buttons =
            (buttons=[])+
            [ PREV_PG_DIALOG_PREFIX+(string)prevPage,
            DIALOG_STOP_BTN, NEXT_PG_DIALOG_PREFIX+(string)nextPage, DIALOG_DONE_BTN
            ]+buttons;
           /|/omit DIALOG_STOP_BTN in line above if not offering
        }
        llDialog(ID, "Page "+(string)pageNum+"\nChoose one:", buttons, channel_dialog);
}
 
 
CancelListen() {
    llListenRemove(listen_id);
    /|/llSetTimerEvent(0);
}
 
default{
  state_entry() {
    channel_dialog = ( -1 * (integer)("0x"+llGetSubString((string)llGetKey(),-5,-1)) );
    loadCards();
  }
  
  on_rez(integer p){
      llResetScript();    
  }
  
  link_message(integer sNum, integer num, string str, key id){
      if (num == -970){
        CancelListen();
        ToucherID = (key)str;
        listen_id = llListen( channel_dialog, "", ToucherID, "");
        pageNum = 1;
        llSleep(1.0);
        giveDialog(ToucherID, pageNum);
        }
      if (num == MENU_LINK){
        CancelListen();
        ToucherID = id; /|/ as of this writing, you can't pass toucher ID with a link message - so this section may never work properly. If that gets added in future updates, and the remenu bit is turned off, this is in place and "should" work. 
llOwnerSay("touched by "+llKey2Name(id));
        listen_id = llListen( channel_dialog, "", ToucherID, "");
        pageNum = 1;
        giveDialog(ToucherID, pageNum);
      }else if ((num >= 700000) && (num <= 700099)){ /|/ accounts for 100 sitters, more than enough. ;)
            /|/this is a bit kludgy but without scripts in each sit prim, it's really the only way I can figure out how to know when everyone has stood up. We need to know this so we can stop the anims from changing even after the last one is up. 
            /|/if (str != "+") return;
            integer num2 = num - 700000;
            list sitterBlah = llParseString2List(str,["|"],[]);
            whosOn = llListReplaceList(whosOn,[(string)llList2Key(sitterBlah,3)],num2,num2);
            integer allOff = TRUE;
            integer a = 0;
            for(; a < llGetListLength(whosOn); ++a){
                if (llList2Key(whosOn,a) != "") allOff = FALSE;
                if (debug == TRUE) llSay(0,(string)a + " ## " + llList2String(whosOn,a) + " Key for Who's On");   
            }
            if (allOff == TRUE){
                CancelListen();
                isRunning = FALSE;
                isPaused = FALSE;
                iLine = 0;
                llSetTimerEvent(0.0);   
            }
      }
  }
 /|*
  touch_start(integer total_number) {
    if (touchable == TRUE){
        CancelListen();
        ToucherID = llDetectedKey(0);
        listen_id = llListen( channel_dialog, "", ToucherID, "");
        pageNum = 1;
        giveDialog(ToucherID, pageNum);
    }
  }
  *|/
    changed(integer change){
        if (change & CHANGED_INVENTORY){
            loadCards();   
        }
    }
 
 
  listen(integer channel, string name, key id, string choice) {
    /|/here, you need to only:
    /|/1. implement something that happens when the back button is pressed, or omit back button
    /|/2. Go to the else event. That is where any actual choice is. Process that choice.
    if (choice == "-") {
     giveDialog(ToucherID, pageNum); 
    }else if ( choice == DIALOG_DONE_BTN){
        CancelListen();
        return;
    }else if (choice == DIALOG_STOP_BTN) {
        CancelListen();
        isRunning = FALSE;
        isPaused = FALSE;
/|/        iLine = 0;
        llSetTimerEvent(0.0);
    }else if (choice == DIALOG_RESUME_BTN){
        CancelListen();
        isRunning = TRUE;
    }else if (llSubStringIndex(choice, PREV_PG_DIALOG_PREFIX) == 0){
        pageNum =
        (integer)llGetSubString(choice, llStringLength(PREV_PG_DIALOG_PREFIX), -1);
        giveDialog(ToucherID, pageNum);
    }else if (llSubStringIndex(choice, NEXT_PG_DIALOG_PREFIX) == 0) {
        pageNum =
        (integer)llGetSubString(choice, llStringLength(NEXT_PG_DIALOG_PREFIX), -1);
        giveDialog(ToucherID, pageNum);
    }else{ /|/this is the section where you do stuff
        /|/ Just for my own reference to get the variables I need: 
        /|/posePause = 0.0;
        /|/poseSet;
        isRunning = TRUE;
        isPaused = TRUE; /|/ this way if they do the resume button, it'll just start over with the same card.
        iLine = 0;
        loopTo = 0;
        loadedCard = cardPrefix + ":" + choice;
        kQuery = llGetNotecardLine(loadedCard, iLine);
    }
  }
 
  timer()   {
        if (isRunning == TRUE) kQuery = llGetNotecardLine(loadedCard, iLine);
  }
  
    dataserver(key query_id, string data) {
        if (query_id == kQuery) {    
            if (data == EOF) {    
                /|/We reached the end of the card and didn't see a "LOOP" command so we assume it's over and stop.
                isRunning = FALSE;
                isPaused = FALSE;
                llSetTimerEvent(0.0);
                CancelListen();
        
                iLine = 0;
                llSetTimerEvent(0.0);
 
            }else{
 
    /|/NOTCARD LINES ARE THIS:
    /|/Timer|Name of nPose Set Notecard
    /|/ e.g. 60|SET:Sex 1:69 <-- will run the pose from that notecard for 60 seconds and then do the next
    
    /|/Also: 
    /|/LOOPTO will set a point at which the sequence will loop back to. If not found as it runs through, first line will be the LOOPTO point.
    /|/LOOP will tell it to cycle back to the LOOPTO or first line. If not found, sequence will stop at end. 
    
                if (debug == TRUE) llSay(0, "Line " + (string)iLine + ": " + data);   /|/ data has the current line from this notecard
                list thisLine = llParseString2List(data,["|"],[]);
                if (llList2String(thisLine,0) == "LOOPTO"){
                    loopTo = iLine; 
                    posePause = 0.1; /|/Grab the next line quickly.
                }else if (llList2String(thisLine,0) == "LOOP"){
                    iLine = loopTo;
                    if (iLine == 0) iLine = -1; /|/ if it's the first line, go one less for the increment.
                    posePause = 0.1; /|/Grab the next line quickly.
                }
                else{
                    posePause = llList2Float(thisLine,0);
                    llMessageLinked(LINK_SET,200,llList2String(thisLine,1),NULL_KEY);   
/|/                    llMessageLinked(LINK_SET,35353,llList2String(thisLine,1),NULL_KEY);   
                }
                iLine++;   /|/ increment line count
                llSetTimerEvent(posePause);
            }
        }
    }
}
*/
//end_unprocessed_text
//nfo_preprocessor_version 0
//program_version Phoenix Firestorm-Release v4.1.1.28744 - Howard Baxton
//mono


list whosOn = [NULL_KEY,NULL_KEY,NULL_KEY,NULL_KEY];
float posePause = 0.0;
integer pageNum;
integer loopTo = 0;
string loadedCard;
integer listen_id;
key kQuery;
integer isRunning = FALSE;
integer isPaused = FALSE;
integer iLine = 0;
integer debug = FALSE;
integer channel_dialog;
string cardPrefix = "SEQ";
key ToucherID;
string PREV_PG_DIALOG_PREFIX = "< Page ";
integer N_DIALOG_CHOICES;
string NEXT_PG_DIALOG_PREFIX = "> Page ";
integer MENU_LINK = -123;
integer MAX_DIALOG_CHOICES_PER_PG = 8;
string DIALOG_STOP_BTN = "Stop";
string DIALOG_RESUME_BTN = " ";
string DIALOG_DONE_BTN = "Done";
list DIALOG_CHOICES = [];
integer seatupdate = 35353;


list SeatedAvs(){
    list avs = [];
    integer n;
    integer linkcount = llGetNumberOfPrims();
    for (n = linkcount; n >= 0; n--){
        key id = llGetLinkKey(n);
        if (llGetAgentSize(id) != ZERO_VECTOR){
            avs = [id] + avs;
        }
    }
    return avs;
}



loadCards(){
    
    
    DIALOG_CHOICES = [];
    integer a = 0;
    integer b = llGetInventoryNumber(INVENTORY_NOTECARD);
    for(; a < b; ++a){
        string cardName = llGetInventoryName(INVENTORY_NOTECARD,a);
        list cardParts = llParseString2List(cardName,[":"],[]);
        if (llList2String(cardParts,0) == cardPrefix){
            DIALOG_CHOICES = DIALOG_CHOICES + [llList2String(cardParts,1)];
        }  
    }
}

 
giveDialog(key ID, integer pageNum) {
    list buttons;
    integer firstChoice;
    integer lastChoice;
    integer prevPage;
    integer nextPage;
    string OnePage;
    N_DIALOG_CHOICES = llGetListLength(DIALOG_CHOICES);
    if (N_DIALOG_CHOICES <= 10) {
        buttons = DIALOG_CHOICES;
        OnePage = "Yes";
    }else {
        integer nPages = (N_DIALOG_CHOICES+MAX_DIALOG_CHOICES_PER_PG-1)/MAX_DIALOG_CHOICES_PER_PG;
        if (pageNum < 1 || pageNum > nPages) {
            pageNum = 1;
        }
        integer firstChoice = (pageNum-1)*MAX_DIALOG_CHOICES_PER_PG;
        integer lastChoice = firstChoice+MAX_DIALOG_CHOICES_PER_PG-1;
        if (lastChoice >= N_DIALOG_CHOICES) {
            lastChoice = N_DIALOG_CHOICES;
        }
        if (pageNum <= 1) {
            prevPage = nPages;
            nextPage = 2;
        }else if (pageNum >= nPages) {
            prevPage = nPages-1;
            nextPage = 1;
        }else {
            prevPage = pageNum-1;
            nextPage = pageNum+1;
        }
        buttons = llList2List(DIALOG_CHOICES, firstChoice, lastChoice);
    }
    
        list buttons01 = llList2List(buttons, 0, 2);
        list buttons02 = llList2List(buttons, 3, 5);
        list buttons03 = llList2List(buttons, 6, 8);
        list buttons04;
        if (OnePage == "Yes") {
            buttons04 = llList2List(buttons, 9, 11);
        }
        buttons = buttons04 + buttons03 + buttons02 + buttons01;
        if (OnePage == "Yes") {
             buttons += [ DIALOG_STOP_BTN, DIALOG_RESUME_BTN ];
            
        }else {
            buttons =
            (buttons=[])+
            [ PREV_PG_DIALOG_PREFIX+(string)prevPage,
            DIALOG_STOP_BTN, NEXT_PG_DIALOG_PREFIX+(string)nextPage, DIALOG_DONE_BTN
            ]+buttons;
           
        }
        llDialog(ID, "Page "+(string)pageNum+"\nChoose one:", buttons, channel_dialog);
}

 
 
CancelListen() {
    llListenRemove(listen_id);
    
}

 
default{
  state_entry() {
    channel_dialog = ( -1 * (integer)("0x"+llGetSubString((string)llGetKey(),-5,-1)) );
    loadCards();
  }
  
  on_rez(integer p){
      llResetScript();    
  }
  
  link_message(integer sNum, integer num, string str, key id){
      if (num == -970){
        CancelListen();
        ToucherID = (key)str;
        listen_id = llListen( channel_dialog, "", ToucherID, "");
        pageNum = 1;
        llSleep(1.0);
        giveDialog(ToucherID, pageNum);
      }else if (num == MENU_LINK){
        CancelListen();
        ToucherID = id; 
        listen_id = llListen( channel_dialog, "", ToucherID, "");
        pageNum = 1;
        giveDialog(ToucherID, pageNum);
      }else if (num == 34334){
        llSay(0,"Memory Used by " + llGetScriptName() + ": " + (string)llGetUsedMemory() + " of " + (string)llGetMemoryLimit()
             + ",Leaving " + (string)llGetFreeMemory() + " memory free.");
      }
  }
 

    changed(integer change){
        if (change & CHANGED_INVENTORY){
            loadCards();   
        }
        if (change & CHANGED_LINK){
            if (llGetListLength(SeatedAvs()) <= 0){
                CancelListen();
                isRunning = FALSE;
                isPaused = FALSE;
                iLine = 0;
                llSetTimerEvent(0.0); 
            }  
        }
    }
 
 
  listen(integer channel, string name, key id, string choice) {
    
    
    
    if (choice == "-") {
     giveDialog(ToucherID, pageNum); 
    }else if ( choice == DIALOG_DONE_BTN){
        CancelListen();
        return;
    }else if (choice == DIALOG_STOP_BTN) {
        CancelListen();
        isRunning = FALSE;
        isPaused = FALSE;

        llSetTimerEvent(0.0);
    }else if (choice == DIALOG_RESUME_BTN){
        CancelListen();
        isRunning = TRUE;
    }else if (llSubStringIndex(choice, PREV_PG_DIALOG_PREFIX) == 0){
        pageNum =
        (integer)llGetSubString(choice, llStringLength(PREV_PG_DIALOG_PREFIX), -1);
        giveDialog(ToucherID, pageNum);
    }else if (llSubStringIndex(choice, NEXT_PG_DIALOG_PREFIX) == 0) {
        pageNum =
        (integer)llGetSubString(choice, llStringLength(NEXT_PG_DIALOG_PREFIX), -1);
        giveDialog(ToucherID, pageNum);
    }else{ 
        
        
        
        isRunning = TRUE;
        isPaused = TRUE; 
        iLine = 0;
        loopTo = 0;
        loadedCard = cardPrefix + ":" + choice;
        kQuery = llGetNotecardLine(loadedCard, iLine);
    }
  }
 
  timer()   {
        if (isRunning == TRUE) kQuery = llGetNotecardLine(loadedCard, iLine);
  }
  
    dataserver(key query_id, string data) {
        if (query_id == kQuery) {    
            if (data == EOF) {    
                
                isRunning = FALSE;
                isPaused = FALSE;
                llSetTimerEvent(0.0);
                CancelListen();
        
                iLine = 0;
                llSetTimerEvent(0.0);
 
            }else{
 
    
    
    
    
    
    
    
    
                if (debug == TRUE) llSay(0, "Line " + (string)iLine + ": " + data);   
                list thisLine = llParseString2List(data,["|"],[]);
                if (llList2String(thisLine,0) == "LOOPTO"){
                    loopTo = iLine; 
                    posePause = 0.1; 
                }else if (llList2String(thisLine,0) == "LOOP"){
                    iLine = loopTo;
                    if (iLine == 0) iLine = -1; 
                    posePause = 0.1; 
                }
                else{
                    posePause = llList2Float(thisLine,0);
                    llMessageLinked(LINK_SET,200,llList2String(thisLine,1),NULL_KEY);   

                }
                iLine++;   
                llSetTimerEvent(posePause);
            }
        }
    }
    
}

