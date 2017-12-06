require 'goapplanner'
require 'actions/gather'
require 'actions/eat'
require 'general-utils/table_ops'

PlanActions = Class(BehaviourNode, function(self, inst)
		       BehaviourNode._ctor(self, 'PlanActions')
		       self.inst = inst			   
		       self.all_actions = {
			  Gather(inst, 'twigs'),
			  Gather(inst, 'food'), -- generic
			  Eat(inst)
		       }
end)

function PlanActions:generate_world_state()	
   local res = {}
   local inventory = self.inst.components.inventory
   if not inventory:IsFull() then
      res['has_inv_spc'] = true		
   end

   print('inventory item number start over ' .. tostring(inventory:GetNumSlots()))
   
   -- goal precond + not have enough or not have, need
   -- can get goal and calculate how many times to repeat
   for i=1,inventory:GetNumSlots() do
	  	local item = inventory:GetItemInSlot(i)	  	  
		if item then
			print(tostring(item))
			if res[item.prefab] then
				print 'item exist in state'
	 			-- total stack size, not restricted by in-game
	 			if item.components.stackable then
	    			res[item.prefab] = res[item.prefab] + item.components.stackable.stacksize
	 			else
	    			res[item.prefab] = res[item.prefab] + 1
	 			end
			else
		 		if item.components.stackable then				
	    			res[item.prefab] = item.components.stackable.stacksize
		 		else					
	    			res[item.prefab] = 1
	 	 		end	
			   end
			local has_key = 'has' .. tostring(item.prefab)			
      	end	 
   	end
   return res
end

function PlanActions:Visit()
   print('planning action')
   local world_state = self:generate_world_state()
   print('world state')
   printt(world_state)
   local goal_state = self.inst.components.planholder.currentgoal:GetGoalState()
   local action_sequence = goap_plan_action(world_state, goal_state, self.all_actions)
   self.inst:PushEvent('actionplanned', {a_sequence=action_sequence})
end