local _, T = ...
local DB = T.DB
local UI = T.UI

local Layout = {}
T.Layout = Layout

Layout.WIDTH = 330
Layout.INDENT = 16
Layout.PAD = 8

local HEADER_H, ROW_H = 18, 18
local FOLD_W = 12
local ICON = 16
local LABEL_W = 84
local STATUS_W = 14
local RIGHT_W = 52
local BAR_H = 12
local BAR_TEXTURE = "Interface\\Buttons\\WHITE8X8"
local CONTENT_W = Layout.WIDTH - 2 * Layout.PAD
-- GetWidth() is 0 before the first layout pass.
local BAR_W = CONTENT_W - Layout.INDENT - (ICON + 6) - LABEL_W - 4 - 4 - RIGHT_W - 4 - STATUS_W

local content, rowPool, headerPool
local y = 0

local function pool(create)
    local items, used = {}, 0
    return {
        acquire = function()
            used = used + 1
            local item = items[used]
            if not item then
                item = create()
                items[used] = item
            end
            item:ClearAllPoints()
            return item
        end,
        releaseAll = function()
            for i = 1, #items do items[i]:Hide() end
            used = 0
        end,
    }
end

local function setColor(fs, c) fs:SetTextColor(c[1], c[2], c[3]) end

local function onRowEnter(self)
    if not DB.Profile().showTooltip or not self.tooltip then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    self.tooltip(GameTooltip)
    GameTooltip:Show()
end

local function onRowLeave() GameTooltip:Hide() end

local function onRowClick(self)
    if self.link and T.Addon.ShiftDown() then ChatEdit_InsertLink(self.link) end
end

local function fontString(parent, template)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(false)
    return fs
end

local function createBar(r)
    local bar = CreateFrame("StatusBar", nil, r)
    bar:SetPoint("LEFT", r.label, "RIGHT", 4, 0)
    bar:SetPoint("RIGHT", r.right, "LEFT", -4, 0)
    bar:SetHeight(BAR_H)
    bar:SetStatusBarTexture(BAR_TEXTURE)
    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(1, 1, 1, 0.08)
    bar.mark = bar:CreateTexture(nil, "OVERLAY")
    bar.mark:SetColorTexture(1, 1, 1, 0.8)
    bar.mark:SetSize(1, BAR_H)
    bar.text = fontString(bar)
    bar.text:SetPoint("LEFT", 4, 0)
    bar:Hide()
    return bar
end

local function createRow()
    local r = CreateFrame("Button", nil, content)
    r:SetHeight(ROW_H)
    r.icon = r:CreateTexture(nil, "ARTWORK")
    r.icon:SetSize(ICON, ICON)
    r.icon:SetPoint("LEFT", 0, 0)
    r.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    r.label = fontString(r)

    r.status = r:CreateTexture(nil, "ARTWORK")
    r.status:SetSize(STATUS_W, STATUS_W)
    r.status:SetPoint("RIGHT", 0, 0)

    r.right = fontString(r)
    r.right:SetPoint("RIGHT", -STATUS_W - 4, 0)
    r.right:SetWidth(RIGHT_W)
    r.right:SetJustifyH("RIGHT")

    r.value = fontString(r)
    r.value:SetPoint("LEFT", r.label, "RIGHT", 4, 0)
    r.value:SetPoint("RIGHT", r.right, "LEFT", -4, 0)

    r.bar = createBar(r)

    r:RegisterForClicks("LeftButtonUp")
    r:SetScript("OnClick", onRowClick)
    r:SetScript("OnEnter", onRowEnter)
    r:SetScript("OnLeave", onRowLeave)
    return r
end

local function createHeader()
    local h = CreateFrame("Button", nil, content)
    h:SetHeight(HEADER_H)
    local bg = h:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(1, 1, 1, 0.06)
    h.icon = h:CreateTexture(nil, "ARTWORK")
    h.icon:SetSize(FOLD_W, FOLD_W)
    h.icon:SetPoint("LEFT", 2, 0)
    h.label = fontString(h, "GameFontNormal")
    h.label:SetPoint("LEFT", Layout.INDENT + 2, 0)
    h.summary = fontString(h)
    h.summary:SetPoint("RIGHT", -4, 0)
    h.summary:SetJustifyH("RIGHT")
    h:RegisterForClicks("AnyUp")
    h:SetScript("OnClick", function(self)
        DB.ToggleFold(self.key)
        T.Window.Refresh()
    end)
    return h
end

function Layout.Begin(parent)
    if not content then
        content = parent
        rowPool = pool(createRow)
        headerPool = pool(createHeader)
    end
    rowPool.releaseAll()
    headerPool.releaseAll()
    y = 0
end

function Layout.Height() return y end
function Layout.Gap(height) y = y + height end

-- Returns whether the section is unfolded.
function Layout.Header(key, text, summary)
    local h = headerPool.acquire()
    local folded = DB.IsFolded(key)
    h.key = key
    h:SetPoint("TOPLEFT", 0, -y)
    h:SetPoint("RIGHT", content, "RIGHT", 0, 0)
    h.icon:SetTexture(folded and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
    h.label:SetText(text)
    h.summary:SetText(summary or "")
    h:Show()
    y = y + HEADER_H + 2
    return not folded
end

-- spec: icon (false hides it), flush (label starts at the icon column), label, labelColor,
-- value, valueColor, right, rightColor, status, statusColor, bar = { value, max, mark, color }, tooltip(tt), link
function Layout.Row(spec)
    local r = rowPool.acquire()
    r:SetPoint("TOPLEFT", Layout.INDENT, -y)
    r:SetPoint("RIGHT", content, "RIGHT", 0, 0)
    r.icon:SetTexture(spec.icon or UI.ICON_FALLBACK)
    r.icon:SetShown(spec.icon ~= false)
    local labelX = spec.flush and 0 or ICON + 6
    r.label:SetPoint("LEFT", labelX, 0)
    r.label:SetWidth(LABEL_W + ICON + 6 - labelX)
    r.label:SetText(spec.label or "")
    setColor(r.label, spec.labelColor or UI.GREY)
    r.value:SetText(spec.value or "")
    setColor(r.value, spec.valueColor or UI.WHITE)
    r.right:SetText(spec.right or "")
    setColor(r.right, spec.rightColor or UI.WHITE)
    local sc = spec.statusColor or UI.WHITE
    r.status:SetTexture(spec.status)
    r.status:SetVertexColor(sc[1], sc[2], sc[3])
    r.status:SetShown(spec.status ~= nil)

    local bar = spec.bar
    r.bar:SetShown(bar ~= nil)
    r.value:SetShown(bar == nil)
    if bar then
        r.bar:SetMinMaxValues(0, bar.max)
        r.bar:SetValue(math.min(bar.value, bar.max))
        r.bar:SetStatusBarColor(bar.color[1], bar.color[2], bar.color[3])
        r.bar.text:SetText(spec.value or "")
        r.bar.mark:SetPoint("CENTER", r.bar, "LEFT", BAR_W * bar.mark / bar.max, 0)
    end

    r.tooltip = spec.tooltip
    r.link = spec.link
    r:Show()
    y = y + ROW_H
end
