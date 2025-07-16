------------------------------------------------------------------------------------------------
--
--  PROJECT:         Trident Sky Company
--  VERSION:         2.0
--  FILE:            editorC.lua
--  PURPOSE:         Lua Code Editor Client-side
--  DEVELOPERS:      [BranD] - Lead Developer
--  CONTACT:         tridentskycompany@gmail.com | Discord: BrandSilva
--  COPYRIGHT:       © 2025 Brando Silva All rights reserved.
--                   This software is protected by copyright laws.
--                   Unauthorized distribution or modification is strictly prohibited.
--
------------------------------------------------------------------------------------------------

local editorBrowser = nil
local editorGui = nil
local isMinimized = false

function createEditorPanel()
    if (editorGui) then
        destroyElement(editorGui)
        editorGui = nil
        editorBrowser = nil
    end
    
    local screenW, screenH = guiGetScreenSize()
    editorGui = guiCreateBrowser(0, 0, screenW, screenH, true, true, false)
    
    if (editorGui) then
        editorBrowser = guiGetBrowser(editorGui)
        addEventHandler("onClientBrowserCreated", editorGui, onBrowserCreated)
        guiSetVisible(editorGui, true)
        guiBringToFront(editorGui)
        showCursor(true)
        return true
    end
    
    return false
end

function onBrowserCreated()
    if (editorBrowser) then
        loadBrowserURL(editorBrowser, "http://mta/local/index.html")
        focusBrowser(editorBrowser)
    end
end

function openEditorPanel(scripts)
    if (not editorGui) then
        if (createEditorPanel()) then
            setTimer(function()
                if (editorBrowser and guiGetVisible(editorGui)) then
                    loadScriptsList(scripts)
                end
            end, 2000, 1)
        end
    else
        if (not guiGetVisible(editorGui)) then
            guiSetVisible(editorGui, true)
            guiBringToFront(editorGui)
            showCursor(true)
            focusBrowser(editorBrowser)
            isMinimized = false
            loadScriptsList(scripts)
        end
    end
end

