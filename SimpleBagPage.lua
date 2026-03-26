local CONFIG = {
  -- Overall scale of the Blizzard bag frame.
  bagScale = 0.9,
  -- Horizontal gap between the combined bag and reagent bag.
  combinedReagentGapX = -3,
  -- Vertical offset between the combined bag and reagent bag.
  combinedReagentGapY = 0,

  -- Font used for stack count text.
  countFont = STANDARD_TEXT_FONT,
  -- Font size of stack count text.
  countFontSize = 14,
  -- Font outline style for stack count text.
  countOutline = "OUTLINE",
  -- Stack count anchor: { point, xOffset, yOffset }.
  countAnchor = { "BOTTOMRIGHT", 1, 1 },
}

local DEFAULTS = {
  disableAuctionHouseAutoOpen = true,
}

local function GetDB()
  if type(_G.SimpleBagPageDB) ~= "table" then
    _G.SimpleBagPageDB = {}
  end

  return _G.SimpleBagPageDB
end

local function IsAuctionHouseAutoOpenDisabled()
  local db = GetDB()
  if db.disableAuctionHouseAutoOpen == nil then
    db.disableAuctionHouseAutoOpen = DEFAULTS.disableAuctionHouseAutoOpen
  end

  return db.disableAuctionHouseAutoOpen
end

local function SetAuctionHouseAutoOpenDisabled(disabled)
  GetDB().disableAuctionHouseAutoOpen = disabled and true or false
end

local function IsAuctionHouseFrame(frame)
  return frame and frame.GetName and frame:GetName() == "AuctionHouseFrame"
end

local function PrintStatus(message)
  DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffSimpleBagPage|r: " .. message)
end

local function ApplyTextStyle(button)
  if button.Count then
    button.Count:SetFont(CONFIG.countFont, CONFIG.countFontSize, CONFIG.countOutline)
    button.Count:ClearAllPoints()
    button.Count:SetPoint(CONFIG.countAnchor[1], button, CONFIG.countAnchor[1], CONFIG.countAnchor[2], CONFIG.countAnchor[3])
  end
end

local function ApplyButtonStyle(button)
  if not button then
    return
  end

  ApplyTextStyle(button)
end

local function ApplyContainerLayout(container)
  if not container then
    return
  end

  container:SetScale(CONFIG.bagScale)

  if container.EnumerateValidItems then
    for _, button in container:EnumerateValidItems() do
      ApplyButtonStyle(button)
    end
  end
end

local function ApplyContainerScale(container)
  if not container then
    return
  end

  container:SetScale(CONFIG.bagScale)
end

local function ApplyCombinedReagentGap()
  local combined = ContainerFrameCombinedBags
  local reagent = ContainerFrame6
  if not combined or not reagent or not combined:IsShown() or not reagent:IsShown() then
    return
  end

  reagent:ClearAllPoints()
  reagent:SetPoint("BOTTOMRIGHT", combined, "BOTTOMLEFT", CONFIG.combinedReagentGapX, CONFIG.combinedReagentGapY)
end

local function ApplyAllLayouts()
  if ContainerFrameCombinedBags then
    ApplyContainerScale(ContainerFrameCombinedBags)
    ApplyContainerLayout(ContainerFrameCombinedBags)
  end

  for i = 1, NUM_CONTAINER_FRAMES do
    local frame = _G["ContainerFrame" .. i]
    if frame and frame:IsShown() then
      ApplyContainerScale(frame)
      ApplyContainerLayout(frame)
    end
  end

  ApplyCombinedReagentGap()
end

local function HookContainer(container)
  if not container or container.__simpleBagPageHooked then
    return
  end

  container.__simpleBagPageHooked = true

  if container.UpdateItems then
    hooksecurefunc(container, "UpdateItems", ApplyAllLayouts)
  end

  container:HookScript("OnShow", ApplyAllLayouts)
end

local function HookElvUIBags()
  if _G.SimpleBagPageElvUIHooked then
    return
  end

  ---@diagnostic disable-next-line: undefined-field
  local elvuiTable = _G.ElvUI
  local E = elvuiTable and elvuiTable[1]
  ---@diagnostic disable-next-line: undefined-field
  local bags = E and E.Bags
  if not bags or type(bags.UpdateContainerFrameAnchors) ~= "function" then
    return
  end

  hooksecurefunc(bags, "UpdateContainerFrameAnchors", ApplyAllLayouts)
  _G.SimpleBagPageElvUIHooked = true
