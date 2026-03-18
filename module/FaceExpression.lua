local FaceExpression = {

    Expressions = { 
        {   name = "Neutral", idle = 2, category = 2 },
        {   name = "Joy", idle = 5, category = 3 },
        {   name = "Smile", idle = 6, category = 3 },
        {   name = "Sad", idle = 3, category = 3 },
        {   name = "Surprise", idle = 8, category = 3 },
        {   name = "Aggressive", idle = 2, category = 3 },
        {   name = "Anger", idle = 1, category = 3 },
        {   name = "Interested", idle = 3, category = 1 },
        {   name = "Disinterested", idle = 6, category = 1 },
        {   name = "Disappointed", idle = 4, category = 3 },
        {   name = "Disgust", idle = 7, category = 3 },
        {   name = "Exertion", idle = 1, category = 1 },
        {   name = "Nervous", idle = 10, category = 3 },
        {   name = "Fear", idle = 11, category = 3 },
        {   name = "Terrified", idle = 9, category = 3 },
        {   name = "Pain", idle = 2, category = 1 },
        {   name = "Sleepy", idle = 5, category = 1 },
        {   name = "Unconscious", idle = 4, category = 1 },
        {   name = "Dead", idle = 1, category =  2 }
    }

}

function FaceExpression.Init(cron)
    FaceExpression.cron = cron
end
function FaceExpression.ActivateFacialExpression(target, expressionName)
    if not target then
        print("FaceExpression.ActivateFacialExpression: target is nil")
        return
    end
    if target == nil then
        print("FaceExpression.ActivateFacialExpression: target is nil")
        return
    end
    if expressionName == nil then
        print("FaceExpression.ActivateFacialExpression: expression name not given")
        return
    end
    local stimComp = target:GetStimReactionComponent()
    local animComp = target:GetAnimationControllerComponent()
    local expr
    local foundExpr = false
    for i=1, #(FaceExpression.Expressions) do
        if FaceExpression.Expressions[i].name == expressionName then
            expr = FaceExpression.Expressions[i]
            foundExpr = true
            break
        end
    end
    if foundExpr == false then
        return
    end
    
    if stimComp and animComp then
      stimComp:ResetFacial(0)
      FaceExpression.cron.After(0.5, function()          
          local animFeat = NewObject("handle:AnimFeature_FacialReaction")
          animFeat.category = expr.category
          animFeat.idle = expr.idle
          animComp:ApplyFeature(CName.new("FacialReaction"), animFeat)
        end,
        {})
    end
end

function FaceExpression.Neutral(target)
    FaceExpression.ActivateFacialExpression(target, "Neutral")
end
function FaceExpression.Joy(target)
    FaceExpression.ActivateFacialExpression(target, "Joy")
end
function FaceExpression.Smile(target)
    FaceExpression.ActivateFacialExpression(target, "Smile")
end
function FaceExpression.Sad(target)
    FaceExpression.ActivateFacialExpression(target, "Sad")
end
function FaceExpression.Surprise(target)
    FaceExpression.ActivateFacialExpression(target, "Surprise")
end
function FaceExpression.Aggressive(target)
    FaceExpression.ActivateFacialExpression(target, "Aggressive")
end
function FaceExpression.Anger(target)
    FaceExpression.ActivateFacialExpression(target, "Anger")
end
function FaceExpression.Interested(target)
    FaceExpression.ActivateFacialExpression(target, "Interested")
end
function FaceExpression.Disinterested(target)
    FaceExpression.ActivateFacialExpression(target, "Disinterested")
end
function FaceExpression.Disappointed(target)
    FaceExpression.ActivateFacialExpression(target, "Disappointed")
end
function FaceExpression.Disgust(target)
    FaceExpression.ActivateFacialExpression(target, "Disgust")
end
function FaceExpression.Exertion(target)
    FaceExpression.ActivateFacialExpression(target, "Exertion")
end
function FaceExpression.Nervous(target)
    FaceExpression.ActivateFacialExpression(target, "Nervous")
end
function FaceExpression.Fear(target)
    FaceExpression.ActivateFacialExpression(target, "Fear")
end
function FaceExpression.Terrified(target)
    FaceExpression.ActivateFacialExpression(target, "Terrified")
end
function FaceExpression.Pain(target)
    FaceExpression.ActivateFacialExpression(target, "Pain")
end
function FaceExpression.Sleepy(target)
    FaceExpression.ActivateFacialExpression(target, "Sleepy")
end
function FaceExpression.Unconscious(target)
    FaceExpression.ActivateFacialExpression(target, "Unconscious")
end
function FaceExpression.Dead(target)
    FaceExpression.ActivateFacialExpression(target, "Dead")
end

return FaceExpression