function loadScriptsList(scripts)
    if (not editorBrowser or not guiGetVisible(editorGui)) then return end
    
    if (scripts and #scripts > 0) then
        local jsArray = "["
        for i, script in ipairs(scripts) do
            if (i > 1) then jsArray = jsArray .. "," end
            
            local clientFiles = "["
            if (script.clientFiles) then
                for j, file in ipairs(script.clientFiles) do
                    if (j > 1) then clientFiles = clientFiles .. "," end
                    clientFiles = clientFiles .. '"' .. file .. '"'
                end
            end
            clientFiles = clientFiles .. "]"
            
            local serverFiles = "["
            if (script.serverFiles) then
                for j, file in ipairs(script.serverFiles) do
                    if (j > 1) then serverFiles = serverFiles .. "," end
                    serverFiles = serverFiles .. '"' .. file .. '"'
                end
            end
            serverFiles = serverFiles .. "]"
            
            jsArray = jsArray .. '{'
            jsArray = jsArray .. 'name:"' .. script.name .. '",'
            jsArray = jsArray .. 'clientFiles:' .. clientFiles .. ','
            jsArray = jsArray .. 'serverFiles:' .. serverFiles
            jsArray = jsArray .. '}'
        end
        jsArray = jsArray .. "]"
        
        executeBrowserJavascript(editorBrowser, "loadScriptsList(" .. jsArray .. ");")
    end
end

function loadScriptFiles(scriptName, files)
    if (not editorBrowser or not guiGetVisible(editorGui)) then return end
    
    if (not files or #files == 0) then
        executeBrowserJavascript(editorBrowser, "loadScriptFiles([]);")
        return
    end
    
    local jsArray = "["
    for i, file in ipairs(files) do
        if (i > 1) then jsArray = jsArray .. "," end
        
        local isCompiled = string.find(file.path, "%.luac$") ~= nil
        
        jsArray = jsArray .. '{'
        jsArray = jsArray .. 'path:"' .. file.path .. '",'
        jsArray = jsArray .. 'type:"' .. file.type .. '",'
        jsArray = jsArray .. 'compiled:' .. (isCompiled and "true" or "false")
        jsArray = jsArray .. '}'
    end
    jsArray = jsArray .. "]"
    
    executeBrowserJavascript(editorBrowser, "loadScriptFiles(" .. jsArray .. ");")
end

function sendFileContent(content)
    if (not editorBrowser or not guiGetVisible(editorGui)) then return end
    
    local escapedContent = content:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\n", "\\n"):gsub("\r", "")
    executeBrowserJavascript(editorBrowser, 'receiveFileContent("' .. escapedContent .. '");')
end

function closePanel()
    if (editorGui) then
        removeEventHandler("onClientBrowserCreated", editorGui, onBrowserCreated)
        destroyElement(editorGui)
        editorGui = nil
        editorBrowser = nil
        showCursor(false)
        isMinimized = false
    end
end
addEvent("closePanel", true)
addEventHandler("closePanel", root, closePanel)

function minimizePanel()
    if (editorGui and guiGetVisible(editorGui)) then
        guiSetVisible(editorGui, false)
        showCursor(false)
        isMinimized = true
    end
end
addEvent("minimizePanel", true)
addEventHandler("minimizePanel", root, minimizePanel)

function restoreEditorPanel()
    if (editorGui and isMinimized) then
        guiSetVisible(editorGui, true)
        guiBringToFront(editorGui)
        showCursor(true)
        focusBrowser(editorBrowser)
        isMinimized = false
    end
end

function requestScriptsList()
    triggerServerEvent("luaEditor.requestScriptsList", localPlayer)
end
addEvent("requestScriptsList", true)
addEventHandler("requestScriptsList", root, requestScriptsList)

function requestScriptFiles(scriptName)
    if (scriptName and scriptName ~= "") then
        triggerServerEvent("luaEditor.requestScriptFiles", localPlayer, scriptName)
    end
end
addEvent("requestScriptFiles", true)
addEventHandler("requestScriptFiles", root, requestScriptFiles)

function requestFileContent(scriptName, filePath)
    if (scriptName and filePath and scriptName ~= "" and filePath ~= "") then
        triggerServerEvent("luaEditor.requestFileContent", localPlayer, scriptName, filePath)
    end
end
addEvent("requestFileContent", true)
addEventHandler("requestFileContent", root, requestFileContent)

function saveFileContent(scriptName, filePath, content)
    if (scriptName and filePath and content and scriptName ~= "" and filePath ~= "") then
        triggerServerEvent("luaEditor.saveFileContent", localPlayer, scriptName, filePath, content)
    end
end
addEvent("saveFileContent", true)
addEventHandler("saveFileContent", root, saveFileContent)

function onScriptsListReceived(scripts)
    openEditorPanel(scripts)
end
addEvent("luaEditor.onScriptsListReceived", true)
addEventHandler("luaEditor.onScriptsListReceived", localPlayer, onScriptsListReceived)

function onScriptFilesReceived(scriptName, files)
    loadScriptFiles(scriptName, files)
end
addEvent("luaEditor.onScriptFilesReceived", true)
addEventHandler("luaEditor.onScriptFilesReceived", localPlayer, onScriptFilesReceived)

function onFileContentReceived(content)
    sendFileContent(content)
end
addEvent("luaEditor.onFileContentReceived", true)
addEventHandler("luaEditor.onFileContentReceived", localPlayer, onFileContentReceived)

function onFileSaved(success, message)
    if (editorBrowser and guiGetVisible(editorGui)) then
        local jsMessage = message:gsub("\\", "\\\\"):gsub("\"", "\\\"")
        executeBrowserJavascript(editorBrowser, 'onFileSaved(' .. (success and "true" or "false") .. ', "' .. jsMessage .. '");')
    end
end
addEvent("luaEditor.onFileSaved", true)
addEventHandler("luaEditor.onFileSaved", localPlayer, onFileSaved)