require 'brains/selectgoal'
require 'brains/planactions'
require 'behaviours/goapsequencenode'
require 'goals/stayfull'
require 'goals/stayhealthy'
require("goals/followplayer")
require("goals/keepplayerfull")

require 'brains/utils'

require 'general-utils/table_ops'
require 'general-utils/debugprint'

local GoalBasedBrain = Class(Brain, function (self, inst)
	Brain._ctor(self, inst)
   self.gwu_list = {}
   self.actionplan = {}
end)


local function initialise_gwu(inst)
   -- Add all goals to the list, for now weight is always 1 (most important)
   local player = GetPlayer()

   local gwu_list = {}
   --local stayhealthy = StayHealthy(inst)
   --local stayfull = StayFull(inst)
   local followPlayer = FollowPlayer(inst, player)
   local keepplayerfull = KeepPlayerFull(inst, player)
   
   --local healthy = goal_tuple(stayhealthy, 1)
   --local full = goal_tuple(stayfull, 1)
   local follow = goal_tuple(followPlayer, 1)
   local keepfull = goal_tuple(keepplayerfull, 1)

   --gwu_list[stayhealthy.name] = healthy
   --gwu_list[stayfull.name] = full
   gwu_list[followPlayer.name] = follow
   gwu_list[keepplayerfull.name] = keepfull

   return gwu_list
end

local function onNextGoalFound(inst, data)    
   inst.brain.currentgoal = data.goal
   info('DECIDED ON GOAL ' .. tostring(inst.brain.currentgoal) .. '\n')
end

local function onActionPlanned(inst, data)
   if data.a_sequence ~= nil then
      local a_sequence = data.a_sequence
      local plan = {}
      for a=1,#a_sequence do
         info('putting in plan' .. tostring(a_sequence[a]))
         table.insert(plan, #plan+1, a_sequence[a]:Perform())
      end
      info('.\n')
      inst.brain.actionplan = plan
   end
end

local function onInsertGoal(inst, data)
   local goal = data.goal
   local g = goal_tuple(goal, 1) -- in proto following orders is important so 1
   inst.brain.gwu_list[goal.name] = g

   -- currently, this goal is first considered in the next iteration
end

local function onDropGoal(inst, data)
   local goalname = data.goalname
   error('GOAL DROPPED '..goalname)
   inst.brain.gwu_list[goalname] = nil
end

function GoalBasedBrain:OnStart()
   self.gwu_list = initialise_gwu(self.inst)

   self.inst:ListenForEvent('nextgoalfound', onNextGoalFound)
   self.inst:ListenForEvent('actionplanned', onActionPlanned)
   self.inst:ListenForEvent('insertgoal', onInsertGoal)
   self.inst:ListenForEvent('dropgoal', onDropGoal)

   self.inst.components.inventory:GiveItem(SpawnPrefab('cutgrass'))
   self.inst.components.inventory:GiveItem(SpawnPrefab('cutgrass'))
   self.inst.components.inventory:GiveItem(SpawnPrefab('cutgrass'))
   self.inst.components.inventory:GiveItem(SpawnPrefab('cutgrass'))
   self.inst.components.inventory:GiveItem(SpawnPrefab('cutgrass'))
   self.inst.components.inventory:GiveItem(SpawnPrefab('cutgrass'))
   self.inst.components.inventory:GiveItem(SpawnPrefab('twigs'))
   self.inst.components.inventory:GiveItem(SpawnPrefab('twigs'))
   self.inst.components.inventory:GiveItem(SpawnPrefab('flint'))
   

   local root = ResponsiveGOAPNode(self.inst, .25, function ()
      return self.gwu_list
   end)
   self.bt = BT(self.inst, root)
end

function GoalBasedBrain:OnStop()
   self.inst:RemoveEventCallback('nextgoalfound', onNextGoalFound)
   self.inst:RemoveEventCallback('actionplanned', onActionPlanned)
   self.inst:RemoveEventCallback('insertgoal', onInsertGoal)
   self.inst:RemoveEventCallback('dropgoal', onDropGoal)

   for _,v in pairs(self.gwu_list) do
      v.goal:OnStop()
   end
end

return GoalBasedBrain
