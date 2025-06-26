const SANDBALL_MODEL = "models/weapons/w_models/w_baseball.mdl";
const CRIT_TRAIL = "critical_rocket_blue";


function ReplaceProjectiles() {
    local projectile = null;
    while (projectile = Entities.FindByClassname(projectile, "tf_projectile_*")) {
        local classname = projectile.GetClassname();
        
        if (classname != "tf_projectile_rocket" && 
            classname != "tf_projectile_pipe") continue;
        
        local owner = projectile.GetOwner();
        if (!owner || !owner.IsValid()) continue;

        if (owner.GetTeam() == 3 ) {
            projectile.SetModel(SANDBALL_MODEL);
            projectile.SetModelScale(2.0, 0);
            projectile.ValidateScriptScope();
            local scope = projectile.GetScriptScope();
            
            if (!("trail" in scope)) {

                local velocity = projectile.GetVelocity();
                local angles = Vector(0, 0, 0);
                
                if (velocity.Length() > 0) {
                    angles.y = atan2(velocity.y, velocity.x) * 180.0 / PI;
                    angles.x = -atan2(velocity.z, sqrt(velocity.x * velocity.x + velocity.y * velocity.y)) * 180.0 / PI;
                }
                
                local trail = SpawnEntityFromTable("info_particle_system",
                {
                    origin = projectile.GetOrigin()
                    angles = angles
                    effect_name = CRIT_TRAIL
                    start_active = 1
                })

                EntFireByHandle(trail, "SetParent", "!activator", 0, projectile, null);
                scope.trail <- trail;
                
                scope.OnDestroy <- function() {
                    if ("trail" in this && this.trail.IsValid()) {
                        EntFireByHandle(this.trail, "Kill", "", 0, null, null);
                    }
                }
            }
        }
    }
}

function SetupController() {
    local oldController = Entities.FindByName(null, "mvm_snowball");
    if (oldController && oldController.IsValid()) {
        EntFireByHandle(oldController, "Kill", "", 0, null, null);
    }
    
    local controller = Entities.CreateByClassname("logic_script");
    controller.ValidateScriptScope();
    controller.GetScriptScope().ReplaceProjectiles <- ReplaceProjectiles;
    controller.GetScriptScope().OnGameFrame <- ReplaceProjectiles;

    AddThinkToEnt(controller, "OnGameFrame");
    EntFireByHandle(controller, "RunScriptCode", "ReplaceProjectiles()", 0, null, null);
    DoEntFire("!self", "AddOutput", "targetname mvm_snowball", 0, null, controller);
}
SetupController();

