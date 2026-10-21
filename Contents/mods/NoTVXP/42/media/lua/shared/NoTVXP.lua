-- No XP From Life and Living (VHS Still Teaches)
-- Copyright (C) 2026 Okarim
-- SPDX-License-Identifier: GPL-3.0-or-later
--
-- This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
-- License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any
-- later version. It is distributed WITHOUT ANY WARRANTY. Full text: LICENSE in the mod folder or
-- https://www.gnu.org/licenses/gpl-3.0.html
--
-- The game has one sandbox option for all media (SandboxVars.LevelForMediaXPCutoff), so it cannot turn off TV
-- skill shows alone. In vanilla only the Life and Living TV channel has skill codes; modded channels are covered too. Device text reaches ISRadioInteractions through Events.OnDeviceText(guid, codes, x, y, z, line).
-- Recorded media lines (VHS, CD) carry the text guid from recorded_media.lua, which starts with "RM_"; broadcast
-- lines (TV, radio) carry their guid from RadioData.xml without that prefix. Tapes added by other mods may use any key,
-- so every line key registered in RecMedia also counts as recorded. For broadcast lines we drop the skill
-- codes (CRP+1, COO+2, ...) and keep the rest (boredom, mood, recipes). The guid stays, so a line heard once still
-- does nothing the second time, like in vanilla. Broadcast and tape guids never overlap (checked on 42.x data), so
-- hearing a show on TV does not use up a tape.

local SKILL = {
    SPR = true, LFT = true, NIM = true, SNE = true, BAA = true, BUA = true, CRP = true, COO = true, FRM = true,
    DOC = true, ELC = true, MTL = true, FKN = true, CRV = true, AIM = true, REL = true, FIS = true, TRA = true,
    FOR = true, TAI = true, MEC = true, CMB = true, SPE = true, SBU = true, LBA = true, SBA = true, MAS = true,
    POT = true, BLA = true, GLA = true, HUS = true, BUT = true, TRK = true,
}

local function withoutSkills(codes)
    local kept = {}
    for code in string.gmatch(codes, "([^,]+)") do
        if not SKILL[string.sub(code, 1, 3)] then
            table.insert(kept, code)
        end
    end
    return table.concat(kept, ",")
end

local recordedKeys = nil

local function isRecorded(guid)
    if guid == nil then return false end
    if string.sub(guid, 1, 3) == "RM_" then return true end
    if recordedKeys == nil then
        recordedKeys = {}
        for _, media in pairs(RecMedia or {}) do
            for _, line in ipairs(media.lines or {}) do
                if line.text then recordedKeys[line.text] = true end
            end
        end
    end
    return recordedKeys[guid] == true
end

local function install()
    if not ISRadioInteractions or NoTVXP_INSTALLED then return end
    local inst = ISRadioInteractions:getInstance()
    local original = inst.OnDeviceText
    Events.OnDeviceText.Remove(original)
    inst.OnDeviceText = function(guid, codes, x, y, z, line)
        if codes ~= nil and codes ~= "" and not isRecorded(guid) then
            codes = withoutSkills(codes)
        end
        return original(guid, codes, x, y, z, line)
    end
    Events.OnDeviceText.Add(inst.OnDeviceText)
    NoTVXP_INSTALLED = true
    print("[NoTVXP] TV and radio broadcasts give no skill XP; VHS and CDs unchanged")
end

Events.OnGameBoot.Add(install)
Events.OnServerStarted.Add(install)
