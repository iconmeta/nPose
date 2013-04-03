//------------------------------------------------------------------------------
// FixSitInsidePhantom
// fix sitting inside the bbox of phantom prims
// should be added to the containing phantom prim, not to the furniture
// by Kitsune Ethaniel
//
// changelog
//   v1.0, 2011-10-03: downloaded from JIRA SVC-3811.
//

default {

  state_entry() {
    // Make this object collide ONLY with objects named Farkle
    llCollisionFilter("Farkle", "", TRUE);
    
    // This makes the object work like a phantom prim but still trigger 
    // collison_start and collision_end events. Must be used in root prim.
    llVolumeDetect(1);
    
    // Set the prim to phantom
    llSetStatus(STATUS_PHANTOM, 1);
  }

}
