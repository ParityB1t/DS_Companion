require 'general-utils/debugprint'

PerformSearchFor = Class(BehaviourNode, function(self, inst, entity, period)
   -- search for is travelling in a random direction
   -- then do another check to see if entity wanted is in view
   -- fail if no entity is in view then
   BehaviourNode._ctor(self, "PerformSearchFor")
   self.inst = inst
   self.entity = entity   
   self.waittime = 0
   self.period = period
   self.lasttime = nil
end)

function PerformSearchFor:OnFail()
   self.pendingstatus = FAILED
end
function PerformSearchFor:OnSucceed()
   self.pendingstatus = SUCCESS
end

-- unused atm
function PerformSearchFor:SearchWithPoint()   
   if self.status == READY then
      local maxSearchDist = 20
      local minSearchDist = 5
      local currentPos = Vector3(self.inst.Transform:GetWorldPosition())
      local newx = currentPos.x + math.rad(minSearchDist, maxSearchDist)
      local newy = currentPos.y + math.rad(minSearchDist, maxSearchDist)
      local newPos = Vector3(newx, newy, currentPos.z)
      -- implement valid point later
      action =  BufferedAction(self.inst, nil, ACTIONS.WALKTO, nil, newPos,nil, 0.1)
      action:AddFailAction(function() self:OnFail() end)
      action:AddSuccessAction(function() self:OnSucceed() end)   
      self.action = action
      self.pendingstatus = nil   
      self.inst.components.locomotor:PushAction(action, true)   
      self.status = RUNNING
   elseif self.status == RUNNING then
      if self.pendingstatus then
         self.status = self.pendingstatus
      elseif not self.action:IsValid() then
         self.status = FAILED
      end   
   end
end

function PerformSearchFor:CheckTarget()
   return FindEntity(self.inst, 6, function(ent)
               return ent.prefab == self.entity       
            end )
end

function PerformSearchFor:SearchWithDirection()
   if self.status == READY then            
      local randomAngle = math.random() * 360 -- in degrees
      info('random degrees ' .. tostring(randomAngle))
      self.waittime = GetTime() + 6
      self.lasttime = GetTime()
      info('start time '..tostring(GetTime()))
      info('end time '..tostring(self.waittime))
      self.inst.components.locomotor:RunInDirection(randomAngle) -- want walk but not SG
      self.status = RUNNING
   elseif self.status == RUNNING then
      info('time '..tostring(GetTime()))      
      local eval = self.lasttime and self.period and GetTime() > self.lasttime + self.period      
      if GetTime() > self.waittime or eval then         
         local target = self:CheckTarget()
         self.lasttime = GetTime()

         if target then -- regarldess of eval
            -- found something after searching
            self.status = SUCCESS
            self.inst.components.locomotor:Stop()
         elseif not eval then -- and not target
            info('complete search found nothing')
            self.status = FAILED -- for now only try once            
            self.inst.components.locomotor:Stop() -- later change so only stop when completely fail and success               
         end
      end

      self:Sleep(self.waittime - GetTime()) -- sleep until wake
   end
end

function PerformSearchFor:Visit()
   self:SearchWithDirection()
end