end

local function HookAuctionHouseAutoOpen()
  if _G.SimpleBagPageAuctionHooked then
    return
  end

  local originalOpenAllBags = _G.OpenAllBags
  if type(originalOpenAllBags) == "function" then
    _G.OpenAllBags = function(frame, forceUpdate)
      if IsAuctionHouseAutoOpenDisabled() and IsAuctionHouseFrame(frame) then
        return
      end

      return originalOpenAllBags(frame, forceUpdate)
    end
  end

  _G.SimpleBagPageAuctionHooked = true
end

local function HookElvUIAuctionAutoOpen()
  if _G.SimpleBagPageElvUIAuctionHooked then
    return
  end

  ---@diagnostic disable-next-line: undefined-field
  local elvuiTable = _G.ElvUI
  local E = elvuiTable and elvuiTable[1]
  ---@diagnostic disable-next-line: undefined-field
  local bags = E and E.Bags
  if not bags or type(bags.AutoToggleFunction) ~= "function" then
    return
  end

  local originalAutoToggleFunction = bags.AutoToggleFunction
  bags.AutoToggleFunction = function(event, ...)
    if IsAuctionHouseAutoOpenDisabled() and event == "AUCTION_HOUSE_SHOW" then
      return
    end

    return originalAutoToggleFunction(event, ...)
  end

  _G.SimpleBagPageElvUIAuctionHooked = true
end

local function HookItemButtonCount()
  if _G.SimpleBagPageCountHooked then
    return
  end

  hooksecurefunc("SetItemButtonCount", function(button)
    ApplyTextStyle(button)
  end)

  _G.SimpleBagPageCountHooked = true
end

local function RegisterSlashCommands()
  SLASH_SIMPLEBAGPAGE1 = "/sbp"
  SLASH_SIMPLEBAGPAGE2 = "/simplebagpage"

  SlashCmdList.SIMPLEBAGPAGE = function(msg)
    local command = msg and msg:match("^%s*(.-)%s*$") or ""
    command = command:lower()

    if command == "" or command == "status" then
      local status = IsAuctionHouseAutoOpenDisabled() and "off" or "on"
      PrintStatus("拍卖行自动开包当前为 " .. status .. "。使用 /sbp ah on 或 /sbp ah off。")
      return
    end

    if command == "ah on" then
      SetAuctionHouseAutoOpenDisabled(false)
      PrintStatus("已开启拍卖行自动开包。")
      return
    end

    if command == "ah off" then
      SetAuctionHouseAutoOpenDisabled(true)
      if _G.CloseAllBags and _G.AuctionHouseFrame and _G.AuctionHouseFrame:IsShown() then
        _G.CloseAllBags(_G.AuctionHouseFrame)
      end
      PrintStatus("已关闭拍卖行自动开包。")
      return
    end

    PrintStatus("用法: /sbp ah on | /sbp ah off | /sbp status")
  end
end

local function Initialize()
  IsAuctionHouseAutoOpenDisabled()
  HookItemButtonCount()
  HookAuctionHouseAutoOpen()
  HookElvUIBags()
  HookElvUIAuctionAutoOpen()
  HookContainer(ContainerFrameCombinedBags)
  RegisterSlashCommands()

  for i = 1, NUM_CONTAINER_FRAMES do
    HookContainer(_G["ContainerFrame" .. i])
  end

  local frame = CreateFrame("Frame")
  frame:RegisterEvent("BAG_UPDATE_DELAYED")
  frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  frame:RegisterEvent("BANKFRAME_OPENED")
  frame:SetScript("OnEvent", function(_, event, ...)
    HookAuctionHouseAutoOpen()
    HookElvUIBags()
    HookElvUIAuctionAutoOpen()
    HookContainer(ContainerFrameCombinedBags)

    for i = 1, NUM_CONTAINER_FRAMES do
      HookContainer(_G["ContainerFrame" .. i])
    end

    ApplyAllLayouts()
  end)

  hooksecurefunc("UpdateContainerFrameAnchors", ApplyAllLayouts)

  ApplyAllLayouts()
end

Initialize()
