// Created by BillySue LittleBoots 
// Add this script to the root prim of an object where the nPose engine is in a CHILD prim.

integer DOMENU = -800;

default
{
    state_entry()
    {
       
    }
    
    touch_start(integer total_number)
    {
      
                key toucher = llDetectedKey(0);
               
              
                {
                   
                    llMessageLinked(LINK_SET, DOMENU, "",toucher); 
                }
            }
            
        }
 

