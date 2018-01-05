require("goals/goal")

FollowPlayer = Class(Goal, function(self, inst, player)
   Goal._ctor(self, inst, "FollowPlayer")
   self.urgency = 0.3 -- primary task unless extremely important one   
   self.player = player   
end)

function FollowPlayer:OnStop()   
end

function FollowPlayer:Satisfaction()
   -- further away, need to follow more
   -- if doing task, could reduce satisfaction
   local pos = Point(self.inst.Transform:GetWorldPosition())
   local target_pos = Point(self.player.Transform:GetWorldPosition())
   local dist_sq = distsq(pos, target_pos)

   -- 4, 6, 10
   
   local satisfaction = dist_sq / (11*11)
   return satisfaction
end

function FollowPlayer:GetGoalState()
   return {close_to_player=true}
end